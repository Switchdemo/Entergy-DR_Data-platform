"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  getSitesOverview,
  getDailySummary,
  getHourlyProfile,
  getWeatherHourly,
  getHolidays,
  type SiteOverview,
  type DailyRow,
  type HourlyRow,
  type WeatherRow,
} from "@/lib/rpc";
import { classifyDay, holidaySet } from "@/lib/dayClassify";
import { wxByDate, wxByHour, type WeatherSelection } from "@/lib/weather";
import { downloadCsv } from "@/lib/csv";
import DailyChart from "@/components/DailyChart";
import HourlyChart from "@/components/HourlyChart";
import WeatherToggle from "@/components/WeatherToggle";
import { StatCards, DayLegend, type Stat } from "@/components/StatCards";

type View = "daily" | "hourly";
type Status = { text: string; kind: "ok" | "err" | "loading" };

export default function DashboardPage() {
  const [sites, setSites] = useState<SiteOverview[]>([]);
  const [meter, setMeter] = useState<string>("");
  const [startDate, setStartDate] = useState("2026-07-01");
  const [endDate, setEndDate] = useState("2026-07-31");

  const [view, setView] = useState<View>("daily");
  const [selectedDay, setSelectedDay] = useState<string | null>(null);
  const [selWx, setSelWx] = useState<WeatherSelection>("none");

  const [dailyData, setDailyData] = useState<DailyRow[]>([]);
  const [hourlyData, setHourlyData] = useState<HourlyRow[]>([]);
  const [weatherData, setWeatherData] = useState<WeatherRow[]>([]);
  const [holidayDates, setHolidayDates] = useState<Set<string>>(new Set());

  const [status, setStatus] = useState<Status>({ text: "Connecting…", kind: "loading" });
  const [error, setError] = useState<string | null>(null);

  const selectedSite = useMemo(
    () => sites.find((s) => s.meter_number === meter) ?? null,
    [sites, meter]
  );

  // ---- Load sites once ----
  useEffect(() => {
    (async () => {
      try {
        const rows = await getSitesOverview();
        setSites(rows);
        if (rows.length) setMeter(rows[0].meter_number);
        setStatus({ text: `${rows.length} sites loaded`, kind: "ok" });
      } catch (e: any) {
        setStatus({ text: "Connection failed", kind: "err" });
        setError(e.message);
      }
    })();
  }, []);

  // ---- Load daily whenever meter/date range changes ----
  const loadDaily = useCallback(async () => {
    if (!meter) return;
    setView("daily");
    setSelectedDay(null);
    setStatus({ text: "Loading…", kind: "loading" });
    setError(null);
    try {
      const [daily, weather, holidays] = await Promise.all([
        getDailySummary(meter, startDate, endDate),
        getWeatherHourly(startDate, endDate),
        getHolidays(startDate, endDate),
      ]);
      setDailyData(daily);
      setWeatherData(weather);
      setHolidayDates(holidaySet(holidays));
      setStatus({ text: `${daily.length} days loaded`, kind: "ok" });
    } catch (e: any) {
      setStatus({ text: "Failed", kind: "err" });
      setError(e.message);
    }
  }, [meter, startDate, endDate]);

  useEffect(() => {
    if (meter) loadDaily();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [meter, startDate, endDate]);

  // ---- Drill down to hourly ----
  const loadHourly = useCallback(
    async (day: string) => {
      if (!meter) return;
      setView("hourly");
      setSelectedDay(day);
      setStatus({ text: "Loading hourly…", kind: "loading" });
      setError(null);
      try {
        const [hourly, weather] = await Promise.all([
          getHourlyProfile(meter, day, "del"),
          getWeatherHourly(day, day),
        ]);
        setHourlyData(hourly);
        setWeatherData(weather);
        setStatus({ text: `${hourly.length} hours loaded`, kind: "ok" });
      } catch (e: any) {
        setStatus({ text: "Failed", kind: "err" });
        setError(e.message);
      }
    },
    [meter]
  );

  const backToDaily = () => loadDaily();

  // ---- Daily stats ----
  const dailyStats: Stat[] = useMemo(() => {
    const d = dailyData;
    if (!d.length) return [];
    const avgKw = (d.reduce((a, b) => a + Number(b.avg_kw), 0) / d.length).toFixed(1);
    const peakKw = Math.max(...d.map((x) => Number(x.peak_kw))).toFixed(1);
    const totalKwh = Math.round(d.reduce((a, b) => a + Number(b.total_kwh), 0)).toLocaleString();
    const gaps = d.filter((x) => Number(x.hours_with_gaps) > 0).length;
    const wd = Object.values(wxByDate(weatherData));
    const maxT = wd.length ? Math.max(...wd.map((w) => w.temperature_f ?? 0)).toFixed(0) : "—";
    const maxH = wd.length ? Math.max(...wd.map((w) => w.heat_index_f ?? 0)).toFixed(0) : "—";
    return [
      { label: "Avg demand", value: avgKw + " kW", color: "#3b82f6" },
      { label: "Peak demand", value: peakKw + " kW", color: "#f59e0b" },
      { label: "Total energy", value: totalKwh + " kWh", color: "#22c55e" },
      { label: "Days w/ gaps", value: `${gaps}/${d.length}`, color: gaps ? "#f59e0b" : "#71717a" },
      { label: "Max temp", value: maxT + "°F", color: "#f97316" },
      { label: "Max heat index", value: maxH + "°F", color: "#ef4444" },
    ];
  }, [dailyData, weatherData]);

  // ---- CSV export ----
  const exportCsv = () => {
    if (view === "daily" && dailyData.length) {
      const wa = wxByDate(weatherData);
      downloadCsv(
        `daily_${meter}_${startDate}_${endDate}.csv`,
        ["Date", "Day Type", "Avg kW", "Peak kW", "Total kWh", "Hours with Gaps", "Temp F", "Heat Index F", "Humidity %", "Dew Point F", "Wind mph"],
        dailyData.map((d) => {
          const w = wa[d.read_date] ?? ({} as any);
          return [
            d.read_date,
            classifyDay(d.read_date, holidayDates),
            d.avg_kw, d.peak_kw, d.total_kwh, d.hours_with_gaps,
            w.temperature_f ?? "", w.heat_index_f ?? "", w.humidity_pct ?? "", w.dew_point_f ?? "", w.wind_speed_mph ?? "",
          ];
        })
      );
    } else if (view === "hourly" && hourlyData.length && selectedDay) {
      const dw = wxByHour(weatherData, selectedDay);
      downloadCsv(
        `hourly_${meter}_${selectedDay}.csv`,
        ["Hour", "Avg kW", "Intervals", "Gaps", "Temp F", "Heat Index F", "Humidity %", "Dew Point F", "Wind mph"],
        hourlyData.map((d) => {
          const h = new Date(d.hour_ct).getHours();
          const w = dw[h] ?? ({} as any);
          return [
            d.hour_ct, d.avg_kw, d.interval_count, String(d.has_gaps),
            w.temperature_f ?? "", w.heat_index_f ?? "", w.humidity_pct ?? "", w.dew_point_f ?? "", w.wind_speed_mph ?? "",
          ];
        })
      );
    }
  };

  // ---- Titles ----
  const dailyTitle = `Daily peak demand — ${selectedSite?.site_name ?? ""}`;
  const hourlyTitle = `Hourly load profile — ${selectedSite?.site_name ?? ""}`;
  const hourlySubtitle = useMemo(() => {
    if (!selectedDay) return "";
    const dayStr = new Date(selectedDay + "T12:00:00").toLocaleDateString("en-US", {
      weekday: "long", month: "long", day: "numeric", year: "numeric",
    });
    const type = classifyDay(selectedDay, holidayDates);
    const tag = type === "holiday" ? " · Holiday" : type === "weekend" ? " · Weekend" : "";
    const hasGaps = hourlyData.some((d) => d.has_gaps);
    return dayStr + tag + (hasGaps ? " · ⚠ some hours incomplete" : "");
  }, [selectedDay, holidayDates, hourlyData]);

  return (
    <>
      <p style={{ color: "var(--muted)", fontSize: 13, marginTop: 4 }}>
        <span className={`status ${status.kind}`}>● {status.text}</span>
      </p>

      {error && <div className="error-box">{error}</div>}

      <div className="controls">
        <select value={meter} onChange={(e) => setMeter(e.target.value)}>
          {sites.length === 0 && <option>Loading sites…</option>}
          {sites.map((s) => (
            <option key={s.meter_number} value={s.meter_number}>
              {s.customer_name} — {s.site_name} ({s.meter_number})
            </option>
          ))}
        </select>
        <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
        <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
        {view === "hourly" && (
          <button className="btn btn-back" onClick={backToDaily}>
            ← Back to daily
          </button>
        )}
        <button className="btn" onClick={exportCsv}>
          Export CSV
        </button>
      </div>

      <WeatherToggle value={selWx} onChange={setSelWx} />

      {view === "daily" && <StatCards stats={dailyStats} />}

      <div className="chart-card">
        <div className="chart-title">{view === "daily" ? dailyTitle : hourlyTitle}</div>
        <div className="chart-subtitle">
          {view === "daily" ? "Click a bar to see the hourly profile" : hourlySubtitle}
        </div>
        {view === "daily" && <DayLegend />}
        <div className="chart-container">
          {view === "daily" ? (
            <DailyChart
              dailyData={dailyData}
              weatherData={weatherData}
              holidayDates={holidayDates}
              selWx={selWx}
              onBarClick={loadHourly}
            />
          ) : (
            selectedDay && (
              <HourlyChart
                hourlyData={hourlyData}
                weatherData={weatherData}
                selectedDay={selectedDay}
                selWx={selWx}
              />
            )
          )}
        </div>
      </div>

      {selectedSite && (
        <div className="meta">
          <span>Customer: {selectedSite.customer_name}</span>
          <span>Device Location: {selectedSite.device_location}</span>
          <span>Meter: {selectedSite.meter_number}</span>
          <span>Type: {(selectedSite.meter_type || "").toUpperCase()}</span>
        </div>
      )}
    </>
  );
}
