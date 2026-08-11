"use client";

import { useEffect, useRef } from "react";
import Chart from "chart.js/auto";
import type { HourlyRow, WeatherRow } from "@/lib/rpc";
import { WX_CFG, wxByHour, type WeatherSelection } from "@/lib/weather";

interface Props {
  hourlyData: HourlyRow[];
  weatherData: WeatherRow[];
  selectedDay: string;
  selWx: WeatherSelection;
}

export default function HourlyChart({
  hourlyData,
  weatherData,
  selectedDay,
  selWx,
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
      },
    ];

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
          legend: { display: hasWx, labels: { color: "#e4e4e7", font: { size: 11 }, usePointStyle: true, padding: 16 } },
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
  }, [hourlyData, weatherData, selectedDay, selWx]);

  return <canvas ref={canvasRef} />;
}
