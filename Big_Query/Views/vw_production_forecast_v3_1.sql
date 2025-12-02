-- Production Forecast View - Using V3.1 Model for SQLs + Hybrid Conversion Rates
-- Architecture:
--   Top of Funnel (MQLs): ARIMA_PLUS models via daily_forecasts table
--   Top of Funnel (SQLs): V3.1 Super-Segment ML Model (2.24x more accurate than ARIMA_PLUS)
--   Bottom of Funnel (SQL→SQO): Hybrid Approach (Trailing rates weighted by volume + V2 Challenger fallback)
--
-- V3.1 Model Benefits:
--   - Validated: -27.1% error vs ARIMA_PLUS -60.7% error (2.24x better!)
--   - Backtest: October 2025 - Forecasted 64.9 SQLs vs 89 actual (vs V1's 35 SQLs)
--   - Uses super-segment forecasts distributed to Channel/Source granularity

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_production_forecast` AS

WITH 

-- Get ARIMA_PLUS forecasts for MQLs (still using ARIMA for MQLs)
arima_mql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    mqls_forecast,
    mqls_lower,
    mqls_upper,
    -- Calculate Standard Deviation from the 95% CI (approx. 1.96 std devs)
    SAFE_DIVIDE(mqls_upper - mqls_forecast, 1.96) AS mqls_std_dev
  FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  WHERE forecast_date = (
    SELECT MAX(forecast_date) 
    FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  )
  AND date_day > CURRENT_DATE()  -- Only future dates
),

-- Get V3.1 SQL forecasts (distributed to Channel/Source level)
v3_1_sql_forecast AS (
  SELECT
    date_day,
    Channel_Grouping_Name,
    Original_source,
    sqls_forecast_v3_1 AS sqls_forecast,
    -- Estimate confidence intervals using V3.1's validation MAE (0.68 per segment-day)
    -- Scale by distribution fraction to get Channel/Source level uncertainty
    sqls_forecast_v3_1 - 0.68 AS sqls_lower_estimate,
    sqls_forecast_v3_1 + 0.68 AS sqls_upper_estimate,
    -- Calculate std dev for 50% CI calculation
    0.68 / 1.96 AS sqls_std_dev_estimate
  FROM `savvy-gtm-analytics.savvy_forecast.vw_v3_1_sql_forecast_by_channel_source`
  WHERE date_day > CURRENT_DATE()
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
hybrid_conversion_rate AS (
  SELECT
    hybrid_sql_to_sqo_rate,
    v2_challenger_rate
  FROM `savvy-gtm-analytics.savvy_forecast.vw_hybrid_conversion_rates`
  LIMIT 1
),

combined AS (
  SELECT
    COALESCE(a.Channel_Grouping_Name, COALESCE(amf.Channel_Grouping_Name, v3f.Channel_Grouping_Name)) AS Channel_Grouping_Name,
    COALESCE(a.Original_source, COALESCE(amf.Original_source, v3f.Original_source)) AS Original_source,
    COALESCE(a.date_day, COALESCE(amf.date_day, v3f.date_day)) AS date_day,
    
    a.mqls_actual,
    a.sqls_actual,
    a.sqos_actual,
    
    -- Use actual if available, else forecast
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.mqls_actual
      ELSE amf.mqls_forecast
    END AS mqls_combined,
    
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqls_actual
      ELSE v3f.sqls_forecast  -- V3.1 model forecast!
    END AS sqls_combined,
    
    -- SQO: Use actual if available, else calculate using Hybrid Conversion Rate
    CASE 
      WHEN a.date_day IS NOT NULL THEN a.sqos_actual
      ELSE v3f.sqls_forecast * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)
    END AS sqos_combined,

    -- Forecast-only values
    amf.mqls_forecast,  -- ARIMA_PLUS for MQLs
    v3f.sqls_forecast,  -- V3.1 Super-Segment ML for SQLs (BETTER!)
    CASE 
      WHEN a.date_day IS NULL THEN v3f.sqls_forecast * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)
      ELSE NULL
    END AS sqos_forecast,
    
    -- 95% Confidence Intervals
    CASE WHEN a.date_day IS NULL THEN amf.mqls_lower END AS mqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN amf.mqls_upper END AS mqls_upper_95,
    CASE WHEN a.date_day IS NULL THEN v3f.sqls_lower_estimate END AS sqls_lower_95,
    CASE WHEN a.date_day IS NULL THEN v3f.sqls_upper_estimate END AS sqls_upper_95,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, v3f.sqls_lower_estimate * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)) END AS sqos_lower_95,
    CASE WHEN a.date_day IS NULL THEN v3f.sqls_upper_estimate * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate) END AS sqos_upper_95,

    -- 50% Confidence Intervals (calculated)
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, amf.mqls_forecast - (amf.mqls_std_dev * 0.674)) END AS mqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN amf.mqls_forecast + (amf.mqls_std_dev * 0.674) END AS mqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, v3f.sqls_forecast - (v3f.sqls_std_dev_estimate * 0.674)) END AS sqls_lower_50,
    CASE WHEN a.date_day IS NULL THEN v3f.sqls_forecast + (v3f.sqls_std_dev_estimate * 0.674) END AS sqls_upper_50,
    CASE WHEN a.date_day IS NULL THEN GREATEST(0, (v3f.sqls_forecast - (v3f.sqls_std_dev_estimate * 0.674)) * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate)) END AS sqos_lower_50,
    CASE WHEN a.date_day IS NULL THEN (v3f.sqls_forecast + (v3f.sqls_std_dev_estimate * 0.674)) * COALESCE(hcr.hybrid_sql_to_sqo_rate, hcr.v2_challenger_rate) END AS sqos_upper_50,
    
    CASE 
      WHEN a.date_day IS NOT NULL THEN 'ACTUAL'
      ELSE 'FORECAST'
    END AS data_type,
    
    EXTRACT(QUARTER FROM COALESCE(a.date_day, COALESCE(amf.date_day, v3f.date_day))) AS quarter,
    EXTRACT(MONTH FROM COALESCE(a.date_day, COALESCE(amf.date_day, v3f.date_day))) AS month,
    EXTRACT(YEAR FROM COALESCE(a.date_day, COALESCE(amf.date_day, v3f.date_day))) AS year
    
  FROM actuals a
  FULL OUTER JOIN arima_mql_forecast amf
    ON a.Channel_Grouping_Name = amf.Channel_Grouping_Name
    AND a.Original_source = amf.Original_source
    AND a.date_day = amf.date_day
  FULL OUTER JOIN v3_1_sql_forecast v3f
    ON COALESCE(a.Channel_Grouping_Name, amf.Channel_Grouping_Name) = v3f.Channel_Grouping_Name
    AND COALESCE(a.Original_source, amf.Original_source) = v3f.Original_source
    AND COALESCE(a.date_day, amf.date_day) = v3f.date_day
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

