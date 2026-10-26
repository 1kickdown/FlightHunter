-- Серверное хранение: устройства, подписки на направления и история цен.
-- Аккаунтов нет: устройство опознаётся случайным анонимным ID установки (install_id).

-- Устройство = одна установка приложения.
create table if not exists public.devices (
  install_id  uuid primary key,                 -- анонимный ID из приложения (InstallID)
  push_token  text,                             -- токен APNs; null, пока нет разрешения на пуши
  environment text not null default 'production'
              check (environment in ('sandbox', 'production')),  -- отладочная или боевая сборка
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Подписка = направление, за которым следит пользователь.
create table if not exists public.subscriptions (
  id                  uuid primary key default gen_random_uuid(),
  install_id          uuid not null references public.devices(install_id) on delete cascade,
  origin              text not null check (origin ~ '^[A-Z]{3}$'),
  destination         text not null check (destination ~ '^[A-Z]{3}$'),
  month               text not null check (month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
  include_nearby      boolean not null default false,
  threshold_kzt       integer check (threshold_kzt is null or threshold_kzt > 0),
  -- Служебные поля для решения «слать ли пуш»:
  last_price          integer,                  -- последняя найденная лучшая цена
  last_notified_price integer,                  -- цена, о которой уже сообщили
  last_notified_at    timestamptz,              -- когда сообщили
  created_at          timestamptz not null default now(),
  -- Одно и то же направление у одного устройства не дублируется
  unique (install_id, origin, destination, month, include_nearby)
);

-- Быстрый поиск подписок по маршруту (так задача по расписанию собирает уникальные маршруты)
create index if not exists subscriptions_route_idx
  on public.subscriptions (origin, destination, month, include_nearby);

-- История лучших цен по маршруту: по ней определяем «обычную» цену.
create table if not exists public.price_history (
  origin         text    not null,
  destination    text    not null,
  month          text    not null,
  include_nearby boolean not null,
  day            date    not null,              -- день замера
  best_price     integer not null,              -- лучшая цена в этот день, ₸
  primary key (origin, destination, month, include_nearby, day)
);

-- Прямого доступа из приложения к таблицам нет (RLS включён, политик нет).
-- Edge Functions работают через service_role и обходят RLS.
alter table public.devices       enable row level security;
alter table public.subscriptions enable row level security;
alter table public.price_history enable row level security;
