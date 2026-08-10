-- ============================================================
-- DR Data Platform — Supabase Schema DDL
-- All timestamps stored in UTC (timestamptz)
-- Display timezone: America/Chicago
-- Interval convention: end-of-interval
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. REFERENCE TABLES
-- ============================================================

-- Customers: top-level entity for multi-tenant access
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    short_name TEXT, -- slug for URLs, exports
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sites: keyed by DeviceLocation (the stable identifier)
-- Replaces the traditional "premises" concept since PremiseId is unreliable
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    device_location TEXT NOT NULL, -- stable key from utility (e.g., '1725811')
    name TEXT NOT NULL, -- friendly label (e.g., 'Cabrini site (1)')
    pelican_name TEXT, -- DRAS participant name (e.g., 'CabriniHighSchool')
    account_number TEXT, -- utility account number
    premise_id_utility TEXT, -- PremiseId from CSV — informational only, can change
    address TEXT,
    timezone TEXT NOT NULL DEFAULT 'America/Chicago',
    weather_station_id TEXT, -- NOAA station code, nullable until weather is wired up
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_sites_device_location UNIQUE (device_location)
);

CREATE INDEX idx_sites_customer ON sites(customer_id);

-- Meters: physical devices, 1:1 with a site at any point in time
-- but can move between sites over time (tracked in meter_assignments)
CREATE TABLE meters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meter_number TEXT NOT NULL, -- from CSV MeterNumber (e.g., 'AM12864382')
    meter_type TEXT NOT NULL DEFAULT 'ami', -- 'ami', 'pulse_kyz', 'non_ami'
    backfill_recorder_id TEXT, -- for non-AMI meters, the ID used to request data from Entergy
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_meters_meter_number UNIQUE (meter_number),
    CONSTRAINT chk_meter_type CHECK (meter_type IN ('ami', 'pulse_kyz', 'non_ami'))
);

-- Meter assignments: which meter is/was active at which site, and when
-- This is the history timeline that handles meter swaps, enrollments, and decommissions
CREATE TABLE meter_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meter_id UUID NOT NULL REFERENCES meters(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    start_date DATE NOT NULL, -- date this meter became active at this site
    end_date DATE, -- NULL means currently active
    enrollment_status TEXT NOT NULL DEFAULT 'active', -- 'active', 'pending_enrollment', 'not_receiving', 'decommissioned'
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_enrollment_status CHECK (
        enrollment_status IN ('active', 'pending_enrollment', 'not_receiving', 'decommissioned')
    ),
    CONSTRAINT chk_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_meter_assignments_meter ON meter_assignments(meter_id);
CREATE INDEX idx_meter_assignments_site ON meter_assignments(site_id);
CREATE INDEX idx_meter_assignments_active ON meter_assignments(site_id, start_date, end_date)
    WHERE end_date IS NULL;

-- ============================================================
-- 2. LAYER 1 — RAW LANDING (immutable audit trail)
-- ============================================================

-- Track each ingested file
CREATE TABLE raw_file_loads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    filename TEXT NOT NULL,
    file_date DATE, -- parsed from filename (YYYYMMDD)
    file_format TEXT NOT NULL DEFAULT 'ami_sftp', -- 'ami_sftp', 'entergy_backfill', 'manual'
    row_count INTEGER,
    duplicate_count INTEGER DEFAULT 0, -- exact dups skipped
    new_meter_count INTEGER DEFAULT 0, -- unrecognized meters found
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    loaded_by TEXT NOT NULL DEFAULT 'system',
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'success', 'partial', 'failed'
    error_message TEXT,
    CONSTRAINT chk_file_status CHECK (
        status IN ('pending', 'processing', 'success', 'partial', 'failed')
    )
);

-- Every row from every CSV, untouched
CREATE TABLE raw_interval_reads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_load_id UUID NOT NULL REFERENCES raw_file_loads(id),
    premise_id_utility TEXT,
    device_location TEXT,
    meter_number TEXT,
    channel_name TEXT, -- 'KWH Del', 'KWH Rec', etc.
    reading_value NUMERIC(12,5),
    interval_timestamp TIMESTAMP NOT NULL, -- raw, no timezone coercion
    interval_status TEXT,
    reading_error_flag TEXT,
    modified_timestamp TIMESTAMP,
    remote_id TEXT,
    row_hash TEXT NOT NULL -- SHA-256 of full row for de-dup detection
);

