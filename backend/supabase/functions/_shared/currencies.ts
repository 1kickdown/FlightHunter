// Поддерживаемые валюты (коды в нижнем регистре, как их понимает Travelpayouts).
// Список проверен запросами к API: по каждой валюте приходят цены.
// Чтобы добавить валюту, добавьте её сюда и в список в приложении (Currency.swift).

export const CURRENCIES = [
  "kzt", "rub", "usd", "eur", "uzs", "kgs", "tjs", "azn", "gel",
  "amd", "byn", "uah", "try", "gbp", "pln", "czk", "huf", "aed",
] as const;

export const DEFAULT_CURRENCY = "kzt"; // тенге — целевая аудитория из Казахстана

// Проверяет, что строка — поддерживаемая валюта.
export function isCurrency(value: unknown): value is (typeof CURRENCIES)[number] {
  return typeof value === "string" && (CURRENCIES as readonly string[]).includes(value);
}
