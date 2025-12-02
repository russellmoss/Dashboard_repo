-- Updated Production Forecast View with Live Rolling Conversion Rates
-- Architecture:
--   Top of Funnel (MQLs, SQLs): ARIMA_PLUS models via daily_forecasts table
--   Bottom of Funnel (SQL→SQO): Live rolling 90-day conversion rate (updates automatically)
--
-- Conversion Rates:
--   - Contacted → MQL: Live 90-day rolling rate
--   - MQL → SQL: Live 90-day rolling rate  
--   - SQL → SQO: Live 90-day rolling rate (replaces static 69.3%)

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

-- Live Rolling Conversion Rates (90-day window, updates automatically)
live_conversion_rates AS (
  SELECT
    contacted_to_mql_rate,
    mql_to_sql_rate,
    sql_to_sqo_rate
  FROM `savvy-gtm-analytics.savvy_forecast.vw_live_conversion_rates`
  WHERE rate_date = CURRENT_DATE()
  LIMIT 1
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
    
    -- SQO: Use actual if available, else recalculate using Live Rolling Rate
    -- Live Rate: SQL→SQO conversion (bottom of funnel)
    -- Uses 90-day rolling average instead of static 69.3% rate
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqos_actual
      ELSE f.sqls_forecast * COALESCE(l.sql_to_sqo_rate, 0.60)  -- Live rate with fallback
    END AS sqos_combined,

    -- Forecast-only values (Top of Funnel: ARIMA_PLUS models)
    f.mqls_forecast,  -- From model_arima_mqls via daily_forecasts
    f.sqls_forecast,  -- From model_arima_sqls via daily_forecasts (ARIMA_PLUS hybrid)
    -- SQO forecast: Bottom of Funnel using Live Rolling Conversion Rate
    CASE 
      WHEN a.date_day IS NULL THEN f.sqls_forecast * COALESCE(l.sql_to_sqo_rate, 0.60)  -- Live rate
      ELSE NULL
    END AS sqos_forecast,
    
    -- 95% Confidence Intervals (from model)
    CASE WHEN a.date_day IS NULL THEN f.mqls_lower END AS mqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.mqls_upper END AS mqls_upper_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_lower END AS sqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper END AS sqls_upper_95,
    -- SQO CIs: Calculate from SQL CIs using live rate
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_lower * COALESCE(l.sql_to_sqo_rate, 0.60)) END AS sqos_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper * COALESCE(l.sql_to_sqo_rate, 0.60) END AS sqos_upper_95,

    -- 50% Confidence Intervals (calculated)
    -- A 50% CI is approx. 0.674 standard deviations
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.mqls_forecast - (f.mqls_std_dev * 0.674)) END AS mqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.mqls_forecast + (f.mqls_std_dev * 0.674) END AS mqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_forecast - (f.sqls_std_dev * 0.674)) END AS sqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.sqls_forecast + (f.sqls_std_dev * 0.674) END AS sqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, (f.sqls_forecast - (f.sqls_std_dev * 0.674)) * COALESCE(l.sql_to_sqo_rate, 0.60)) END AS sqos_lower_50,
    CASE WHEN a.date_day IS NULL THEN (f.sqls_forecast + (f.sqls_std_dev * 0.674)) * COALESCE(l.sql_to_sqo_rate, 0.60) END AS sqos_upper_50,
    
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
  CROSS JOIN live_conversion_rates l
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