CREATE INDEX idx_raw_reads_file ON raw_interval_reads(file_load_id);
CREATE INDEX idx_raw_reads_meter_ts ON raw_interval_reads(meter_number, interval_timestamp);

-- ============================================================
-- 3. LAYER 2 — CURATED INTERVAL STORE (single source of truth)
-- ============================================================

CREATE TABLE curated_intervals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_id UUID NOT NULL REFERENCES meters(id),
    channel TEXT NOT NULL, -- 'del' or 'rec'
    interval_end TIMESTAMPTZ NOT NULL, -- end-of-interval convention, stored in UTC
    reading_kwh NUMERIC(12,5) NOT NULL,
    reading_kw NUMERIC(12,5) NOT NULL, -- kwh * 12 (for 5-min intervals)
    interval_status TEXT,
    reading_error_flag TEXT,
    source_modified_ts TIMESTAMPTZ, -- latest ModifiedTimestamp that produced this value
    source_file_load_id UUID REFERENCES raw_file_loads(id),
    is_estimated BOOLEAN NOT NULL DEFAULT FALSE,
    is_outlier BOOLEAN NOT NULL DEFAULT FALSE,
    outlier_reason TEXT, -- e.g., '3x rolling 30-day avg for hour-of-day'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_curated_interval UNIQUE (meter_id, channel, interval_end),
    CONSTRAINT chk_channel CHECK (channel IN ('del', 'rec'))
);

-- Primary access pattern: all intervals for a meter/channel in a date range
CREATE INDEX idx_curated_meter_channel_ts ON curated_intervals(meter_id, channel, interval_end);

-- For outlier review
CREATE INDEX idx_curated_outliers ON curated_intervals(is_outlier, interval_end)
    WHERE is_outlier = TRUE;

-- ============================================================
-- 4. LAYER 3 — HOURLY ROLLUPS (recomputable from curated)
-- ============================================================

CREATE TABLE hourly_reads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meter_id UUID NOT NULL REFERENCES meters(id),
    channel TEXT NOT NULL, -- 'del', 'rec', 'net'
    hour_start TIMESTAMPTZ NOT NULL, -- clock hour start (UTC)
    kwh_total NUMERIC(12,5) NOT NULL, -- sum of 5-min kWh in that hour
    avg_kw NUMERIC(12,5) NOT NULL, -- average demand in kW for the hour
    interval_count SMALLINT NOT NULL, -- expect 12; fewer = gaps
    has_gaps BOOLEAN NOT NULL DEFAULT FALSE, -- true if interval_count < 12
    has_outliers BOOLEAN NOT NULL DEFAULT FALSE, -- true if any contributing interval is flagged
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_hourly_read UNIQUE (meter_id, channel, hour_start),
    CONSTRAINT chk_hourly_channel CHECK (channel IN ('del', 'rec', 'net'))
);

CREATE INDEX idx_hourly_meter_channel_ts ON hourly_reads(meter_id, channel, hour_start);

-- ============================================================
-- 5. DR EVENT MANAGEMENT
-- ============================================================

-- Programs: group methodologies and events
CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL, -- e.g., 'ENO DR Pilot'
    utility TEXT NOT NULL DEFAULT 'Entergy New Orleans',
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DR Events
CREATE TABLE dr_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID REFERENCES programs(id),
    event_name TEXT,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL, -- local time (CT)
    end_time TIME NOT NULL, -- local time (CT)
    created_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dr_events_date ON dr_events(event_date);

-- Which sites participated in each event
CREATE TABLE dr_event_sites (
    event_id UUID NOT NULL REFERENCES dr_events(id) ON DELETE CASCADE,
    site_id UUID NOT NULL REFERENCES sites(id),
    opted_out BOOLEAN NOT NULL DEFAULT FALSE, -- track if site opted out
    notes TEXT,
    PRIMARY KEY (event_id, site_id)
);

