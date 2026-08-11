"""
baseline_engine.py
------------------
Computes demand response baselines using the pluggable methodology
configuration stored in baseline_methodologies.

Supports:
- Similar day selection (weekday/weekend/holiday logic)
- Configurable aggregation (mean, median, high-x-of-y)
- Same-day adjustment (positive-only additive, symmetric, multiplicative)
- Missing data handling with lookback expansion
- Shutdown day handling (include, exclude, or both)
- Dual baseline computation when shutdown_handling = 'both'

Usage:
    # Compute baseline for a specific event
    python scripts/baseline_engine.py --event-id <uuid> --db-url postgresql://...

    # Compute for all events using a specific methodology
    python scripts/baseline_engine.py --methodology "Concerto 10 of 10" --db-url postgresql://...

    # Dry run — show similar days and intermediate values without saving
    python scripts/baseline_engine.py --event-id <uuid> --dry-run

    # Use DATABASE_URL env var
    DATABASE_URL=postgresql://... python scripts/baseline_engine.py --event-id <uuid>
"""

import argparse
import os
import sys
import json
from datetime import datetime, date, timedelta, time
from decimal import Decimal

import psycopg2
from psycopg2.extras import RealDictCursor, execute_values


TIMEZONE = 'America/Chicago'


# ============================================================
# Database helpers
# ============================================================

def get_db_connection(db_url=None):
    url = db_url or os.getenv('DATABASE_URL')
    if not url:
        print("ERROR: No database URL. Use --db-url or set DATABASE_URL env var.")
        sys.exit(1)
    return psycopg2.connect(url)


def fetch_event(conn, event_id):
    """Fetch a DR event by ID."""
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT id, event_name, event_date, start_time, end_time, program_id
        FROM dr_events WHERE id = %s::uuid
    """, (event_id,))
    event = cur.fetchone()
    cur.close()
    return event


def fetch_all_events(conn):
    """Fetch all DR events."""
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT id, event_name, event_date, start_time, end_time, program_id FROM dr_events ORDER BY event_date")
    events = cur.fetchall()
    cur.close()
    return events


def fetch_methodology(conn, name=None, methodology_id=None):
    """Fetch a baseline methodology by name or ID."""
    cur = conn.cursor(cursor_factory=RealDictCursor)
    if methodology_id:
        cur.execute("SELECT * FROM baseline_methodologies WHERE id = %s::uuid AND is_active = TRUE", (methodology_id,))
    elif name:
        cur.execute("SELECT * FROM baseline_methodologies WHERE name = %s AND is_active = TRUE ORDER BY version DESC LIMIT 1", (name,))
    else:
        cur.execute("SELECT * FROM baseline_methodologies WHERE is_active = TRUE ORDER BY created_at LIMIT 1")
    method = cur.fetchone()
    cur.close()
    return method


def fetch_event_sites(conn, event_id):
    """Fetch sites participating in an event, with their active meters."""
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT
            des.site_id::text,
            s.name AS site_name,
            s.device_location,
            ma.meter_id::text,
            m.meter_number,
            m.meter_type
        FROM dr_event_sites des
        JOIN sites s ON s.id = des.site_id
        JOIN meter_assignments ma ON ma.site_id = s.id AND ma.end_date IS NULL
            AND ma.enrollment_status = 'active'
        JOIN meters m ON m.id = ma.meter_id AND m.is_active = TRUE
        WHERE des.event_id = %s::uuid
          AND des.opted_out = FALSE
    """, (event_id,))
    sites = cur.fetchall()
    cur.close()
    return sites


def fetch_holidays(conn, start_date, end_date):
    """Fetch all holiday dates (both actual and observed) in a range."""
    cur = conn.cursor()
    cur.execute("""
        SELECT DISTINCT d::date FROM (
            SELECT holiday_date AS d FROM federal_holidays
            WHERE holiday_date BETWEEN %s AND %s
            UNION
            SELECT observed_date AS d FROM federal_holidays
            WHERE observed_date BETWEEN %s AND %s
        ) sub
    """, (start_date, end_date, start_date, end_date))
    holidays = {row[0] for row in cur.fetchall()}
    cur.close()
    return holidays


