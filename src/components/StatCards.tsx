"use client";

export interface Stat {
  label: string;
  value: string;
  color: string;
}

export function StatCards({ stats }: { stats: Stat[] }) {
  if (!stats.length) return null;
  return (
    <div className="stats">
      {stats.map((s) => (
        <div className="stat-card" key={s.label}>
          <div className="stat-label">{s.label}</div>
          <div className="stat-value" style={{ color: s.color }}>
            {s.value}
          </div>
        </div>
      ))}
    </div>
  );
}

export function DayLegend() {
  return (
    <div className="legend-row">
      <div className="legend-item">
        <div className="legend-swatch" style={{ background: "#3b82f6" }} /> Weekday
      </div>
      <div className="legend-item">
        <div
          className="legend-swatch"
          style={{
            background:
              "repeating-linear-gradient(-45deg, #1e3a6b, #1e3a6b 2px, #5b8def 2px, #5b8def 4px)",
          }}
        />{" "}
        Weekend
      </div>
      <div className="legend-item">
        <div
          className="legend-swatch"
          style={{
            background: "repeating-conic-gradient(#3b2008 0% 25%, #f59e0b 0% 50%) 50%/6px 6px",
          }}
        />{" "}
        Holiday
      </div>
    </div>
  );
}
