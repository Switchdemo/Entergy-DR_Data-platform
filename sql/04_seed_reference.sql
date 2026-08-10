-- ============================================================
-- SEED DATA — Reference tables from ENO Meter Map
-- Generated 2026-08-10
-- ============================================================

-- Customers
INSERT INTO customers (name, short_name) VALUES ('643 Magazine St', '643_magazine_st') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('ACE Hotel', 'ace_hotel') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Alta Max Packing', 'alta_max_packing') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Cabrini', 'cabrini') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('EMR / Southern Scrap', 'emr___southern_scrap') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Franklin Ave Baptist', 'franklin_ave_baptist') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Highland Fleet', 'highland_fleet') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Hyatt Regency Hotel', 'hyatt_regency_hotel') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Jesuit High School', 'jesuit_high_school') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('LSU Health', 'lsu_health') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Lake Forest School', 'lake_forest_school') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Lineage', 'lineage') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Maison de la Luz Hotel', 'maison_de_la_luz_hotel') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('McGehee School', 'mcgehee_school') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Mount Carmel', 'mount_carmel') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('New Orleans & Co', 'new_orleans_&_co') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Ross Dept Store', 'ross_dept_store') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('SMG/Louisiana Superdome', 'smg_louisiana_superdome') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Science and Math HS (SciHigh)', 'science_and_math_hs_scihigh') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Smoothie King Center', 'smoothie_king_center') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('St Augustine High School', 'st_augustine_high_school') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Tubman Charter MS', 'tubman_charter_ms') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Tubman Montessori', 'tubman_montessori') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Tulane Medical Center', 'tulane_medical_center') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('USDA', 'usda') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Ulta Beauty', 'ulta_beauty') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('University of New Orleans', 'university_of_new_orleans') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('VA Hospital', 'va_hospital') ON CONFLICT DO NOTHING;
INSERT INTO customers (name, short_name) VALUES ('Walgreens', 'walgreens') ON CONFLICT DO NOTHING;

-- Sites, Meters, and Assignments
-- Using DO blocks to handle FK references by name lookup

-- 643 Magazine St 1 | Meter: AM12547332 | DevLoc: 1787467
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = '643 Magazine St';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1787467', '643 Magazine St 1', '634Magazine', '76841485.0', '992489.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12547332', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- 643 Magazine St 2 | Meter: AM12547335 | DevLoc: 1787452
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = '643 Magazine St';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1787452', '643 Magazine St 2', NULL, '76841485.0', NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12547335', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- St Augustine High School | Meter: AM12989994 | DevLoc: 8216360
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'St Augustine High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8216360', 'St Augustine High School', 'StAugustine', '11719234.0', '848987.0', 'Notified of new meter 2/10/25.')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12989994', 'ami', NULL, 'Notified of new meter 2/10/25.')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Notified of new meter 2/10/25.')
    ON CONFLICT DO NOTHING;

END $$;

-- St Augustine High School (2) | Meter: AM10990722 | DevLoc: 1100687
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'St Augustine High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1100687', 'St Augustine High School (2)', 'StAugustine2', '12911350.0', '842275.0', 'updated meter and premise id using updated aptim file 12/22/25. Accurate?')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10990722', 'ami', 'requested to add into sftp 3.24.26', 'updated meter and premise id using updated aptim file 12/22/25. Accurate?')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'updated meter and premise id using updated aptim file 12/22/25. Accurate?')
    ON CONFLICT DO NOTHING;

END $$;

