-- Кэш ответов Travelpayouts, чтобы не дёргать их API на каждый запрос пользователя.
create table if not exists public.price_cache (
  -- Ключ запроса, например "month-matrix:KGF:BUD:2026-12:any"
  cache_key  text primary key,
  -- Уже нормализованный ответ (то, что мы отдаём приложению)
  payload    jsonb       not null,
  -- Когда запись сохранена; по ней решаем, свежая она или нет
  fetched_at timestamptz not null default now()
);

-- Включаем защиту строк и не создаём политик: напрямую из приложения таблица недоступна.
-- Edge Function ходит в неё через service_role-ключ, который RLS обходит.
alter table public.price_cache enable row level security;
