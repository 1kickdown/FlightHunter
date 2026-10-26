// Edge Function "sync": приложение присылает свой анонимный ID, push-токен и список направлений,
// сервер сохраняет их, чтобы потом проверять цены и слать пуши.
//
//   POST /functions/v1/sync
//   {
//     "install_id": "9b2f...-uuid",
//     "push_token": "ab12...",          // можно null, если пуши не разрешены
//     "environment": "sandbox",         // "sandbox" (отладка из Xcode) или "production"
//     "locale": "ru",                   // язык интерфейса: "ru" или "en" (на нём пишется текст пуша)
//     "destinations": [
//       { "origin": "ALA", "destination": "BUD", "month": "2026-11",
//         "include_nearby": false, "currency": "kzt", "threshold": 70000 }  // порог — в валюте направления
//     ]
//   }
//
// Присланный список считается полным: чего в нём нет, с сервера удаляется.
// Аккаунтов нет: install_id (случайный UUID) служит секретным ключом устройства.

import { createClient } from "npm:@supabase/supabase-js@2";
import { DEFAULT_CURRENCY, isCurrency } from "../_shared/currencies.ts";

const MAX_DESTINATIONS = 10; // лимит на устройство, защита от злоупотреблений

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

interface Destination {
  origin: string;
  destination: string;
  month: string;
  include_nearby: boolean;
  currency: string;
  threshold: number | null;
}

// Проверяет одно направление; возвращает его в чистом виде или null, если оно некорректно.
function cleanDestination(d: any): Destination | null {
  const origin = String(d?.origin ?? "").toUpperCase();
  const destination = String(d?.destination ?? "").toUpperCase();
  const month = String(d?.month ?? "");
  if (!/^[A-Z]{3}$/.test(origin) || !/^[A-Z]{3}$/.test(destination)) return null;
  if (origin === destination) return null;
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) return null;
  const currency = String(d?.currency ?? DEFAULT_CURRENCY).toLowerCase();
  if (!isCurrency(currency)) return null;
  const t = d?.threshold;
  if (t != null && !(Number.isInteger(t) && t > 0 && t < 100_000_000)) return null;
  return { origin, destination, month, include_nearby: d?.include_nearby === true, currency, threshold: t ?? null };
}

// Ключ направления для сравнения «что было» и «что стало»
const keyOf = (d: { origin: string; destination: string; month: string; include_nearby: boolean; currency: string }) =>
  `${d.origin}|${d.destination}|${d.month}|${d.include_nearby}|${d.currency}`;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Только POST" }, 405);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Тело запроса должно быть JSON" }, 400);
  }

  // 1. Проверка входных данных
  const installId = String(body?.install_id ?? "").toLowerCase();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(installId)) {
    return json({ error: "install_id — UUID" }, 400);
  }
  const pushToken = body?.push_token ?? null;
  if (pushToken !== null && !/^[0-9a-fA-F]{32,200}$/.test(String(pushToken))) {
    return json({ error: "push_token — hex-строка токена APNs или null" }, 400);
  }
  const environment = body?.environment === "sandbox" ? "sandbox" : "production";
  const locale = body?.locale === "en" ? "en" : "ru"; // любой другой язык — русский по умолчанию

  if (!Array.isArray(body?.destinations)) return json({ error: "destinations — список" }, 400);
  if (body.destinations.length > MAX_DESTINATIONS) {
    return json({ error: `Не больше ${MAX_DESTINATIONS} направлений на устройство` }, 400);
  }
  const wanted: Destination[] = [];
  for (const raw of body.destinations) {
    const d = cleanDestination(raw);
    if (!d) return json({ error: "Некорректное направление в списке" }, 400);
    wanted.push(d);
  }

  // 2. Устройство: создаём или обновляем токен
  const { error: deviceError } = await db.from("devices").upsert({
    install_id: installId,
    push_token: pushToken,
    environment,
    locale,
    updated_at: new Date().toISOString(),
  });
  if (deviceError) {
    console.error(deviceError);
    return json({ error: "Не удалось сохранить устройство" }, 500);
  }

  // 3. Подписки: добавляем новые, обновляем порог у существующих (служебные поля сохраняются),
  //    удаляем те, которых в присланном списке больше нет.
  const rows = wanted.map((d) => ({ install_id: installId, ...d }));
  if (rows.length > 0) {
    const { error } = await db.from("subscriptions").upsert(rows, {
      onConflict: "install_id,origin,destination,month,include_nearby,currency",
    });
    if (error) {
      console.error(error);
      return json({ error: "Не удалось сохранить направления" }, 500);
    }
  }

  const { data: existing, error: listError } = await db
    .from("subscriptions").select("id, origin, destination, month, include_nearby, currency")
    .eq("install_id", installId);
  if (listError) {
    console.error(listError);
    return json({ error: "Не удалось прочитать направления" }, 500);
  }
  const keep = new Set(wanted.map(keyOf));
  const staleIds = (existing ?? []).filter((e) => !keep.has(keyOf(e))).map((e) => e.id);
  if (staleIds.length > 0) {
    const { error } = await db.from("subscriptions").delete().in("id", staleIds);
    if (error) console.error(error);
  }

  return json({ ok: true, count: wanted.length });
});
