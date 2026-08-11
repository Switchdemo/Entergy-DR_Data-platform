export type DayType = "weekday" | "weekend" | "holiday";

export function classifyDay(dateStr: string, holidayDates: Set<string>): DayType {
  const dt = new Date(dateStr + "T12:00:00");
  const dow = dt.getDay(); // 0=Sun, 6=Sat
  if (holidayDates.has(dateStr)) return "holiday";
  if (dow === 0 || dow === 6) return "weekend";
  return "weekday";
}

// Build the holiday date set from get_holidays rows (both actual and observed).
export function holidaySet(
  rows: { holiday_date: string; observed_date: string }[]
): Set<string> {
  const s = new Set<string>();
  for (const h of rows) {
    if (h.holiday_date) s.add(h.holiday_date);
    if (h.observed_date) s.add(h.observed_date);
  }
  return s;
}
