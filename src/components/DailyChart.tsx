"use client";

import { useEffect, useRef } from "react";
import Chart from "chart.js/auto";
import type { DailyRow, WeatherRow } from "@/lib/rpc";
import { classifyDay } from "@/lib/dayClassify";
import { buildDayPatterns } from "@/lib/patterns";
import { WX_CFG, wxByDate, type WeatherSelection } from "@/lib/weather";

interface Props {
  dailyData: DailyRow[];
  weatherData: WeatherRow[];
  holidayDates: Set<string>;
  selWx: WeatherSelection;
  onBarClick: (date: string) => void;
}

export default function DailyChart({
  dailyData,
  weatherData,
  holidayDates,
  selWx,
  onBarClick,
}: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const chartRef = useRef<Chart | null>(null);
  // keep latest click handler without re-creating the chart
  const clickRef = useRef(onBarClick);
  clickRef.current = onBarClick;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    if (chartRef.current) chartRef.current.destroy();

    const patterns = buildDayPatterns(ctx);
    const labels = dailyData.map((d) =>
      new Date(d.read_date + "T12:00:00").toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      })
    );

    const barColors = dailyData.map((d) => {
      const type = classifyDay(d.read_date, holidayDates);
      if (type === "holiday") return patterns.holiday ?? "#f59e0b";
      if (type === "weekend") return patterns.weekend ?? "#5b8def";
      return "#3b82f6";
    });
    const barBorders = dailyData.map((d) => {
      const type = classifyDay(d.read_date, holidayDates);
      if (type === "holiday") return "#f59e0b";
      if (type === "weekend") return "#5b8def";
      return "#3b82f6";
    });

    const wa = wxByDate(weatherData);
    const hasWx = selWx !== "none" && Object.keys(wa).length > 0;
    const wc = selWx !== "none" ? WX_CFG[selWx] : null;

    const datasets: any[] = [
      {
        label: "Peak kW",
        data: dailyData.map((d) => Number(d.peak_kw)),
        backgroundColor: barColors,
        borderColor: barBorders,
        borderWidth: 1,
        borderRadius: 3,
        borderSkipped: false,
        yAxisID: "y",
        order: 2,
      },
    ];

    if (hasWx && wc) {
      datasets.push({
        label: wc.label,
        data: dailyData.map((d) => {
          const w = wa[d.read_date];
          return w ? w[selWx as keyof typeof w] : null;
        }),
        type: "line",
        borderColor: wc.color,
        backgroundColor: wc.color + "20",
        borderWidth: 2.5,
        pointRadius: 3,
        pointBackgroundColor: wc.color,
        tension: 0.3,
        yAxisID: "y2",
        order: 1,
      });
    }

    const scales: any = {
      x: { ticks: { color: "#71717a", font: { size: 11 }, maxTicksLimit: 15 }, grid: { display: false }, border: { color: "#2a2d38" } },
      y: { position: "left", ticks: { color: "#71717a", font: { size: 11 } }, grid: { color: "#1f2230" }, border: { display: false }, title: { display: true, text: "kW", color: "#71717a", font: { size: 11 } } },
    };
    if (hasWx && wc) {
      scales.y2 = { position: "right", ticks: { color: wc.color, font: { size: 11 } }, grid: { display: false }, border: { display: false }, title: { display: true, text: `${wc.label} (${wc.axis})`, color: wc.color, font: { size: 11 } } };
    }

    chartRef.current = new Chart(ctx, {
      type: "bar",
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        onClick: (_e, el) => {
          if (el.length) clickRef.current(dailyData[el[0].index].read_date);
        },
        onHover: (e, el) => {
          const t = (e.native?.target as HTMLElement) || null;
          if (t) t.style.cursor = el.length ? "pointer" : "default";
        },
        plugins: {
          legend: {
            display: hasWx,
            labels: {
              color: "#e4e4e7",
              font: { size: 11 },
              usePointStyle: true,
              padding: 16,
              filter: (item) => item.datasetIndex! > 0, // custom legend below handles bars
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
              title: (items) => {
                const d = dailyData[items[0].dataIndex];
                const label = new Date(d.read_date + "T12:00:00").toLocaleDateString("en-US", {
                  weekday: "short",
                  month: "short",
                  day: "numeric",
                });
                const type = classifyDay(d.read_date, holidayDates);
                if (type === "holiday") return label + " (Holiday)";
                if (type === "weekend") return label + " (Weekend)";
                return label;
              },
              label: (item) => {
                if (item.datasetIndex === 0) {
                  const d = dailyData[item.dataIndex];
                  return [
                    "Peak: " + Number(d.peak_kw).toFixed(1) + " kW",
                    "Avg: " + Number(d.avg_kw).toFixed(1) + " kW",
                    "Energy: " + Number(d.total_kwh).toFixed(0) + " kWh",
                  ];
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
  }, [dailyData, weatherData, holidayDates, selWx]);

  return <canvas ref={canvasRef} />;
}