-- Federal holidays (pre-populated)
CREATE TABLE federal_holidays (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    holiday_date DATE NOT NULL, -- actual calendar date
    observed_date DATE NOT NULL, -- observed date (Sat→Fri, Sun→Mon)
    name TEXT NOT NULL,
    year SMALLINT NOT NULL,
    CONSTRAINT uq_holiday UNIQUE (holiday_date, name)
);

CREATE INDEX idx_holidays_date ON federal_holidays(holiday_date);
CREATE INDEX idx_holidays_observed ON federal_holidays(observed_date);

-- Site shutdown days
CREATE TABLE site_shutdown_days (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    shutdown_date DATE NOT NULL,
    reason TEXT, -- e.g., 'planned maintenance', 'weather closure'
    flagged_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_site_shutdown UNIQUE (site_id, shutdown_date)
);

-- ============================================================
-- 6. BASELINE METHODOLOGY ENGINE
-- ============================================================

-- Pluggable methodology configuration
CREATE TABLE baseline_methodologies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL, -- e.g., 'Concerto 10 of 10'
    version TEXT NOT NULL DEFAULT '1.0',
    description TEXT,

    -- Similar day selection
    weekday_similar_count INTEGER NOT NULL DEFAULT 10,
    weekend_similar_count INTEGER NOT NULL DEFAULT 5,
    max_lookback_weekday INTEGER NOT NULL DEFAULT 20,
    max_lookback_weekend INTEGER NOT NULL DEFAULT 10,
    min_similar_days INTEGER NOT NULL DEFAULT 1,
    exclude_holidays BOOLEAN NOT NULL DEFAULT TRUE,
    exclude_event_days BOOLEAN NOT NULL DEFAULT TRUE,

    -- Aggregation
    aggregation_method TEXT NOT NULL DEFAULT 'mean', -- 'mean', 'median', 'high_x_of_y'
    aggregation_param INTEGER, -- e.g., x=4 for high-4-of-5

    -- Adjustment
    adjustment_type TEXT NOT NULL DEFAULT 'positive_only_additive',
        -- 'positive_only_additive', 'symmetric_additive', 'multiplicative', 'none'
    adjustment_pre_event_hours NUMERIC NOT NULL DEFAULT 2, -- hours before event start
    adjustment_duration_hours NUMERIC NOT NULL DEFAULT 1, -- length of adjustment window

    -- Metering
    metering_type TEXT NOT NULL DEFAULT 'gross', -- 'gross' (Del only), 'net' (Del - Rec)

    -- Shutdown handling
    shutdown_handling TEXT NOT NULL DEFAULT 'include', -- 'include', 'exclude', 'both'

    -- Weather (future)
    use_weather BOOLEAN NOT NULL DEFAULT FALSE,
    weather_variable TEXT, -- 'temperature', 'heat_index', etc.

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_methodology_version UNIQUE (name, version),
    CONSTRAINT chk_aggregation CHECK (
        aggregation_method IN ('mean', 'median', 'high_x_of_y')
    ),
    CONSTRAINT chk_adjustment CHECK (
        adjustment_type IN ('positive_only_additive', 'symmetric_additive', 'multiplicative', 'none')
    ),
    CONSTRAINT chk_metering CHECK (metering_type IN ('gross', 'net')),
    CONSTRAINT chk_shutdown CHECK (shutdown_handling IN ('include', 'exclude', 'both'))
);

