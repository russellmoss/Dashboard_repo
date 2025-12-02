-- Final Production Forecast View - Using Hybrid Conversion Rates
-- Architecture:
--   Top of Funnel (MQLs, SQLs): ARIMA_PLUS models via daily_forecasts table
--   Bottom of Funnel (SQL→SQO): Hybrid Approach (Trailing rates weighted by volume + V2 Challenger fallback)
--
-- SQL forecasts come from daily_forecasts table which uses:
--   - model_arima_mqls for MQL forecasts
--   - model_arima_sqls for SQL forecasts (ARIMA_PLUS hybrid approach)
--
-- SQO forecasts are calculated using Hybrid conversion rate approach:
--   - Uses trailing rates (segment-specific historical rates) weighted by SQL volume
--   - Falls back to V2 Challenger rate (69.3%) for segments without trailing rates
--   - Validated in October 2025 backtest: -5.35% error (best performing method)

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

-- Hybrid Conversion Rate (Bottom of Funnel)
-- Uses trailing rates weighted by SQL volume, with V2 Challenger (69.3%) as fallback
-- Validated in October 2025 backtest: -5.35% error (best performing method)
-- Source: SQL_to_SQO_Conversion_Backtest_October_2025.md
hybrid_conversion_rate AS (
  SELECT
    hybrid_sql_to_sqo_rate,
    v2_challenger_rate
  FROM `savvy-gtm-analytics.savvy_forecast.vw_hybrid_conversion_rates`
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
    
    -- SQO: Use actual if available, else calculate using Hybrid Conversion Rate
    -- Hybrid Approach: Trailing rates weighted by SQL volume + V2 Challenger fallback
    -- Validated in October 2025 backtest: -5.35% error (best performing method)
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqos_actual
      ELSE f.sqls_forecast * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)  -- Hybrid: SQLs × Hybrid Rate
    END AS sqos_combined,

    -- Forecast-only values (Top of Funnel: ARIMA_PLUS models)
    f.mqls_forecast,  -- From model_arima_mqls via daily_forecasts
    f.sqls_forecast,  -- From model_arima_sqls via daily_forecasts (ARIMA_PLUS hybrid)
    -- SQO forecast: Bottom of Funnel using Hybrid Conversion Rate
    CASE 
      WHEN a.date_day IS NULL THEN f.sqls_forecast * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)  -- Hybrid: SQLs × Hybrid Rate
      ELSE NULL
    END AS sqos_forecast,
    
    -- 95% Confidence Intervals (from model)
    CASE WHEN a.date_day IS NULL THEN f.mqls_lower END AS mqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.mqls_upper END AS mqls_upper_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_lower END AS sqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper END AS sqls_upper_95,
    -- SQO CIs: Calculate from SQL CIs using Hybrid rate
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_lower * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)) END AS sqos_lower_95,
    CASE WHEN a.date_day IS NULL THEN f.sqls_upper * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate) END AS sqos_upper_95,

    -- 50% Confidence Intervals (calculated)
    -- A 50% CI is approx. 0.674 standard deviations
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.mqls_forecast - (f.mqls_std_dev * 0.674)) END AS mqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.mqls_forecast + (f.mqls_std_dev * 0.674) END AS mqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, f.sqls_forecast - (f.sqls_std_dev * 0.674)) END AS sqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN f.sqls_forecast + (f.sqls_std_dev * 0.674) END AS sqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, (f.sqls_forecast - (f.sqls_std_dev * 0.674)) * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)) END AS sqos_lower_50,
    CASE WHEN a.date_day IS NULL THEN (f.sqls_forecast + (f.sqls_std_dev * 0.674)) * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate) END AS sqos_upper_50,
    
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
  CROSS JOIN hybrid_conversion_rate hcr
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