-- St Augustine High School (3) | Meter: AM12529785 | DevLoc: 8220687
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'St Augustine High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8220687', 'St Augustine High School (3)', 'StAugustine3', '39112503.0', '2752165.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12529785', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- ACE Hotel | Meter: AM12159700 | DevLoc: 6912030
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'ACE Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6912030', 'ACE Hotel', 'AceHotel', '126972108.0', '3652702.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159700', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- ACE Hotel (2) | Meter: AM12135985 | DevLoc: 7028522
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'ACE Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '7028522', 'ACE Hotel (2)', 'AceHotel2', '129165957.0', '3708864.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12135985', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Maison de la Luz Hotel | Meter: AM12159836 | DevLoc: 1755870
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Maison de la Luz Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1755870', 'Maison de la Luz Hotel', 'MaisonDeLaLuz', '154459903.0', '1005174.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159836', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- EMR / Southern Scrap | Meter: AM12536279 | DevLoc: 1734393
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'EMR / Southern Scrap';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1734393', 'EMR / Southern Scrap', 'EMR', '36482867.0', '839247.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12536279', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- EMR / Southern Scrap (2) | Meter: 8039987 | DevLoc: PULSE METER(kyz2)
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'EMR / Southern Scrap';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039987', 'EMR / Southern Scrap (2)', NULL, '97614689.0', NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039987', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- EMR / Southern Scrap (3) | Meter: 8039988 | DevLoc: PULSE METER(kyz1)
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'EMR / Southern Scrap';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039988', 'EMR / Southern Scrap (3)', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039988', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- EMR / Southern Scrap (4) | Meter: 8039986 | DevLoc: PULSE METER(kyz3)
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'EMR / Southern Scrap';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039986', 'EMR / Southern Scrap (4)', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039986', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Ulta Beauty | Meter: AM11442820 | DevLoc: 6847085
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Ulta Beauty';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6847085', 'Ulta Beauty', 'UltaBeauty', '120215736.0', '3621327.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11442820', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site | Meter: AM12864382 | DevLoc: 1725811
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1725811', 'Cabrini site', 'CabriniHighSchool', '10943827.0', '914087.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12864382', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (2) | Meter: AM12536667 | DevLoc: 1725829
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1725829', 'Cabrini site (2)', 'CabriniHighSchool2', '10943827.0', NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12536667', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (3) | Meter: AM12864342 | DevLoc: 1977227
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1977227', 'Cabrini site (3)', 'CabriniHighSchool3', '10944585.0', '895501.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12864342', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (4) | Meter: AM11982894 | DevLoc: 1977212
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1977212', 'Cabrini site (4)', 'CabriniHighSchool4', '11302288.0', '895496.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11982894', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (5) | Meter: AM10694458 | DevLoc: 1742239
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1742239', 'Cabrini site (5)', 'CabriniHighSchool5', '11854007.0', '916769.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10694458', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (6) | Meter: AM12536541 | DevLoc: 1790500
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1790500', 'Cabrini site (6)', 'CabriniHighSchool6', '12593398.0', '912593.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12536541', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (7) | Meter: AM10694457 | DevLoc: 8310356
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8310356', 'Cabrini site (7)', 'CabriniHighSchool7', '81248395.0', '925689.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10694457', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Cabrini site (8) | Meter: AM14249718 | DevLoc: 1721255
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Cabrini';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1721255', 'Cabrini site (8)', 'CabriniHighSchool8', '161300454.0', '4387002.0', 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM14249718', 'ami', NULL, 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data')
    ON CONFLICT DO NOTHING;

END $$;

-- Mount Carmel site 1 | Meter: AM10126883 | DevLoc: 1954714
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Mount Carmel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1954714', 'Mount Carmel site 1', 'MtCarmel', '10993830.0', '876078.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126883', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Mount Carmel site 2 | Meter: AM12535612 | DevLoc: 1954684
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Mount Carmel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1954684', 'Mount Carmel site 2', 'MtCarmel2', '10994093.0', '876073.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12535612', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Mount Carmel site 3 | Meter: AM10126845 | DevLoc: 2065570
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Mount Carmel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '2065570', 'Mount Carmel site 3', 'MtCarmel3', '42772095.0', '1098252.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126845', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Jesuit HS site 1 | Meter: AM12192927 | DevLoc: 8657804
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Jesuit High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8657804', 'Jesuit HS site 1', 'JesuitHighSchool', '13291570.0', '826134.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12192927', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Jesuit HS site 2 | Meter: EM17001237 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Jesuit High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001237', 'Jesuit HS site 2', 'JesuitHighSchool2', '13291810.0', '1029419.0', 'Non AMI meter. This meter will not report data through SFTP files')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001237', 'pulse_kyz', NULL, 'Non AMI meter. This meter will not report data through SFTP files')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Non AMI meter. This meter will not report data through SFTP files')
    ON CONFLICT DO NOTHING;

