// Edge Function "check-prices": проверяет цены по всем подпискам и решает, кого уведомить.
// Запускается по расписанию (pg_cron), а не из приложения.
//
//   POST /functions/v1/check-prices                 — боевой запуск (шлёт пуши)
//   POST /functions/v1/check-prices?dry_run=true    — пробный: ничего не шлёт и не меняет, только показывает,
//                                                     что было бы отправлено
//   POST /functions/v1/check-prices?dry_run=true&now=2026-11-01T08:00:00Z — пробный запуск «в другое время»
//
// Защита: без заголовка x-cron-secret (равного секрету CRON_SECRET) функция не работает,
// иначе любой мог бы запустить рассылку.

import { createClient } from "npm:@supabase/supabase-js@2";
import { getPrices } from "../_shared/prices.ts";
import { decide, inQuietHours, median, RULES } from "../_shared/rules.ts";

// Запуски идут раз в 3–4 часа, поэтому берём кэш не старше 3 часов, чтобы цены были свежими.
const CRON_CACHE_TTL_MS = 3 * 60 * 60 * 1000;
const CONCURRENCY = 4; // сколько маршрутов проверяем одновременно

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ---- Тексты пуша ----

type Locale = "ru" | "en";

const MONTHS: Record<Locale, string[]> = {
  ru: ["янв.", "февр.", "мар.", "апр.", "мая", "июн.", "июл.", "авг.", "сент.", "окт.", "нояб.", "дек."],
  en: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
};

// "2026-12-11" → "11 дек." или "Dec 11"
function dayText(date: string, locale: Locale): string {
  const [, m, d] = date.split("-");
  const month = MONTHS[locale][Number(m) - 1];
  return locale === "ru" ? `${Number(d)} ${month}` : `${month} ${Number(d)}`;
}

// 50980, "kzt" → "50 980 ₸" (ru) или "KZT 50,980" / "$206" (en) — формат берётся из Intl
function priceText(value: number, currency: string, locale: Locale): string {
  return new Intl.NumberFormat(locale === "ru" ? "ru-RU" : "en-US", {
    style: "currency", currency: currency.toUpperCase(), maximumFractionDigits: 0,
  }).format(value);
}

// Тексты пуша на языке устройства
const TEXTS: Record<Locale, { title: string; on: string; threshold: string; usual: string }> = {
  ru: { title: "Цена на билеты упала", on: "на", threshold: "ниже вашего порога", usual: "ниже обычной цены" },
  en: { title: "Flight price dropped", on: "on", threshold: "below your threshold", usual: "below the usual price" },
};

// Названия городов из кэша справочника на обоих языках
// (если справочник ещё не загружали — в тексте будут коды городов).
async function loadCityNames(): Promise<Record<Locale, Map<string, string>>> {
  const { data } = await db.from("price_cache").select("payload").eq("cache_key", "cities:ru").maybeSingle();
  const names = { ru: new Map<string, string>(), en: new Map<string, string>() };
  for (const c of data?.payload?.cities ?? []) {
    names.ru.set(c.code, c.name);
    names.en.set(c.code, c.name_en ?? c.name);
  }
  return names;
}

// ---- Данные ----

interface Subscription {
  id: string;
  install_id: string;
  origin: string;
  destination: string;
  month: string;
  include_nearby: boolean;
  threshold: number | null;
  currency: string;
  last_notified_price: number | null;
  last_notified_at: string | null;
  devices: { push_token: string | null; environment: string; locale: Locale };
}