-- Baseline computation results — version-stamped, auditable
CREATE TABLE baseline_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES dr_events(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    meter_id UUID NOT NULL REFERENCES meters(id),
    methodology_id UUID NOT NULL REFERENCES baseline_methodologies(id),
    methodology_version TEXT NOT NULL, -- snapshot at computation time

    -- Per-hour results (one row per event hour per meter)
    hour_start TIMESTAMPTZ NOT NULL,
    baseline_kw NUMERIC(12,5), -- unadjusted baseline
    adjustment_kw NUMERIC(12,5) DEFAULT 0, -- the adjustment value
    adjusted_baseline_kw NUMERIC(12,5), -- baseline + adjustment (final)
    actual_kw NUMERIC(12,5), -- what the meter actually read
    reduction_kw NUMERIC(12,5), -- adjusted_baseline - actual

    -- Shutdown variant tracking
    shutdown_variant TEXT NOT NULL DEFAULT 'per_spec', -- 'per_spec' or 'shutdown_excluded'

    -- Audit trail
    similar_days_used JSONB, -- array of dates used
    similar_days_discarded JSONB, -- array of {date, reason}
    days_discarded_count INTEGER DEFAULT 0,
    computation_notes TEXT,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Prevent duplicate computations for same event/meter/methodology/hour/variant
    CONSTRAINT uq_baseline_result UNIQUE (
        event_id, meter_id, methodology_id, hour_start, shutdown_variant
    )
);

CREATE INDEX idx_baseline_event ON baseline_results(event_id);
CREATE INDEX idx_baseline_site ON baseline_results(site_id);
CREATE INDEX idx_baseline_meter ON baseline_results(meter_id);

-- ============================================================
-- 7. WEATHER (designed in, wired up later)
-- ============================================================

CREATE TABLE weather_stations (
    id TEXT PRIMARY KEY, -- NOAA station ID (e.g., 'KMSY')
    name TEXT NOT NULL,
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6)
);

CREATE TABLE weather_observations (
    station_id TEXT NOT NULL REFERENCES weather_stations(id),
    observation_hour TIMESTAMPTZ NOT NULL,
    temperature_f NUMERIC(5,1),
    dew_point_f NUMERIC(5,1),
    humidity_pct NUMERIC(5,1),
    heat_index_f NUMERIC(5,1),
    wind_speed_mph NUMERIC(5,1),
    PRIMARY KEY (station_id, observation_hour)
);

-- ============================================================
-- 8. USER ROLES & ROW-LEVEL SECURITY
-- ============================================================

-- Map Supabase auth users to customers and roles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id), -- NULL for internal/admin users
    role TEXT NOT NULL DEFAULT 'customer', -- 'admin', 'internal', 'customer'
    display_name TEXT,
    email TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_role CHECK (role IN ('admin', 'internal', 'customer'))
);

-- Enable RLS on all customer-facing tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE meter_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE curated_intervals ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE dr_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE dr_event_sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE baseline_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_shutdown_days ENABLE ROW LEVEL SECURITY;

-- Helper function: get the current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
    SELECT role FROM user_profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Helper function: get the current user's customer_id
CREATE OR REPLACE FUNCTION get_user_customer_id()
RETURNS UUID AS $$
    SELECT customer_id FROM user_profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Internal/admin users see everything; customers see only their own
-- Pattern: one policy per table, checking role or customer_id match

-- Customers table
CREATE POLICY customers_select ON customers FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR id = get_user_customer_id()
);

-- Sites table
CREATE POLICY sites_select ON sites FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR customer_id = get_user_customer_id()
);

-- Meters: visible if assigned to a site the user can see
CREATE POLICY meters_select ON meters FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR id IN (
        SELECT ma.meter_id FROM meter_assignments ma
        JOIN sites s ON s.id = ma.site_id
        WHERE s.customer_id = get_user_customer_id()
    )
);

-- Meter assignments
CREATE POLICY meter_assignments_select ON meter_assignments FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR site_id IN (
        SELECT id FROM sites WHERE customer_id = get_user_customer_id()
    )
);

-- Curated intervals: visible if meter is assigned to user's site
CREATE POLICY curated_intervals_select ON curated_intervals FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR meter_id IN (
        SELECT ma.meter_id FROM meter_assignments ma
        JOIN sites s ON s.id = ma.site_id
        WHERE s.customer_id = get_user_customer_id()
    )
);

-- Hourly reads: same pattern as curated intervals
CREATE POLICY hourly_reads_select ON hourly_reads FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR meter_id IN (
        SELECT ma.meter_id FROM meter_assignments ma
        JOIN sites s ON s.id = ma.site_id
        WHERE s.customer_id = get_user_customer_id()
    )
);

