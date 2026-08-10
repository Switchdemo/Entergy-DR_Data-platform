# Decision Log

Decisions made during discovery session, August 10 2026.

## Locked Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Stable site identifier | `DeviceLocation` | `PremiseId` changes without notice |
| 2 | Interval convention | End-of-interval | Confirmed matches utility definition |
| 3 | Hourly rollup | Hour 14:00 = intervals ending 14:05–15:00 | Confirmed matches legacy system |
| 4 | Net vs gross metering | Per-methodology config (`metering_type` field) | Different programs have different rules |
| 5 | DST handling | Store UTC, display America/Chicago | PostgreSQL `timestamptz` handles conversion; eliminates fall-back ambiguity |
| 6 | Data finality | No formal lock; restatements accepted anytime | Rare enough to handle ad-hoc; flag if post-baseline |
| 7 | Units | Store kWh raw, compute kW (×12), baselines/settlements in kW | Preserves source fidelity, kW is settlement unit |
| 8 | Outlier detection | Flag but don't reject | `is_outlier` + `outlier_reason` on curated_intervals |
| 9 | Shutdown days | Dual baseline (per-spec + shutdown-excluded) | Customers see both, prevents disputes |
| 10 | Meter history | Assignment timeline with start/end dates | Handles swaps, enrollments, decommissions |
| 11 | Legacy integration | None — standalone build | Legacy too antiquated for cost-effective integration |
| 12 | Hosting | Supabase (separate project), eventual Azure migration | Already in use for other work; PostgreSQL portable to Azure |
| 13 | Frontend | Next.js + Supabase JS SDK (to be built) | Best SDK support and auth integration |
| 14 | Data ingestion | Manual upload first, SFTP automation later | Practical phasing |
| 15 | Customer UI | View + export first, interactive later | Deliver value quickly |
