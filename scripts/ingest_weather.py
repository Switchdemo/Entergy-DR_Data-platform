"""
ingest_weather.py
-----------------
Fetches hourly weather observations for the New Orleans area and stores
them in the weather_stations and weather_observations tables.

Uses Open-Meteo Archive API (free, no API key required).
Source: https://open-meteo.com/

Usage:
    # Fetch weather for a date range
    python scripts/ingest_weather.py --start 2025-07-01 --end 2026-08-01

    # Fetch last 30 days
    python scripts/ingest_weather.py --days 30

    # Dry run
    python scripts/ingest_weather.py --start 2026-07-01 --end 2026-07-31 --dry-run

    # Use DATABASE_URL env var
    DATABASE_URL=postgresql://... python scripts/ingest_weather.py --start 2026-07-01 --end 2026-07-31
"""

import argparse
import json
import os
import sys
from datetime import datetime, date, timedelta

import requests
import psycopg2
from psycopg2.extras import execute_values

# ============================================================
# Configuration
# ============================================================

# New Orleans area — Louis Armstrong International Airport (KMSY)
STATION_ID = "KMSY"
STATION_NAME = "New Orleans Intl Airport (KMSY)"
LATITUDE = 29.9934
LONGITUDE = -90.2580

# Open-Meteo archive API (free, no key)
OPEN_METEO_URL = "https://archive-api.open-meteo.com/v1/archive"

# Hourly variables to fetch
HOURLY_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
    "dew_point_2m",
    "apparent_temperature",
    "wind_speed_10m",
]

TIMEZONE = "America/Chicago"


# ============================================================
# Database helpers
# ============================================================

def get_db_connection(db_url=None):
    url = db_url or os.getenv('DATABASE_URL')
    if not url:
        print("ERROR: No database URL. Use --db-url or set DATABASE_URL env var.")
        sys.exit(1)
    return psycopg2.connect(url)


def ensure_station(conn):
    """Insert the weather station if it doesn't exist."""
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO weather_stations (id, name, latitude, longitude)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (id) DO NOTHING
    """, (STATION_ID, STATION_NAME, LATITUDE, LONGITUDE))
    conn.commit()
    cur.close()
    print(f"  Station: {STATION_ID} ({STATION_NAME})", flush=True)


def link_station_to_sites(conn):
    """Set weather_station_id on all sites that don't have one."""
    cur = conn.cursor()
    cur.execute("""
        UPDATE sites SET weather_station_id = %s
        WHERE weather_station_id IS NULL
    """, (STATION_ID,))
    updated = cur.rowcount
    conn.commit()
    cur.close()
    if updated > 0:
        print(f"  Linked {updated} sites to station {STATION_ID}", flush=True)


def upsert_observations(conn, observations):
    """Bulk upsert weather observations."""
    cur = conn.cursor()

    sql = """
        INSERT INTO weather_observations
            (station_id, observation_hour, temperature_f, dew_point_f,
             humidity_pct, heat_index_f, wind_speed_mph)
        VALUES %s
        ON CONFLICT (station_id, observation_hour)
        DO UPDATE SET
            temperature_f = EXCLUDED.temperature_f,
            dew_point_f = EXCLUDED.dew_point_f,
            humidity_pct = EXCLUDED.humidity_pct,
            heat_index_f = EXCLUDED.heat_index_f,
            wind_speed_mph = EXCLUDED.wind_speed_mph
    """
# Deduplicate by station_id + observation_hour
    seen = set()
    deduped = []
    for obs in observations:
        key = (obs['station_id'], obs['observation_hour'])
        if key not in seen:
            seen.add(key)
            deduped.append(obs)
    observations = deduped
    
    rows = [(
        obs['station_id'],
        obs['observation_hour'],
        obs['temperature_f'],
        obs['dew_point_f'],
        obs['humidity_pct'],
        obs['heat_index_f'],
        obs['wind_speed_mph'],
    ) for obs in observations]

    template = "(%s, %s::timestamptz, %s, %s, %s, %s, %s)"

    chunk_size = 1000
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        execute_values(cur, sql, chunk, template=template, page_size=chunk_size)

    conn.commit()
    cur.close()
    print(f"  Upserted {len(rows)} weather observations", flush=True)


# ============================================================
# Open-Meteo API
# ============================================================

def celsius_to_fahrenheit(c):
    """Convert Celsius to Fahrenheit."""
    if c is None:
        return None
    return round(c * 9 / 5 + 32, 1)


def kmh_to_mph(kmh):
    """Convert km/h to mph."""
    if kmh is None:
        return None
    return round(kmh * 0.621371, 1)


def compute_heat_index(temp_f, humidity):
    """
    Compute heat index using the Rothfusz regression.
    Only valid for temp >= 80°F and humidity >= 40%.
    """
    if temp_f is None or humidity is None:
        return None
    if temp_f < 80:
        return temp_f

    hi = (-42.379
          + 2.04901523 * temp_f
          + 10.14333127 * humidity
          - 0.22475541 * temp_f * humidity
          - 0.00683783 * temp_f ** 2
          - 0.05481717 * humidity ** 2
          + 0.00122874 * temp_f ** 2 * humidity
          + 0.00085282 * temp_f * humidity ** 2
          - 0.00000199 * temp_f ** 2 * humidity ** 2)

    return round(hi, 1)


