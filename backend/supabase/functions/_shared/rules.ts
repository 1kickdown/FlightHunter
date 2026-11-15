export const RULES = {
  USUAL_RATIO: 0.85,
  HISTORY_DAYS: 14,
  MIN_HISTORY_POINTS: 5,
  MIN_REPEAT_DROP: 0.05,
  REPEAT_AFTER_DAYS: 3,
  MIN_HOURS_BETWEEN: 24,
  QUIET_FROM_HOUR: 9,
  QUIET_TO_HOUR: 21,
  TZ_OFFSET_HOURS: 5,
};

export type Reason = "threshold" | "usual";

export interface DecideInput {
  best: number;
  threshold: number | null;
  median: number | null;
  lastNotifiedPrice: number | null;
  lastNotifiedAt: Date | null;
  now: Date;
}

export type Decision = { notify: true; reason: Reason } | { notify: false; skip: string };

export function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : Math.round((s[mid - 1] + s[mid]) / 2);
}

export function inQuietHours(now: Date): boolean {
  const hour = (now.getUTCHours() + RULES.TZ_OFFSET_HOURS) % 24;
  return hour < RULES.QUIET_FROM_HOUR || hour >= RULES.QUIET_TO_HOUR;
}

export function decide(i: DecideInput): Decision {
  let reason: Reason | null = null;
  if (i.threshold != null && i.best <= i.threshold) reason = "threshold";
  else if (i.median != null && i.best <= i.median * RULES.USUAL_RATIO) reason = "usual";
  if (!reason) return { notify: false, skip: "цена не ниже порога и не ниже обычной" };

  if (i.lastNotifiedAt) {
    const hours = (i.now.getTime() - i.lastNotifiedAt.getTime()) / 3_600_000;
    if (hours < RULES.MIN_HOURS_BETWEEN) return { notify: false, skip: "уже уведомляли меньше суток назад" };
    if (i.lastNotifiedPrice != null) {
      const droppedMore = i.best <= i.lastNotifiedPrice * (1 - RULES.MIN_REPEAT_DROP);
      const longAgo = hours >= RULES.REPEAT_AFTER_DAYS * 24;
      if (!droppedMore && !longAgo) return { notify: false, skip: "цена не упала ещё и прошло мало дней" };
    }
  }
  return { notify: true, reason };
}