def fetch_event_dates(conn, start_date, end_date):
    """Fetch all DR event dates in a range (to exclude from similar days)."""
    cur = conn.cursor()
    cur.execute("""
        SELECT DISTINCT event_date FROM dr_events
        WHERE event_date BETWEEN %s AND %s
    """, (start_date, end_date))
    event_dates = {row[0] for row in cur.fetchall()}
    cur.close()
    return event_dates


def fetch_shutdown_dates(conn, site_id, start_date, end_date):
    """Fetch shutdown dates for a site in a range."""
    cur = conn.cursor()
    cur.execute("""
        SELECT shutdown_date FROM site_shutdown_days
        WHERE site_id = %s::uuid AND shutdown_date BETWEEN %s AND %s
    """, (site_id, start_date, end_date))
    shutdowns = {row[0] for row in cur.fetchall()}
    cur.close()
    return shutdowns


def fetch_hourly_reads(conn, meter_id, channel, dates):
    """Fetch hourly reads for a meter on specific dates."""
    if not dates:
        return {}

    cur = conn.cursor(cursor_factory=RealDictCursor)
    date_list = [d.isoformat() for d in dates]
    cur.execute("""
        SELECT
            hour_start,
            (hour_start AT TIME ZONE 'America/Chicago')::date AS read_date,
            EXTRACT(HOUR FROM hour_start AT TIME ZONE 'America/Chicago')::int AS hour_of_day,
            avg_kw,
            has_gaps,
            interval_count
        FROM hourly_reads
        WHERE meter_id = %s::uuid
          AND channel = %s
          AND (hour_start AT TIME ZONE 'America/Chicago')::date = ANY(%s::date[])
        ORDER BY hour_start
    """, (meter_id, channel, date_list))

    reads = {}
    for row in cur.fetchall():
        d = row['read_date']
        if d not in reads:
            reads[d] = {}
        reads[d][row['hour_of_day']] = {
            'avg_kw': float(row['avg_kw']),
            'has_gaps': row['has_gaps'],
            'interval_count': row['interval_count'],
        }

    cur.close()
    return reads


def save_baseline_results(conn, results):
    """Save computed baseline results to the database."""
    cur = conn.cursor()

    sql = """
        INSERT INTO baseline_results
            (event_id, site_id, meter_id, methodology_id, methodology_version,
             hour_start, baseline_kw, adjustment_kw, adjusted_baseline_kw,
             actual_kw, reduction_kw, shutdown_variant,
             similar_days_used, similar_days_discarded, days_discarded_count,
             computation_notes)
        VALUES %s
        ON CONFLICT (event_id, meter_id, methodology_id, hour_start, shutdown_variant)
        DO UPDATE SET
            baseline_kw = EXCLUDED.baseline_kw,
            adjustment_kw = EXCLUDED.adjustment_kw,
            adjusted_baseline_kw = EXCLUDED.adjusted_baseline_kw,
            actual_kw = EXCLUDED.actual_kw,
            reduction_kw = EXCLUDED.reduction_kw,
            similar_days_used = EXCLUDED.similar_days_used,
            similar_days_discarded = EXCLUDED.similar_days_discarded,
            days_discarded_count = EXCLUDED.days_discarded_count,
            computation_notes = EXCLUDED.computation_notes,
            computed_at = NOW()
    """

    rows = []
    for r in results:
        rows.append((
            r['event_id'], r['site_id'], r['meter_id'],
            r['methodology_id'], r['methodology_version'],
            r['hour_start'],
            r['baseline_kw'], r['adjustment_kw'], r['adjusted_baseline_kw'],
            r['actual_kw'], r['reduction_kw'], r['shutdown_variant'],
            json.dumps(r['similar_days_used']),
            json.dumps(r['similar_days_discarded']),
            r['days_discarded_count'],
            r.get('computation_notes'),
        ))

    template = """(%s::uuid, %s::uuid, %s::uuid, %s::uuid, %s,
                   %s::timestamptz, %s, %s, %s, %s, %s, %s,
                   %s::jsonb, %s::jsonb, %s, %s)"""

    execute_values(cur, sql, rows, template=template, page_size=100)
    conn.commit()
    cur.close()
    print(f"  Saved {len(rows)} baseline result rows")


