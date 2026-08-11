"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  getSitesOverview,
  getBaselineResults,
  type SiteOverview,
  type BaselineRow,
} from "@/lib/rpc";
import { downloadCsv } from "@/lib/csv";
import BaselineChart from "@/components/BaselineChart";

type Status = { text: string; kind: "ok" | "err" | "loading" };

const ALL_METHODS = ["10 of 10", "High 5 of 10", "High 3 of 10"] as const;

interface DaySummary {
  date: string;
  rows: BaselineRow[];
  // per-method reduction stats (avg kW, peak kW, % of baseline)
  methods: Record<
    string,
    { avgRed: number; peakRed: number; pctRed: number; avgBaseline: number }
  >;
}

// Compute per-method reduction stats for a set of rows belonging to one date
function buildDaySummary(date: string, rows: BaselineRow[]): DaySummary {
  const methods: DaySummary["methods"] = {};
  for (const method of ALL_METHODS) {
    const mRows = rows.filter((r) => r.baseline_method === method);
    if (!mRows.length) continue;
    const reductions = mRows.map(
      (r) => Number(r.baseline_kw) - Number(r.actual_kw)
    );
    const baseSum = mRows.reduce((a, r) => a + Number(r.baseline_kw), 0);
    const redSum = reductions.reduce((a, v) => a + v, 0);
    methods[method] = {
      avgRed: reductions.length ? redSum / reductions.length : 0,
      peakRed: reductions.length ? Math.max(...reductions) : 0,
      pctRed: baseSum ? (redSum / baseSum) * 100 : 0,
      avgBaseline: mRows.length
        ? baseSum / mRows.length
        : 0,
    };
  }
  return { date, rows, methods };
}

