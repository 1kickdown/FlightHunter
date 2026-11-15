import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

export const DEFAULT_TTL_MS = 6 * 60 * 60 * 1000;
const API = "https://api.travelpayouts.com";

export interface Day {
  date: string;
  price: number;
  transfers: number;
  return_date: string | null;
  origin: string;
  destination: string;
}

export interface PricesPayload {
  origin: string;
  destination: string;
  month: string;
  nearby: boolean;
  currency: string;
  days: Day[];
  cheapest: Day[];
  no_fresh_prices: boolean;
}

export type PricesResult = PricesPayload & { cached: boolean; stale?: boolean };

async function tp(path: string, params: Record<string, string>) {
  const token = Deno.env.get("TRAVELPAYOUTS_TOKEN") ?? "";
  const url = new URL(API + path);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const res = await fetch(url, { headers: { "X-Access-Token": token } });
  if (!res.ok) throw new Error(`Travelpayouts ответил ${res.status}`);
  return await res.json();
}

export function toDays(items: any[]): Day[] {
  const best = new Map<string, Day>();
  for (const it of items ?? []) {
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

export async function getPrices(
  db: SupabaseClient,
  q: { origin: string; destination: string; month: string; nearby: boolean; currency: string },
  ttlMs = DEFAULT_TTL_MS,
): Promise<PricesResult> {
  const { origin, destination, month, nearby, currency } = q;
  const cacheKey = `${nearby ? "nearby" : "month-matrix"}:${currency}:${origin}:${destination}:${month}`;
  const { data: cached } = await db
    .from("price_cache").select("payload, fetched_at").eq("cache_key", cacheKey).maybeSingle();
  if (cached && Date.now() - new Date(cached.fetched_at).getTime() < ttlMs) {
    return { ...cached.payload, cached: true };
  }

  try {
    let days: Day[];
    if (nearby) {
      const r = await tp("/v2/prices/nearest-places-matrix", {
        origin, destination, currency, depart_date: month,
        flexibility: "7", limit: "7", show_to_affiliates: "true",
      });
      days = toDays(r.prices);
    } else {
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
