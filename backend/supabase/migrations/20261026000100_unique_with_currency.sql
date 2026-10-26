-- Один и тот же маршрут можно отслеживать в разных валютах, поэтому валюта входит в уникальный ключ подписки.
do $$
declare
  c text;
begin
  -- Находим прежний уникальный ключ (его имя Postgres сгенерировал сам) и удаляем
  for c in
    select conname from pg_constraint
    where conrelid = 'public.subscriptions'::regclass and contype = 'u'
  loop
    execute format('alter table public.subscriptions drop constraint %I', c);
  end loop;
end $$;

alter table public.subscriptions
  add constraint subscriptions_unique_route
  unique (install_id, origin, destination, month, include_nearby, currency);
