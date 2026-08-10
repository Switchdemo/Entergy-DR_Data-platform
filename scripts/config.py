"""
config.py
---------
Shared configuration and database connection for DR Platform scripts.
Reads from .env file or environment variables.
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Load .env from project root
env_path = Path(__file__).resolve().parent.parent / '.env'
load_dotenv(env_path)

# ============================================================
# Database configuration
# ============================================================

def get_db_url():
    """Build PostgreSQL connection string from env vars."""
    # Check for explicit DATABASE_URL first
    url = os.getenv('DATABASE_URL')
    if url:
        return url

    # Build from components
    host = os.getenv('SUPABASE_DB_HOST')
    port = os.getenv('SUPABASE_DB_PORT', '5432')
    name = os.getenv('SUPABASE_DB_NAME', 'postgres')
    user = os.getenv('SUPABASE_DB_USER', 'postgres')
    password = os.getenv('SUPABASE_DB_PASSWORD')

    if not host or not password:
        print("ERROR: Database credentials not configured.")
        print("Copy .env.example to .env and fill in your Supabase details.")
        sys.exit(1)

    return f"postgresql://{user}:{password}@{host}:{port}/{name}"


def get_db_connection():
    """Get a psycopg2 database connection."""
    import psycopg2
    return psycopg2.connect(get_db_url())


# ============================================================
# Platform constants
# ============================================================

TIMEZONE = 'America/Chicago'
INTERVAL_MINUTES = 5
KWH_TO_KW_FACTOR = 60 / INTERVAL_MINUTES  # 12

# Outlier detection
OUTLIER_MULTIPLIER = 3.0
OUTLIER_WINDOW_DAYS = 30

# Channel mapping from CSV to internal
CHANNEL_MAP = {
    'KWH Del': 'del',
    'KWH Rec': 'rec',
}

# Expected CSV columns
EXPECTED_COLUMNS = [
    'PremiseId', 'DeviceLocation', 'MeterNumber', 'ChannelName',
    'ReadingValue', 'IntervalTimestamp', 'IntervalStatus',
    'ReadingErrorFlag', 'ModifiedTimestamp', 'RemoteId'
]
