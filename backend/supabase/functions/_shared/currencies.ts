export const CURRENCIES = [
  "kzt", "rub", "usd", "eur", "uzs", "kgs", "tjs", "azn", "gel",
  "amd", "byn", "uah", "try", "gbp", "pln", "czk", "huf", "aed",
] as const;

export const DEFAULT_CURRENCY = "kzt";

export function isCurrency(value: unknown): value is (typeof CURRENCIES)[number] {
  return typeof value === "string" && (CURRENCIES as readonly string[]).includes(value);
}
