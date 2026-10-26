// Общая логика получения цен: запрос к Travelpayouts + кэш в таблице price_cache.
// Используется функцией "prices" (для приложения) и "check-prices" (проверка по расписанию),
// поэтому оба работают с одним кэшем и не дёргают Travelpayouts лишний раз.

import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

export const DEFAULT_TTL_MS = 6 * 60 * 60 * 1000; // сколько кэш считается свежим
const API = "https://api.travelpayouts.com";

// Один день в календаре цен — формат ответа для приложения.
export interface Day {
  date: string; // дата вылета, YYYY-MM-DD
  price: number;
  transfers: number; // число пересадок
  return_date: string | null; // дата обратного рейса, null если билет в одну сторону
  origin: string;
  destination: string;
}

export interface PricesPayload {
  origin: string;
  destination: string;
  month: string;
  nearby: boolean;
  currency: string; // валюта цен: kzt, rub, usd...
  days: Day[];
  cheapest: Day[]; // 10 самых дешёвых дат
  no_fresh_prices: boolean; // true — данных нет, приложение покажет «нет свежих цен»
}

export type PricesResult = PricesPayload & { cached: boolean; stale?: boolean };

// Запрос к Travelpayouts. Токен передаём в заголовке, а не в адресе — так он не попадёт в логи.
async function tp(path: string, params: Record<string, string>) {
  const token = Deno.env.get("TRAVELPAYOUTS_TOKEN") ?? "";
  const url = new URL(API + path);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const res = await fetch(url, { headers: { "X-Access-Token": token } });
  if (!res.ok) throw new Error(`Travelpayouts ответил ${res.status}`);
  return await res.json();
}

// Из списка вариантов оставляем для каждой пары (дата, обратная дата, откуда, куда) самый дешёвый,
// и сортируем по дате.
export function toDays(items: any[]): Day[] {
  const best = new Map<string, Day>();
  for (const it of items ?? []) {
    // Разные эндпоинты называют поля по-разному: value/price, number_of_changes/transfers,
    // а дата иногда приходит со временем ("2026-11-09T05:45:00+06:00") — берём только день.
    const price = it?.value ?? it?.price;
    const date = String(it?.depart_date ?? "").slice(0, 10);
    if (!date || typeof price !== "number") continue;
    const day: Day = {
      date,
      price: Math.round(price),
      transfers: it.number_of_changes ?? it.transfers ?? 0,
      return_date: it.return_date ? String(it.return_date).slice(0, 10) : null,
      origin: it.origin,
      destination: it.destination,
    };
    const key = `${day.date}|${day.return_date}|${day.origin}|${day.destination}`;
    const prev = best.get(key);
    if (!prev || day.price < prev.price) best.set(key, day);
  }
  return [...best.values()].sort((a, b) => a.date.localeCompare(b.date));
}

// Цены по направлению за месяц: из кэша, если он свежее ttlMs, иначе из Travelpayouts.
// Если Travelpayouts недоступен, но есть старый кэш — отдаёт его с пометкой stale.
// Если нет ни того, ни другого — бросает ошибку.
export async function getPrices(
  db: SupabaseClient,
  q: { origin: string; destination: string; month: string; nearby: boolean; currency: string },
  ttlMs = DEFAULT_TTL_MS,
): Promise<PricesResult> {
  const { origin, destination, month, nearby, currency } = q;
  // Валюта входит в ключ: цены в разных валютах кэшируются отдельно.
  const cacheKey = `${nearby ? "nearby" : "month-matrix"}:${currency}:${origin}:${destination}:${month}`;
  const { data: cached } = await db
    .from("price_cache").select("payload, fetched_at").eq("cache_key", cacheKey).maybeSingle();
  if (cached && Date.now() - new Date(cached.fetched_at).getTime() < ttlMs) {
    return { ...cached.payload, cached: true };
  }

  try {
    let days: Day[];
    if (nearby) {
      // Цены через соседние города (например, из Астаны вместо Караганды).
      const r = await tp("/v2/prices/nearest-places-matrix", {
        origin, destination, currency, depart_date: month,
        flexibility: "7", limit: "7", show_to_affiliates: "true",
      });
      days = toDays(r.prices);
    } else {
      // Календарь цен на месяц. Параметр month — первое число месяца.
      const r = await tp("/v2/prices/month-matrix", {
        origin, destination, currency, month: `${month}-01`,
        show_to_affiliates: "true",
      });
      days = toDays(r.data);
    }

    const payload: PricesPayload = {
      origin, destination, month, nearby, currency,
      days,
      cheapest: [...days].sort((a, b) => a.price - b.price).slice(0, 10),
      no_fresh_prices: days.length === 0,
    };
    await db.from("price_cache").upsert({
      cache_key: cacheKey, payload, fetched_at: new Date().toISOString(),
    });
    return { ...payload, cached: false };
  } catch (e) {
    console.error(e);
    if (cached) return { ...cached.payload, cached: true, stale: true };
    throw e;
  }
}
