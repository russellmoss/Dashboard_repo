-- Updated Model Performance View
-- Tracks performance of:
--   - Top of Funnel: ARIMA_PLUS models (MQLs, SQLs)
--   - Bottom of Funnel: V2 Challenger Model (SQL→SQO conversion at 69.3%)
-- Uses updated vw_production_forecast which uses V2 conversion rate for SQOs

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_model_performance` AS

WITH recent_performance AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    ABS(mqls_actual - COALESCE(mqls_combined, mqls_forecast)) AS mql_mae,
    ABS(sqls_actual - COALESCE(sqls_combined, sqls_forecast)) AS sql_mae,
    ABS(sqos_actual - COALESCE(sqos_combined, sqos_forecast)) AS sqo_mae
  FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
  WHERE data_type = 'ACTUAL'
    AND date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
),

aggregated AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    AVG(mql_mae) AS recent_mql_mae,
    AVG(sql_mae) AS recent_sql_mae,
    AVG(sqo_mae) AS recent_sqo_mae,
    COUNT(*) AS num_recent_forecasts
  FROM recent_performance
  GROUP BY 1, 2
)

SELECT
  *,
  -- Performance flags based on MAE
  CASE 
    WHEN recent_mql_mae > 1.0 THEN 'POOR'
    WHEN recent_mql_mae > 0.5 THEN 'FAIR'
    ELSE 'GOOD'
  END AS mql_performance_status,
  CASE 
    WHEN recent_sqo_mae > 0.5 THEN 'POOR'
    WHEN recent_sqo_mae > 0.25 THEN 'FAIR'
    ELSE 'GOOD'
  END AS sqo_performance_status,
  CURRENT_TIMESTAMP() AS evaluated_at
FROM aggregated;