# ============================================================
# Similar day selection
# ============================================================

def select_similar_days(event_date, method, holidays, event_dates, shutdown_dates=None):
    """
    Select similar days per the methodology's rules.

    Returns:
        tuple: (selected_days, discarded_days)
            selected_days: list of dates
            discarded_days: list of {'date': date, 'reason': str}
    """
    dow = event_date.weekday()  # 0=Monday, 6=Sunday
    is_holiday = event_date in holidays

    # Determine day type and parameters
    if is_holiday or dow == 6:  # Sunday or holiday
        target_count = method['weekend_similar_count']
        max_lookback = method['max_lookback_weekend']
        day_filter = lambda d: d.weekday() == 6 or d in holidays  # Sundays + holidays
    elif dow == 5:  # Saturday
        target_count = method['weekend_similar_count']
        max_lookback = method['max_lookback_weekend']
        day_filter = lambda d: d.weekday() == 5  # Saturdays only
    else:  # Weekday
        target_count = method['weekday_similar_count']
        max_lookback = method['max_lookback_weekday']
        day_filter = lambda d: d.weekday() < 5  # Mon-Fri

    selected = []
    discarded = []
    candidates_checked = 0
    current_date = event_date - timedelta(days=1)

    while len(selected) < target_count and candidates_checked < max_lookback:
        # Check if this date matches the day type
        if day_filter(current_date):
            candidates_checked += 1

            # Check exclusions
            if method['exclude_holidays'] and current_date in holidays and not is_holiday:
                discarded.append({'date': str(current_date), 'reason': 'holiday'})
            elif method['exclude_event_days'] and current_date in event_dates:
                discarded.append({'date': str(current_date), 'reason': 'event_day'})
            else:
                selected.append(current_date)

        current_date -= timedelta(days=1)

        # Safety: don't look back more than 365 days
        if (event_date - current_date).days > 365:
            break

    return selected, discarded


# ============================================================
# Baseline computation
# ============================================================

