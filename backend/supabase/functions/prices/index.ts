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

  const p = new URL(req.url).searchParams;
  const origin = (p.get("origin") ?? "").toUpperCase();
  const destination = (p.get("destination") ?? "").toUpperCase();
  const month = p.get("month") ?? "";
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
