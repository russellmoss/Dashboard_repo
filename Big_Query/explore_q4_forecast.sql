/*
 * Explore Q4 2025 Forecast Data Structure
 * Run these queries to understand the data before filtering for SQOs
 */

-- 1. Check what stage values exist for Provided Lead List
SELECT DISTINCT stage
FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
WHERE original_source = 'Provided Lead List'
  AND metric = 'Cohort_source'
ORDER BY stage;

-- 2. See sample data to understand structure
SELECT 
  month_key,
  metric,
  original_source,
  stage,
  forecast_value
FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
WHERE original_source = 'Provided Lead List'
  AND metric = 'Cohort_source'
ORDER BY month_key, stage
LIMIT 20;

-- 3. Check if there's any data at all for Provided Lead List
SELECT 
  COUNT(*) as total_rows,
  COUNT(DISTINCT month_key) as distinct_months,
  COUNT(DISTINCT stage) as distinct_stages
FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
WHERE original_source = 'Provided Lead List'
  AND metric = 'Cohort_source';