def compute_baseline_for_meter(conn, event, method, meter_id, site_id, channel='del',
                                shutdown_dates=None, dry_run=False):
    """
    Compute the baseline for a single meter for a given event.

    Returns list of result dicts ready for save_baseline_results.
    """
    event_date = event['event_date']
    start_hour = event['start_time'].hour
    end_hour = event['end_time'].hour
    event_hours = list(range(start_hour, end_hour))

    # Determine channel based on methodology metering type
    if method['metering_type'] == 'net':
        # TODO: implement net metering (del - rec)
        pass

    # Compute lookback range for fetching holidays and event dates
    lookback_start = event_date - timedelta(days=365)
    holidays = fetch_holidays(conn, lookback_start, event_date)
    event_dates = fetch_event_dates(conn, lookback_start, event_date)
    site_shutdowns = fetch_shutdown_dates(conn, site_id, lookback_start, event_date) if shutdown_dates is None else shutdown_dates

    # Select similar days
    similar_days, discarded = select_similar_days(event_date, method, holidays, event_dates)

    if len(similar_days) < method['min_similar_days']:
        print(f"    WARNING: Only {len(similar_days)} similar days found (min: {method['min_similar_days']})")
        if len(similar_days) == 0:
            return []

    # Fetch hourly reads for similar days and event day
    all_dates = similar_days + [event_date]
    hourly_data = fetch_hourly_reads(conn, meter_id, channel, all_dates)

    # Check for missing data in similar days during event/adjustment hours
    adj_pre_hours = int(method['adjustment_pre_event_hours'])
    adj_duration = int(method['adjustment_duration_hours'])
    adj_start_hour = start_hour - adj_pre_hours
    adj_end_hour = adj_start_hour + adj_duration
    adj_hours = list(range(adj_start_hour, adj_end_hour))
    required_hours = set(event_hours + adj_hours)

    valid_similar_days = []
    missing_data_discarded = []
    for d in similar_days:
        if d not in hourly_data:
            missing_data_discarded.append({'date': str(d), 'reason': 'no_data'})
            continue
        day_hours = set(hourly_data[d].keys())
        missing = required_hours - day_hours
        if missing:
            missing_data_discarded.append({'date': str(d), 'reason': f'missing_hours_{sorted(missing)}'})
            continue
        # Check for gaps in the required hours
        has_gap = any(hourly_data[d][h]['has_gaps'] for h in required_hours if h in hourly_data[d])
        if has_gap:
            missing_data_discarded.append({'date': str(d), 'reason': 'has_gaps_in_required_hours'})
            continue
        valid_similar_days.append(d)

    all_discarded = discarded + missing_data_discarded

    if len(valid_similar_days) < method['min_similar_days']:
        print(f"    WARNING: Only {len(valid_similar_days)} valid similar days after data check")
        if len(valid_similar_days) == 0:
            return []

    # Determine shutdown handling variants
    variants = []
    if method['shutdown_handling'] == 'both':
        variants = ['per_spec', 'shutdown_excluded']
    elif method['shutdown_handling'] == 'exclude':
        variants = ['shutdown_excluded']
    else:
        variants = ['per_spec']

    all_results = []

    for variant in variants:
        # Filter similar days based on variant
        if variant == 'shutdown_excluded':
            working_days = [d for d in valid_similar_days if d not in site_shutdowns]
            variant_discarded = all_discarded + [
                {'date': str(d), 'reason': 'shutdown'} for d in valid_similar_days if d in site_shutdowns
            ]
        else:
            working_days = valid_similar_days
            variant_discarded = all_discarded

        if len(working_days) == 0:
            print(f"    WARNING: No valid similar days for variant '{variant}'")
            continue

        # Compute baseline for each event hour
        for hour in event_hours:
            # Aggregate similar day values for this hour
            values = []
            for d in working_days:
                if d in hourly_data and hour in hourly_data[d]:
                    values.append(hourly_data[d][hour]['avg_kw'])

            if not values:
                continue

            # Apply aggregation method
            if method['aggregation_method'] == 'mean':
                baseline_kw = sum(values) / len(values)
            elif method['aggregation_method'] == 'median':
                sorted_vals = sorted(values)
                mid = len(sorted_vals) // 2
                baseline_kw = (sorted_vals[mid] + sorted_vals[~mid]) / 2
            elif method['aggregation_method'] == 'high_x_of_y':
                x = method['aggregation_param'] or len(values)
                sorted_vals = sorted(values, reverse=True)[:x]
                baseline_kw = sum(sorted_vals) / len(sorted_vals)
            else:
                baseline_kw = sum(values) / len(values)

            # Compute adjustment
            adjustment_kw = 0.0
            if method['adjustment_type'] != 'none':
                # Similar day average for adjustment window
                adj_values = []
                for d in working_days:
                    if d in hourly_data:
                        for ah in adj_hours:
                            if ah in hourly_data[d]:
                                adj_values.append(hourly_data[d][ah]['avg_kw'])

                similar_adj_avg = sum(adj_values) / len(adj_values) if adj_values else 0

                # Event day values for adjustment window
                event_adj_values = []
                event_day_data = hourly_data.get(event_date, {})
                for ah in adj_hours:
                    if ah in event_day_data:
                        event_adj_values.append(event_day_data[ah]['avg_kw'])

                if event_adj_values:
                    event_adj_avg = sum(event_adj_values) / len(event_adj_values)
                else:
                    # Missing event day adjustment data: set to similar day avg (zero adjustment)
                    event_adj_avg = similar_adj_avg

                raw_adjustment = event_adj_avg - similar_adj_avg

                if method['adjustment_type'] == 'positive_only_additive':
                    adjustment_kw = max(0, raw_adjustment)
                elif method['adjustment_type'] == 'symmetric_additive':
                    adjustment_kw = raw_adjustment
                elif method['adjustment_type'] == 'multiplicative':
                    if similar_adj_avg > 0:
                        ratio = event_adj_avg / similar_adj_avg
                        adjustment_kw = baseline_kw * (ratio - 1)
                    else:
                        adjustment_kw = 0

            adjusted_baseline_kw = baseline_kw + adjustment_kw

            # Get actual event day value
            actual_kw = None
            if event_date in hourly_data and hour in hourly_data[event_date]:
                actual_kw = hourly_data[event_date][hour]['avg_kw']

            reduction_kw = None
            if actual_kw is not None:
                reduction_kw = adjusted_baseline_kw - actual_kw

            # Build hour_start timestamp in UTC
            event_dt = datetime.combine(event_date, time(hour=hour))
            # This is Central Time, convert conceptually — store as timestamptz
            hour_start_str = f"{event_date.isoformat()} {hour:02d}:00:00 America/Chicago"

            result = {
                'event_id': str(event['id']),
                'site_id': site_id,
                'meter_id': meter_id,
                'methodology_id': str(method['id']),
                'methodology_version': method['version'],
                'hour_start': hour_start_str,
                'baseline_kw': round(baseline_kw, 5),
                'adjustment_kw': round(adjustment_kw, 5),
                'adjusted_baseline_kw': round(adjusted_baseline_kw, 5),
                'actual_kw': round(actual_kw, 5) if actual_kw is not None else None,
                'reduction_kw': round(reduction_kw, 5) if reduction_kw is not None else None,
                'shutdown_variant': variant,
                'similar_days_used': [str(d) for d in working_days],
                'similar_days_discarded': variant_discarded,
                'days_discarded_count': len(variant_discarded),
                'computation_notes': f"Computed with {len(working_days)} similar days",
            }

            all_results.append(result)

    if dry_run:
        print(f"    Similar days selected: {[str(d) for d in valid_similar_days]}")
        print(f"    Days discarded: {len(all_discarded)}")
        for r in all_results[:3]:
            print(f"    Hour {r['hour_start']}: baseline={r['baseline_kw']:.2f} kW, "
                  f"adj={r['adjustment_kw']:.2f}, adjusted={r['adjusted_baseline_kw']:.2f}, "
                  f"actual={r['actual_kw']}, reduction={r['reduction_kw']}")
        if len(all_results) > 3:
            print(f"    ... and {len(all_results) - 3} more hours")

    return all_results


