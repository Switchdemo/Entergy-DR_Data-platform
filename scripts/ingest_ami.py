"""
ingest_ami.py
-------------
Ingests AMI interval CSV files (DECRYPTED_DRPilot_AMIReads_YYYYMMDD.csv)
through the full pipeline:

    1. Validate file structure
    2. Log to raw_file_loads
    3. Bulk insert to raw_interval_reads (with de-dup via row hash)
    4. UPSERT to curated_intervals (restatement-aware, with kW conversion)
    5. Flag outliers
    6. Recompute hourly_reads for affected hours

Runs via GitHub Actions, locally, or as a scheduled function.

Usage:
    # Single file
    python scripts/ingest_ami.py --file /path/to/file.csv --db-url postgresql://...

    # Zip archive
    python scripts/ingest_ami.py --zip /path/to/meterdata.zip --db-url postgresql://...

    # Directory of files
    python scripts/ingest_ami.py --dir /path/to/csvs/ --db-url postgresql://...

    # Dry run (validate only, no DB writes)
    python scripts/ingest_ami.py --file /path/to/file.csv --dry-run

    # Use DATABASE_URL env var instead of --db-url
    DATABASE_URL=postgresql://... python scripts/ingest_ami.py --file /path/to/file.csv
"""

import argparse
import hashlib
import io
import os
import re
import sys
import tempfile
import zipfile
from datetime import datetime, date, timedelta

import pandas as pd
import numpy as np

# ============================================================
# Configuration
# ============================================================

EXPECTED_COLUMNS = [
    'PremiseId', 'DeviceLocation', 'MeterNumber', 'ChannelName',
    'ReadingValue', 'IntervalTimestamp', 'IntervalStatus',
    'ReadingErrorFlag', 'ModifiedTimestamp', 'RemoteId'
]

TIMEZONE = 'America/Chicago'
INTERVAL_MINUTES = 5
KWH_TO_KW_FACTOR = 60 / INTERVAL_MINUTES  # 12

OUTLIER_MULTIPLIER = 3.0

CHANNEL_MAP = {
    'KWH Del': 'del',
    'KWH Rec': 'rec',
}


# ============================================================
# Database helpers
# ============================================================

def get_db_connection(db_url=None):
    """Get a psycopg2 connection from explicit URL or env var."""
    import psycopg2
    url = db_url or os.getenv('DATABASE_URL')
    if not url:
        print("ERROR: No database URL. Use --db-url or set DATABASE_URL env var.")
        sys.exit(1)
    return psycopg2.connect(url)


def fetch_known_meters(conn):
    """Fetch meter_number → meter_id mapping from the database."""
    cur = conn.cursor()
    cur.execute("SELECT meter_number, id::text FROM meters WHERE is_active = TRUE")
    result = {row[0]: row[1] for row in cur.fetchall()}
    cur.close()
    print(f"  Loaded {len(result)} known meters from database")
    return result