END $$;

-- Jesuit HS site 3 | Meter: AM10126831 | DevLoc: 8031147
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Jesuit High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8031147', 'Jesuit HS site 3', 'JesuitHighSchool3', '148050453.0', '4258104.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126831', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Jesuit HS site 4 | Meter: AM12159860 | DevLoc: 1990066
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Jesuit High School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1990066', 'Jesuit HS site 4', 'JesuitHighSchool4', '13291463.0', '948870.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159860', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Franklin Ave Baptist | Meter: AM12159869 | DevLoc: 8216692
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Franklin Ave Baptist';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8216692', 'Franklin Ave Baptist', 'Franklin_Baptist', '65429656.0', '1062505.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159869', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- New Orleans & Co | Meter: AM12160410 | DevLoc: 1870703
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'New Orleans & Co';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1870703', 'New Orleans & Co', 'NOCom', '11861531.0', '1002535.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12160410', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Alta Max Packing | Meter: AM10121302 | DevLoc: 1697709
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Alta Max Packing';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1697709', 'Alta Max Packing', 'AltaMax', '80211832.0', '1018107.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121302', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Montessori site 1 | Meter: AM12538300 | DevLoc: 8489485
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Montessori';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8489485', 'Tubman Montessori site 1', 'TubmanMontessori', '169019288.0', '4470434.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12538300', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Montessori site 2 | Meter: AM12122833 | DevLoc: 8489605
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Montessori';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8489605', 'Tubman Montessori site 2', 'TubmanMontessori2', '169161023.0', '4470528.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12122833', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Montessori site 3 | Meter: AM12293329 | DevLoc: 8492736
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Montessori';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8492736', 'Tubman Montessori site 3', 'TubmanMontessori3', '169017803.0', '4474640.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12293329', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Charter MS site 1 | Meter: AM12160067 | DevLoc: 8492478
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Charter MS';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8492478', 'Tubman Charter MS site 1', 'TubmanCharter', '168993442.0', '4474533.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12160067', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Charter MS site 2 | Meter: AM10225151 | DevLoc: 5560160
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Charter MS';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '5560160', 'Tubman Charter MS site 2', 'TubmanCharter2', '52650751.0', '2997445.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10225151', 'ami', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Science and Math HS (SciHigh) | Meter: AM12689415 | DevLoc: 8398848
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Science and Math HS (SciHigh)';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8398848', 'Science and Math HS (SciHigh)', 'SciHighSchool', '165483009.0', '4428839.0', 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data. Waiting for backfill data from ENO 4/24/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12689415', 'ami', NULL, 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data. Waiting for backfill data from ENO 4/24/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'Notified of new meter 2/10/25. Need to be added to SFTP batch. Entergy will be sending data. Waiting for backfill data from ENO 4/24/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Lake Forest School | Meter: AM12887149 | DevLoc: 6863683
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lake Forest School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6863683', 'Lake Forest School', 'LakeForestGW400', '119777522.0', '3629312.0', '3/13/26 not in APTIM file.')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12887149', 'ami', NULL, '3/13/26 not in APTIM file.')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '3/13/26 not in APTIM file.')
    ON CONFLICT DO NOTHING;

END $$;

-- Hyatt Regency Hotel | Meter: EM17000935 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Hyatt Regency Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17000935', 'Hyatt Regency Hotel', 'Hyatt', '13294814.0', '894438.0', 'KYZ meters')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17000935', 'pulse_kyz', NULL, 'KYZ meters')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'KYZ meters')
    ON CONFLICT DO NOTHING;

