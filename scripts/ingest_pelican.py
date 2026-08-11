""" 
ingest_pelican.py
-----------------
Fetches interval data from Pelican PowerLink devices via the OpenAPI
and feeds it into the same curated_intervals pipeline as AMI data.

Two modes:
  --discover  : List all Pelican sites and PowerLink devices (for mapping)
  --ingest    : Pull interval data for mapped meters and write to database

Usage:
    # Discover all PowerLink devices across all sites
    python scripts/ingest_pelican.py --discover

    # Ingest data for a date range
    python scripts/ingest_pelican.py --ingest --start 2026-07-01 --end 2026-07-31

    # Ingest last N days
    python scripts/ingest_pelican.py --ingest --days 30

    # Dry run (fetch and display without saving)
    python scripts/ingest_pelican.py --ingest --days 7 --dry-run

Environment variables (set as GitHub secrets):
    PELICAN_USERNAME  - Pelican MySites login email
    PELICAN_PASSWORD  - Pelican MySites password
    DATABASE_URL      - Supabase PostgreSQL connection string
"""

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from datetime import date, timedelta, datetime

import requests
import psycopg2
from psycopg2.extras import RealDictCursor, execute_values

# ============================================================
# Configuration
# ============================================================

MYSITES_URL = "https://mysites.officeclimatecontrol.net"
TIMEZONE = "America/Chicago"

# Try these durations in order to discover what works
DURATION_OPTIONS = ["PT5M", "PT15M", "PT1H"]

# kWh to kW conversion factors by interval minutes
KW_FACTOR = {
    5: 12,     # 60/5
    15: 4,     # 60/15
    60: 1,     # 60/60
}


# ============================================================
# Database helpers
# ============================================================

def get_db_connection(db_url=None):
    url = db_url or os.getenv('DATABASE_URL')
    if not url:
        print("ERROR: No database URL.", flush=True)
        sys.exit(1)
    return psycopg2.connect(url)


def get_pelican_meters(conn):
    """Fetch pulse/non-AMI meters that have a pelican_site_domain configured."""
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT
            m.id::text AS meter_id,
            m.meter_number,
            m.meter_type,
            m.backfill_recorder_id,
            m.pelican_device_name,
            s.id::text AS site_id,
            s.name AS site_name,
            s.pelican_name,
            s.pelican_site_domain
        FROM meters m
        JOIN meter_assignments ma ON ma.meter_id = m.id AND ma.end_date IS NULL
        JOIN sites s ON s.id = ma.site_id
        WHERE m.meter_type IN ('pulse_kyz', 'non_ami')
          AND m.is_active = TRUE
          AND s.pelican_site_domain IS NOT NULL
          AND s.pelican_site_domain != ''
        ORDER BY s.name, m.meter_number
    """)
    meters = cur.fetchall()
    cur.close()
    return meters


def upsert_curated_from_pelican(conn, records, file_load_id=None):
    """UPSERT Pelican data into curated_intervals."""
    cur = conn.cursor()
    sql = """
        INSERT INTO curated_intervals
            (meter_id, channel, interval_end, reading_kwh, reading_kw,
             interval_status, source_file_load_id, is_estimated, is_outlier)
        VALUES %s
        ON CONFLICT (meter_id, channel, interval_end)
        DO UPDATE SET
            reading_kwh = EXCLUDED.reading_kwh,
            reading_kw = EXCLUDED.reading_kw,
            interval_status = EXCLUDED.interval_status,
            updated_at = NOW()
    """
    rows = [(
        r['meter_id'], 'del', r['interval_end'],
        r['reading_kwh'], r['reading_kw'],
        'VAL', file_load_id, False, False
    ) for r in records]

    template = "(%s::uuid, %s, %s::timestamptz, %s, %s, %s, %s::uuid, %s, %s)"

    for i in range(0, len(rows), 500):
        chunk = rows[i:i+500]
        execute_values(cur, sql, chunk, template=template, page_size=100)

    conn.commit()
    cur.close()
    return len(rows)


def upsert_hourly_from_curated(conn, meter_id, start_date, end_date):
    """Recompute hourly rollups for a meter over a date range."""
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO hourly_reads (meter_id, channel, hour_start, kwh_total, avg_kw, interval_count, has_gaps, has_outliers)
        SELECT
            meter_id, channel,
            date_trunc('hour', interval_end - interval '1 second') AS hour_start,
            SUM(reading_kwh) AS kwh_total,
            SUM(reading_kwh) AS avg_kw,
            COUNT(*) AS interval_count,
            FALSE AS has_gaps,
            BOOL_OR(is_outlier) AS has_outliers
        FROM curated_intervals
        WHERE meter_id = %s::uuid
          AND channel = 'del'
          AND (interval_end AT TIME ZONE 'America/Chicago')::date BETWEEN %s AND %s
        GROUP BY meter_id, channel, date_trunc('hour', interval_end - interval '1 second')
        ON CONFLICT (meter_id, channel, hour_start)
        DO UPDATE SET
            kwh_total = EXCLUDED.kwh_total,
            avg_kw = EXCLUDED.avg_kw,
            interval_count = EXCLUDED.interval_count,
            has_gaps = EXCLUDED.has_gaps,
            has_outliers = EXCLUDED.has_outliers,
            computed_at = NOW()
    """, (meter_id, start_date.isoformat(), end_date.isoformat()))
    updated = cur.rowcount
    conn.commit()
    cur.close()
    return updated


