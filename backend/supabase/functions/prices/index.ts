// Edge Function "prices": отдаёт приложению цены по направлению.
//
// Пример запроса:
//   GET /functions/v1/prices?origin=KGF&destination=BUD&month=2026-12
//   GET /functions/v1/prices?origin=KGF&destination=BUD&month=2026-12&nearby=true
//   GET /functions/v1/prices?origin=ALA&destination=BUD&month=2026-12&currency=usd   (валюта; по умолчанию kzt)
//
// Как это работает:
//   1. Проверяем параметры.
//   2. Берём цены через общий модуль (кэш 6 часов, при промахе — запрос к Travelpayouts).
//
// Токен Travelpayouts берётся ТОЛЬКО из переменной окружения и никогда не уходит в приложение.

import { createClient } from "npm:@supabase/supabase-js@2";
import { getPrices } from "../_shared/prices.ts";
import { DEFAULT_CURRENCY, isCurrency } from "../_shared/currencies.ts";

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

Deno.serve(async (req) => {
  if (req.method !== "GET") return json({ error: "Только GET" }, 405);
  if (!Deno.env.get("TRAVELPAYOUTS_TOKEN")) return json({ error: "Сервер не настроен" }, 500);

  // Проверка параметров (защита от мусора и подстановки лишнего в запрос).
  const p = new URL(req.url).searchParams;
  const origin = (p.get("origin") ?? "").toUpperCase();
  const destination = (p.get("destination") ?? "").toUpperCase();
  const month = p.get("month") ?? ""; // YYYY-MM
  const nearby = p.get("nearby") === "true";
  const currency = (p.get("currency") ?? DEFAULT_CURRENCY).toLowerCase();

  if (!/^[A-Z]{3}$/.test(origin) || !/^[A-Z]{3}$/.test(destination)) {
    return json({ error: "origin и destination — трёхбуквенные коды IATA, например KGF" }, 400);
  }
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    return json({ error: "month — в формате YYYY-MM, например 2026-12" }, 400);
  }

  if (!isCurrency(currency)) return json({ error: "Неподдерживаемая валюта" }, 400);

  try {
    return json(await getPrices(db, { origin, destination, month, nearby, currency }));
  } catch {
    return json({ error: "Не удалось получить цены, попробуйте позже" }, 502);
  }
});
