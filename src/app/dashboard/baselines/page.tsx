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

interface EventSummary {
  event_date: string;
  method: string;
  rows: BaselineRow[];
  avgReduction: number;
  peakReduction: number;
  pctReduction: number;
}

// Group flat baseline rows into per-event summaries. An "event" is a unique
// (event_date, baseline_method) pair. Reduction metrics are computed over event
// hours when the is_event_hour flag is present, otherwise over all hours.
function summarize(rows: BaselineRow[]): EventSummary[] {
  const groups: Record<string, BaselineRow[]> = {};
  for (const r of rows) {
    const key = `${r.event_date}__${r.baseline_method}`;
    (groups[key] ??= []).push(r);
  }
  const anyEventFlag = rows.some((r) => r.is_event_hour);

  return Object.values(groups)
    .map((grp) => {
      const eventRows = anyEventFlag ? grp.filter((r) => r.is_event_hour) : grp;
      const reductions = eventRows.map((r) => Number(r.baseline_kw) - Number(r.actual_kw));
      const baseSum = eventRows.reduce((a, r) => a + Number(r.baseline_kw), 0);
      const redSum = reductions.reduce((a, v) => a + v, 0);
      const avg = reductions.length ? redSum / reductions.length : 0;
      const peak = reductions.length ? Math.max(...reductions) : 0;
      const pct = baseSum ? (redSum / baseSum) * 100 : 0;
      return {
        event_date: grp[0].event_date,
        method: grp[0].baseline_method,
        rows: grp,
        avgReduction: avg,
        peakReduction: peak,
        pctReduction: pct,
      };
    })
    .sort((a, b) => b.event_date.localeCompare(a.event_date));
}

export default function BaselinesPage() {
  const [sites, setSites] = useState<SiteOverview[]>([]);
  const [meter, setMeter] = useState("");
  const [startDate, setStartDate] = useState("2026-06-01");
  const [endDate, setEndDate] = useState("2026-09-30");

  const [rows, setRows] = useState<BaselineRow[]>([]);
  const [selectedKey, setSelectedKey] = useState<string | null>(null);
  const [status, setStatus] = useState<Status>({ text: "Connecting…", kind: "loading" });
  const [error, setError] = useState<string | null>(null);
  const [notReady, setNotReady] = useState(false);

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

  const load = useCallback(async () => {
    if (!meter) return;
    setStatus({ text: "Loading baselines…", kind: "loading" });
    setError(null);
    setNotReady(false);
    setSelectedKey(null);
    try {
      const data = await getBaselineResults(meter, startDate, endDate);
      setRows(data);
      setStatus({ text: `${data.length} rows loaded`, kind: "ok" });
    } catch (e: any) {
      // Most likely cause during first setup: the RPC doesn't exist yet.
      const msg = String(e.message || "");
      if (/get_baseline_results|does not exist|not found|schema cache/i.test(msg)) {
        setNotReady(true);
        setStatus({ text: "Baseline RPC not found", kind: "err" });
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

  const events = useMemo(() => summarize(rows), [rows]);
  const selected = useMemo(
    () => events.find((e) => `${e.event_date}__${e.method}` === selectedKey) ?? null,
    [events, selectedKey]
  );

  const exportEvent = () => {
    if (!selected) return;
    const sorted = [...selected.rows].sort(
      (a, b) => new Date(a.hour_ct).getTime() - new Date(b.hour_ct).getTime()
    );
    downloadCsv(
      `baseline_${meter}_${selected.event_date}.csv`,
      ["Hour", "Baseline kW", "Actual kW", "Reduction kW", "Event Hour", "Method"],
      sorted.map((r) => [
        r.hour_ct,
        r.baseline_kw,
        r.actual_kw,
        (Number(r.baseline_kw) - Number(r.actual_kw)).toFixed(2),
        String(r.is_event_hour ?? ""),
        r.baseline_method,
      ])
    );
  };

  return (
    <>
      <p style={{ color: "var(--muted)", fontSize: 13, marginTop: 4 }}>
        <span className={`status ${status.kind}`}>● {status.text}</span>
      </p>

      {error && <div className="error-box">{error}</div>}

      {notReady && (
        <div className="info-box">
          The <code>get_baseline_results</code> RPC wasn&apos;t found on your
          Supabase project. This page expects a function
          <code> get_baseline_results(p_meter_number, p_start_date, p_end_date)</code>{" "}
          returning one row per (event_date, hour) with columns{" "}
          <code>event_date, baseline_method, hour_ct, baseline_kw, actual_kw</code>{" "}
          (and optionally <code>is_event_hour</code>). See the README for a
          starter SQL definition, or remap field names in{" "}
          <code>src/lib/rpc.ts</code> if your schema differs.
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
        <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
        <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
        {selected && (
          <button className="btn" onClick={exportEvent}>
            Export event CSV
          </button>
        )}
      </div>

      {!selected && events.length > 0 && (
        <div className="chart-card" style={{ padding: 0, overflow: "hidden" }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Event date</th>
                <th>Method</th>
                <th>Avg reduction</th>
                <th>Peak reduction</th>
                <th>% reduction</th>
              </tr>
            </thead>
            <tbody>
              {events.map((e) => {
                const key = `${e.event_date}__${e.method}`;
                return (
                  <tr key={key} className="clickable" onClick={() => setSelectedKey(key)}>
                    <td>
                      {new Date(e.event_date + "T12:00:00").toLocaleDateString("en-US", {
                        weekday: "short", month: "short", day: "numeric", year: "numeric",
                      })}
                    </td>
                    <td>{e.method}</td>
                    <td style={{ color: "#22c55e" }}>{e.avgReduction.toFixed(1)} kW</td>
                    <td style={{ color: "#22c55e" }}>{e.peakReduction.toFixed(1)} kW</td>
                    <td>{e.pctReduction.toFixed(1)}%</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {!selected && events.length === 0 && !notReady && status.kind === "ok" && (
        <div className="info-box">No baseline events in this date range for this meter.</div>
      )}

      {selected && (
        <>
          <div className="controls" style={{ margin: "0 0 16px" }}>
            <button className="btn btn-back" onClick={() => setSelectedKey(null)}>
              ← Back to events
            </button>
          </div>
          <div className="stats">
            <div className="stat-card">
              <div className="stat-label">Avg reduction</div>
              <div className="stat-value" style={{ color: "#22c55e" }}>
                {selected.avgReduction.toFixed(1)} kW
              </div>
            </div>
            <div className="stat-card">
              <div className="stat-label">Peak reduction</div>
              <div className="stat-value" style={{ color: "#22c55e" }}>
                {selected.peakReduction.toFixed(1)} kW
              </div>
            </div>
            <div className="stat-card">
              <div className="stat-label">% reduction</div>
              <div className="stat-value">{selected.pctReduction.toFixed(1)}%</div>
            </div>
            <div className="stat-card">
              <div className="stat-label">Method</div>
              <div className="stat-value" style={{ fontSize: 15 }}>{selected.method}</div>
            </div>
          </div>
          <div className="chart-card">
            <div className="chart-title">
              Baseline vs actual —{" "}
              {new Date(selected.event_date + "T12:00:00").toLocaleDateString("en-US", {
                weekday: "long", month: "long", day: "numeric", year: "numeric",
              })}
            </div>
            <div className="chart-subtitle">
              Shaded area is estimated load reduction · amber markers are called event hours
            </div>
            <div className="chart-container">
              <BaselineChart rows={selected.rows} />
            </div>
          </div>
        </>
      )}
    </>
  );
}