export default function BaselinesPage() {
  const [sites, setSites] = useState<SiteOverview[]>([]);
  const [meter, setMeter] = useState("");

  // Default to a single day — keeps the query fast
  const [startDate, setStartDate] = useState("2026-07-15");
  const [endDate, setEndDate] = useState("2026-07-15");

  const [rows, setRows] = useState<BaselineRow[]>([]);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [enabledMethods, setEnabledMethods] = useState<Set<string>>(
    new Set(ALL_METHODS)
  );

  const [status, setStatus] = useState<Status>({
    text: "Connecting…",
    kind: "loading",
  });
  const [error, setError] = useState<string | null>(null);
  const [notReady, setNotReady] = useState(false);

  // ── Load sites ──
  useEffect(() => {
    (async () => {
      try {
        const s = await getSitesOverview();
        setSites(s);
        if (s.length) setMeter(s[0].meter_number);
      } catch (e: any) {
        setStatus({ text: "Connection failed", kind: "err" });
        setError(e.message);
      }
    })();
  }, []);

  // ── Load baselines ──
  const load = useCallback(async () => {
    if (!meter) return;
    setStatus({ text: "Computing baselines…", kind: "loading" });
    setError(null);
    setNotReady(false);
    setSelectedDate(null);
    try {
      const data = await getBaselineResults(meter, startDate, endDate);
      setRows(data);
      // If single day, auto-select it
      const dates = [...new Set(data.map((r) => r.event_date))];
      if (dates.length === 1) setSelectedDate(dates[0]);
      setStatus({
        text: `${data.length} rows · ${dates.length} day${dates.length !== 1 ? "s" : ""}`,
        kind: "ok",
      });
    } catch (e: any) {
      const msg = String(e.message || "");
      if (/get_baseline_results|does not exist|not found|schema cache/i.test(msg)) {
        setNotReady(true);
        setStatus({ text: "Baseline function not found", kind: "err" });
      } else {
        setError(msg);
        setStatus({ text: "Failed", kind: "err" });
      }
      setRows([]);
    }
  }, [meter, startDate, endDate]);

  useEffect(() => {
    if (meter) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [meter, startDate, endDate]);

  // ── Group into per-date summaries ──
  const daySummaries = useMemo(() => {
    const byDate: Record<string, BaselineRow[]> = {};
    for (const r of rows) (byDate[r.event_date] ??= []).push(r);
    return Object.entries(byDate)
      .map(([d, rs]) => buildDaySummary(d, rs))
      .sort((a, b) => b.date.localeCompare(a.date));
  }, [rows]);

  const selected = useMemo(
    () => daySummaries.find((d) => d.date === selectedDate) ?? null,
    [daySummaries, selectedDate]
  );

  // ── Method toggle ──
  const toggleMethod = (m: string) => {
    setEnabledMethods((prev) => {
      const next = new Set(prev);
      if (next.has(m)) {
        if (next.size > 1) next.delete(m); // don't allow empty
      } else {
        next.add(m);
      }
      return next;
    });
  };

  // ── CSV export ──
  const exportCsv = () => {
    const target = selected ? selected.rows : rows;
    if (!target.length) return;
    const sorted = [...target].sort(
      (a, b) =>
        a.event_date.localeCompare(b.event_date) ||
        a.baseline_method.localeCompare(b.baseline_method) ||
        new Date(a.hour_ct).getTime() - new Date(b.hour_ct).getTime()
    );
    downloadCsv(
      `baseline_${meter}_${startDate}_${endDate}.csv`,
      [
        "Date",
        "Method",
        "Hour",
        "Baseline kW",
        "Actual kW",
        "Reduction kW",
        "Reduction %",
      ],
      sorted.map((r) => {
        const red = Number(r.baseline_kw) - Number(r.actual_kw);
        const pct =
          Number(r.baseline_kw) > 0
            ? ((red / Number(r.baseline_kw)) * 100).toFixed(1)
            : "0.0";
        return [
          r.event_date,
          r.baseline_method,
          r.hour_ct,
          Number(r.baseline_kw).toFixed(2),
          Number(r.actual_kw).toFixed(2),
          red.toFixed(2),
          pct,
        ];
      })
    );
  };

  // ── Selected site label ──
  const selectedSite = sites.find((s) => s.meter_number === meter);

  return (
    <>
      <p style={{ color: "var(--muted)", fontSize: 13, marginTop: 4 }}>
        <span className={`status ${status.kind}`}>● {status.text}</span>
      </p>

      {error && <div className="error-box">{error}</div>}

      {notReady && (
        <div className="info-box">
          The <code>get_baseline_results</code> function wasn&apos;t found.
          Run the SQL in <code>baseline_function.sql</code> in your Supabase SQL
          Editor to create it.
        </div>
      )}

      <div className="controls">
        <select value={meter} onChange={(e) => setMeter(e.target.value)}>
          {sites.length === 0 && <option>Loading sites…</option>}
          {sites.map((s) => (
            <option key={s.meter_number} value={s.meter_number}>
              {s.customer_name} — {s.site_name} ({s.meter_number})
            </option>
          ))}
        </select>
        <input
          type="date"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
        />
        <input
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
        />
        <button className="btn" onClick={exportCsv} disabled={!rows.length}>
          Export CSV
        </button>
      </div>

      {/* ── Method toggles ── */}
      <div className="weather-controls">
        <span className="weather-label">Methods:</span>
        {ALL_METHODS.map((m) => (
          <button
            key={m}
            className={`weather-btn ${enabledMethods.has(m) ? "active" : ""}`}
            onClick={() => toggleMethod(m)}
          >
            {m}
          </button>
        ))}
      </div>

      {/* ── Multi-day table (if range > 1 day and no date selected) ── */}
      {!selected && daySummaries.length > 1 && (
        <div
          className="chart-card"
          style={{ padding: 0, overflow: "auto" }}
        >
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                {ALL_METHODS.filter((m) => enabledMethods.has(m)).map((m) => (
                  <th key={m} colSpan={2}>
                    {m}
                  </th>
                ))}
              </tr>
              <tr>
                <th></th>
                {ALL_METHODS.filter((m) => enabledMethods.has(m)).map((m) => (
                  <>
                    <th key={m + "-avg"} style={{ fontSize: 10, fontWeight: 400 }}>
                      Avg red.
                    </th>
                    <th key={m + "-pct"} style={{ fontSize: 10, fontWeight: 400 }}>
                      %
                    </th>
                  </>
                ))}
              </tr>
            </thead>
            <tbody>
              {daySummaries.map((ds) => (
                <tr
                  key={ds.date}
                  className="clickable"
                  onClick={() => setSelectedDate(ds.date)}
                >
                  <td>
                    {new Date(ds.date + "T12:00:00").toLocaleDateString(
                      "en-US",
                      {
                        weekday: "short",
                        month: "short",
                        day: "numeric",
                      }
                    )}
                  </td>
                  {ALL_METHODS.filter((m) => enabledMethods.has(m)).map((m) => {
                    const s = ds.methods[m];
                    return (
                      <>
                        <td
                          key={m + "-avg"}
                          style={{ color: "#22c55e" }}
                        >
                          {s ? s.avgRed.toFixed(1) + " kW" : "—"}
                        </td>
                        <td key={m + "-pct"}>
                          {s ? s.pctRed.toFixed(1) + "%" : "—"}
                        </td>
                      </>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── No results message ── */}
      {!selected &&
        daySummaries.length === 0 &&
        !notReady &&
        status.kind === "ok" && (
          <div className="info-box">
            No hourly data found for this meter on the selected date(s). Make
            sure the meter has delivered-channel readings for this period.
          </div>
        )}

      {/* ── Single-day detail view ── */}
      {selected && (
        <>
          {daySummaries.length > 1 && (
            <div className="controls" style={{ margin: "0 0 16px" }}>
              <button
                className="btn btn-back"
                onClick={() => setSelectedDate(null)}
              >
                ← Back to date list
              </button>
            </div>
          )}

          {/* ── Comparison stat cards ── */}
          <div className="stats">
            {ALL_METHODS.filter((m) => enabledMethods.has(m)).map((m) => {
              const s = selected.methods[m];
              if (!s) return null;
              return (
                <div className="stat-card" key={m}>
                  <div className="stat-label">{m}</div>
                  <div
                    className="stat-value"
                    style={{ color: "#22c55e", fontSize: 18 }}
                  >
                    {s.avgRed.toFixed(1)} kW
                  </div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--muted)",
                      marginTop: 4,
                    }}
                  >
                    peak {s.peakRed.toFixed(1)} kW · {s.pctRed.toFixed(1)}%
                    reduction
                  </div>
                  <div
                    style={{
                      fontSize: 11,
                      color: "var(--muted)",
                      marginTop: 2,
                    }}
                  >
                    avg baseline {s.avgBaseline.toFixed(1)} kW
                  </div>
                </div>
              );
            })}
          </div>

          {/* ── Overlay chart ── */}
          <div className="chart-card">
            <div className="chart-title">
              Baseline comparison —{" "}
              {selectedSite?.site_name ?? meter} —{" "}
              {new Date(selected.date + "T12:00:00").toLocaleDateString(
                "en-US",
                {
                  weekday: "long",
                  month: "long",
                  day: "numeric",
                  year: "numeric",
                }
              )}
            </div>
            <div className="chart-subtitle">
              Solid blue = actual metered load · dashed lines = baselines ·
              hover for per-hour reduction
            </div>
            <div className="chart-container">
              <BaselineChart
                rows={selected.rows}
                methods={[...enabledMethods]}
              />
            </div>
          </div>

          {/* ── Eligible days info ── */}
          <div className="meta">
            <span>
              Baselines computed from 10 prior eligible weekdays (excludes
              weekends, holidays, shutdown days)
            </span>
            <span>Meter: {meter}</span>
          </div>
        </>
      )}
    </>
  );
}
