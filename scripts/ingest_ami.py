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

Designed to run locally or as a scheduled function.

Usage:
    # Single file
    python ingest_ami.py --file /path/to/DECRYPTED_DRPilot_AMIReads_20260701.csv --db-url postgresql://...

    # Directory of files
    python ingest_ami.py --dir /path/to/csvs/ --db-url postgresql://...

    # Zip archive
    python ingest_ami.py --zip /path/to/meterdata.zip --db-url postgresql://...

    # Dry run (validate only, no DB writes)
    python ingest_ami.py --file /path/to/file.csv --dry-run
"""

import argparse
import hashlib
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
KWH_TO_KW_FACTOR = 60 / INTERVAL_MINUTES  # 12 for 5-minute intervals

# Outlier detection: flag if reading exceeds this many times the
# meter's rolling average for the same hour-of-day
OUTLIER_MULTIPLIER = 3.0
OUTLIER_WINDOW_DAYS = 30

CHANNEL_MAP = {
    'KWH Del': 'del',
    'KWH Rec': 'rec',
}


# ============================================================
# File parsing and validation
# ============================================================

def parse_filename_date(filename):
    """Extract the date from the filename pattern DECRYPTED_DRPilot_AMIReads_YYYYMMDD.csv"""
    match = re.search(r'(\d{8})', os.path.basename(filename))
    if match:
        return datetime.strptime(match.group(1), '%Y%m%d').date()
    return None


def validate_csv(filepath):
    """Validate CSV structure without loading all data."""
    try:
        df_sample = pd.read_csv(filepath, nrows=5)
        # Strip whitespace from column names
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
        'PremiseId': str,
        'DeviceLocation': str,
        'MeterNumber': str,
        'ChannelName': str,
        'ReadingValue': float,
        'IntervalStatus': str,
        'ReadingErrorFlag': str,
        'RemoteId': str,
    })

    # Strip whitespace from column names and string values
    df.columns = [c.strip() for c in df.columns]
    for col in ['PremiseId', 'DeviceLocation', 'MeterNumber', 'ChannelName',
                'IntervalStatus', 'ReadingErrorFlag', 'RemoteId']:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip()

    # Parse timestamps
    df['IntervalTimestamp'] = pd.to_datetime(df['IntervalTimestamp'], format='mixed')
    df['ModifiedTimestamp'] = pd.to_datetime(df['ModifiedTimestamp'], format='mixed', errors='coerce')

    # Compute row hash for de-dup detection
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

def stage_raw_landing(df, file_load_id):
    """
    Stage 1: Prepare raw_interval_reads inserts.
    De-duplicates exact rows within the file (same row_hash).
    Returns: de-duped DataFrame, duplicate count
    """
    original_count = len(df)
    df_deduped = df.drop_duplicates(subset=['row_hash'])
    dup_count = original_count - len(df_deduped)

    # Add file_load_id
    df_deduped = df_deduped.copy()
    df_deduped['file_load_id'] = file_load_id

    return df_deduped, dup_count


def stage_curate(df, known_meters):
    """
    Stage 2: Transform raw data into curated interval format.
    - Maps channel names
    - Converts to kW
    - Resolves meter_id from known_meters lookup
    - Applies end-of-interval convention (timestamps stored as-is since
      they already represent end-of-interval)
    - Localizes timestamps to UTC via America/Chicago

    Returns: DataFrame ready for curated_intervals UPSERT, list of unknown meters
    """
    # Map channels
    df = df.copy()
    df['channel'] = df['ChannelName'].map(CHANNEL_MAP)
    df = df[df['channel'].notna()]  # skip unknown channels

    # Resolve meter_id
    df['meter_id'] = df['MeterNumber'].map(known_meters)
    unknown = df[df['meter_id'].isna()]['MeterNumber'].unique().tolist()
    df = df[df['meter_id'].notna()]

    # Convert timestamp to UTC
    # Timestamps are in Central Time (end-of-interval)
    df['interval_end'] = (
        df['IntervalTimestamp']
        .dt.tz_localize(TIMEZONE, ambiguous='infer', nonexistent='shift_forward')
        .dt.tz_convert('UTC')
    )

    # Compute kW from kWh
    df['reading_kwh'] = df['ReadingValue']
    df['reading_kw'] = df['ReadingValue'] * KWH_TO_KW_FACTOR

    # Build curated record
    curated = pd.DataFrame({
        'meter_id': df['meter_id'],
        'channel': df['channel'],
        'interval_end': df['interval_end'],
        'reading_kwh': df['reading_kwh'],
        'reading_kw': df['reading_kw'],
        'interval_status': df['IntervalStatus'],
        'reading_error_flag': df['ReadingErrorFlag'].replace('nan', None),
        'source_modified_ts': df['ModifiedTimestamp'].dt.tz_localize(
            TIMEZONE, ambiguous='infer', nonexistent='shift_forward'
        ).dt.tz_convert('UTC') if df['ModifiedTimestamp'].notna().any() else None,
    })

    return curated, unknown


def compute_hourly_rollups(curated_df):
    """
    Stage 3: Compute hourly rollups from curated intervals.
    Hour 14:00 = intervals ending at 14:05 through 15:00

    For end-of-interval convention:
      - interval ending at 14:05 belongs to the 14:00 hour
      - interval ending at 15:00 belongs to the 14:00 hour
      - interval ending at 00:05 belongs to the 00:00 hour

    The hour_start for an interval is: floor(interval_end - 5 minutes) to the hour
    """
    df = curated_df.copy()

    # Compute which hour each interval belongs to
    # Subtract 1 second from interval_end to get into the correct hour bucket
    # e.g., 15:00:00 - 1s = 14:59:59 → floor to 14:00
    # e.g., 14:05:00 - 1s = 14:04:59 → floor to 14:00
    df['hour_start'] = (df['interval_end'] - pd.Timedelta(seconds=1)).dt.floor('h')

    hourly = df.groupby(['meter_id', 'channel', 'hour_start']).agg(
        kwh_total=('reading_kwh', 'sum'),
        avg_kw=('reading_kwh', 'sum'),  # sum of 5-min kWh = avg kW for the hour
        interval_count=('reading_kwh', 'count'),
        has_outliers=('reading_kwh', lambda x: False),  # placeholder, updated after outlier detection
    ).reset_index()

    hourly['has_gaps'] = hourly['interval_count'] < 12

    return hourly


# ============================================================
# Outlier detection
# ============================================================

def detect_outliers(curated_df, historical_stats=None):
    """
    Flag intervals where reading_kw exceeds OUTLIER_MULTIPLIER times
    the meter's average for that hour-of-day.

    If historical_stats is None (first load), uses the current batch's
    statistics as a rough baseline.

    Returns: Series of boolean flags aligned with curated_df index,
             Series of reason strings
    """
    df = curated_df.copy()

    # Compute hour-of-day for each interval (in Central Time)
    df['hour_of_day'] = (df['interval_end'] - pd.Timedelta(seconds=1)).dt.tz_convert(TIMEZONE).dt.hour

    if historical_stats is not None:
        # Merge with historical averages
        df = df.merge(
            historical_stats,
            on=['meter_id', 'channel', 'hour_of_day'],
            how='left',
            suffixes=('', '_hist')
        )
        is_outlier = (
            df['avg_kw_hist'].notna() &
            (df['avg_kw_hist'] > 0) &
            (df['reading_kw'] > df['avg_kw_hist'] * OUTLIER_MULTIPLIER)
        )
    else:
        # Use batch statistics as rough baseline
        batch_avg = df.groupby(['meter_id', 'channel', 'hour_of_day'])['reading_kw'].transform('mean')
        is_outlier = (
            (batch_avg > 0) &
            (df['reading_kw'] > batch_avg * OUTLIER_MULTIPLIER)
        )

    reason = pd.Series('', index=df.index)
    reason[is_outlier] = f'>{OUTLIER_MULTIPLIER}x rolling avg for hour-of-day'

    return is_outlier, reason


# ============================================================
# Summary and reporting
# ============================================================

def generate_summary(filename, file_date, df_raw, df_deduped, dup_count,
                     df_curated, unknown_meters, outlier_count, hourly_df):
    """Generate a human-readable ingest summary."""
    lines = [
        f"{'='*60}",
        f"INGEST SUMMARY: {filename}",
        f"{'='*60}",
        f"File date:           {file_date}",
        f"Raw rows:            {len(df_raw):,}",
        f"Duplicates removed:  {dup_count:,}",
        f"Rows after de-dup:   {len(df_deduped):,}",
        f"Curated intervals:   {len(df_curated):,}",
        f"Outliers flagged:    {outlier_count:,}",
        f"Hourly rollups:      {len(hourly_df):,}",
        f"",
        f"Meters in file:      {df_deduped['MeterNumber'].nunique()}",
        f"Unknown meters:      {len(unknown_meters)}",
    ]

    if unknown_meters:
        lines.append(f"  → {unknown_meters}")

    # Channel breakdown
    if 'ChannelName' in df_deduped.columns:
        lines.append(f"")
        lines.append(f"Channel breakdown:")
        for ch, count in df_deduped['ChannelName'].value_counts().items():
            lines.append(f"  {ch}: {count:,}")

    # Date range
    if 'IntervalTimestamp' in df_deduped.columns:
        lines.append(f"")
        lines.append(f"Interval range:")
        lines.append(f"  Min: {df_deduped['IntervalTimestamp'].min()}")
        lines.append(f"  Max: {df_deduped['IntervalTimestamp'].max()}")

    lines.append(f"{'='*60}")
    return '\n'.join(lines)


# ============================================================
# Main pipeline
# ============================================================

def process_file(filepath, db_url=None, dry_run=False, known_meters=None):
    """
    Process a single AMI CSV file through the full pipeline.

    Args:
        filepath: Path to the CSV file
        db_url: PostgreSQL connection string (None for dry-run)
        dry_run: If True, validate and summarize without DB writes
        known_meters: Dict of meter_number → meter_id (UUID).
                      If None and not dry_run, fetched from DB.

    Returns:
        dict with summary statistics
    """
    filename = os.path.basename(filepath)
    file_date = parse_filename_date(filepath)

    print(f"\nProcessing: {filename}")
    print(f"File date: {file_date}")

    # Step 1: Validate
    is_valid, message = validate_csv(filepath)
    if not is_valid:
        print(f"  VALIDATION FAILED: {message}")
        return {'status': 'failed', 'error': message}

    # Step 2: Load
    print(f"  Loading CSV...")
    df_raw = load_csv(filepath)

    # Step 3: De-duplicate (raw landing)
    file_load_id = hashlib.md5(filename.encode()).hexdigest()[:8]  # placeholder for dry run
    df_deduped, dup_count = stage_raw_landing(df_raw, file_load_id)
    print(f"  Rows: {len(df_raw):,} → {len(df_deduped):,} after de-dup ({dup_count:,} duplicates)")

    # Step 4: Build known_meters lookup if not provided
    if known_meters is None:
        if dry_run:
            # In dry run, build a dummy lookup from the file itself
            # using DeviceLocation as the key (since that's our stable ID)
            unique_meters = df_deduped[['MeterNumber', 'DeviceLocation']].drop_duplicates()
            known_meters = {
                row['MeterNumber']: f"dry-run-{row['MeterNumber']}"
                for _, row in unique_meters.iterrows()
            }
        else:
            # TODO: Fetch from database
            print("  ERROR: known_meters not provided and DB fetch not yet implemented")
            return {'status': 'failed', 'error': 'No meter lookup available'}

    # Step 5: Curate
    print(f"  Curating intervals...")
    df_curated, unknown_meters = stage_curate(df_deduped, known_meters)
    if unknown_meters:
        print(f"  WARNING: {len(unknown_meters)} unknown meters: {unknown_meters}")

    # Step 6: Detect outliers
    print(f"  Detecting outliers...")
    is_outlier, outlier_reason = detect_outliers(df_curated)
    df_curated = df_curated.copy()
    df_curated['is_outlier'] = is_outlier
    df_curated['outlier_reason'] = outlier_reason
    outlier_count = is_outlier.sum()
    if outlier_count > 0:
        print(f"  Flagged {outlier_count:,} outliers")

    # Step 7: Compute hourly rollups
    print(f"  Computing hourly rollups...")
    hourly_df = compute_hourly_rollups(df_curated)

    # Step 8: Summary
    summary = generate_summary(
        filename, file_date, df_raw, df_deduped, dup_count,
        df_curated, unknown_meters, outlier_count, hourly_df
    )
    print(summary)

    if dry_run:
        print("\n  [DRY RUN — no database writes]")
    else:
        # TODO: Database write operations
        # - INSERT into raw_file_loads
        # - COPY into raw_interval_reads
        # - UPSERT into curated_intervals
        # - UPSERT into hourly_reads
        print("\n  [DB write not yet implemented — run with --dry-run for now]")

    return {
        'status': 'success',
        'filename': filename,
        'file_date': str(file_date),
        'raw_rows': len(df_raw),
        'deduped_rows': len(df_deduped),
        'duplicate_count': dup_count,
        'curated_rows': len(df_curated),
        'unknown_meters': unknown_meters,
        'outlier_count': int(outlier_count),
        'hourly_rollups': len(hourly_df),
    }


def process_zip(zip_path, db_url=None, dry_run=False, known_meters=None):
    """Process all CSV files in a zip archive."""
    results = []
    with tempfile.TemporaryDirectory() as tmpdir:
        with zipfile.ZipFile(zip_path, 'r') as zf:
            csv_files = sorted([f for f in zf.namelist() if f.endswith('.csv')])
            print(f"Found {len(csv_files)} CSV files in archive")

            zf.extractall(tmpdir)

            for csv_file in csv_files:
                filepath = os.path.join(tmpdir, csv_file)
                result = process_file(filepath, db_url, dry_run, known_meters)
                results.append(result)

    return results


def process_directory(dir_path, db_url=None, dry_run=False, known_meters=None):
    """Process all CSV files in a directory."""
    csv_files = sorted([
        os.path.join(dir_path, f)
        for f in os.listdir(dir_path)
        if f.endswith('.csv')
    ])
    print(f"Found {len(csv_files)} CSV files in directory")

    results = []
    for filepath in csv_files:
        result = process_file(filepath, db_url, dry_run, known_meters)
        results.append(result)

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

    parser.add_argument('--db-url', help='PostgreSQL connection string')
    parser.add_argument('--dry-run', action='store_true',
                        help='Validate and summarize without DB writes')

    args = parser.parse_args()

    if not args.dry_run and not args.db_url:
        print("ERROR: --db-url required unless --dry-run is set")
        sys.exit(1)

    if args.file:
        results = [process_file(args.file, args.db_url, args.dry_run)]
    elif args.dir:
        results = process_directory(args.dir, args.db_url, args.dry_run)
    elif args.zip:
        results = process_zip(args.zip, args.db_url, args.dry_run)

    # Final summary
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


if __name__ == '__main__':
    main()
