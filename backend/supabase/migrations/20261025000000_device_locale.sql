-- Язык интерфейса приложения на устройстве: на нём сервер пишет текст push-уведомлений.
alter table public.devices
  add column if not exists locale text not null default 'ru'
  check (locale in ('ru', 'en'));
