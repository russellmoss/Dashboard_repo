-- Test Query for vw_actual_vs_forecast_by_source Fix
-- This tests that the view correctly shows actuals outside the forecast date range
-- Expected results:
--   - July-Sept 2025: 221 SQLs (actuals only, no forecast)
--   - October 2025: 84 SQLs (actuals), ~77 SQLs (forecast)

-- Test 1: Check July-September 2025 (should show actuals, NULL forecasts)
SELECT 
  'July-September 2025' AS test_period,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  COUNT(DISTINCT date_day) AS days_with_data,
  COUNT(*) AS total_rows
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-07-01' AND '2025-09-30';

-- Test 2: Check October 2025 (should show both actuals and forecasts)
SELECT 
  'October 2025' AS test_period,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  COUNT(DISTINCT date_day) AS days_with_data,
  COUNT(*) AS total_rows
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';

-- Test 3: Sample rows from July-September to verify structure
SELECT 
  date_day,
  Channel_Grouping_Name,
  Original_source,
  sql_actual,
  sql_forecast,
  sql_variance,
  sql_variance_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-07-01' AND '2025-09-30'
  AND sql_actual > 0
ORDER BY date_day DESC, sql_actual DESC
LIMIT 10;

