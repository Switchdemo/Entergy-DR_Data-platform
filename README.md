# DR Data Platform

Customer-facing viewer for the Entergy Demand Response data platform. Next.js 15
(App Router) exported as a static site, talking directly to Supabase. Auth and
data access are both client-side; **Row Level Security is the security boundary**.

## What's here

- **Auth** — email/password via Supabase, admin vs customer roles, client-side
  route guard on everything under `/dashboard`.
- **Load viewer** (`/dashboard`) — site/meter selector, daily peak-demand bar
  chart with weekend/holiday differentiation, click-through to hourly profile,
  weather overlay (temp, heat index, humidity, dew point, wind), CSV export.
- **Baseline viewer** (`/dashboard/baselines`) — per-event list with reduction
  metrics, drill-down to a baseline-vs-actual curve with the reduction area
  shaded and called event hours highlighted, per-event CSV export.

## Architecture decisions

**Static export, not SSR.** Every route renders to plain HTML/JS at build time
(`output: "export"` → `out/`). There's no server: the browser holds the Supabase
session and every request carries the user's JWT, so RLS filters results
automatically. This is the simplest, most robust fit for Cloudflare Pages — no
`next-on-pages` adapter, no edge runtime, nothing to babysit at request time.

**The anon key is public by design.** It's a JWT with the `anon` role and is
safe to ship in the client bundle. RLS is what actually protects data. Never put
the `service_role` key in this project.

**Client-side auth guard is UX, not security.** The guard in
`src/app/dashboard/layout.tsx` decides what to *render*; it does not protect
data. A determined user can read the bundle, but RLS still stops them from
reading rows they aren't entitled to. Keep your RLS policies airtight.

## Two things you must confirm against your database

Everything else is wired to your existing RPCs
(`get_sites_overview`, `get_daily_summary`, `get_hourly_profile`,
`get_weather_hourly`, `get_holidays`). Two pieces are assumptions:

### 1. Where the role lives (`src/lib/auth.tsx` → `resolveRole`)

Resolved in priority order: JWT `app_metadata.role` → JWT `user_metadata.role`
→ a `profiles` table (`profiles.id = auth.uid()`, column `role`). Defaults to
`customer` (least privilege) if none match. Edit that one function to match how
you provisioned roles. `app_metadata` is the most robust because your RLS
policies can read it directly.

### 2. The baseline RPC (`src/lib/rpc.ts` → `getBaselineResults`)

The viewer expects:

```
get_baseline_results(p_meter_number text, p_start_date date, p_end_date date)
```

returning one row per (event, hour):

| column          | type   | notes                                   |
|-----------------|--------|-----------------------------------------|
| event_date      | date   | the DR event day                        |
| baseline_method | text   | e.g. "10-in-10", "High 5-of-10"         |
| hour_ct         | timestamptz | hour, Central time                 |
| baseline_kw     | numeric | modeled counterfactual load            |
| actual_kw       | numeric | metered load                           |
| is_event_hour   | bool   | optional; true during the called window |

If your baseline table uses different names, remap in the `BaselineRow`
interface and the RPC call rather than touching the components. Starter SQL
(adapt table/column names to your schema):

```sql
create or replace function get_baseline_results(
  p_meter_number text, p_start_date date, p_end_date date
)
returns table (
  event_date date, baseline_method text, hour_ct timestamptz,
  baseline_kw numeric, actual_kw numeric, is_event_hour boolean
)
language sql stable security invoker as $$
  select b.event_date, b.method, b.hour_ct,
         b.baseline_kw, a.actual_kw,
         b.hour_ct >= b.event_start and b.hour_ct < b.event_end as is_event_hour
  from baseline_results b
  join hourly_rollups a
    on a.meter_number = b.meter_number and a.hour_ct = b.hour_ct
  where b.meter_number = p_meter_number
    and b.event_date between p_start_date and p_end_date
  order by b.event_date, b.hour_ct;
$$;
```

Until this RPC exists the baseline page shows a friendly "not found" notice
rather than an error — the rest of the app works without it.

## Local development

```bash
cp .env.local.example .env.local     # fill in your anon key
npm install
npm run dev                          # http://localhost:3000
```

`npm run build` produces the static `out/` directory. `npm run typecheck` runs
`tsc --noEmit`.

## Deploy to Cloudflare Pages

**Option A — connect the Git repo (simplest).** In the Cloudflare dashboard:
Workers & Pages → Create → Pages → connect `Entergy-DR_Data-platform`. Build
settings:

- Framework preset: **Next.js (Static HTML Export)**
- Build command: `npm run build`
- Build output directory: `out`
- Environment variables: `NEXT_PUBLIC_SUPABASE_URL`,
  `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Every push to `main` redeploys; PRs get preview URLs.

**Option B — GitHub Actions.** `.github/workflows/deploy.yml` is included. Add
repo secrets: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
`CLOUDFLARE_API_TOKEN` (Pages: Edit permission), `CLOUDFLARE_ACCOUNT_ID`. Create
a Pages project named `entergy-dr-platform` once (or via `wrangler pages project
create`), then pushes deploy through the workflow.

### After deploy

- Add your `*.pages.dev` domain (and any custom domain) to **Supabase → Auth →
  URL Configuration** redirect allow-list.
- Confirm auth email templates / password setup for your 29 customers.
- `public/_headers` ships a CSP scoped to your Supabase host — update it if you
  change projects, and re-test hydration if you tighten `script-src`.

## Structure

```
src/
  lib/
    supabase.ts     browser client
    rpc.ts          typed RPC wrappers  ← baseline schema assumption
    auth.tsx        AuthProvider + useAuth  ← role assumption
    dayClassify.ts  weekday/weekend/holiday
    weather.ts      overlay config + aggregation
    patterns.ts     weekend/holiday bar fills
    csv.ts          export helper
  components/       DailyChart, HourlyChart, BaselineChart, WeatherToggle, StatCards
  app/
    login/          sign-in
    dashboard/      guarded shell + load viewer + baselines/
```