END $$;

-- Hyatt Regency Hotel | Meter: EM17000936 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Hyatt Regency Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17000936', 'Hyatt Regency Hotel', NULL, NULL, NULL, 'KYZ meters')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17000936', 'pulse_kyz', NULL, 'KYZ meters')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'KYZ meters')
    ON CONFLICT DO NOTHING;

END $$;

-- Hyatt Regency Hotel | Meter: EM17000937 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Hyatt Regency Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17000937', 'Hyatt Regency Hotel', NULL, NULL, NULL, 'KYZ meters')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17000937', 'pulse_kyz', NULL, 'KYZ meters')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'KYZ meters')
    ON CONFLICT DO NOTHING;

END $$;

-- Hyatt Regency Hotel | Meter: EM17000938 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Hyatt Regency Hotel';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17000938', 'Hyatt Regency Hotel', NULL, NULL, NULL, 'KYZ meters')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17000938', 'pulse_kyz', NULL, 'KYZ meters')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'KYZ meters')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: EM17002527 | DevLoc: NON AMI
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17002527', 'University of New Orleans', 'UNO', '10858322.0', '839068.0', '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17002527', 'non_ami', '80040050', '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: EM17002528 | DevLoc: NON AMI
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17002528', 'University of New Orleans', 'UNO5', NULL, NULL, '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17002528', 'non_ami', '80040051', '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '2/10/25 Pilot Meters per Entergy')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: AM12535674 | DevLoc: 1675194
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1675194', 'University of New Orleans', 'UNO2', '10855278.0', '826455.0', 'Entergy will be sending data')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12535674', 'ami', NULL, 'Entergy will be sending data')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Entergy will be sending data')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: AM12535669 | DevLoc: 1977427
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1977427', 'University of New Orleans', 'UNO3', '11500030.0', '1022899.0', 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12535669', 'ami', NULL, 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: AM12159967 | DevLoc: 1896132
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1896132', 'University of New Orleans', 'UNO4', '20564266.0', '990446.0', 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159967', 'ami', NULL, 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Per mark barron 6/1, these two meters are not tied to accounts on Enfra''s end. Removed from DRAS')
    ON CONFLICT DO NOTHING;

END $$;

-- University of New Orleans | Meter: AM12159804 | DevLoc: 5940918
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'University of New Orleans';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '5940918', 'University of New Orleans', 'UNO6', '66169921.0', '5940911.0', 'Mark Barron (enfra) 5/29/26 provided all meters for UNO, we did not have this one. Requested to add into SFTP 6/1/26. Done')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159804', 'ami', NULL, 'Mark Barron (enfra) 5/29/26 provided all meters for UNO, we did not have this one. Requested to add into SFTP 6/1/26. Done')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'Mark Barron (enfra) 5/29/26 provided all meters for UNO, we did not have this one. Requested to add into SFTP 6/1/26. Done')
    ON CONFLICT DO NOTHING;

END $$;

-- Ross Dept Store Holiday Dr | Meter: AM11442833 | DevLoc: 8503935
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Ross Dept Store';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8503935', 'Ross Dept Store Holiday Dr', 'RossAlgiers', '109326645.0', '3539904.0', 'Not receiving data')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11442833', 'ami', NULL, 'Not receiving data')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'not_receiving', 'Not receiving data')
    ON CONFLICT DO NOTHING;

END $$;

-- Ross Dept Store S Claiborne Ave | Meter: AM10121599 | DevLoc: 6847914
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Ross Dept Store';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6847914', 'Ross Dept Store S Claiborne Ave', 'RossCentralNOLA', '120360003.0', '3621705.0', 'Not receiving data')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121599', 'ami', NULL, 'Not receiving data')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'not_receiving', 'Not receiving data')
    ON CONFLICT DO NOTHING;

END $$;

