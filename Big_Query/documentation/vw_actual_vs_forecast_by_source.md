## Purpose

`vw_actual_vs_forecast_by_source` produces a single, analysis-ready table that combines:

- Actual funnel outcomes by day and original source (from `vw_funnel_lead_to_joined_v2`)
- Daily rate forecasts by day and original source (from `vw_daily_forecast`)

It is designed for Looker Studio so that:

- You can filter by arbitrary date ranges, channels, and sources
- Actuals always appear whenever they exist (even if no forecast exists for that date range)
- Forecasts appear only for periods where you’ve published forecast targets


## Upstream Inputs

- **Actuals**: `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  - Provides row-level lead/opportunity fields and derived flags for SQL, SQO, Joined, and AUM
  - Key date fields used for daily attribution:
    - SQLs → `converted_date_raw`
    - SQOs → `Date_Became_SQO__c`
    - Joined → `advisor_join_date__c`
    - AUM → `Stage_Entered_Signed__c` (filtered to exclude `StageName = 'Closed Lost'`)
  - Attribution keys used for grouping:
    - `Channel_Grouping_Name`
    - `Original_source`

- **Forecasts (daily rate)**: `savvy-gtm-analytics.savvy_analytics.vw_daily_forecast`
  - Converts monthly forecast targets into a per-day rate for each day in the month
  - Source monthly targets table (example for Q4 2025):
    - `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
  - Required fields in the monthly table:
    - `Channel` (mapped to `Channel_Grouping_Name`, with special-case: Inbound → Marketing)
    - `original_source`
    - `stage` (values: sql, sqo, joined)
    - `metric` (use `Cohort_source`)
    - `month_key` (e.g. '2025-10')
    - `forecast_value` (integer)


## How the View Works

High-level steps inside `vw_actual_vs_forecast_by_source.sql`:

1) **Actual_Data CTE (no date restriction)**
   - Builds four subqueries (SQL, SQO, Joined, AUM), each attributed to the correct date field
   - Aggregates counts/sums by `date_day`, `Channel_Grouping_Name`, `Original_source`
   - UNION ALLs them and then re-aggregates in `Actual_Aggregated`

2) **Forecast_Data CTE**
   - Pulls daily rate forecasts by `date_day`, `Channel_Grouping_Name`, `Original_source` from `vw_daily_forecast`
   - Note: Forecasts exist only for months that have published monthly targets

3) **Dynamic Date Spine**
   - `Date_Spine` is the UNION of all distinct dates seen in `Actual_Aggregated` and `Forecast_Data`
   - This guarantees rows for any date with actuals, even if no forecast exists (and vice versa)

4) **Channel/Source Universe**
   - `Channel_Source_Combinations` is the UNION of distinct channel/source pairs seen in actuals and forecasts
   - Ensures the final output retains all combinations across both datasets

5) **Full Matrix + LEFT JOINs**
   - `Full_Matrix` = `Date_Spine` × `Channel_Source_Combinations`
   - LEFT JOIN to `Actual_Aggregated` and to `Forecast_Data`
   - Produces one row per date × channel × source with:
     - `sql_actual`, `sqo_actual`, `joined_actual`, `aum_actual`
     - `sql_forecast`, `sqo_forecast`, `joined_forecast` (AUM forecast currently 0)
   - Variance fields are computed simply as actual − forecast, plus % variance when forecast > 0

Result: Looker Studio can SUM across any selected range. If a date range lacks forecasts, forecast fields are 0/NULL while actuals still appear.


## `vw_daily_forecast` Logic (Monthly → Daily Rate)

`vw_daily_forecast.sql`:

- Reads monthly targets from a quarterly table (e.g., `SavvyGTMData.q4_2025_forecast`)
- Normalizes stage names (sql → sqls, sqo → sqos, joined → joined)
- Computes `days_in_month` and divides the monthly total by the number of days to get a flat daily rate
- Joins each month’s daily rate to each calendar day in that month via a date spine
- Pivots to produce `sql_forecast`, `sqo_forecast`, `joined_forecast` columns per day per channel/source

Important: The view only includes the months you load. If you don’t publish monthly targets for a future quarter, the forecast columns will be NULL/0 for those dates, but actuals will still show in `vw_actual_vs_forecast_by_source` thanks to its dynamic date spine.


## Quarterly Forecast Publishing Process

