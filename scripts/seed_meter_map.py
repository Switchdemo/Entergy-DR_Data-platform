"""
seed_meter_map.py
-----------------
Parses the ENO Meter Map Excel file and generates SQL INSERT statements
for customers, sites, meters, and meter_assignments.

Run this to produce the seed SQL, then execute it against your Supabase DB.

Usage:
    python seed_meter_map.py /path/to/ENO_MeterMap.xlsx > seed_reference_data.sql
"""

import sys
import pandas as pd
from datetime import date

def parse_meter_map(filepath):
    """Parse the meter map Excel file and return structured data."""
    df = pd.read_excel(filepath, sheet_name='ENOmeter_map')

    # Clean column names
    df.columns = [c.strip() for c in df.columns]

    # Forward-fill Customer name for multi-meter sites
    df['Customer'] = df['Customer'].ffill()

    # Drop completely empty rows
    df = df.dropna(subset=['MeterNumber'], how='all')
    df = df[df['MeterNumber'].notna() & (df['MeterNumber'].astype(str).str.strip() != '')]

    # Clean up fields
    df['Customer'] = df['Customer'].str.strip()
    df['MeterNumber'] = df['MeterNumber'].astype(str).str.strip()
    df['DeviceLocation'] = df['DeviceLocation'].astype(str).str.strip() if 'DeviceLocation' in df.columns else ''

    # Map Account # column
    acct_col = [c for c in df.columns if 'Account' in c]
    if acct_col:
        df['AccountNum'] = df[acct_col[0]].astype(str).str.strip().replace('nan', '')
    else:
        df['AccountNum'] = ''

    # Map PremiseId
    if 'PremiseId' in df.columns:
        df['PremiseId'] = df['PremiseId'].astype(str).str.strip().replace('nan', '')
    else:
        df['PremiseId'] = ''

    # Map Pelican name
    pelican_col = [c for c in df.columns if 'Pelican' in c]
    if pelican_col:
        df['PelicanName'] = df[pelican_col[0]].astype(str).str.strip().replace('nan', '')
    else:
        df['PelicanName'] = ''

    # Map Recorder ID
    recorder_col = [c for c in df.columns if 'Recorder' in c or 'backfill' in c.lower()]
    if recorder_col:
        df['RecorderID'] = df[recorder_col[0]].astype(str).str.strip().replace('nan', '')
    else:
        df['RecorderID'] = ''

    # Map Notes
    if 'Notes' in df.columns:
        df['Notes'] = df['Notes'].astype(str).str.strip().replace('nan', '')
    else:
        df['Notes'] = ''

    return df


def classify_meter_type(meter_number, device_location):
    """Determine meter type from meter number and device location."""
    meter_number = str(meter_number).upper()
    device_location = str(device_location).upper()

    if 'PULSE' in device_location or 'PULSE' in meter_number:
        return 'pulse_kyz'
    elif 'NON AMI' in device_location or 'NON AMI' in meter_number:
        return 'non_ami'
    elif meter_number.startswith('AM'):
        return 'ami'
    elif meter_number.startswith('EM'):
        return 'pulse_kyz'  # EM prefix meters are typically pulse
    else:
        # Numeric-only meter numbers are typically pulse/KYZ
        try:
            int(meter_number)
            return 'pulse_kyz'
        except ValueError:
            return 'ami'


def extract_customer_name(full_name):
    """Extract the base customer name (without site numbers)."""
    # Group multi-site customers under one parent
    name = full_name.strip()

    # Common patterns: "Cabrini site (2)", "Mount Carmel site 2", "643 Magazine St 1"
    # We want to group these under the base customer name
    import re

    # Map known customers to their canonical names
    customer_mappings = {
        '643 Magazine St': '643 Magazine St',
        'St Augustine High School': 'St Augustine High School',
        'ACE Hotel': 'ACE Hotel',
        'Maison de la Luz Hotel': 'Maison de la Luz Hotel',
        'EMR / Southern Scrap': 'EMR / Southern Scrap',
        'Ulta Beauty': 'Ulta Beauty',
        'Cabrini site': 'Cabrini',
        'Mount Carmel site': 'Mount Carmel',
        'Jesuit HS site': 'Jesuit High School',
        'Franklin Ave Baptist': 'Franklin Ave Baptist',
        'New Orleans & Co': 'New Orleans & Co',
        'Alta Max Packing': 'Alta Max Packing',
        'Tubman Montessori site': 'Tubman Montessori',
        'Tubman Charter MS site': 'Tubman Charter MS',
        'Science and Math HS': 'Science and Math HS (SciHigh)',
        'Lake Forest School': 'Lake Forest School',
        'Hyatt Regency Hotel': 'Hyatt Regency Hotel',
        'University of New Orleans': 'University of New Orleans',
        'Ross Dept Store': 'Ross Dept Store',
        'USDA': 'USDA',
        'LSU': 'LSU Health',
        'McGehee School': 'McGehee School',
        'Lineage': 'Lineage',
        'VA Hospital': 'VA Hospital',
        'SMG/LOUISIANA SUPERDOME': 'SMG/Louisiana Superdome',
        'Smoothie King Center': 'Smoothie King Center',
        'Highland Fleet': 'Highland Fleet',
        'Tulane Medical Center': 'Tulane Medical Center',
    }

    for prefix, canonical in customer_mappings.items():
        if name.startswith(prefix):
            return canonical

    # Walgreens — group all under one customer
    if name.startswith('Walgreens'):
        return 'Walgreens'

    return name