-- USDA | Meter: 8046297 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'USDA';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8046297', 'USDA', 'USDA', '11246048.0', '926993.0', '8046297 is the meter listed in APTIM file - confirm this is the correct meter? Yes correct meter 3.25.26')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8046297', 'pulse_kyz', NULL, '8046297 is the meter listed in APTIM file - confirm this is the correct meter? Yes correct meter 3.25.26')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '8046297 is the meter listed in APTIM file - confirm this is the correct meter? Yes correct meter 3.25.26')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #3558 | Meter: AM10354605 | DevLoc: 1834557
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1834557', 'Walgreens #3558', 'Walgreens3558', '11073152.0', '934697.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10354605', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #4451 | Meter: AM10126481 | DevLoc: 1892047
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1892047', 'Walgreens #4451', 'Walgreens4451', '11935798.0', '930605.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126481', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #9063 | Meter: AM12160415 | DevLoc: 1881207
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1881207', 'Walgreens #9063', 'Walgreens9063', '50014745.0', '875732.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12160415', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #4450 | Meter: AM10121140 | DevLoc: 1696305
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1696305', 'Walgreens #4450', 'Walgreens4450', '13101530.0', '901962.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121140', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #11496 | Meter: AM10126912 | DevLoc: 1813649
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1813649', 'Walgreens #11496', 'Walgreens11496', '76669738.0', '857247.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126912', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #5358 | Meter: AM10126998 | DevLoc: 1936351
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1936351', 'Walgreens #5358', 'Walgreens5358', '10642734.0', '962887.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126998', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #5040 | Meter: AM10126559 | DevLoc: 1994478
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1994478', 'Walgreens #5040', 'Walgreens5040', '11452158.0', '893097.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126559', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #15199 | Meter: AM10126789 | DevLoc: 1809943
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1809943', 'Walgreens #15199', 'Walgreens15199', '107050957.0', '1016170.0', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126789', 'ami', NULL, 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 4/23/25, please update in concerto. Ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (CALS Main 1 and 2) | Meter: EM17001001 | DevLoc: PULSE METERs
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001001', 'LSU Medical Center (CALS Main 1 and 2)', 'LSUCAL', '177054871.0', '4573490.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. pulse meter')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001001', 'pulse_kyz', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. pulse meter')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. pulse meter')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (CALS Main 1 and 2) | Meter: EM17001002 | DevLoc: nan
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001002', 'LSU Medical Center (CALS Main 1 and 2)', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001002', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Education Bldg | Meter: EM17001013 | DevLoc: PULSE METERS
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001013', 'LSU Medical Education Bldg', 'LSUMedEdu', '13294210.0', '938118.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001013', 'pulse_kyz', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Education Bldg | Meter: EM17001014 | DevLoc: nan
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001014', 'LSU Medical Education Bldg', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001014', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Healthcare Science Center (Mervin L Trail) | Meter: AM12864471 | DevLoc: 8834134
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '8834134', 'LSU Healthcare Science Center (Mervin L Trail)', 'LSUMedMLTrail', '11935426.0', '1025765.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12864471', 'ami', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (Lions Eye Center) | Meter: AM12547367 | DevLoc: 1721852
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1721852', 'LSU Medical Center (Lions Eye Center)', 'LSULionsEyeCen', '13294392.0', '973449.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12547367', 'ami', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (School of Allied Health/Nursing) | Meter: AM10126612 | DevLoc: nan
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_AM10126612', 'LSU Medical Center (School of Allied Health/Nursing)', NULL, '13294368.0', '935500.0', 'this meter no longer on premise 3/25/26')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126612', 'ami', NULL, 'this meter no longer on premise 3/25/26')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'decommissioned', 'this meter no longer on premise 3/25/26')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (School of Allied Health/Nursing) | Meter: AM12989910 | DevLoc: 1870681
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1870681', 'LSU Medical Center (School of Allied Health/Nursing)', 'LSUSHealthNurse', '13294368.0', '935500.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12989910', 'ami', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Medical Center (Resource Center Building) | Meter: AM10126614 | DevLoc: 1838347
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1838347', 'LSU Medical Center (Resource Center Building)', 'LSUResCenter', '13294061.0', '919589.0', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. ticket submitted')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126614', 'ami', NULL, 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. ticket submitted')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added 5/16/25 - need to add to SFTP overnight and updated in concerto. ticket submitted')
    ON CONFLICT DO NOTHING;