Use this checklist at the start of each quarter to keep the view working for future periods.

- **Prepare the forecast Google Sheet**
  - Columns required: `Channel`, `original_source`, `stage`, `metric`, `month_key`, `forecast_value`
  - Values:
    - `stage`: sql, sqo, joined (lowercase)
    - `metric`: Cohort_source
    - `month_key`: 'YYYY-MM'
    - `forecast_value`: integer counts per month per channel/source/stage

- **Load the sheet into BigQuery**
  - Destination table naming convention: `SavvyGTMData.qX_YYYY_forecast` (e.g., `q1_2026_forecast`)
  - Ensure data types are correct (e.g., `forecast_value` as INT64)
  - Confirm there are no 'All' values in `original_source` (the daily view excludes `original_source = 'All'`)

- **Update or generalize `vw_daily_forecast`**
  - Option A (fastest): Update the source table reference and month filters to the new quarter:
    - Replace table: `SavvyGTMData.q4_2025_forecast` → `SavvyGTMData.qX_YYYY_forecast`
    - Update `month_key` IN (...) to the three months of the new quarter
  - Option B (recommended medium-term): Create a single canonical table (e.g., `SavvyGTMData.monthly_forecast_targets`) with multiple quarters and drive `vw_daily_forecast` off that table with a parameter or date filter

- **Validate daily forecast output**
  - For each month, SUM daily rates × days in month should equal the monthly target
  - Spot-check a couple of channel/source pairs for correctness

- **End-to-end validation in `vw_actual_vs_forecast_by_source`**
  - Use the test script (e.g., `test_vw_actual_vs_forecast_fix.sql`) to:
    - Verify Actual totals for a historic non-forecast period still show
    - Verify Actual + Forecast totals for the new quarter match expectations


## Operational Notes and Best Practices

- **Actuals date attributions are metric-specific**
  - SQLs: `DATE(converted_date_raw)`
  - SQOs: `DATE(Date_Became_SQO__c)`
  - Joined: `DATE(advisor_join_date__c)`
  - AUM: `DATE(Stage_Entered_Signed__c)` with `StageName != 'Closed Lost'`

- **Channel grouping alignment**
  - Forecast `Channel` 'Inbound' is mapped to `Channel_Grouping_Name = 'Marketing'` to match actuals
  - Keep the channel/source taxonomy consistent between the forecasts and `vw_funnel_lead_to_joined_v2`

- **Looker Studio tips**
  - Use SUM over the date range for actuals and forecasts
  - Compute arrows/indicators in Looker Studio at the aggregate level to avoid row-level variance issues

- **When forecasts are missing**
  - The view still shows actuals due to the dynamic date spine
  - Forecast columns will be 0/NULL; variance % will be NULL to avoid divide-by-zero


## Troubleshooting

- **“No data” for older periods**
  - Ensure `vw_actual_vs_forecast_by_source` has no date filters on actuals (current version removes them)
  - Verify actuals exist in `vw_funnel_lead_to_joined_v2` for the selected period

- **Forecasts not appearing for a future quarter**
  - Confirm the new quarter’s monthly targets were loaded into BigQuery
  - Confirm `vw_daily_forecast` references the correct table and months

- **Totals don’t match monthly targets**
  - Re-check `days_in_month` logic and monthly totals in the source table
  - Ensure `metric = 'Cohort_source'` and `original_source != 'All'`


## Quick Validation Queries

Run these as sanity checks after updating a future quarter’s forecasts:

```sql
-- 1) Validate actuals-only period still shows
SELECT SUM(sql_actual) AS actuals_only_period
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-07-01' AND '2025-09-30';

-- 2) Validate a forecasted month totals
SELECT 
  SUM(sql_forecast) AS total_sql_forecast_oct,
  COUNT(DISTINCT date_day) AS days
FROM `savvy-gtm-analytics.savvy_analytics.vw_daily_forecast`
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';

-- 3) End-to-end for a forecasted month
SELECT 
  SUM(sql_actual) AS total_sql_actual_oct,
  SUM(sql_forecast) AS total_sql_forecast_oct
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';
```


## What to Change Each Quarter (Minimal List)

- Load new monthly targets from Google Sheet → BigQuery table (`SavvyGTMData.qX_YYYY_forecast`)
- Update `vw_daily_forecast` to reference the new table and month list (or move to a canonical table)
- Re-run validation queries and update Looker Studio as needed


