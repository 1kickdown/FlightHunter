// Edge Function "cities": список городов для выбора в приложении.
//
//   GET /functions/v1/cities
//
// Берёт справочник Travelpayouts (русские названия), оставляет только города
// с аэропортом, к которым можно купить билет, и сжимает до нужных полей.
// Справочник общий для всех и меняется редко, поэтому кэшируем на сутки.
// Приложение ходит только к нашему бэкенду, а не к Travelpayouts напрямую.

import { createClient } from "npm:@supabase/supabase-js@2";

const SOURCE = "https://api.travelpayouts.com/data/ru/cities.json";
const FALLBACK_SOURCE = "https://api.travelpayouts.com/data/cities.json"; // английский, если русский недоступен
const CACHE_KEY = "cities:ru";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // сутки

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Город в формате для приложения.
interface City {
  code: string; // код IATA, например "ALA"
  name: string; // название на русском, например "Алматы"
  name_en: string; // английское название — по нему тоже можно искать
  country: string; // код страны, например "KZ"
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function load(url: string): Promise<City[]> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Справочник ответил ${res.status}`);
  const raw: any[] = await res.json();
  return raw
    .filter((c) => c.has_flightable_airport && /^[A-Z]{3}$/.test(c.code ?? "") && c.name)
    .map((c) => ({
      code: c.code,
      name: c.name,
      name_en: c.name_translations?.en ?? c.name,
      country: c.country_code ?? "",
    }))
    .sort((a, b) => a.name.localeCompare(b.name, "ru"));
}

Deno.serve(async (req) => {
  if (req.method !== "GET") return json({ error: "Только GET" }, 405);

  const { data: cached } = await db
    .from("price_cache").select("payload, fetched_at").eq("cache_key", CACHE_KEY).maybeSingle();
  if (cached && Date.now() - new Date(cached.fetched_at).getTime() < CACHE_TTL_MS) {
    return json({ ...cached.payload, cached: true });
  }

  try {
    let cities: City[];
    try {
      cities = await load(SOURCE);
    } catch {
      cities = await load(FALLBACK_SOURCE);
    }
    const payload = { cities };
    await db.from("price_cache").upsert({
      cache_key: CACHE_KEY, payload, fetched_at: new Date().toISOString(),
    });
    return json({ ...payload, cached: false });
  } catch (e) {
    console.error(e);
    // Лучше отдать устаревший список, чем ничего.
    if (cached) return json({ ...cached.payload, cached: true, stale: true });
    return json({ error: "Не удалось получить список городов" }, 502);
  }
});