END $$;

-- LSU Health (generator meter) | Meter: AMI10126611 | DevLoc: nan
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'LSU Health';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_AMI10126611', 'LSU Health (generator meter)', NULL, NULL, NULL, 'requested to add into SFTP 6/18/16. Per Entergy, this generator meter for LSU is not active so they cannot add it into SFTP file')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AMI10126611', 'ami', NULL, 'requested to add into SFTP 6/18/16. Per Entergy, this generator meter for LSU is not active so they cannot add it into SFTP file')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 6/18/16. Per Entergy, this generator meter for LSU is not active so they cannot add it into SFTP file')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School (Family Edu Svcs) | Meter: AM10121637 | DevLoc: 1695706
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1695706', 'McGehee School (Family Edu Svcs)', 'McGeheeFES', '84375427.0', '951299.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121637', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School (Offices of Physicians) | Meter: AM11177055 | DevLoc: 1736039
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1736039', 'McGehee School (Offices of Physicians)', 'McGeheeOOP', '11852837.0', '957462.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11177055', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School (Admin of Edu Programs) | Meter: AM10121066 | DevLoc: 5893482
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '5893482', 'McGehee School (Admin of Edu Programs)', 'McGeheeAEP', '64106206.0', '3159238.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121066', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School 1(Elem/Secondary Schools) | Meter: AM10126223 | DevLoc: 1756990
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1756990', 'McGehee School 1(Elem/Secondary Schools)', 'McGehee1_elemsec', '12861258.0', '962254.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126223', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School 2(Elem/Secondary Schools) | Meter: AM10121635 | DevLoc: 1784954
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1784954', 'McGehee School 2(Elem/Secondary Schools)', 'McGehee2_elemsec', '11853439.0', '1004268.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121635', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School 3(Elem/Secondary Schools) | Meter: AM11719381 | DevLoc: 1819759
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1819759', 'McGehee School 3(Elem/Secondary Schools)', 'McGehee3_elemsec', '11852266.0', '1011386.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11719381', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School (Single fam) | Meter: AM11442779 | DevLoc: 7044249
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '7044249', 'McGehee School (Single fam)', 'McGeheeSF', '130154537.0', '3716323.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11442779', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- McGehee School | Meter: AM11719382 | DevLoc: 1827011
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'McGehee School';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1827011', 'McGehee School', 'McGeheeSchool', '11853173.0', '1011948.0', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM11719382', 'ami', NULL, 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add to SFTP 3.9.26 Updated in DRAS - need to let dras team know')
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Jourdan | Meter: 8039998 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039998', 'Lineage Jourdan', 'LineageJourdan', '14421184.0', '1082088.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039998', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Jourdan | Meter: 8039999 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039999', 'Lineage Jourdan', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039999', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Jourdan | Meter: 8033802 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8033802', 'Lineage Jourdan', NULL, NULL, NULL, '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8033802', 'pulse_kyz', NULL, '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Jourdan | Meter: EM17001262 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001262', 'Lineage Jourdan', NULL, NULL, NULL, 'IS THIS STILL ACTIVE? OR REPLACED WITH PULSE METER? 12/22/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001262', 'pulse_kyz', NULL, 'IS THIS STILL ACTIVE? OR REPLACED WITH PULSE METER? 12/22/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'IS THIS STILL ACTIVE? OR REPLACED WITH PULSE METER? 12/22/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Jourdan | Meter: 8040000 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8040000', 'Lineage Jourdan', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8040000', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Lineage Terminal | Meter: 8039990 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Lineage';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_8039990', 'Lineage Terminal', 'LineageTerminal', '102001369.0', '3459444.0', '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039990', 'pulse_kyz', NULL, '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', '12/22/25 added in new meter # on updated APTIM file. Need to map in DRAS')
    ON CONFLICT DO NOTHING;

