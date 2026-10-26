-- Запуск проверки цен по расписанию: pg_cron вызывает Edge Function "check-prices" через pg_net.
-- В миграции нет ни адресов, ни секретов: они берутся из Supabase Vault (секреты
-- 'project_url' и 'cron_secret'), которые создаются отдельно. Если их нет (например, локально),
-- запуск просто ничего не делает.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net  with schema extensions;

create or replace function public.run_check_prices()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url    text;
  v_secret text;
begin
  select decrypted_secret into v_url    from vault.decrypted_secrets where name = 'project_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'cron_secret';
  if v_url is null or v_secret is null then
    return; -- не настроено, ничего не делаем
  end if;

  -- Асинхронный POST: ответ нам не нужен, функция сама пишет историю и шлёт пуши
  perform net.http_post(
    url     := v_url || '/functions/v1/check-prices',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', v_secret),
    body    := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
end;
$$;

-- Вызывать функцию могут только сервисные роли и cron, но не клиенты
revoke all on function public.run_check_prices() from public, anon, authenticated;

-- Расписание (время UTC): 04:00, 08:00, 12:00, 15:00 = 09:00, 13:00, 17:00, 20:00 по Казахстану,
-- то есть внутри окна, когда разрешены пуши (9:00–21:00).
select cron.schedule('check-prices', '0 4,8,12,15 * * *', 'select public.run_check_prices()');
