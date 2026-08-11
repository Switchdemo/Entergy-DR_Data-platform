import type { WeatherRow } from "./rpc";

export type WeatherMetric =
  | "temperature_f"
  | "heat_index_f"
  | "humidity_pct"
  | "dew_point_f"
  | "wind_speed_mph";

export type WeatherSelection = "none" | WeatherMetric;

export interface WxCfg {
  label: string;
  unit: string;
  color: string;
  axis: string;
}

export const WX_CFG: Record<WeatherMetric, WxCfg> = {
  temperature_f: { label: "Temperature", unit: "°F", color: "#f97316", axis: "°F" },
  heat_index_f: { label: "Heat Index", unit: "°F", color: "#ef4444", axis: "°F" },
  humidity_pct: { label: "Humidity", unit: "%", color: "#06b6d4", axis: "%" },
  dew_point_f: { label: "Dew Point", unit: "°F", color: "#8b5cf6", axis: "°F" },
  wind_speed_mph: { label: "Wind Speed", unit: " mph", color: "#22c55e", axis: "mph" },
};

export const WEATHER_OPTIONS: { key: WeatherSelection; label: string }[] = [
  { key: "none", label: "None" },
  { key: "temperature_f", label: "Temperature" },
  { key: "heat_index_f", label: "Heat Index" },
  { key: "humidity_pct", label: "Humidity" },
  { key: "dew_point_f", label: "Dew Point" },
  { key: "wind_speed_mph", label: "Wind Speed" },
];

export type DailyWx = Record<WeatherMetric, number | null>;

// Aggregate hourly weather into per-date values. Temp/heat-index use the daily
// max (what matters for peak load); humidity/dew/wind use the daily average.
export function wxByDate(data: WeatherRow[]): Record<string, DailyWx> {
  const byDate: Record<string, WeatherRow[]> = {};
  for (const w of data) {
    const d = new Date(w.hour_ct).toISOString().split("T")[0];
    (byDate[d] ??= []).push(w);
  }

  const nums = (rows: WeatherRow[], f: WeatherMetric) =>
    rows.map((h) => Number(h[f])).filter((v) => !Number.isNaN(v));
  const avg = (a: number[]) =>
    a.length ? +(a.reduce((s, v) => s + v, 0) / a.length).toFixed(1) : null;
  const mx = (a: number[]) => (a.length ? +Math.max(...a).toFixed(1) : null);

  const out: Record<string, DailyWx> = {};
  for (const [d, hrs] of Object.entries(byDate)) {
    out[d] = {
      temperature_f: mx(nums(hrs, "temperature_f")),
      heat_index_f: mx(nums(hrs, "heat_index_f")),
      humidity_pct: avg(nums(hrs, "humidity_pct")),
      dew_point_f: avg(nums(hrs, "dew_point_f")),
      wind_speed_mph: avg(nums(hrs, "wind_speed_mph")),
    };
  }
  return out;
}

// Map hour-of-day -> weather row for a single day.
export function wxByHour(data: WeatherRow[], day: string): Record<number, WeatherRow> {
  const out: Record<number, WeatherRow> = {};
  for (const w of data) {
    const dt = new Date(w.hour_ct);
    if (dt.toISOString().split("T")[0] === day) out[dt.getHours()] = w;
  }
  return out;
}
