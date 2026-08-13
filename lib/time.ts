import { formatInTimeZone, fromZonedTime } from "date-fns-tz";
export const BUSINESS_TZ = "Asia/Manila";
export function toUtc(value: string) {
  return fromZonedTime(value, BUSINESS_TZ).toISOString();
}
export function formatPhilippine(
  value: string | Date,
  pattern = "dd MMM yyyy, HH:mm 'PHT'",
) {
  return formatInTimeZone(value, BUSINESS_TZ, pattern);
}
export function duration(ms: number) {
  const h = Math.max(0, Math.floor(ms / 3_600_000));
  return `${Math.floor(h / 24)}d ${h % 24}h`;
}
