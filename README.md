# DR Data Platform

A standalone data management and viewing platform for demand response programs. Ingests AMI interval meter data, computes configurable baselines (10-of-10, high-X-of-Y, etc.), and provides customer-facing data viewing and export.

## Architecture

- **Database:** Supabase (PostgreSQL) with Row-Level Security for multi-tenant customer access
- **Ingest pipeline:** Python scripts for AMI CSV processing (raw → curated → hourly rollups)
- **Baseline engine:** Pluggable, configuration-driven methodology framework
- **Frontend:** Next.js + Supabase JS SDK *(coming soon)*

## Quick Start

### Prerequisites

- Python 3.10+
- A Supabase project ([create one here](https://supabase.com/dashboard))

### 1. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 2. Set up the database

Run the schema and seed files in order in the **Supabase SQL Editor** (Dashboard → SQL Editor → New Query):

```
1. sql/01_schema.sql          — tables, indexes, constraints, RLS policies
2. sql/02_seed_holidays.sql   — federal holidays 2024-2028
3. sql/03_seed_methodology.sql — Concerto 10-of-10 baseline config
4. sql/04_seed_reference.sql  — customers, sites, meters from meter map
```

### 3. Configure your environment

```bash
cp .env.example .env
# Edit .env with your Supabase connection details
```

### 4. Ingest meter data

```bash
# Dry run (validate only, no DB writes)
python scripts/ingest_ami.py --file /path/to/DECRYPTED_DRPilot_AMIReads_20260701.csv --dry-run

# Live ingest
python scripts/ingest_ami.py --file /path/to/file.csv

# Batch ingest from zip
python scripts/ingest_ami.py --zip /path/to/meterdata.zip

# Batch ingest from directory
python scripts/ingest_ami.py --dir /path/to/csv_folder/
```

### 5. Regenerate reference data from meter map

If the meter map Excel is updated:

```bash
python scripts/seed_meter_map.py /path/to/ENO_MeterMap.xlsx > sql/04_seed_reference.sql
```

Then run the output SQL in the Supabase SQL Editor.

## Project Structure

```
dr-platform/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── scripts/
│   ├── ingest_ami.py          # AMI CSV ingest pipeline
│   ├── seed_meter_map.py      # Generate reference data SQL from meter map
│   └── config.py              # Shared configuration and DB connection
├── sql/
│   ├── 01_schema.sql          # Full database schema
│   ├── 02_seed_holidays.sql   # Federal holidays
│   ├── 03_seed_methodology.sql # Baseline methodology configs
│   └── 04_seed_reference.sql  # Customers, sites, meters (generated)
├── docs/
│   ├── architecture.md        # Architecture and design decisions
│   └── decisions.md           # Decision log from discovery
└── tests/
    └── test_ingest.py         # Ingest pipeline tests
```

## Key Design Decisions

| Decision | Choice |
|---|---|
| Stable site identifier | `DeviceLocation` (not `PremiseId`) |
| Interval convention | End-of-interval (timestamp = end of 5-min window) |
| Hourly rollup | Hour 14:00 = intervals ending 14:05 through 15:00 |
| Time storage | UTC internally, display in America/Chicago |
| Units | Store kWh raw, compute kW (× 12 for 5-min), baselines in kW |
| Net vs gross | Per-methodology config |
| Restatements | Always accepted via UPSERT (latest ModifiedTimestamp wins) |
| Outlier detection | Flag but don't reject (3× rolling avg threshold) |
| Shutdown days | Dual baseline: per-spec (included) and shutdown-excluded |

## Meter Types

| Type | Prefix | Data Source |
|---|---|---|
| AMI | `AM` | Nightly SFTP from Entergy |
| Pulse/KYZ | `EM`, numeric | Backfill request from Entergy |
| Non-AMI | `EM` (tagged) | Backfill request with Recorder ID |

## License

Proprietary — internal use only.
