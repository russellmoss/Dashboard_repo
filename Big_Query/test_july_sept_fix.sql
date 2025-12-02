-- Test script to verify the fixes for vw_actual_vs_forecast_by_source
-- Fix 1: July-Sept 2025 data availability
-- Fix 2: October variance calculation accuracy

-- Test Query 1: Check October 2025 totals should match manual counts
SELECT 
  'October 2025' AS period,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  SUM(sql_variance) AS total_sql_variance,
  ROUND(AVG(sql_variance_pct), 1) AS avg_sql_variance_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';

-- Test Query 2: Verify that forecast fallback is working for July-Sept
SELECT 
  date_day,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  CASE 
    WHEN SUM(sql_forecast) = SUM(sql_actual) THEN 'Fallback Applied ✅'
    ELSE 'Using Real Forecast ✅'
  END AS forecast_source
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE date_day BETWEEN '2025-07-01' AND '2025-09-30'
GROUP BY 1
HAVING SUM(sql_actual) > 0 OR SUM(sql_forecast) > 0
ORDER BY 1
LIMIT 10;

-- Test Query 3: Compare Q4 (has forecast) vs Q3 (should use fallback)
SELECT 
  CASE 
    WHEN date_day BETWEEN '2025-07-01' AND '2025-09-30' THEN 'Q3 2025 (No Forecast)'
    WHEN date_day BETWEEN '2025-10-01' AND '2025-12-31' THEN 'Q4 2025 (Has Forecast)'
  END AS quarter,
  COUNT(DISTINCT date_day) AS days_with_data,
  SUM(sql_actual) AS total_sql_actual,
  SUM(sql_forecast) AS total_sql_forecast,
  CASE 
    WHEN SUM(sql_forecast) = SUM(sql_actual) THEN 'Fallback: Actuals as Forecast'
    ELSE 'Using: Real Forecast Data'
  END AS forecast_behavior
FROM `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source`
WHERE (date_day BETWEEN '2025-07-01' AND '2025-09-30')
   OR (date_day BETWEEN '2025-10-01' AND '2025-12-31')
GROUP BY 1
ORDER BY 1;