END $$;

-- VA Hospital | Meter: EM17001054 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'VA Hospital';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001054', 'VA Hospital', 'VA', '114628068.0', '3588330.0', NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001054', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- VA Hospital | Meter: EM17001075 | DevLoc: PULSE METER
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'VA Hospital';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, 'NONAMI_EM17001075', 'VA Hospital', NULL, NULL, NULL, NULL)
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('EM17001075', 'pulse_kyz', NULL, NULL)
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', NULL)
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #10316 | Meter: AM10121241 | DevLoc: 6275071
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6275071', 'Walgreens #10316', 'Walgreens10316', '85504611.0', '3343964.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121241', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #11414 | Meter: AM10121325 | DevLoc: 1782417
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1782417', 'Walgreens #11414', 'Walgreens11414', '77302339.0', '856499.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121325', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #15615 | Meter: AM12162651 | DevLoc: 1745520
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1745520', 'Walgreens #15615', 'Walgreens15615', '121155006.0', '825736.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12162651', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #16312 | Meter: AM12886208 | DevLoc: 6990539
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6990539', 'Walgreens #16312', 'Walgreens16312', '127829687.0', '3679445.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12886208', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #2640 | Meter: AM10126292 | DevLoc: 1827509
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1827509', 'Walgreens #2640', 'Walgreens2640', '10897635.0', '865089.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10126292', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #3139 | Meter: AM10121143 | DevLoc: 1778858
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1778858', 'Walgreens #3139', 'Walgreens3139', '11606498.0', '917318.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121143', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #4305 | Meter: AM12547854 | DevLoc: 1686486
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1686486', 'Walgreens #4305', 'Walgreens4305', '10642569.0', '948620.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12547854', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Walgreens #5866 | Meter: AM12535609 | DevLoc: 5904274
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Walgreens';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '5904274', 'Walgreens #5866', 'Walgreens5866', '64566995.0', '3164389.0', 'added to map 9/19/25')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12535609', 'ami', NULL, 'added to map 9/19/25')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 9/19/25')
    ON CONFLICT DO NOTHING;

END $$;

-- Tulane Medical Center (Enfra) | Meter: AM10121543 | DevLoc: 1754334
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tulane Medical Center';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1754334', 'Tulane Medical Center (Enfra)', NULL, '13294426.0', '846097.0', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121543', 'ami', NULL, 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT DO NOTHING;

END $$;

-- Tulane Medical Center 2 (Enfra) | Meter: AM12159681 | DevLoc: 1893143
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tulane Medical Center';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1893143', 'Tulane Medical Center 2 (Enfra)', NULL, '10642114.0', '1531396.0', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159681', 'ami', NULL, 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT DO NOTHING;

END $$;

-- Tulane Medical Center 3 (Enfra) | Meter: AM12159955 | DevLoc: 1815249
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tulane Medical Center';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1815249', 'Tulane Medical Center 3 (Enfra)', NULL, '10641983.0', '938291.0', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159955', 'ami', NULL, 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT DO NOTHING;

END $$;

-- Tulane Medical Center 4 (Enfra) | Meter: AM12887573 | DevLoc: 1866158
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tulane Medical Center';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1866158', 'Tulane Medical Center 4 (Enfra)', NULL, '12732889.0', '946578.0', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12887573', 'ami', NULL, 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'pending_enrollment', 'added to map 3/11/26 (waiting for enrollment)')
    ON CONFLICT DO NOTHING;

END $$;

-- Highland Fleet 1 | Meter: AM12887136 | DevLoc: 9528753
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Highland Fleet';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '9528753', 'Highland Fleet 1', 'HighlandFleet1', '208556100.0', NULL, 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12887136', 'ami', NULL, 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT DO NOTHING;

