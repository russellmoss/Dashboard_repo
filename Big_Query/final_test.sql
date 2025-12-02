-- FINAL TEST: Run this against the DEPLOYED view
-- This should show 84 actuals and ~77-85 forecast for October

SELECT 
  'October 2025 Summary' AS test,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  SUM(sql_actual) - SUM(sql_forecast) AS variance,
  ROUND(((SUM(sql_actual) - SUM(sql_forecast)) / SUM(sql_forecast)) * 100, 1) AS variance_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';

-- Also test July-September to ensure actuals show with fallback forecast
SELECT 
  'July-Sept 2025 Summary' AS test,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  SUM(sql_actual) - SUM(sql_forecast) AS variance,
  ROUND(((SUM(sql_actual) - SUM(sql_forecast)) / SUM(sql_forecast)) * 100, 1) AS variance_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-07-01' AND '2025-09-30';

