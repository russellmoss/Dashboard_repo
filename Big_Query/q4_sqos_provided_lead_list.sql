/*
 * Q4 2025 SQOs for Provided Lead List
 * 
 * This query sums SQOs by month for original_source = 'Provided Lead List'
 * Only includes rows where metric = 'Cohort_source' (not totals)
 * Stage column contains 'sqo' (lowercase)
 */

SELECT 
  month_key,
  SUM(forecast_value) as total_sqos
FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
WHERE original_source = 'Provided Lead List'
  AND metric = 'Cohort_source'
  AND stage = 'sqo'
GROUP BY month_key
ORDER BY month_key;

