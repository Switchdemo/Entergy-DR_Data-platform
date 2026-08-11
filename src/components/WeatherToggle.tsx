"use client";

import { WEATHER_OPTIONS, type WeatherSelection } from "@/lib/weather";

interface Props {
  value: WeatherSelection;
  onChange: (v: WeatherSelection) => void;
}

export default function WeatherToggle({ value, onChange }: Props) {
  return (
    <div className="weather-controls">
      <span className="weather-label">Weather overlay:</span>
      {WEATHER_OPTIONS.map((opt) => (
        <button
          key={opt.key}
          className={`weather-btn ${value === opt.key ? "active" : ""}`}
          onClick={() => onChange(opt.key)}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
