-- Updated Production Forecast View
-- Architecture:
--   Top of Funnel (MQLs, SQLs): ARIMA_PLUS models via daily_forecasts table
--   Bottom of Funnel (SQL→SQO): V2 Challenger Model (69.3% validated conversion rate)
--
-- SQL forecasts come from daily_forecasts table which uses:
--   - model_arima_mqls for MQL forecasts
--   - model_arima_sqls for SQL forecasts (ARIMA_PLUS hybrid approach)
--   - Segment-specific trailing rates for SQO (V1 approach - REPLACED by V2 below)
--
-- SQO forecasts are recalculated using V2 model conversion rate (69.3%)
-- instead of the segment-specific trailing rates stored in daily_forecasts table

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_production_forecast` AS

WITH 

latest_forecast AS (
  SELECT
    *,
    -- Calculate Standard Deviation from the 95% CI (approx. 1.96 std devs)
    SAFE_DIVIDE(mqls_upper - mqls_forecast, 1.96) AS mqls_std_dev,
    SAFE_DIVIDE(sqls_upper - sqls_forecast, 1.96) AS sqls_std_dev,
    SAFE_DIVIDE(sqos_upper - sqos_forecast, 1.96) AS sqos_std_dev
  FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  WHERE forecast_date = (
    SELECT MAX(forecast_date) 
    FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  )
),

actuals AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    mqls_daily AS mqls_actual,
    sqls_daily AS sqls_actual,
    sqos_daily AS sqos_actual
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE date_day <= CURRENT_DATE()
),

-- V2 Challenger Model Conversion Rate (Bottom of Funnel)
-- 69.3% validated conversion rate from Q3 2024 backtest
-- This replaces the V1 trailing_rates_features approach
-- Source: V2 Backtest Results Q3 2024 - 9.01 predicted SQOs / 13 cohort SQLs
v2_conversion_rate AS (
  SELECT
    SAFE_DIVIDE(9.01, 13) AS v2_sql_to_sqo_rate  -- 69.3% validated conversion rate
),

combined AS (
  SELECT
    COALESCE(a.Channel_Grouping_Name, f.Channel_Grouping_Name) AS Channel_Grouping_Name,
    COALESCE(a.Original_source, f.Original_source) AS Original_source,
    COALESCE(a.date_day, f.date_day) AS date_day,
    
    a.mqls_actual,
    a.sqls_actual,
    a.sqos_actual,
    
    -- Use actual if available, else forecast
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.mqls_actual
      ELSE f.mqls_forecast
    END AS mqls_combined,
    
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqls_actual
      ELSE f.sqls_forecast
    END AS sqls_combined,
    
    -- SQO: Use actual if available, else recalculate using V2 Challenger Model
    -- V2 Model: Bottom of funnel conversion (SQL→SQO)
    -- Uses validated 69.3% rate instead of trailing_rates_features (V1 approach)
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqos_actual
      ELSE f.sqls_forecast * v2.v2_sql_to_sqo_rate  -- V2 Challenger: ARIMA SQLs × 69.3% = SQOs
    END AS sqos_combined,

    -- Forecast-only values (Top of Funnel: ARIMA_PLUS models)
    f.mqls_forecast,  -- From model_arima_mqls via daily_forecasts
    f.sqls_forecast,  -- From model_arima_sqls via daily_forecasts (ARIMA_PLUS hybrid)
    -- SQO forecast: Bottom of Funnel using V2 Challenger Model
    -- Recalculated using V2 rate instead of trailing_rates from daily_forecasts table
    CASE 
      WHEN a.date_day IS NULL THEN f.sqls_forecast * v2.v2_sql_to_sqo_rate  -- V2: SQLs × 69.3%
      ELSE NULL
    END AS sqos_forecast,
    
    -- 95% Confidence Intervals (from model)
    CASE WHEN a.date_day IS NULL THEN f.mqls_lower END AS mqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.mqls_upper END AS mqls_upper_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_lower END AS sqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper END AS sqls_upper_95,
    -- SQO CIs: Calculate from SQL CIs using V2 rate
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_lower * v2.v2_sql_to_sqo_rate) END AS sqos_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper * v2.v2_sql_to_sqo_rate END AS sqos_upper_95,

    -- 50% Confidence Intervals (calculated)
    -- A 50% CI is approx. 0.674 standard deviations
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.mqls_forecast - (f.mqls_std_dev * 0.674)) END AS mqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.mqls_forecast + (f.mqls_std_dev * 0.674) END AS mqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_forecast - (f.sqls_std_dev * 0.674)) END AS sqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.sqls_forecast + (f.sqls_std_dev * 0.674) END AS sqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, (f.sqls_forecast - (f.sqls_std_dev * 0.674)) * v2.v2_sql_to_sqo_rate) END AS sqos_lower_50,
    CASE WHEN a.date_day IS NULL THEN (f.sqls_forecast + (f.sqls_std_dev * 0.674)) * v2.v2_sql_to_sqo_rate END AS sqos_upper_50,
    
    CASE 
      WHEN a.date_day IS NOT NULL THEN 'ACTUAL'
      ELSE 'FORECAST'
    END AS data_type,
    
    EXTRACT(QUARTER FROM COALESCE(a.date_day, f.date_day)) AS quarter,
    EXTRACT(MONTH FROM COALESCE(a.date_day, f.date_day)) AS month,
    EXTRACT(YEAR FROM COALESCE(a.date_day, f.date_day)) AS year
    
  FROM actuals a
  FULL OUTER JOIN latest_forecast f
    ON a.Channel_Grouping_Name = f.Channel_Grouping_Name
    AND a.Original_source = f.Original_source
    AND a.date_day = f.date_day
  CROSS JOIN v2_conversion_rate v2
)

-- Final output with cumulative metrics
SELECT
  *,
  
  -- Month-to-date cumulatives
  SUM(mqls_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, month
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS mqls_mtd,
  
  SUM(sqls_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, month
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS sqls_mtd,

  SUM(sqos_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, month
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS sqos_mtd,
  
  -- Quarter-to-date cumulatives
  SUM(mqls_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, quarter
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS mqls_qtd,

  SUM(sqls_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, quarter
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS sqls_qtd,

  SUM(sqos_combined) OVER (
    PARTITION BY Channel_Grouping_Name, Original_source, year, quarter
    ORDER BY date_day
    ROWS UNBOUNDED PRECEDING
  ) AS sqos_qtd
  
FROM combined;

