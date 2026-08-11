"use client";

import { useEffect, useRef } from "react";
import Chart from "chart.js/auto";
import type { HourlyRow, WeatherRow, BaselineRow } from "@/lib/rpc";
import { WX_CFG, wxByHour, type WeatherSelection } from "@/lib/weather";

// Visual config per baseline method
const METHOD_STYLE: Record<string, { color: string; dash: number[] }> = {
  "10 of 10":      { color: "#a1a1aa", dash: [6, 3] },
  "High 5 of 10":  { color: "#f97316", dash: [8, 4] },
  "High 3 of 10":  { color: "#ef4444", dash: [4, 4] },
};

interface Props {
  hourlyData: HourlyRow[];
  weatherData: WeatherRow[];
  selectedDay: string;
  selWx: WeatherSelection;
  baselineData?: BaselineRow[];
  enabledMethods?: Set<string>;
}

export default function HourlyChart({
  hourlyData,
  weatherData,
  selectedDay,
  selWx,
  baselineData = [],
  enabledMethods = new Set(),
}: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chartRef = useRef<Chart | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    if (chartRef.current) chartRef.current.destroy();

    const dayWx = wxByHour(weatherData, selectedDay);
    const hasWx = selWx !== "none" && Object.keys(dayWx).length > 0;
    const wc = selWx !== "none" ? WX_CFG[selWx] : null;

    const labels = hourlyData.map((d) => {
      const h = new Date(d.hour_ct).getHours();
      return h === 0 ? "12a" : h === 12 ? "12p" : h > 12 ? `${h - 12}p` : `${h}a`;
    });

    const datasets: any[] = [
      {
        label: "Demand (kW)",
        data: hourlyData.map((d) => Number(d.avg_kw)),
        borderColor: "#3b82f6",
        backgroundColor: "rgba(59,130,246,0.08)",
        borderWidth: 2.5,
        pointRadius: 4,
        pointBackgroundColor: hourlyData.map((d) => (d.has_gaps ? "#f59e0b" : "#3b82f6")),
        pointBorderColor: hourlyData.map((d) => (d.has_gaps ? "#f59e0b" : "#3b82f6")),
        fill: true,
        tension: 0.3,
        yAxisID: "y",
        order: 10,
      },
    ];

    // Add baseline overlays
    if (baselineData.length > 0 && enabledMethods.size > 0) {
      const byMethod: Record<string, BaselineRow[]> = {};
      for (const r of baselineData) {
        (byMethod[r.baseline_method] ??= []).push(r);
      }

      for (const method of enabledMethods) {
        const mRows = byMethod[method];
        if (!mRows) continue;
        const style = METHOD_STYLE[method] ?? { color: "#71717a", dash: [6, 3] };

        // Build a map of hour -> baseline_kw for this method
        const byHour: Record<number, number> = {};
        for (const r of mRows) {
          const h = new Date(r.hour_ct).getHours();
          byHour[h] = Number(r.baseline_kw);
        }

        datasets.push({
          label: `Baseline: ${method}`,
          data: hourlyData.map((d) => {
            const h = new Date(d.hour_ct).getHours();
            return byHour[h] ?? null;
          }),
          borderColor: style.color,
          backgroundColor: "transparent",
          borderWidth: 2,
          borderDash: style.dash,
          pointRadius: 2,
          pointBackgroundColor: style.color,
          fill: false,
          tension: 0.3,
          yAxisID: "y",
          order: 5,
        });
      }
    }

    // Weather overlay
    if (hasWx && wc) {
      datasets.push({
        label: wc.label,
        data: hourlyData.map((d) => {
          const h = new Date(d.hour_ct).getHours();
          const w = dayWx[h];
          return w ? Number(w[selWx as keyof typeof w]) : null;
        }),
        borderColor: wc.color,
        backgroundColor: wc.color + "15",
        borderWidth: 2,
        borderDash: [6, 3],
        pointRadius: 3,
        pointBackgroundColor: wc.color,
        fill: true,
        tension: 0.3,
        yAxisID: "y2",
      });
    }

    const scales: any = {
      x: { ticks: { color: "#71717a", font: { size: 11 } }, grid: { display: false }, border: { color: "#2a2d38" } },
      y: { position: "left", ticks: { color: "#71717a", font: { size: 11 } }, grid: { color: "#1f2230" }, border: { display: false }, title: { display: true, text: "kW", color: "#71717a", font: { size: 11 } } },
    };
    if (hasWx && wc) {
      scales.y2 = { position: "right", ticks: { color: wc.color, font: { size: 11 } }, grid: { display: false }, border: { display: false }, title: { display: true, text: `${wc.label} (${wc.axis})`, color: wc.color, font: { size: 11 } } };
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
            display: true,
            labels: { color: "#e4e4e7", font: { size: 11 }, usePointStyle: true, padding: 16 },
          },
          tooltip: {
            backgroundColor: "#0f1117",
            borderColor: "#2a2d38",
            borderWidth: 1,
            titleColor: "#e4e4e7",
            bodyColor: "#e4e4e7",
            padding: 12,
            callbacks: {
              label: (item) => {
                if (item.datasetIndex === 0) {
                  const d = hourlyData[item.dataIndex];
                  let l = Number(d.avg_kw).toFixed(2) + " kW";
                  if (d.has_gaps) l += ` (${d.interval_count}/12)`;
                  return "Demand: " + l;
                }
                // Baseline datasets
                const dsLabel = item.dataset.label || "";
                if (dsLabel.startsWith("Baseline:")) {
                  const actual = Number(hourlyData[item.dataIndex]?.avg_kw ?? 0);
                  const bl = Number(item.raw ?? 0);
                  const red = bl - actual;
                  return `${dsLabel}: ${bl.toFixed(2)} kW (${red >= 0 ? "+" : ""}${red.toFixed(1)} kW)`;
                }
                return wc ? `${wc.label}: ${item.raw}${wc.unit}` : "";
              },
            },
          },
        },
        scales,
      },
    });

    return () => {
      chartRef.current?.destroy();
      chartRef.current = null;
    };
  }, [hourlyData, weatherData, selectedDay, selWx, baselineData, enabledMethods]);

  return <canvas ref={canvasRef} />;
}
