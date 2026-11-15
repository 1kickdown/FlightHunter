const MARKER = Deno.env.get("TRAVELPAYOUTS_MARKER") ?? "";
const PROJECT_ID = Deno.env.get("TRAVELPAYOUTS_TRS") ?? "";
const CAMPAIGN_ID = "100";
const PROGRAM_ID = "4114";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function ddmm(date: string): string | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (!m) return null;
  const [, y, mo, d] = m;
  const parsed = new Date(Date.UTC(+y, +mo - 1, +d));
  if (parsed.getUTCFullYear() !== +y || parsed.getUTCMonth() !== +mo - 1 || parsed.getUTCDate() !== +d) {
    return null;
  }
  return d + mo;
}

Deno.serve((req) => {
  if (req.method !== "GET") return json({ error: "Только GET" }, 405);
  if (!MARKER || !PROJECT_ID) return json({ error: "Сервер не настроен" }, 500);

  const p = new URL(req.url).searchParams;
  const origin = (p.get("origin") ?? "").toUpperCase();
  const destination = (p.get("destination") ?? "").toUpperCase();
  const date = p.get("date") ?? "";
  const returnDate = p.get("return_date") ?? "";

  if (!/^[A-Z]{3}$/.test(origin) || !/^[A-Z]{3}$/.test(destination)) {
    return json({ error: "origin и destination — трёхбуквенные коды IATA, например ALA" }, 400);
  }
  const there = ddmm(date);
  if (!there) return json({ error: "date — в формате YYYY-MM-DD, например 2026-11-16" }, 400);

  let code = `${origin}${there}${destination}`;
  if (returnDate) {
    const back = ddmm(returnDate);
    if (!back || returnDate < date) {
      return json({ error: "return_date — корректная дата не раньше даты вылета" }, 400);
    }
    code += back;
  }
  code += "1";

  const searchUrl = `https://www.aviasales.com/search/${code}`;
  const url = new URL("https://tp.media/r");
  url.searchParams.set("campaign_id", CAMPAIGN_ID);
  url.searchParams.set("marker", MARKER);
  url.searchParams.set("p", PROGRAM_ID);
  url.searchParams.set("trs", PROJECT_ID);
  url.searchParams.set("u", searchUrl);

  return json({ url: url.toString() });
});
