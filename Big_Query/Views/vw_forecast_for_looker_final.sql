-- Forecast View Optimized for Looker Shotgun-Style Graphs (Final Version)
-- Provides forecast values with 50% and 95% confidence intervals by Original Source, Channel, and Date
-- Designed for time-series visualization with confidence bands that widen over time
--
-- Use Cases:
--   - Shotgun-style graphs with confidence intervals (50% and 95%)
--   - Actuals vs Forecast comparison
--   - Filterable by Original_source, Channel_Grouping_Name, and date ranges
--
-- Architecture:
--   - Sources from vw_production_forecast (uses Hybrid conversion rates for SQOs)
--   - Includes both 50% and 95% confidence intervals for all stages

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker` AS

SELECT
  -- Dimensions for filtering
  Channel_Grouping_Name,
  Original_source,
  date_day,
  
  -- Time dimensions for grouping
  EXTRACT(YEAR FROM date_day) AS year,
  EXTRACT(QUARTER FROM date_day) AS quarter,
  EXTRACT(MONTH FROM date_day) AS month,
  EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
  FORMAT_DATE('%A', date_day) AS day_name,
  FORMAT_DATE('%B', date_day) AS month_name,
  
  -- Days from today (for filtering recent vs future)
  DATE_DIFF(date_day, CURRENT_DATE(), DAY) AS days_from_today,
  CASE 
    WHEN date_day < CURRENT_DATE() THEN 'ACTUAL'
    WHEN date_day = CURRENT_DATE() THEN 'TODAY'
    ELSE 'FORECAST'
  END AS time_period_type,
  
  -- Data type indicator
  data_type,
  
  -- MQL Metrics
  COALESCE(mqls_actual, 0) AS mqls_actual,
  COALESCE(mqls_forecast, 0) AS mqls_forecast,
  COALESCE(mqls_lower_50, 0) AS mqls_forecast_lower_50,
  COALESCE(mqls_upper_50, 0) AS mqls_forecast_upper_50,
  COALESCE(mqls_lower_95, 0) AS mqls_forecast_lower_95,
  COALESCE(mqls_upper_95, 0) AS mqls_forecast_upper_95,
  -- Combined (actual if available, else forecast)
  COALESCE(mqls_combined, mqls_forecast, 0) AS mqls_value,
  
  -- SQL Metrics
  COALESCE(sqls_actual, 0) AS sqls_actual,
  COALESCE(sqls_forecast, 0) AS sqls_forecast,
  COALESCE(sqls_lower_50, 0) AS sqls_forecast_lower_50,
  COALESCE(sqls_upper_50, 0) AS sqls_forecast_upper_50,
  COALESCE(sqls_lower_95, 0) AS sqls_forecast_lower_95,
  COALESCE(sqls_upper_95, 0) AS sqls_forecast_upper_95,
  -- Combined (actual if available, else forecast)
  COALESCE(sqls_combined, sqls_forecast, 0) AS sqls_value,
  
  -- SQO Metrics (using Hybrid conversion rates)
  COALESCE(sqos_actual, 0) AS sqos_actual,
  COALESCE(sqos_forecast, 0) AS sqos_forecast,
  COALESCE(sqos_lower_50, 0) AS sqos_forecast_lower_50,
  COALESCE(sqos_upper_50, 0) AS sqos_forecast_upper_50,
  COALESCE(sqos_lower_95, 0) AS sqos_forecast_lower_95,
  COALESCE(sqos_upper_95, 0) AS sqos_forecast_upper_95,
  -- Combined (actual if available, else forecast)
  COALESCE(sqos_combined, sqos_forecast, 0) AS sqos_value,
  
  -- Cumulative metrics (month-to-date)
  mqls_mtd,
  sqls_mtd,
  sqos_mtd,
  
  -- Cumulative metrics (quarter-to-date)
  mqls_qtd,
  sqls_qtd,
  sqos_qtd,
  
  -- Confidence interval width (for visualizations - shows widening over time)
  COALESCE(mqls_upper_50, 0) - COALESCE(mqls_lower_50, 0) AS mqls_ci_width_50,
  COALESCE(sqls_upper_50, 0) - COALESCE(sqls_lower_50, 0) AS sqls_ci_width_50,
  COALESCE(sqos_upper_50, 0) - COALESCE(sqos_lower_50, 0) AS sqos_ci_width_50,
  COALESCE(mqls_upper_95, 0) - COALESCE(mqls_lower_95, 0) AS mqls_ci_width_95,
  COALESCE(sqls_upper_95, 0) - COALESCE(sqls_lower_95, 0) AS sqls_ci_width_95,
  COALESCE(sqos_upper_95, 0) - COALESCE(sqos_lower_95, 0) AS sqos_ci_width_95

FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`;