# ============================================================
# Main orchestration
# ============================================================

def compute_event_baselines(conn, event_id, methodology_name=None, methodology_id=None,
                             dry_run=False):
    """Compute baselines for all meters in an event."""
    print(f"[compute] Fetching event {event_id}...", flush=True)
    event = fetch_event(conn, event_id)
    if not event:
        print(f"ERROR: Event {event_id} not found", flush=True)
        return []

    print(f"[compute] Event found: {event['event_name']} on {event['event_date']}", flush=True)
    print(f"[compute] Fetching methodology...", flush=True)
    method = fetch_methodology(conn, name=methodology_name, methodology_id=methodology_id)
    if not method:
        print(f"ERROR: No active methodology found", flush=True)
        return []

    print(f"[compute] Methodology: {method['name']} v{method['version']}", flush=True)
    print(f"[compute] Fetching participating sites...", flush=True)
    sites = fetch_event_sites(conn, event_id)
    if not sites:
        print(f"WARNING: No participating sites found for event {event_id}", flush=True)
        return []

    print(f"\n{'='*60}", flush=True)
    print(f"BASELINE COMPUTATION", flush=True)
    print(f"{'='*60}", flush=True)
    print(f"Event:       {event['event_name'] or event['event_date']}", flush=True)
    print(f"Date:        {event['event_date']}", flush=True)
    print(f"Window:      {event['start_time']} - {event['end_time']} CT", flush=True)
    print(f"Methodology: {method['name']} v{method['version']}", flush=True)
    print(f"Sites:       {len(sites)}", flush=True)
    print(f"{'='*60}", flush=True)

    all_results = []
    for site in sites:
        print(f"\n  Site: {site['site_name']} ({site['meter_number']})")
        results = compute_baseline_for_meter(
            conn, event, method,
            meter_id=site['meter_id'],
            site_id=site['site_id'],
            channel='del',
            dry_run=dry_run
        )
        all_results.extend(results)

    if not dry_run and all_results:
        print(f"\n  Saving {len(all_results)} results...")
        save_baseline_results(conn, all_results)

    # Summary
    if all_results:
        total_reduction = sum(r['reduction_kw'] for r in all_results
                             if r['reduction_kw'] is not None and r['shutdown_variant'] == 'per_spec')
        event_hours = len(set(r['hour_start'] for r in all_results if r['shutdown_variant'] == 'per_spec'))
        meter_count = len(set(r['meter_id'] for r in all_results))

        print(f"\n{'='*60}")
        print(f"RESULTS SUMMARY")
        print(f"{'='*60}")
        print(f"Meters computed:     {meter_count}")
        print(f"Event hours:         {event_hours}")
        print(f"Total result rows:   {len(all_results)}")
        if total_reduction:
            print(f"Total reduction:     {total_reduction:.2f} kW (per-spec variant)")
        print(f"{'='*60}")

    return all_results


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='Compute DR baselines')
    parser.add_argument('--event-id', help='Event UUID to compute baselines for')
    parser.add_argument('--all-events', action='store_true', help='Compute for all events')
    parser.add_argument('--methodology', help='Methodology name (default: first active)')
    parser.add_argument('--methodology-id', help='Methodology UUID')
    parser.add_argument('--db-url', help='PostgreSQL connection string')
    parser.add_argument('--dry-run', action='store_true', help='Show computations without saving')

    args = parser.parse_args()
    print(f"[baseline_engine] Starting...", flush=True)

    if not args.event_id and not args.all_events:
        print("ERROR: Specify --event-id or --all-events", flush=True)
        sys.exit(1)

    db_url = args.db_url or os.getenv('DATABASE_URL')
    print(f"[baseline_engine] Connecting to database...", flush=True)

    try:
        conn = get_db_connection(db_url)
        print(f"[baseline_engine] Connected.", flush=True)
    except Exception as e:
        print(f"[baseline_engine] Connection failed: {e}", flush=True)
        sys.exit(1)

    try:
        if args.all_events:
            events = fetch_all_events(conn)
            print(f"[baseline_engine] Found {len(events)} events", flush=True)
            for event in events:
                compute_event_baselines(conn, str(event['id']),
                                         methodology_name=args.methodology,
                                         methodology_id=args.methodology_id,
                                         dry_run=args.dry_run)
        else:
            print(f"[baseline_engine] Computing for event: {args.event_id}", flush=True)
            compute_event_baselines(conn, args.event_id,
                                     methodology_name=args.methodology,
                                     methodology_id=args.methodology_id,
                                     dry_run=args.dry_run)
    except Exception as e:
        print(f"[baseline_engine] ERROR: {e}", flush=True)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()
        print(f"[baseline_engine] Done.", flush=True)


if __name__ == '__main__':
    main()