def escape_sql(val):
    """Escape a string for SQL insertion."""
    if not val or val == '' or val == 'nan' or val == 'None':
        return 'NULL'
    return "'" + str(val).replace("'", "''") + "'"


def generate_sql(df):
    """Generate SQL INSERT statements from parsed meter map data."""
    lines = []
    lines.append("-- ============================================================")
    lines.append("-- SEED DATA — Reference tables from ENO Meter Map")
    lines.append(f"-- Generated {date.today().isoformat()}")
    lines.append("-- ============================================================")
    lines.append("")

    # --- Customers ---
    customers = {}
    for _, row in df.iterrows():
        cust_name = extract_customer_name(row['Customer'])
        if cust_name not in customers:
            customers[cust_name] = cust_name

    lines.append("-- Customers")
    for cust_name in sorted(customers.keys()):
        short = cust_name.lower().replace(' ', '_').replace('/', '_').replace('(', '').replace(')', '')
        lines.append(
            f"INSERT INTO customers (name, short_name) VALUES "
            f"({escape_sql(cust_name)}, {escape_sql(short)}) "
            f"ON CONFLICT DO NOTHING;"
        )
    lines.append("")

    # --- Sites and Meters ---
    lines.append("-- Sites, Meters, and Assignments")
    lines.append("-- Using DO blocks to handle FK references by name lookup")
    lines.append("")

    seen_meters = set()

    for _, row in df.iterrows():
        meter_number = str(row['MeterNumber']).strip()
        device_location = str(row['DeviceLocation']).strip()
        cust_name = extract_customer_name(row['Customer'])
        site_name = str(row['Customer']).strip()
        pelican = row.get('PelicanName', '')
        account = row.get('AccountNum', '')
        premise = row.get('PremiseId', '')
        recorder = row.get('RecorderID', '')
        notes = row.get('Notes', '')
        meter_type = classify_meter_type(meter_number, device_location)

        # Skip if device_location is a label like "PULSE METER" or "NON AMI"
        # These don't have a real device location — use meter_number as fallback
        dl_upper = device_location.upper()
        is_placeholder_location = (
            dl_upper in ('', 'NAN', 'NONE')
            or 'PULSE' in dl_upper
            or 'NON AMI' in dl_upper
        )

        effective_device_loc = device_location if not is_placeholder_location else f"NONAMI_{meter_number}"

        if meter_number in seen_meters:
            continue
        seen_meters.add(meter_number)

        lines.append(f"-- {site_name} | Meter: {meter_number} | DevLoc: {device_location}")
        lines.append("DO $$")
        lines.append("DECLARE")
        lines.append("    v_customer_id UUID;")
        lines.append("    v_site_id UUID;")
        lines.append("    v_meter_id UUID;")
        lines.append("BEGIN")
        lines.append(f"    SELECT id INTO v_customer_id FROM customers WHERE name = {escape_sql(cust_name)};")
        lines.append("")

        # Upsert site
        lines.append(f"    INSERT INTO sites (customer_id, device_location, name, pelican_name, account_number, premise_id_utility, notes)")
        lines.append(f"    VALUES (v_customer_id, {escape_sql(effective_device_loc)}, {escape_sql(site_name)}, "
                      f"{escape_sql(pelican)}, {escape_sql(account)}, {escape_sql(premise)}, {escape_sql(notes)})")
        lines.append(f"    ON CONFLICT (device_location) DO UPDATE SET")
        lines.append(f"        name = EXCLUDED.name, pelican_name = EXCLUDED.pelican_name,")
        lines.append(f"        account_number = EXCLUDED.account_number, premise_id_utility = EXCLUDED.premise_id_utility")
        lines.append(f"    RETURNING id INTO v_site_id;")
        lines.append("")

        # Upsert meter
        lines.append(f"    INSERT INTO meters (meter_number, meter_type, backfill_recorder_id, notes)")
        lines.append(f"    VALUES ({escape_sql(meter_number)}, {escape_sql(meter_type)}, "
                      f"{escape_sql(recorder)}, {escape_sql(notes)})")
        lines.append(f"    ON CONFLICT (meter_number) DO UPDATE SET")
        lines.append(f"        meter_type = EXCLUDED.meter_type, backfill_recorder_id = EXCLUDED.backfill_recorder_id")
        lines.append(f"    RETURNING id INTO v_meter_id;")
        lines.append("")

        # Determine enrollment status
        notes_str = str(notes).lower() if notes and str(notes) not in ('', 'nan', 'None') else ''
        if 'not receiving' in notes_str:
            enrollment = 'not_receiving'
        elif 'waiting for enrollment' in notes_str or 'need to be added' in notes_str:
            enrollment = 'pending_enrollment'
        elif 'no longer on premise' in notes_str:
            enrollment = 'decommissioned'
        else:
            enrollment = 'active'

        # Insert meter assignment (if not already exists)
        lines.append(f"    INSERT INTO meter_assignments (meter_id, site_id, start_date, enrollment_status, notes)")
        lines.append(f"    VALUES (v_meter_id, v_site_id, '2024-01-01', {escape_sql(enrollment)}, {escape_sql(notes)})")
        lines.append(f"    ON CONFLICT DO NOTHING;")
        lines.append("")
        lines.append("END $$;")
        lines.append("")

    return '\n'.join(lines)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        filepath = '/mnt/user-data/uploads/ENO_MeterMap_2026_working_doc__5_.xlsx'
    else:
        filepath = sys.argv[1]

    df = parse_meter_map(filepath)
    sql = generate_sql(df)
    print(sql)
