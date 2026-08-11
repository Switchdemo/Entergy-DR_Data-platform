"use client";

import { useEffect, useRef } from "react";
import Chart from "chart.js/auto";
import type { BaselineRow } from "@/lib/rpc";

// Visual config per method — color + dash pattern
const METHOD_STYLE: Record<string, { color: string; dash: number[] }> = {
  "10 of 10":      { color: "#a1a1aa", dash: [6, 3] },    // gray dashed
  "High 5 of 10":  { color: "#f97316", dash: [8, 4] },    // orange dashed
  "High 3 of 10":  { color: "#ef4444", dash: [4, 4] },    // red dashed
};

const ACTUAL_COLOR = "#3b82f6";

interface Props {
  rows: BaselineRow[];        // all methods for ONE event_date
  methods: string[];          // which methods to show (toggled by user)
}

export default function BaselineChart({ rows, methods }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chartRef = useRef<Chart | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    if (chartRef.current) chartRef.current.destroy();

    // Group rows by method
    const byMethod: Record<string, BaselineRow[]> = {};
    for (const r of rows) {
      (byMethod[r.baseline_method] ??= []).push(r);
    }

    // Sort each group by hour
    for (const m of Object.keys(byMethod)) {
      byMethod[m].sort(
        (a, b) => new Date(a.hour_ct).getTime() - new Date(b.hour_ct).getTime()
      );
    }

    // Use any method's rows for the hour labels and actual load (actual is the same across methods)
    const anyMethod = Object.values(byMethod)[0] ?? [];
    const labels = anyMethod.map((d) => {
      const h = new Date(d.hour_ct).getHours();
      return h === 0 ? "12a" : h === 12 ? "12p" : h > 12 ? `${h - 12}p` : `${h}a`;
    });

    const datasets: any[] = [
      // Actual load — always shown
      {
        label: "Actual (metered)",
        data: anyMethod.map((d) => Number(d.actual_kw)),
        borderColor: ACTUAL_COLOR,
        backgroundColor: ACTUAL_COLOR + "15",
        borderWidth: 2.5,
        pointRadius: 4,
        pointBackgroundColor: ACTUAL_COLOR,
        fill: false,
        tension: 0.3,
        order: 10,
      },
    ];

    // One line per selected baseline method
    for (const method of methods) {
      const mRows = byMethod[method];
      if (!mRows) continue;
      const style = METHOD_STYLE[method] ?? { color: "#71717a", dash: [6, 3] };
      datasets.push({
        label: `Baseline: ${method}`,
        data: mRows.map((d) => Number(d.baseline_kw)),
        borderColor: style.color,
        backgroundColor: "transparent",
        borderWidth: 2,
        borderDash: style.dash,
        pointRadius: 2,
        pointBackgroundColor: style.color,
        fill: false,
        tension: 0.3,
        order: 5,
      });
    }

    chartRef.current = new Chart(ctx, {
      type: "line",
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: {
            labels: {
              color: "#e4e4e7",
              font: { size: 11 },
              usePointStyle: true,
              padding: 16,
            },
          },
          tooltip: {
            backgroundColor: "#0f1117",
            borderColor: "#2a2d38",
            borderWidth: 1,
            titleColor: "#e4e4e7",
            bodyColor: "#e4e4e7",
            padding: 12,
            callbacks: {
              afterBody: (items) => {
                const idx = items[0].dataIndex;
                const lines: string[] = [];
                const actual = Number(anyMethod[idx]?.actual_kw ?? 0);
                for (const method of methods) {
                  const mRows = byMethod[method];
                  if (!mRows?.[idx]) continue;
                  const bl = Number(mRows[idx].baseline_kw);
                  const red = bl - actual;
                  const pct = bl > 0 ? ((red / bl) * 100).toFixed(1) : "0.0";
                  lines.push(`${method} reduction: ${red.toFixed(1)} kW (${pct}%)`);
                }
                return lines;
              },
            },
          },
        },
        scales: {
          x: {
            ticks: { color: "#71717a", font: { size: 11 } },
            grid: { display: false },
            border: { color: "#2a2d38" },
          },
          y: {
            ticks: { color: "#71717a", font: { size: 11 } },
            grid: { color: "#1f2230" },
            border: { display: false },
            title: {
              display: true,
              text: "kW",
              color: "#71717a",
              font: { size: 11 },
            },
          },
        },
      },
    });

    return () => {
      chartRef.current?.destroy();
      chartRef.current = null;
    };
  }, [rows, methods]);

  return <canvas ref={canvasRef} />;
}
