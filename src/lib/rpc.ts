import { supabase } from "./supabase";

// ---------------------------------------------------------------------------
// Row shapes returned by the existing Postgres RPCs. These mirror what the
// original single-file viewer consumed. Adjust field names here if your
// functions differ — everything downstream is typed off these interfaces.
// ---------------------------------------------------------------------------

export interface SiteOverview {
  meter_number: string;
  customer_name: string;
  site_name: string;
  device_location: string;
  meter_type: string;
}

export interface DailyRow {
  read_date: string; // "YYYY-MM-DD"
  avg_kw: number;
  peak_kw: number;
  total_kwh: number;
  hours_with_gaps: number;
}

export interface HourlyRow {
  hour_ct: string; // ISO timestamp, Central time
  avg_kw: number;
  interval_count: number;
  has_gaps: boolean;
}

export interface WeatherRow {
  hour_ct: string;
  temperature_f: number | null;
  heat_index_f: number | null;
  humidity_pct: number | null;
  dew_point_f: number | null;
  wind_speed_mph: number | null;
}

export interface HolidayRow {
  holiday_date: string;
  observed_date: string;
  name?: string;
}

// ---------------------------------------------------------------------------
// BASELINE RESULTS — SCHEMA ASSUMPTION.
//
// The original viewer had no baseline RPC, so this is the one contract you must
// confirm against your database. The viewer expects an RPC named
// `get_baseline_results(p_meter_number, p_start_date, p_end_date)` that returns
// one row per (event_date, hour) with the modeled baseline load and the actual
// metered load. If your table/function differs, remap in `BASELINE_FIELDS`
// below rather than editing the components.
// ---------------------------------------------------------------------------

export interface BaselineRow {
  event_date: string; // "YYYY-MM-DD" — the DR event day
  baseline_method: string; // e.g. "10-in-10", "High 5-of-10", "Weather-adjusted"
  hour_ct: string; // ISO timestamp for the hour
  baseline_kw: number; // modeled counterfactual load
  actual_kw: number; // metered load
  is_event_hour?: boolean; // true during the called DR window (optional)
}

// Generic RPC caller with typed return.
async function rpc<T>(fn: string, params: Record<string, unknown> = {}): Promise<T> {
  const { data, error } = await supabase.rpc(fn, params);
  if (error) {
    throw new Error(`RPC ${fn} failed: ${error.message}`);
  }
  return (data ?? []) as T;
}

export const getSitesOverview = () => rpc<SiteOverview[]>("get_sites_overview");

export const getDailySummary = (meter: string, start: string, end: string) =>
  rpc<DailyRow[]>("get_daily_summary", {
    p_meter_number: meter,
    p_start_date: start,
    p_end_date: end,
  });

export const getHourlyProfile = (
  meter: string,
  day: string,
  channel: string = "del"
) =>
  rpc<HourlyRow[]>("get_hourly_profile", {
    p_meter_number: meter,
    p_start_date: day,
    p_end_date: day,
    p_channel: channel,
  });

export const getWeatherHourly = (start: string, end: string) =>
  rpc<WeatherRow[]>("get_weather_hourly", {
    p_start_date: start,
    p_end_date: end,
  });

export const getHolidays = (start: string, end: string) =>
  rpc<HolidayRow[]>("get_holidays", {
    p_start_date: start,
    p_end_date: end,
  });

export const getBaselineResults = (meter: string, start: string, end: string) =>
  rpc<BaselineRow[]>("get_baseline_results", {
    p_meter_number: meter,
    p_start_date: start,
    p_end_date: end,
  });