END $$;

-- Highland Fleet 2 | Meter: AM10121195 | DevLoc: 1793427
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Highland Fleet';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1793427', 'Highland Fleet 2', 'HighlandFleet2', '166755009.0', NULL, 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10121195', 'ami', NULL, 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'added to map 3/11/26 . Has been added into SFTP file')
    ON CONFLICT DO NOTHING;

END $$;

-- SMG/LOUISIANA SUPERDOME 1 | Meter: 8019786 | DevLoc: 13295167
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'SMG/Louisiana Superdome';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '13295167', 'SMG/LOUISIANA SUPERDOME 1', 'SuperdomeNonAMI1', '13295167.0', '977843.0', 'non ami')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8019786', 'pulse_kyz', NULL, 'non ami')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'non ami')
    ON CONFLICT DO NOTHING;

END $$;

-- SMG/LOUISIANA SUPERDOME 1 | Meter: 8039989 | DevLoc: 13295168
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'SMG/Louisiana Superdome';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '13295168', 'SMG/LOUISIANA SUPERDOME 1', 'SuperdomeNonAMI2', NULL, NULL, 'non ami')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('8039989', 'pulse_kyz', NULL, 'non ami')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'non ami')
    ON CONFLICT DO NOTHING;

END $$;

-- SMG/LOUISIANA SUPERDOME 2 | Meter: AM12159765 | DevLoc: 1878743
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'SMG/Louisiana Superdome';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1878743', 'SMG/LOUISIANA SUPERDOME 2', 'Superdome', '13294699.0', '1022883.0', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12159765', 'ami', NULL, 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT DO NOTHING;

END $$;

-- SMG/LOUISIANA SUPERDOME 3 | Meter: AM12149172 | DevLoc: 6380919
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'SMG/Louisiana Superdome';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '6380919', 'SMG/LOUISIANA SUPERDOME 3', 'Superdome2', '89740138.0', '3395051.0', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12149172', 'ami', NULL, 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT DO NOTHING;

END $$;

-- SMG/LOUISIANA SUPERDOME 4 | Meter: AM12149173 | DevLoc: 2001709
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'SMG/Louisiana Superdome';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '2001709', 'SMG/LOUISIANA SUPERDOME 4', 'Superdome3', '12378691.0', '977923.0', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM12149173', 'ami', NULL, 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 6/18/16. done')
    ON CONFLICT DO NOTHING;

END $$;

-- Smoothie King Center | Meter: AM10199225 | DevLoc: 1711551
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Smoothie King Center';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '1711551', 'Smoothie King Center', 'SmoothieKing', '12669347.0', NULL, 'requested to add into SFTP 7/20/26')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM10199225', 'ami', 'flowing through sftp 8/2/26', 'requested to add into SFTP 7/20/26')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 7/20/26')
    ON CONFLICT DO NOTHING;

END $$;

-- Tubman Montessori site 4 | Meter: AM13081182 | DevLoc: 9519756
DO $$
DECLARE
    v_customer_id UUID;
    v_site_id UUID;
    v_meter_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE name = 'Tubman Montessori';

    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)
    VALUES (v_customer_id, '9519756', 'Tubman Montessori site 4', 'TubmanMontessori4', NULL, NULL, 'requested to add into SFTP 7/21/26')
    ON CONFLICT (device_location) DO UPDATE SET
        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,
        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility
    RETURNING id INTO v_site_id;

    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)
    VALUES ('AM13081182', 'ami', 'flowing through sftp 8/2/26', 'requested to add into SFTP 7/21/26')
    ON CONFLICT (meter_number) DO UPDATE SET
        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id
    RETURNING id INTO v_meter_id;

    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)
    VALUES (v_meter_id, v_site_id, '2024-01-01', 'active', 'requested to add into SFTP 7/21/26')
    ON CONFLICT DO NOTHING;

END $$;