// Маршрут = направление + месяц + режим + валюта (цены в разных валютах проверяются отдельно)
const routeKey = (s: { origin: string; destination: string; month: string; include_nearby: boolean; currency: string }) =>
  `${s.origin}|${s.destination}|${s.month}|${s.include_nearby}|${s.currency}`;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Только POST" }, 405);

  // Защита от посторонних запусков
  const secret = Deno.env.get("CRON_SECRET") ?? "";
  if (!secret) return json({ error: "Сервер не настроен" }, 500);
  if (req.headers.get("x-cron-secret") !== secret) return json({ error: "Нет доступа" }, 401);

  const params = new URL(req.url).searchParams;
  const dryRun = params.get("dry_run") === "true";
  // Подмена времени разрешена только в пробном режиме (чтобы проверять тихие часы)
  const nowParam = dryRun ? params.get("now") : null;
  const now = nowParam && !isNaN(Date.parse(nowParam)) ? new Date(nowParam) : new Date();
  const today = now.toISOString().slice(0, 10);
  const currentMonth = today.slice(0, 7);

  // 1. Все подписки с токеном и не из прошлых месяцев
  const { data: subs, error } = await db
    .from("subscriptions")
    .select("id, install_id, origin, destination, month, include_nearby, threshold, currency, " +
      "last_notified_price, last_notified_at, devices!inner(push_token, environment, locale)")
    .gte("month", currentMonth);
  if (error) {
    console.error(error);
    return json({ error: "Не удалось прочитать подписки" }, 500);
  }
  const subscriptions = (subs ?? []) as unknown as Subscription[];

  // 2. Группируем по маршруту: один запрос цен на всех подписчиков маршрута
  const routes = new Map<string, Subscription[]>();
  for (const s of subscriptions) {
    const k = routeKey(s);
    routes.set(k, [...(routes.get(k) ?? []), s]);
  }

  const cityNames = await loadCityNames();
  const city = (code: string, locale: Locale) => cityNames[locale].get(code) ?? code;

  const notifications: any[] = [];
  const skipped: { subscription_id: string; reason: string }[] = [];
  const errors: string[] = [];
  const quiet = inQuietHours(now);

  // 3. Проверяем один маршрут
  async function checkRoute(group: Subscription[]) {
    const first = group[0];
    try {
      const prices = await getPrices(db, {
        origin: first.origin, destination: first.destination,
        month: first.month, nearby: first.include_nearby, currency: first.currency,
      }, CRON_CACHE_TTL_MS);
      const bestDay = prices.no_fresh_prices ? null : prices.cheapest[0];

      if (!bestDay) {
        for (const s of group) skipped.push({ subscription_id: s.id, reason: "нет свежих цен" });
        return;
      }

      // «Обычная» цена: медиана замеров за последние 14 дней (не считая сегодняшний)
      const since = new Date(now.getTime() - RULES.HISTORY_DAYS * 86_400_000).toISOString().slice(0, 10);
      const { data: history } = await db.from("price_history").select("best_price")
        .eq("origin", first.origin).eq("destination", first.destination)
        .eq("month", first.month).eq("include_nearby", first.include_nearby)
        .eq("currency", first.currency)
        .gte("day", since).lt("day", today);
      const usual = (history?.length ?? 0) >= RULES.MIN_HISTORY_POINTS
        ? median(history!.map((h) => h.best_price)) : null;

      // Запоминаем сегодняшнюю лучшую цену в истории (кроме пробного запуска)
      if (!dryRun) {
        await db.from("price_history").upsert({
          origin: first.origin, destination: first.destination, month: first.month,
          include_nearby: first.include_nearby, currency: first.currency, day: today, best_price: bestDay.price,
        });
      }

      for (const s of group) {
        if (!s.devices.push_token) {
          skipped.push({ subscription_id: s.id, reason: "нет push-токена" });
          continue;
        }
        const decision = decide({
          best: bestDay.price, threshold: s.threshold, median: usual,
          lastNotifiedPrice: s.last_notified_price,
          lastNotifiedAt: s.last_notified_at ? new Date(s.last_notified_at) : null, now,
        });
        if (!decision.notify) {
          skipped.push({ subscription_id: s.id, reason: decision.skip });
          continue;
        }
        if (quiet) {
          skipped.push({ subscription_id: s.id, reason: "тихие часы (вне 9:00–21:00 по Казахстану)" });
          continue;
        }
        const locale: Locale = s.devices.locale === "en" ? "en" : "ru";
        const t = TEXTS[locale];
        const why = decision.reason === "threshold" ? t.threshold : t.usual;
        notifications.push({
          subscription_id: s.id,
          install_id: s.install_id,
          reason: decision.reason,
          price: bestDay.price,
          usual_price: usual,
          title: t.title,
          body: `${city(s.origin, locale)} → ${city(s.destination, locale)}: ${priceText(bestDay.price, s.currency, locale)} ${t.on} ${dayText(bestDay.date, locale)} (${why})`,
          // Данные для открытия нужного экрана по нажатию на пуш
          data: { origin: s.origin, destination: s.destination, month: s.month, nearby: s.include_nearby },
          _token: s.devices.push_token, _env: s.devices.environment,
        });
      }
    } catch (e) {
      console.error(e);
      errors.push(`${first.origin}→${first.destination} ${first.month}: не удалось получить цены`);
    }
  }

  // Маршруты проверяем с ограниченной параллельностью
  const queue = [...routes.values()];
  await Promise.all(Array.from({ length: Math.min(CONCURRENCY, queue.length) }, async () => {
    while (queue.length > 0) await checkRoute(queue.shift()!);
  }));

  // 4. Отправка. Реальная отправка через APNs появится на шаге 5.4.
  let sent = 0;
  if (!dryRun && notifications.length > 0) {
    return json({
      error: "Отправка через APNs ещё не подключена (шаг 5.4)",
      pending: notifications.length,
    }, 501);
  }

  return json({
    dry_run: dryRun,
    now: now.toISOString(),
    quiet_hours: quiet,
    routes: routes.size,
    subscriptions: subscriptions.length,
    sent,
    // В ответ не попадают токены устройств
    notifications: notifications.map(({ _token, _env, install_id, ...rest }) => rest),
    skipped,
    errors,
  });
});
