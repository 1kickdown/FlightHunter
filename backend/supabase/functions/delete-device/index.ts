// Edge Function "delete-device": удаляет с сервера все данные устройства —
// запись об устройстве (ID установки, push-токен) и все его направления.
//
//   POST /functions/v1/delete-device
//   { "install_id": "9b2f...-uuid" }
//
// Вызывается кнопкой «Удалить мои данные» в приложении.
// Подписки удаляются автоматически вместе с устройством (on delete cascade в базе).
// Аккаунтов нет: install_id (случайный UUID) служит секретным ключом устройства.

import { createClient } from "npm:@supabase/supabase-js@2";

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
  if (req.method !== "POST") return json({ error: "Только POST" }, 405);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Тело запроса должно быть JSON" }, 400);
  }

  const installId = String(body?.install_id ?? "").toLowerCase();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(installId)) {
    return json({ error: "install_id — UUID" }, 400);
  }

  const { error } = await db.from("devices").delete().eq("install_id", installId);
  if (error) {
    console.error(error);
    return json({ error: "Не удалось удалить данные" }, 500);
  }
  // Ответ одинаковый, были данные или нет: так по ответу нельзя «угадывать» чужие ID
  return json({ ok: true });
});
