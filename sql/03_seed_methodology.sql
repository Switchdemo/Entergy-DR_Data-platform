-- 10. SEED DATA — CONCERTO 10 OF 10 METHODOLOGY
-- ============================================================

INSERT INTO baseline_methodologies (
    name, version, description,
    weekday_similar_count, weekend_similar_count,
    max_lookback_weekday, max_lookback_weekend, min_similar_days,
    exclude_holidays, exclude_event_days,
    aggregation_method, aggregation_param,
    adjustment_type, adjustment_pre_event_hours, adjustment_duration_hours,
    metering_type, shutdown_handling,
    use_weather, is_active
) VALUES (
    'Concerto 10 of 10', '1.0',
    'Performance measured against a 10-of-10 similar day baseline with positive-only same-day additive adjustment. '
    'Weekday events use 10 prior non-holiday, non-event weekdays. '
    'Saturday events use 5 prior Saturdays. '
    'Sunday/holiday events use 5 prior Sundays or federal holidays. '
    'Adjustment window is 1 hour ending 2 hours before event start.',
    10, 5,    -- similar day counts
    20, 10,   -- max lookback
    1,        -- min similar days
    TRUE, TRUE, -- exclude holidays and event days
    'mean', NULL, -- simple average
    'positive_only_additive', 2, 1, -- adjustment config
    'gross',  -- metering type
    'both',   -- compute both per-spec and shutdown-excluded baselines
    FALSE,    -- no weather yet
    TRUE      -- active
);

-- ============================================================
-- 11. SEED DATA — PROGRAM
-- ============================================================

INSERT INTO programs (name, utility, description) VALUES (
    'ENO DR Pilot',
    'Entergy New Orleans',
    'Demand response pilot program operating under the Concerto platform with AMI and pulse/KYZ metered sites in the New Orleans area.'
);