def log_file_load(conn, description):
    """Create a raw_file_loads entry for Pelican ingestion."""
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO raw_file_loads (filename, file_format, status, loaded_by)
        VALUES (%s, 'pelican_api', 'processing', 'github_actions')
        RETURNING id::text
    """, (description,))
    fid = cur.fetchone()[0]
    conn.commit()
    cur.close()
    return fid


def update_file_load(conn, fid, status, row_count=0):
    cur = conn.cursor()
    cur.execute("""
        UPDATE raw_file_loads SET status = %s, row_count = %s WHERE id = %s::uuid
    """, (status, row_count, fid))
    conn.commit()
    cur.close()


# ============================================================
# Pelican API helpers
# ============================================================

def pelican_get(base_url, username, password, obj, selection, values, token=None):
    """Make a GET request to the Pelican API, return parsed XML."""
    sel_str = ";".join(f"{k}:{v}" for k, v in selection.items()) + ";"
    val_str = ";".join(values)

    params = {
        "request": "get",
        "object": obj,
        "selection": sel_str,
        "value": val_str,
    }

    if token:
        params["token"] = token
    else:
        params["username"] = username
        params["password"] = password

    url = f"{base_url}/api.cgi"
    resp = requests.get(url, params=params, timeout=30, verify=True)

    if resp.status_code != 200:
        print(f"    API error {resp.status_code}: {resp.text[:200]}", flush=True)
        return None

    try:
        root = ET.fromstring(resp.text)
        return root
    except ET.ParseError as e:
        print(f"    XML parse error: {e}", flush=True)
        print(f"    Response: {resp.text[:500]}", flush=True)
        return None


def get_mysites_tokens(username, password):
    """Get all site names, domains, and tokens from MySites."""
    print("[pelican] Authenticating with MySites...", flush=True)

    params = {
        "username": username,
        "password": password,
        "request": "get",
        "object": "Sites",
        "value": "name;domain;token",
    }

    resp = requests.get(f"{MYSITES_URL}/api.cgi", params=params, timeout=30, verify=True)
    if resp.status_code != 200:
        print(f"  ERROR: MySites returned {resp.status_code}", flush=True)
        return []

    try:
        root = ET.fromstring(resp.text)
    except ET.ParseError:
        print(f"  ERROR: Could not parse MySites response", flush=True)
        print(f"  Response: {resp.text[:500]}", flush=True)
        return []

    success = root.findtext("success")
    if success != "1":
        msg = root.findtext("message", "Unknown error")
        print(f"  ERROR: {msg}", flush=True)
        return []

    sites = []
    for site_el in root.findall("Sites"):
        name = site_el.findtext("name", "")
        domain = site_el.findtext("domain", "")
        token = site_el.findtext("token", "")
        if domain:
            sites.append({"name": name, "domain": domain, "token": token})

    print(f"  Found {len(sites)} sites", flush=True)
    return sites


def discover_powerlinks(site, username, password):
    """Query a site for PowerLink devices and available data."""
    domain = site["domain"]
    token = site.get("token")
    base_url = f"https://{domain}"

    # Query a small date range to find what PowerLink devices exist
    today = date.today()
    yesterday = today - timedelta(days=1)

    selection = {
        "startDateTime": f"{yesterday.isoformat()}T00:00:00Z",
        "endDateTime": f"{yesterday.isoformat()}T23:59:59Z",
        "duration": "day",
    }
    values = ["name", "meterId", "serialNo", "kWh", "kW", "timestamp", "unitsPerPulse", "units"]

    root = pelican_get(base_url, username, password, "PowerUsage", selection, values, token)
    if root is None:
        return []

    devices = []
    for pu in root.findall("PowerUsage"):
        name = pu.findtext("name", "")
        meter_id = pu.findtext("meterId", "")
        serial = pu.findtext("serialNo", "")
        kwh = pu.findtext("kWh", "")
        units_per_pulse = pu.findtext("unitsPerPulse", "")
        units = pu.findtext("units", "")

        devices.append({
            "site_name": site["name"],
            "site_domain": domain,
            "device_name": name,
            "meter_id": meter_id,
            "serial_no": serial,
            "sample_kwh": kwh,
            "units_per_pulse": units_per_pulse,
            "units": units,
        })

    return devices


def detect_granularity(base_url, username, password, token=None):
    """Try different durations to find the finest available granularity."""
    today = date.today()
    test_date = today - timedelta(days=2)

    for duration in DURATION_OPTIONS:
        selection = {
            "startDateTime": f"{test_date.isoformat()}T00:00:00Z",
            "endDateTime": f"{test_date.isoformat()}T23:59:59Z",
            "duration": duration,
        }
        values = ["name", "kWh", "timestamp"]

        root = pelican_get(base_url, username, password, "PowerUsage", selection, values, token)
        if root is None:
            continue

        records = root.findall("PowerUsage")
        # Check if we got more than 1 record (1 might just be a daily summary)
        if len(records) > 1:
            # Determine interval from timestamps
            timestamps = [r.findtext("timestamp", "") for r in records if r.findtext("timestamp")]
            if len(timestamps) >= 2:
                t1 = datetime.fromisoformat(timestamps[0].replace("Z", "+00:00"))
                t2 = datetime.fromisoformat(timestamps[1].replace("Z", "+00:00"))
                diff_minutes = int((t2 - t1).total_seconds() / 60)
                print(f"    Detected granularity: {duration} ({diff_minutes}-min intervals, {len(records)} records)", flush=True)
                return duration, diff_minutes

    print(f"    WARNING: Could not detect granularity, defaulting to PT15M", flush=True)
    return "PT15M", 15


def fetch_power_usage(base_url, username, password, token, start_dt, end_dt, duration, device_name=None):
    """Fetch PowerUsage data for a date range."""
    all_records = []

    # API limits: max 31 days per request for daily, similar for intervals
    # Chunk into 7-day blocks for interval data to be safe
    chunk_days = 7
    current = start_dt

    while current <= end_dt:
        chunk_end = min(current + timedelta(days=chunk_days - 1), end_dt)

        selection = {
            "startDateTime": f"{current.isoformat()}T00:00:00Z",
            "endDateTime": f"{chunk_end.isoformat()}T23:59:59Z",
            "duration": duration,
        }
        if device_name:
            selection["name"] = device_name

        values = ["name", "meterId", "serialNo", "kWh", "kW", "timestamp"]

        root = pelican_get(base_url, username, password, "PowerUsage", selection, values, token)
        if root is not None:
            for pu in root.findall("PowerUsage"):
                name = pu.findtext("name", "")
                kwh_str = pu.findtext("kWh", "0")
                kw_str = pu.findtext("kW", "0")
                ts_str = pu.findtext("timestamp", "")
                meter_id_val = pu.findtext("meterId", "")

                if ts_str:
                    all_records.append({
                        "device_name": name,
                        "pelican_meter_id": meter_id_val,
                        "kwh": float(kwh_str) if kwh_str else 0,
                        "kw": float(kw_str) if kw_str else 0,
                        "timestamp": ts_str,
                    })

        current = chunk_end + timedelta(days=1)

    return all_records


# ============================================================
# Discovery mode
# ============================================================

def run_discover(username, password):
    """Discover all PowerLink devices across all Pelican sites."""
    sites = get_mysites_tokens(username, password)
    if not sites:
        return

    print(f"\n{'='*70}", flush=True)
    print(f"PELICAN POWERLINK DISCOVERY", flush=True)
    print(f"{'='*70}", flush=True)

    all_devices = []
    for site in sites:
        print(f"\n  Site: {site['name']} ({site['domain']})", flush=True)
        devices = discover_powerlinks(site, username, password)
        if devices:
            for d in devices:
                print(f"    PowerLink: {d['device_name']} | MeterId: {d['meter_id']} | "
                      f"Serial: {d['serial_no']} | Sample kWh: {d['sample_kwh']} | "
                      f"Units/Pulse: {d['units_per_pulse']}", flush=True)
            all_devices.extend(devices)
        else:
            print(f"    No PowerLink devices found", flush=True)

    print(f"\n{'='*70}", flush=True)
    print(f"SUMMARY", flush=True)
    print(f"{'='*70}", flush=True)
    print(f"Total sites scanned:    {len(sites)}", flush=True)
    print(f"Sites with PowerLinks:  {len(set(d['site_domain'] for d in all_devices))}", flush=True)
    print(f"Total PowerLink inputs: {len(all_devices)}", flush=True)

    if all_devices:
        print(f"\nTo map these to your database, add these columns to your sites/meters:", flush=True)
        print(f"  sites.pelican_site_domain  = the site domain (e.g., 'jesuiteno.officeclimatecontrol.net')", flush=True)
        print(f"  meters.pelican_device_name = the PowerLink device name from above", flush=True)
        print(f"\nSQL example:", flush=True)
        print(f"  UPDATE sites SET pelican_site_domain = 'jesuiteno.officeclimatecontrol.net'", flush=True)
        print(f"    WHERE pelican_name = 'JesuitHighSchool';", flush=True)
        print(f"  UPDATE meters SET pelican_device_name = 'Main Meter'", flush=True)
        print(f"    WHERE meter_number = 'EM17001237';", flush=True)

    print(f"{'='*70}", flush=True)
    return all_devices


# ============================================================
# Ingest mode
# ============================================================

def run_ingest(username, password, start_dt, end_dt, db_url=None, dry_run=False):
    """Pull PowerLink data for mapped meters and write to database."""
    print(f"[pelican] Ingest mode: {start_dt} to {end_dt}", flush=True)

    # Get MySites tokens
    sites_tokens = get_mysites_tokens(username, password)
    token_map = {s["domain"]: s["token"] for s in sites_tokens}

    # Get mapped meters from database
    conn = get_db_connection(db_url)
    meters = get_pelican_meters(conn)

    if not meters:
        print("[pelican] No pulse/non-AMI meters with pelican_site_domain configured.", flush=True)
        print("[pelican] Run --discover first, then map meters in the database.", flush=True)
        conn.close()
        return

    print(f"[pelican] Found {len(meters)} mapped meters", flush=True)

    # Group meters by site domain
    by_domain = {}
    for m in meters:
        domain = m["pelican_site_domain"]
        if domain not in by_domain:
            by_domain[domain] = []
        by_domain[domain].append(m)

    # Log file load
    file_load_id = None
    if not dry_run:
        file_load_id = log_file_load(conn, f"Pelican API {start_dt} to {end_dt}")

    total_records = 0
    total_curated = 0
    total_hourly = 0

    for domain, domain_meters in by_domain.items():
        token = token_map.get(domain)
        if not token:
            print(f"\n  WARNING: No token for {domain} — skipping", flush=True)
            continue

        base_url = f"https://{domain}"
        print(f"\n  Site: {domain} ({len(domain_meters)} meters)", flush=True)

        # Detect granularity
        duration, interval_minutes = detect_granularity(base_url, username, password, token)
        kw_factor = KW_FACTOR.get(interval_minutes, 4)

        for meter in domain_meters:
            print(f"    Meter: {meter['meter_number']} ({meter['site_name']})", flush=True)
            device_name = meter.get("pelican_device_name")

            records = fetch_power_usage(base_url, username, password, token,
                                         start_dt, end_dt, duration, device_name)

            if not records:
                print(f"      No data returned", flush=True)
                continue

            print(f"      Fetched {len(records)} intervals", flush=True)
            total_records += len(records)

            # Transform to curated format
            curated = []
            for r in records:
                ts = r["timestamp"].replace("Z", "+00:00")
                try:
                    dt = datetime.fromisoformat(ts)
                except ValueError:
                    continue

                # Convert to Central Time then to UTC for storage
                reading_kwh = r["kwh"]
                reading_kw = reading_kwh * kw_factor if reading_kwh else r["kw"]

                curated.append({
                    "meter_id": meter["meter_id"],
                    "interval_end": dt.isoformat(),
                    "reading_kwh": round(reading_kwh, 5),
                    "reading_kw": round(reading_kw, 5),
                })

            if not dry_run and curated:
                count = upsert_curated_from_pelican(conn, curated, file_load_id)
                total_curated += count
                print(f"      Wrote {count} curated intervals", flush=True)

                # Recompute hourly rollups
                h_count = upsert_hourly_from_curated(conn, meter["meter_id"], start_dt, end_dt)
                total_hourly += h_count
                print(f"      Updated {h_count} hourly rollups", flush=True)
            elif dry_run:
                print(f"      [DRY RUN] Would write {len(curated)} intervals", flush=True)
                # Show sample
                for c in curated[:3]:
                    print(f"        {c['interval_end']}: {c['reading_kwh']} kWh / {c['reading_kw']} kW", flush=True)

    # Update file load status
    if not dry_run and file_load_id:
        update_file_load(conn, file_load_id, "success", total_records)

    conn.close()

    print(f"\n{'='*60}", flush=True)
    print(f"PELICAN INGEST SUMMARY", flush=True)
    print(f"{'='*60}", flush=True)
    print(f"Date range:        {start_dt} to {end_dt}", flush=True)
    print(f"Records fetched:   {total_records}", flush=True)
    print(f"Curated written:   {total_curated}", flush=True)
    print(f"Hourly updated:    {total_hourly}", flush=True)
    print(f"{'='*60}", flush=True)


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Ingest Pelican PowerLink data")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--discover", action="store_true", help="Discover PowerLink devices")
    mode.add_argument("--ingest", action="store_true", help="Ingest data for mapped meters")

    parser.add_argument("--start", help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end", help="End date (YYYY-MM-DD)")
    parser.add_argument("--days", type=int, help="Fetch last N days")
    parser.add_argument("--db-url", help="PostgreSQL connection string")
    parser.add_argument("--dry-run", action="store_true", help="Fetch without saving")

    args = parser.parse_args()
    print("[pelican] Starting...", flush=True)

    username = os.getenv("PELICAN_USERNAME")
    password = os.getenv("PELICAN_PASSWORD")

    if not username or not password:
        print("ERROR: Set PELICAN_USERNAME and PELICAN_PASSWORD env vars", flush=True)
        sys.exit(1)

    if args.discover:
        run_discover(username, password)

    elif args.ingest:
        if args.days:
            end_dt = date.today() - timedelta(days=1)
            start_dt = end_dt - timedelta(days=args.days)
        elif args.start and args.end:
            start_dt = date.fromisoformat(args.start)
            end_dt = date.fromisoformat(args.end)
        else:
            print("ERROR: Specify --start/--end or --days", flush=True)
            sys.exit(1)

        run_ingest(username, password, start_dt, end_dt, args.db_url, args.dry_run)


if __name__ == "__main__":
    main()
