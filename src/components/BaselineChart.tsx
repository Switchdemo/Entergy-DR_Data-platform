"use client";

import { useEffect, useRef } from "react";
import Chart from "chart.js/auto";
import type { BaselineRow } from "@/lib/rpc";

interface Props {
  rows: BaselineRow[]; // rows for ONE event_date, any order
}

// Renders the modeled baseline load against the metered actual for a single
// event day. The area between the two (baseline above actual) is the estimated
// load reduction. Event-window hours are drawn with amber markers.
export default function BaselineChart({ rows }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chartRef = useRef<Chart | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    if (chartRef.current) chartRef.current.destroy();

    const sorted = [...rows].sort(
      (a, b) => new Date(a.hour_ct).getTime() - new Date(b.hour_ct).getTime()
    );

    const labels = sorted.map((d) => {
      const h = new Date(d.hour_ct).getHours();
      return h === 0 ? "12a" : h === 12 ? "12p" : h > 12 ? `${h - 12}p` : `${h}a`;
    });

    chartRef.current = new Chart(ctx, {
      type: "line",
      data: {
        labels,
        datasets: [
          {
            label: "Baseline (modeled)",
            data: sorted.map((d) => Number(d.baseline_kw)),
            borderColor: "#a1a1aa",
            backgroundColor: "transparent",
            borderWidth: 2,
            borderDash: [6, 3],
            pointRadius: 2,
            tension: 0.3,
            order: 1,
          },
          {
            label: "Actual (metered)",
            data: sorted.map((d) => Number(d.actual_kw)),
            borderColor: "#3b82f6",
            // Fill between actual and baseline to visualize the reduction area.
            backgroundColor: "rgba(34,197,94,0.16)",
            fill: "-1",
            borderWidth: 2.5,
            pointRadius: sorted.map((d) => (d.is_event_hour ? 5 : 3)),
            pointBackgroundColor: sorted.map((d) => (d.is_event_hour ? "#f59e0b" : "#3b82f6")),
            pointBorderColor: sorted.map((d) => (d.is_event_hour ? "#f59e0b" : "#3b82f6")),
            tension: 0.3,
            order: 2,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: { labels: { color: "#e4e4e7", font: { size: 11 }, usePointStyle: true, padding: 16 } },
          tooltip: {
            backgroundColor: "#0f1117",
            borderColor: "#2a2d38",
            borderWidth: 1,
            titleColor: "#e4e4e7",
            bodyColor: "#e4e4e7",
            padding: 12,
            callbacks: {
              afterBody: (items) => {
                const d = sorted[items[0].dataIndex];
                const red = Number(d.baseline_kw) - Number(d.actual_kw);
                const tag = d.is_event_hour ? " (event hour)" : "";
                return `Reduction: ${red.toFixed(1)} kW${tag}`;
              },
            },
          },
        },
        scales: {
          x: { ticks: { color: "#71717a", font: { size: 11 } }, grid: { display: false }, border: { color: "#2a2d38" } },
          y: { ticks: { color: "#71717a", font: { size: 11 } }, grid: { color: "#1f2230" }, border: { display: false }, title: { display: true, text: "kW", color: "#71717a", font: { size: 11 } } },
        },
      },
    });

    return () => {
      chartRef.current?.destroy();
      chartRef.current = null;
    };
  }, [rows]);

  return <canvas ref={canvasRef} />;
}
