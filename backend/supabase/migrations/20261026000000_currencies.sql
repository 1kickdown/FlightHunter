-- Несколько валют: у каждого направления теперь своя валюта, а порог цены задан в ней.

-- Порог больше не обязательно в тенге: колонка переименована из threshold_kzt в threshold
alter table public.subscriptions rename column threshold_kzt to threshold;

-- Валюта направления (код в нижнем регистре: kzt, rub, usd...). У уже сохранённых — тенге.
alter table public.subscriptions
  add column if not exists currency text not null default 'kzt'
  check (currency ~ '^[a-z]{3}$');

-- История цен ведётся отдельно по каждой валюте (цены в разных валютах нельзя смешивать)
alter table public.price_history
  add column if not exists currency text not null default 'kzt';
alter table public.price_history drop constraint if exists price_history_pkey;
alter table public.price_history
  add primary key (origin, destination, month, include_nearby, currency, day);
