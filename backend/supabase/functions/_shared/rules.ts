// Правила уведомлений — все числа в одном месте, чтобы их было легко поменять.

export const RULES = {
  USUAL_RATIO: 0.85, // «заметно ниже обычной»: цена ≤ 85% медианы за период
  HISTORY_DAYS: 14, // сколько дней истории берём для «обычной» цены
  MIN_HISTORY_POINTS: 5, // меньше замеров — «обычную» цену не считаем
  MIN_REPEAT_DROP: 0.05, // повторный пуш по тому же направлению: цена упала ещё минимум на 5%...
  REPEAT_AFTER_DAYS: 3, // ...или прошло 3 дня
  MIN_HOURS_BETWEEN: 24, // не чаще одного пуша в сутки на направление
  QUIET_FROM_HOUR: 9, // присылаем пуши с 9:00
  QUIET_TO_HOUR: 21, // ...до 21:00
  TZ_OFFSET_HOURS: 5, // по времени Казахстана (UTC+5)
};

export type Reason = "threshold" | "usual";

export interface DecideInput {
  best: number; // лучшая текущая цена (в валюте подписки)
  threshold: number | null; // порог пользователя
  median: number | null; // обычная цена (медиана истории); null — мало данных
  lastNotifiedPrice: number | null;
  lastNotifiedAt: Date | null;
  now: Date;
}

export type Decision = { notify: true; reason: Reason } | { notify: false; skip: string };

// Медиана списка чисел (null для пустого списка).
export function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : Math.round((s[mid - 1] + s[mid]) / 2);
}

// Сейчас «тихие часы»? (вне окна 9:00–21:00 по Казахстану)
export function inQuietHours(now: Date): boolean {
  const hour = (now.getUTCHours() + RULES.TZ_OFFSET_HOURS) % 24;
  return hour < RULES.QUIET_FROM_HOUR || hour >= RULES.QUIET_TO_HOUR;
}

// Решает, нужно ли слать пуш по одной подписке.
export function decide(i: DecideInput): Decision {
  // 1. Почему вообще стоит уведомлять
  let reason: Reason | null = null;
  if (i.threshold != null && i.best <= i.threshold) reason = "threshold";
  else if (i.median != null && i.best <= i.median * RULES.USUAL_RATIO) reason = "usual";
  if (!reason) return { notify: false, skip: "цена не ниже порога и не ниже обычной" };

  // 2. Не спамим: не чаще раза в сутки...
  if (i.lastNotifiedAt) {
    const hours = (i.now.getTime() - i.lastNotifiedAt.getTime()) / 3_600_000;
    if (hours < RULES.MIN_HOURS_BETWEEN) return { notify: false, skip: "уже уведомляли меньше суток назад" };
    // ...и повторно — только если цена упала ещё или прошло достаточно дней
    if (i.lastNotifiedPrice != null) {
      const droppedMore = i.best <= i.lastNotifiedPrice * (1 - RULES.MIN_REPEAT_DROP);
      const longAgo = hours >= RULES.REPEAT_AFTER_DAYS * 24;
      if (!droppedMore && !longAgo) return { notify: false, skip: "цена не упала ещё и прошло мало дней" };
    }
  }
  return { notify: true, reason };
}