def fetch_weather(start_date, end_date):
    """
    Fetch hourly weather from Open-Meteo Archive API.
    Returns list of observation dicts.
    """
    # Open-Meteo limits requests to ~1 year at a time
    # Split into chunks if needed
    all_observations = []
    current_start = start_date

    while current_start <= end_date:
        chunk_end = min(current_start + timedelta(days=364), end_date)

        print(f"  Fetching {current_start} to {chunk_end}...", flush=True)

        params = {
            "latitude": LATITUDE,
            "longitude": LONGITUDE,
            "start_date": current_start.isoformat(),
            "end_date": chunk_end.isoformat(),
            "hourly": ",".join(HOURLY_VARS),
            "temperature_unit": "celsius",
            "wind_speed_unit": "kmh",
            "timezone": TIMEZONE,
        }

        resp = requests.get(OPEN_METEO_URL, params=params, timeout=60)
        if resp.status_code != 200:
            print(f"  ERROR: API returned {resp.status_code}: {resp.text}", flush=True)
            current_start = chunk_end + timedelta(days=1)
            continue

        data = resp.json()
        hourly = data.get("hourly", {})
        times = hourly.get("time", [])
        temps = hourly.get("temperature_2m", [])
        humidities = hourly.get("relative_humidity_2m", [])
        dew_points = hourly.get("dew_point_2m", [])
        apparent_temps = hourly.get("apparent_temperature", [])
        wind_speeds = hourly.get("wind_speed_10m", [])

        for i, t in enumerate(times):
            temp_f = celsius_to_fahrenheit(temps[i] if i < len(temps) else None)
            dew_f = celsius_to_fahrenheit(dew_points[i] if i < len(dew_points) else None)
            humidity = humidities[i] if i < len(humidities) else None
            wind_mph = kmh_to_mph(wind_speeds[i] if i < len(wind_speeds) else None)
            heat_idx = compute_heat_index(temp_f, humidity)

            all_observations.append({
                'station_id': STATION_ID,
                'observation_hour': t + ":00 " + TIMEZONE,
                'temperature_f': temp_f,
                'dew_point_f': dew_f,
                'humidity_pct': humidity,
                'heat_index_f': heat_idx,
                'wind_speed_mph': wind_mph,
            })

        print(f"  Got {len(times)} hours for this chunk", flush=True)
        current_start = chunk_end + timedelta(days=1)

    return all_observations


# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='Ingest weather data from Open-Meteo')
    parser.add_argument('--start', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end', help='End date (YYYY-MM-DD)')
    parser.add_argument('--days', type=int, help='Fetch last N days (alternative to --start/--end)')
    parser.add_argument('--db-url', help='PostgreSQL connection string')
    parser.add_argument('--dry-run', action='store_true', help='Fetch and display without saving')

    args = parser.parse_args()
    print("[weather] Starting...", flush=True)

    # Determine date range
    if args.days:
        end_dt = date.today() - timedelta(days=1)  # yesterday (today may be incomplete)
        start_dt = end_dt - timedelta(days=args.days)
    elif args.start and args.end:
        start_dt = date.fromisoformat(args.start)
        end_dt = date.fromisoformat(args.end)
    else:
        print("ERROR: Specify --start/--end or --days")
        sys.exit(1)

    print(f"[weather] Date range: {start_dt} to {end_dt}", flush=True)
    print(f"[weather] Station: {STATION_ID} ({LATITUDE}, {LONGITUDE})", flush=True)

    # Fetch from API
    observations = fetch_weather(start_dt, end_dt)
    print(f"\n[weather] Total observations fetched: {len(observations)}", flush=True)

    if not observations:
        print("[weather] No data returned.", flush=True)
        return

    # Show sample
    print(f"\n  Sample (first 5):", flush=True)
    for obs in observations[:5]:
        print(f"    {obs['observation_hour']}: {obs['temperature_f']}°F, "
              f"{obs['humidity_pct']}% humidity, "
              f"heat index {obs['heat_index_f']}°F, "
              f"wind {obs['wind_speed_mph']} mph", flush=True)

    # Stats
    temps = [o['temperature_f'] for o in observations if o['temperature_f'] is not None]
    if temps:
        print(f"\n  Temperature range: {min(temps)}°F – {max(temps)}°F", flush=True)
        print(f"  Average: {sum(temps)/len(temps):.1f}°F", flush=True)

    heat_indices = [o['heat_index_f'] for o in observations if o['heat_index_f'] is not None and o['heat_index_f'] >= 80]
    if heat_indices:
        print(f"  Heat index range (when ≥80°F): {min(heat_indices)}°F – {max(heat_indices)}°F", flush=True)
        hours_over_100 = len([h for h in heat_indices if h >= 100])
        print(f"  Hours with heat index ≥100°F: {hours_over_100}", flush=True)

    if args.dry_run:
        print(f"\n[weather] DRY RUN — not saving to database", flush=True)
        return

    # Save to database
    print(f"\n[weather] Connecting to database...", flush=True)
    conn = get_db_connection(args.db_url)

    try:
        ensure_station(conn)
        link_station_to_sites(conn)
        upsert_observations(conn, observations)
        print(f"\n[weather] Done. {len(observations)} observations saved.", flush=True)
    except Exception as e:
        print(f"[weather] ERROR: {e}", flush=True)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()


if __name__ == '__main__':
    main()
