## Savvy Wealth RevOps Dashboards and Reporting (SQL)

This repository contains the canonical SQL used to power Savvy Wealth Revenue Operations dashboards and reports. It includes stage definitions, corrected conversion-rate logic, and views used in Looker Studio (and other BI tools) to analyze funnel performance from first touch through SQO and Joined.

### Repository layout
- `.cursor/` — IDE and MCP configuration.
- `Views/` — BigQuery SQL views that power dashboards and scorecards.
- Top-level markdowns — model documentation and forecasting plans.

---

## Key funnel definitions

We use corrected, progression-based logic to avoid inflation from people who enter the funnel out of normal sequence.

- Contacted (TOF): `is_contacted = 1` when the record has a non-null `stage_entered_contacting__c` (Lead object). Date anchor for Contacted/TOF is `DATE(FilterDate)`.
- MQL: `is_mql = 1` when the lead reaches MQL milestone. Date anchor is `DATE(mql_stage_entered_ts)`.
- SQL: `is_sql = 1` when the lead becomes SQL (SFDC Lead → Opportunity conversion). Date anchor is `DATE(converted_date_raw)`.
- SQO: `is_sqo = 1` on opportunities where the SQO evaluation is present. Date anchor is `DATE(Date_Became_SQO__c)`.
- Joined: `is_joined = 1` when the advisor joins. Date anchor is `DATE(advisor_join_date__c)`.

Notes:
- We restrict rate estimation and open-pipeline metrics to the active SGA/SGM cohort (from `SavvyGTMData.User` where `(IsSGA__c OR Is_SGM__c) AND IsActive=TRUE`).
- `FilterDate` is a canonical daily anchor derived from the earliest meaningful stage timestamp (e.g., CreatedDate/contacting/new) and is used as the date dimension for many aggregations.

### Corrected conversion rates (progression-based)
To avoid overstating conversion, only true progressions are counted in the numerator; denominators represent the eligible population at the prior stage.

- Contacted → MQL: `SUM(contacted∧MQL) / SUM(contacted)`
- MQL → SQL: `SUM(MQL∧SQL) / SUM(MQL)`
- SQL → SQO: `COUNT_DISTINCT(SQL∧SQO opportunity_id) / COUNT_DISTINCT(SQL opportunity_id)`
- SQO → Joined: `COUNT_DISTINCT(SQO∧Joined opportunity_id) / COUNT_DISTINCT(SQO opportunity_id)`

Handling non-sequential entrants:
- People who enter at a downstream stage (e.g., SQL without MQL) are not counted as progressions for upstream conversions. This prevents inflated rates and preserves true stage-to-stage performance.

---

## Views overview (BigQuery)

Below are the primary views you will interact with in `Views/`.

- `vw_funnel_lead_to_joined_v2.sql`
  - Base, unified funnel with per-record stage flags, opportunity identifiers, and canonical dates.
  - Provides the raw signal for all downstream aggregations, including corrected stage events.

- `vw_sga_funnel.sql`
  - Team- and date-grained aggregations of funnel counts for active SGA/SGM owners.
  - Useful for time-series charts and simple conversion summaries.

- `vw_sga_funnel_team_agg.sql`
  - Aggregated team funnel with corrected progression-rate outputs (Contacted→MQL/SQL/SQO and stage-to-stage rates).
  - Includes funnel-entry analysis to understand how records enter (normal sequence, direct to SQL/SQO, etc.).
  - Use weighted averages in BI to aggregate rates over multiple rows; prefer aggregating numerators/denominators where possible.

- `vw_source_performance_summary.sql` and `vw_source_performance_summary_aggregated.sql`
  - Source-level performance rollups (by `Channel_Grouping_Name`, `Original_source`).
  - Useful for channel/source scorecards, contribution analysis, and mix tracking.

- `vw_channel_drill_base.sql` and `vw_channel_drill_rollup_unified_date.sql`
  - Drillable source/channel detail aligned on a unified date, facilitating cross-filtered BI views.

- `vw_daily_funnel_metrics_hybrid.sql`
  - Daily-level funnel counts with corrected logic, suitable for daily trend lines.

- Forecast-related views:
  - `vw_daily_forecast.sql`: Converts monthly forecast targets into daily rates/targets for cross-filtered blending with actuals.
  - `vw_forecast_timeseries_with_confidence.sql`: Produces cumulative predicted curves, lower/upper bands, and stepped monthly targets for Looker Studio time-series.
  - `vw_forecast_vs_actuals.sql`: Combines QTD actuals with future expectations using corrected rates and open pipeline, with guardrails (e.g., daily caps and asymmetric downscale) to keep projections realistic.

- `vw_recruitment_firm_summary.sql`
  - Summary view for recruitment firms and related performance, helpful for ecosystem/partner channels.

- `vw_actual_vs_forecast_by_source.sql`
  - Side-by-side comparison of actuals and targets at the source level for monitoring performance against plan.

> Tip: Views are designed to be composable. For scorecards aggregating across many rows/dates, prefer aggregating numerators and denominators directly in BI and then computing ratios to avoid weight/rounding bias.

---

## How to use in BI

1) Date anchoring (critical):
   - For stage event counts/curves, tie each stage to its event date to reflect what happened in the selected period:
     - MQLs → `DATE(mql_stage_entered_ts)`
     - SQLs → `DATE(converted_date_raw)`
     - SQOs → `DATE(Date_Became_SQO__c)`
     - Joined → `DATE(advisor_join_date__c)`
   - `FilterDate` is often earlier and may lag event timestamps by weeks/months; do NOT use it for stage event time series.

2) Conversion rates: use `FilterDate` to define eligibility and hold numerators/denominators to the same cohort/date basis, ensuring apples-to-apples progression math.

3) Team/cohort filters: apply Active Owner filters where appropriate to match funnel-rate logic.

4) Correct, weighted averages for scorecards:
   - Contacted→MQL (team average): `SUM(corrected_contacted_to_mql_rate * team_contacted) / SUM(team_contacted)`
   - MQL→SQL (team average): `SUM(mql_to_sql_rate * team_mql) / SUM(team_mql)`
   - SQL→SQO (team average): `SUM(sql_to_sqo_rate * team_sql) / SUM(team_sql)`
   - Overall Contacted→SQO (team average): `SUM(corrected_contacted_to_sqo_rate * team_contacted) / SUM(team_contacted)`
   - Where available, prefer aggregating raw numerators/denominators for exact rollups.

---

## Forecasting (high level)

Where forecasting is needed, we rely on:
- Corrected progression rates and open pipeline to estimate remaining period outcomes, with daily caps that reflect historical p90 production.
- Asymmetric downscale guardrail: if modeled totals exceed targets by a wide margin, scale down the future component; do not scale up when under.

For a best-in-class statistical approach (with intervals and formal reconciliation), see `BQML_Forecasting_Plan.md` for an ARIMA_PLUS + propensity roadmap.

---

## Contributing
- Changes to views should preserve corrected progression logic and active-cohort filtering.
- When adding scorecard metrics, expose both rates and their numerators/denominators to support unbiased rollups.
- Document new fields and definitions in markdown at the repo root.