def insert_file_load(conn, filename, file_date, row_count, dup_count, status='processing'):
    """Insert a record into raw_file_loads and return its UUID."""
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO raw_file_loads (filename, file_date, file_format, row_count, duplicate_count, status, loaded_by)
        VALUES (%s, %s, 'ami_sftp', %s, %s, %s, 'github_actions')
        RETURNING id::text
    """, (filename, file_date, row_count, dup_count, status))
    file_load_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    return file_load_id


def update_file_load_status(conn, file_load_id, status, error_message=None, new_meter_count=0):
    """Update the status of a raw_file_loads record."""
    cur = conn.cursor()
    cur.execute("""
        UPDATE raw_file_loads
        SET status = %s, error_message = %s, new_meter_count = %s
        WHERE id = %s::uuid
    """, (status, error_message, new_meter_count, file_load_id))
    conn.commit()
    cur.close()


def bulk_insert_raw_reads(conn, df, file_load_id):
    """Bulk insert de-duped raw rows into raw_interval_reads using COPY."""
    cur = conn.cursor()

    # Build the CSV buffer
    buf = io.StringIO()
    for _, row in df.iterrows():
        values = [
            file_load_id,
            row.get('PremiseId', ''),
            row.get('DeviceLocation', ''),
            row.get('MeterNumber', ''),
            row.get('ChannelName', ''),
            str(row.get('ReadingValue', '')),
            str(row.get('IntervalTimestamp', '')),
            row.get('IntervalStatus', ''),
            str(row.get('ReadingErrorFlag', '')) if pd.notna(row.get('ReadingErrorFlag')) else '',
            str(row.get('ModifiedTimestamp', '')) if pd.notna(row.get('ModifiedTimestamp')) else '',
            str(row.get('RemoteId', '')) if pd.notna(row.get('RemoteId')) else '',
            row.get('row_hash', ''),
        ]
        buf.write('\t'.join(values) + '\n')

    buf.seek(0)
    cur.copy_from(buf, 'raw_interval_reads', sep='\t', null='',
                  columns=['file_load_id', 'premise_id_utility', 'device_location',
                           'meter_number', 'channel_name', 'reading_value',
                           'interval_timestamp', 'interval_status', 'reading_error_flag',
                           'modified_timestamp', 'remote_id', 'row_hash'])
    conn.commit()
    cur.close()
    print(f"  Inserted {len(df):,} rows into raw_interval_reads")


def upsert_curated_intervals(conn, df, file_load_id):
    """
    UPSERT curated intervals. Only updates if incoming source_modified_ts
    is later than existing (restatement handling).
    """
    from psycopg2.extras import execute_values

    cur = conn.cursor()

    # Prepare values
    rows = []
    for _, r in df.iterrows():
        modified_ts = r.get('source_modified_ts')
        if pd.isna(modified_ts):
            modified_ts = None

        rows.append((
            r['meter_id'],
            r['channel'],
            str(r['interval_end']),
            float(r['reading_kwh']),
            float(r['reading_kw']),
            r.get('interval_status'),
            r.get('reading_error_flag') if pd.notna(r.get('reading_error_flag')) else None,
            str(modified_ts) if modified_ts else None,
            file_load_id,
            bool(r.get('is_estimated', False)),
            bool(r.get('is_outlier', False)),
            r.get('outlier_reason') if r.get('is_outlier') else None,
        ))

    # Batch upsert
    sql = """
        INSERT INTO curated_intervals
            (meter_id, channel, interval_end, reading_kwh, reading_kw,
             interval_status, reading_error_flag, source_modified_ts,
             source_file_load_id, is_estimated, is_outlier, outlier_reason)
        VALUES %s
        ON CONFLICT (meter_id, channel, interval_end)
        DO UPDATE SET
            reading_kwh = EXCLUDED.reading_kwh,
            reading_kw = EXCLUDED.reading_kw,
            interval_status = EXCLUDED.interval_status,
            reading_error_flag = EXCLUDED.reading_error_flag,
            source_modified_ts = EXCLUDED.source_modified_ts,
            source_file_load_id = EXCLUDED.source_file_load_id,
            is_outlier = EXCLUDED.is_outlier,
            outlier_reason = EXCLUDED.outlier_reason,
            updated_at = NOW()
        WHERE curated_intervals.source_modified_ts IS NULL
           OR EXCLUDED.source_modified_ts IS NULL
           OR EXCLUDED.source_modified_ts >= curated_intervals.source_modified_ts
    """

    template = "(%s::uuid, %s, %s::timestamptz, %s, %s, %s, %s, %s::timestamptz, %s::uuid, %s, %s, %s)"

    # Process in chunks of 1000
    chunk_size = 1000
    total_upserted = 0
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        execute_values(cur, sql, chunk, template=template, page_size=chunk_size)
        total_upserted += len(chunk)

    conn.commit()
    cur.close()
    print(f"  Upserted {total_upserted:,} rows into curated_intervals")


def upsert_hourly_reads(conn, df):
    """UPSERT hourly rollups."""
    from psycopg2.extras import execute_values

    cur = conn.cursor()

    rows = []
    for _, r in df.iterrows():
        rows.append((
            r['meter_id'],
            r['channel'],
            str(r['hour_start']),
            float(r['kwh_total']),
            float(r['avg_kw']),
            int(r['interval_count']),
            bool(r['has_gaps']),
            bool(r.get('has_outliers', False)),
        ))

    sql = """
        INSERT INTO hourly_reads
            (meter_id, channel, hour_start, kwh_total, avg_kw,
             interval_count, has_gaps, has_outliers, computed_at)
        VALUES %s
        ON CONFLICT (meter_id, channel, hour_start)
        DO UPDATE SET
            kwh_total = EXCLUDED.kwh_total,
            avg_kw = EXCLUDED.avg_kw,
            interval_count = EXCLUDED.interval_count,
            has_gaps = EXCLUDED.has_gaps,
            has_outliers = EXCLUDED.has_outliers,
            computed_at = NOW()
    """

    template = "(%s::uuid, %s, %s::timestamptz, %s, %s, %s, %s, %s, NOW())"

    chunk_size = 1000
    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        execute_values(cur, sql, chunk, template=template, page_size=chunk_size)

    conn.commit()
    cur.close()
    print(f"  Upserted {len(rows):,} rows into hourly_reads")


# ============================================================
# File parsing and validation
# ============================================================

def parse_filename_date(filename):
    """Extract the date from filename pattern DECRYPTED_DRPilot_AMIReads_YYYYMMDD.csv"""
    match = re.search(r'(\d{8})', os.path.basename(filename))
    if match:
        return datetime.strptime(match.group(1), '%Y%m%d').date()
    return None


def validate_csv(filepath):
    """Validate CSV structure without loading all data."""
    try:
        df_sample = pd.read_csv(filepath, nrows=5)
        df_sample.columns = [c.strip() for c in df_sample.columns]
        missing = [c for c in EXPECTED_COLUMNS if c not in df_sample.columns]
        if missing:
            return False, f"Missing columns: {missing}"
        return True, "Valid"
    except Exception as e:
        return False, f"Parse error: {str(e)}"


def load_csv(filepath):
    """Load and clean a CSV file."""
    df = pd.read_csv(filepath, dtype={
        'PremiseId': str, 'DeviceLocation': str, 'MeterNumber': str,
        'ChannelName': str, 'ReadingValue': float, 'IntervalStatus': str,
        'ReadingErrorFlag': str, 'RemoteId': str,
    })

    df.columns = [c.strip() for c in df.columns]
    for col in ['PremiseId', 'DeviceLocation', 'MeterNumber', 'ChannelName',
                'IntervalStatus', 'ReadingErrorFlag', 'RemoteId']:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip()

    df['IntervalTimestamp'] = pd.to_datetime(df['IntervalTimestamp'], format='mixed')
    df['ModifiedTimestamp'] = pd.to_datetime(df['ModifiedTimestamp'], format='mixed', errors='coerce')

    # Row hash for de-dup
    hash_cols = ['PremiseId', 'DeviceLocation', 'MeterNumber', 'ChannelName',
                 'ReadingValue', 'IntervalTimestamp', 'IntervalStatus',
                 'ReadingErrorFlag', 'ModifiedTimestamp', 'RemoteId']
    df['row_hash'] = df[hash_cols].fillna('').astype(str).agg('|'.join, axis=1).apply(
        lambda x: hashlib.sha256(x.encode()).hexdigest()
    )

    return df


# ============================================================
# Pipeline stages
# ============================================================

def stage_raw_landing(df):
    """De-duplicate exact rows within the file."""
    original_count = len(df)
    df_deduped = df.drop_duplicates(subset=['row_hash'])
    dup_count = original_count - len(df_deduped)
    return df_deduped.copy(), dup_count


def stage_curate(df, known_meters):
    """Transform raw data into curated interval format."""
    df = df.copy()
    df['channel'] = df['ChannelName'].map(CHANNEL_MAP)
    df = df[df['channel'].notna()]

    df['meter_id'] = df['MeterNumber'].map(known_meters)
    unknown = df[df['meter_id'].isna()]['MeterNumber'].unique().tolist()
    df = df[df['meter_id'].notna()]

    # Convert to UTC from Central Time
    df['interval_end'] = (
        df['IntervalTimestamp']
        .dt.tz_localize(TIMEZONE, ambiguous='infer', nonexistent='shift_forward')
        .dt.tz_convert('UTC')
    )

    df['reading_kwh'] = df['ReadingValue']
    df['reading_kw'] = df['ReadingValue'] * KWH_TO_KW_FACTOR

    # Handle ModifiedTimestamp - convert to UTC
    if df['ModifiedTimestamp'].notna().any():
        mod_ts_notna = df.loc[df['ModifiedTimestamp'].notna(), 'ModifiedTimestamp']
        mod_ts_utc = (
            mod_ts_notna
            .dt.tz_localize(TIMEZONE, ambiguous='infer', nonexistent='shift_forward')
            .dt.tz_convert('UTC')
        )
        # Create a new series with NaT for missing values
        source_modified = pd.Series(pd.NaT, index=df.index, dtype='datetime64[us, UTC]')
        source_modified[mod_ts_utc.index] = mod_ts_utc
    else:
        source_modified = pd.Series(pd.NaT, index=df.index, dtype='datetime64[us, UTC]')

    curated = pd.DataFrame({
        'meter_id': df['meter_id'].values,
        'channel': df['channel'].values,
        'interval_end': df['interval_end'].values,
        'reading_kwh': df['reading_kwh'].values,
        'reading_kw': df['reading_kw'].values,
        'interval_status': df['IntervalStatus'].values,
        'reading_error_flag': df['ReadingErrorFlag'].replace('nan', None).values,
        'source_modified_ts': source_modified.values,
        'is_estimated': False,
    })

    return curated, unknown


def compute_hourly_rollups(curated_df):
    """
    Hour 14:00 = intervals ending 14:05 through 15:00.
    Subtract 1 second to bucket correctly.
    """
    df = curated_df.copy()
    df['hour_start'] = (df['interval_end'] - pd.Timedelta(seconds=1)).dt.floor('h')

    hourly = df.groupby(['meter_id', 'channel', 'hour_start']).agg(
        kwh_total=('reading_kwh', 'sum'),
        avg_kw=('reading_kwh', 'sum'),
        interval_count=('reading_kwh', 'count'),
        has_outliers=('is_outlier', 'any'),
    ).reset_index()

    hourly['has_gaps'] = hourly['interval_count'] < 12
    return hourly


def detect_outliers(curated_df):
    """Flag intervals where reading_kw exceeds OUTLIER_MULTIPLIER × batch avg."""
    df = curated_df.copy()
    df['hour_of_day'] = (df['interval_end'] - pd.Timedelta(seconds=1)).dt.hour

    batch_avg = df.groupby(['meter_id', 'channel', 'hour_of_day'])['reading_kw'].transform('mean')
    is_outlier = (batch_avg > 0) & (df['reading_kw'] > batch_avg * OUTLIER_MULTIPLIER)

    reason = pd.Series('', index=df.index)
    reason[is_outlier] = f'>{OUTLIER_MULTIPLIER}x batch avg for hour-of-day'

    return is_outlier, reason


# ============================================================
# Summary
# ============================================================

def generate_summary(filename, file_date, raw_count, deduped_count, dup_count,
                     curated_count, unknown_meters, outlier_count, hourly_count,
                     meter_count, df_deduped):
    lines = [
        f"{'='*60}",
        f"INGEST SUMMARY: {filename}",
        f"{'='*60}",
        f"File date:           {file_date}",
        f"Raw rows:            {raw_count:,}",
        f"Duplicates removed:  {dup_count:,}",
        f"Rows after de-dup:   {deduped_count:,}",
        f"Curated intervals:   {curated_count:,}",
        f"Outliers flagged:    {outlier_count:,}",
        f"Hourly rollups:      {hourly_count:,}",
        f"",
        f"Meters in file:      {meter_count}",
        f"Unknown meters:      {len(unknown_meters)}",
    ]
    if unknown_meters:
        lines.append(f"  → {unknown_meters}")

    if 'ChannelName' in df_deduped.columns:
        lines.append("")
        lines.append("Channel breakdown:")
        for ch, count in df_deduped['ChannelName'].value_counts().items():
            lines.append(f"  {ch}: {count:,}")

    if 'IntervalTimestamp' in df_deduped.columns:
        lines.append("")
        lines.append("Interval range:")
        lines.append(f"  Min: {df_deduped['IntervalTimestamp'].min()}")
        lines.append(f"  Max: {df_deduped['IntervalTimestamp'].max()}")

    lines.append(f"{'='*60}")
    return '\n'.join(lines)


# ============================================================
# Main pipeline
# ============================================================

def process_file(filepath, db_url=None, dry_run=False, known_meters=None, conn=None):
    """Process a single AMI CSV file through the full pipeline."""
    filename = os.path.basename(filepath)
    file_date = parse_filename_date(filepath)

    print(f"\nProcessing: {filename}")
    print(f"File date: {file_date}")

    # Validate
    is_valid, message = validate_csv(filepath)
    if not is_valid:
        print(f"  VALIDATION FAILED: {message}")
        return {'status': 'failed', 'error': message}

    # Load
    print(f"  Loading CSV...")
    df_raw = load_csv(filepath)

    # De-duplicate
    df_deduped, dup_count = stage_raw_landing(df_raw)
    print(f"  Rows: {len(df_raw):,} → {len(df_deduped):,} after de-dup ({dup_count:,} duplicates)")

    # Get DB connection and meter lookup for live runs
    own_conn = False
    if not dry_run and conn is None:
        conn = get_db_connection(db_url)
        own_conn = True

    if known_meters is None:
        if dry_run:
            unique_meters = df_deduped[['MeterNumber']].drop_duplicates()
            known_meters = {row['MeterNumber']: f"dry-run-{row['MeterNumber']}" for _, row in unique_meters.iterrows()}
        else:
            known_meters = fetch_known_meters(conn)

    # Log file load
    file_load_id = None
    if not dry_run:
        file_load_id = insert_file_load(conn, filename, file_date, len(df_raw), dup_count)
        print(f"  File load ID: {file_load_id}")

    try:
        # Insert raw reads
        if not dry_run:
            print(f"  Writing raw reads...")
            bulk_insert_raw_reads(conn, df_deduped, file_load_id)

        # Curate
        print(f"  Curating intervals...")
        df_curated, unknown_meters_list = stage_curate(df_deduped, known_meters)
        if unknown_meters_list:
            print(f"  WARNING: {len(unknown_meters_list)} unknown meters: {unknown_meters_list}")

        # Outlier detection
        print(f"  Detecting outliers...")
        is_outlier, outlier_reason = detect_outliers(df_curated)
        df_curated = df_curated.copy()
        df_curated['is_outlier'] = is_outlier
        df_curated['outlier_reason'] = outlier_reason
        outlier_count = int(is_outlier.sum())
        if outlier_count > 0:
            print(f"  Flagged {outlier_count:,} outliers")

        # UPSERT curated intervals
        if not dry_run:
            print(f"  Writing curated intervals...")
            upsert_curated_intervals(conn, df_curated, file_load_id)

        # Hourly rollups
        print(f"  Computing hourly rollups...")
        hourly_df = compute_hourly_rollups(df_curated)

        if not dry_run:
            print(f"  Writing hourly rollups...")
            upsert_hourly_reads(conn, hourly_df)

        # Update file load status
        if not dry_run:
            update_file_load_status(conn, file_load_id, 'success',
                                    new_meter_count=len(unknown_meters_list))

        # Summary
        summary = generate_summary(
            filename, file_date, len(df_raw), len(df_deduped), dup_count,
            len(df_curated), unknown_meters_list, outlier_count, len(hourly_df),
            df_deduped['MeterNumber'].nunique(), df_deduped
        )
        print(summary)

        if dry_run:
            print("\n  [DRY RUN — no database writes]")
        else:
            print("\n  [SUCCESS — all data written to database]")

        return {
            'status': 'success',
            'filename': filename,
            'file_date': str(file_date),
            'raw_rows': len(df_raw),
            'deduped_rows': len(df_deduped),
            'duplicate_count': dup_count,
            'curated_rows': len(df_curated),
            'unknown_meters': unknown_meters_list,
            'outlier_count': outlier_count,
            'hourly_rollups': len(hourly_df),
        }

    except Exception as e:
        if not dry_run and file_load_id:
            update_file_load_status(conn, file_load_id, 'failed', str(e))
        print(f"  ERROR: {str(e)}")
        raise
    finally:
        if own_conn and conn:
            conn.close()


def process_zip(zip_path, db_url=None, dry_run=False):
    """Process all CSV files in a zip archive."""
    conn = None
    known_meters = None

    if not dry_run:
        conn = get_db_connection(db_url)
        known_meters = fetch_known_meters(conn)

    results = []
    with tempfile.TemporaryDirectory() as tmpdir:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            csv_files = sorted([f for f in zf.namelist() if f.endswith('.csv')])
            print(f"Found {len(csv_files)} CSV files in archive")
            zf.extractall(tmpdir)

            for csv_file in csv_files:
                filepath = os.path.join(tmpdir, csv_file)
                result = process_file(filepath, db_url, dry_run, known_meters, conn)
                results.append(result)

    if conn:
        conn.close()

    return results


def process_directory(dir_path, db_url=None, dry_run=False):
    """Process all CSV files in a directory."""
    conn = None
    known_meters = None

    if not dry_run:
        conn = get_db_connection(db_url)
        known_meters = fetch_known_meters(conn)

    csv_files = sorted([
        os.path.join(dir_path, f) for f in os.listdir(dir_path) if f.endswith('.csv')
    ])
    print(f"Found {len(csv_files)} CSV files in directory")

    results = []
    for filepath in csv_files:
        result = process_file(filepath, db_url, dry_run, known_meters, conn)
        results.append(result)

    if conn:
        conn.close()

    return results


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='Ingest AMI interval data')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--file', help='Single CSV file to ingest')
    group.add_argument('--dir', help='Directory of CSV files to ingest')
    group.add_argument('--zip', help='Zip archive of CSV files to ingest')

    parser.add_argument('--db-url', help='PostgreSQL connection string (or set DATABASE_URL env var)')
    parser.add_argument('--dry-run', action='store_true', help='Validate and summarize without DB writes')

    args = parser.parse_args()

    if not args.dry_run and not args.db_url and not os.getenv('DATABASE_URL'):
        print("ERROR: --db-url or DATABASE_URL env var required unless --dry-run is set")
        sys.exit(1)

    db_url = args.db_url or os.getenv('DATABASE_URL')

    if args.file:
        results = [process_file(args.file, db_url, args.dry_run)]
    elif args.dir:
        results = process_directory(args.dir, db_url, args.dry_run)
    elif args.zip:
        results = process_zip(args.zip, db_url, args.dry_run)

    # Batch summary
    print(f"\n{'='*60}")
    print(f"BATCH SUMMARY")
    print(f"{'='*60}")
    total_raw = sum(r.get('raw_rows', 0) for r in results)
    total_curated = sum(r.get('curated_rows', 0) for r in results)
    total_dups = sum(r.get('duplicate_count', 0) for r in results)
    total_outliers = sum(r.get('outlier_count', 0) for r in results)
    failed = [r for r in results if r.get('status') == 'failed']

    print(f"Files processed:     {len(results)}")
    print(f"Files failed:        {len(failed)}")
    print(f"Total raw rows:      {total_raw:,}")
    print(f"Total duplicates:    {total_dups:,}")
    print(f"Total curated:       {total_curated:,}")
    print(f"Total outliers:      {total_outliers:,}")

    if failed:
        print(f"\nFailed files:")
        for r in failed:
            print(f"  {r.get('filename', 'unknown')}: {r.get('error', 'unknown error')}")

    print(f"{'='*60}")

    # Exit with error code if any files failed
    if failed:
        sys.exit(1)


if __name__ == '__main__':
    main()