-- DR events: visible to all authenticated users (events are program-wide)
CREATE POLICY dr_events_select ON dr_events FOR SELECT USING (
    get_user_role() IS NOT NULL
);

-- DR event sites: customers see only their own sites' participation
CREATE POLICY dr_event_sites_select ON dr_event_sites FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR site_id IN (
        SELECT id FROM sites WHERE customer_id = get_user_customer_id()
    )
);

-- Baseline results: customers see only their own
CREATE POLICY baseline_results_select ON baseline_results FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR site_id IN (
        SELECT id FROM sites WHERE customer_id = get_user_customer_id()
    )
);

-- Site shutdown days
CREATE POLICY site_shutdown_days_select ON site_shutdown_days FOR SELECT USING (
    get_user_role() IN ('admin', 'internal')
    OR site_id IN (
        SELECT id FROM sites WHERE customer_id = get_user_customer_id()
    )
);

-- Admin/internal write policies (customers are read-only)
CREATE POLICY customers_admin_all ON customers FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY sites_admin_all ON sites FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY meters_admin_all ON meters FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY meter_assignments_admin_all ON meter_assignments FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY curated_intervals_admin_all ON curated_intervals FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY hourly_reads_admin_all ON hourly_reads FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY dr_events_admin_all ON dr_events FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY dr_event_sites_admin_all ON dr_event_sites FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY baseline_results_admin_all ON baseline_results FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);

CREATE POLICY site_shutdown_days_admin_all ON site_shutdown_days FOR ALL USING (
    get_user_role() IN ('admin', 'internal')
);


-- 12. UTILITY VIEWS
-- ============================================================

-- Active meter assignments with site and customer info
CREATE OR REPLACE VIEW v_active_meters AS
SELECT
    ma.id AS assignment_id,
    m.id AS meter_id,
    m.meter_number,
    m.meter_type,
    s.id AS site_id,
    s.device_location,
    s.name AS site_name,
    s.pelican_name,
    c.id AS customer_id,
    c.name AS customer_name,
    ma.start_date,
    ma.enrollment_status
FROM meter_assignments ma
JOIN meters m ON m.id = ma.meter_id
JOIN sites s ON s.id = ma.site_id
JOIN customers c ON c.id = s.customer_id
WHERE ma.end_date IS NULL
  AND m.is_active = TRUE;

-- Daily data completeness summary
CREATE OR REPLACE VIEW v_daily_completeness AS
SELECT
    ci.meter_id,
    m.meter_number,
    ci.channel,
    DATE(ci.interval_end AT TIME ZONE 'America/Chicago') AS read_date,
    COUNT(*) AS interval_count,
    288 - COUNT(*) AS missing_intervals,
    ROUND(COUNT(*) * 100.0 / 288, 1) AS completeness_pct,
    SUM(CASE WHEN ci.is_outlier THEN 1 ELSE 0 END) AS outlier_count,
    SUM(ci.reading_kwh) AS total_kwh,
    SUM(ci.reading_kwh) AS avg_kw -- sum of 5-min kWh over full day = avg kW * 24... use for reference
FROM curated_intervals ci
JOIN meters m ON m.id = ci.meter_id
GROUP BY ci.meter_id, m.meter_number, ci.channel,
         DATE(ci.interval_end AT TIME ZONE 'America/Chicago');

-- Outlier review queue
CREATE OR REPLACE VIEW v_outlier_review AS
SELECT
    ci.id,
    m.meter_number,
    s.name AS site_name,
    c.name AS customer_name,
    ci.channel,
    ci.interval_end AT TIME ZONE 'America/Chicago' AS interval_ct,
    ci.reading_kwh,
    ci.reading_kw,
    ci.outlier_reason,
    ci.source_file_load_id
FROM curated_intervals ci
JOIN meters m ON m.id = ci.meter_id
JOIN meter_assignments ma ON ma.meter_id = m.id AND ma.end_date IS NULL
JOIN sites s ON s.id = ma.site_id
JOIN customers c ON c.id = s.customer_id
WHERE ci.is_outlier = TRUE
ORDER BY ci.interval_end DESC;
