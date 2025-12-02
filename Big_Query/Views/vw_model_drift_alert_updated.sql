-- Updated Model Drift Alert View
-- Monitors drift for:
--   - Top of Funnel: ARIMA_PLUS models (MQLs, SQLs)
--   - Bottom of Funnel: V2 Challenger Model (SQL→SQO conversion)
-- Uses V2 model baseline for SQO drift detection
-- Compares recent performance vs V2 validated baseline (Q3 2024 backtest)

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_model_drift_alert` AS

WITH baseline_period AS (
  -- Baseline MAE values for drift detection
  -- Top of Funnel (ARIMA_PLUS): Historical performance from ARIMA models
  -- Bottom of Funnel (V2 Challenger): Q3 2024 backtest results
  --   - V2 Forecast: 9.01 SQOs, Actual: 6 SQOs = 3.01 absolute error
  --   - Baseline: 3.01 / 13 SQLs ≈ 0.23 MAE per SQL
  SELECT
    0.09 AS baseline_mql_mae,  -- ARIMA_PLUS (Top of Funnel): Historical performance
    0.04 AS baseline_sql_mae,  -- ARIMA_PLUS (Top of Funnel): Historical performance
    0.23 AS baseline_sqos_mae  -- V2 Challenger (Bottom of Funnel): Q3 2024 backtest baseline
  FROM (SELECT 1)
),

recent_period AS (
  -- Compare against the last 7 days
  SELECT
    AVG(ABS(mqls_actual - mqls_combined)) AS recent_mql_mae,
    AVG(ABS(sqls_actual - sqls_combined)) AS recent_sql_mae,
    AVG(ABS(sqos_actual - sqos_combined)) AS recent_sqos_mae
  FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
  WHERE data_type = 'ACTUAL'
    AND date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
)

SELECT
  r.recent_mql_mae,
  b.baseline_mql_mae,
  SAFE_DIVIDE(r.recent_mql_mae, b.baseline_mql_mae) AS mql_drift_ratio,
  
  r.recent_sql_mae,
  b.baseline_sql_mae,
  SAFE_DIVIDE(r.recent_sql_mae, b.baseline_sql_mae) AS sql_drift_ratio,
  
  r.recent_sqos_mae,
  b.baseline_sqos_mae,
  SAFE_DIVIDE(r.recent_sqos_mae, b.baseline_sqos_mae) AS sqo_drift_ratio,
  
  -- Alert status for MQL model
  CASE
    WHEN SAFE_DIVIDE(r.recent_mql_mae, b.baseline_mql_mae) > 2.0 THEN 'RETRAIN_RECOMMENDED'
    WHEN SAFE_DIVIDE(r.recent_mql_mae, b.baseline_mql_mae) > 1.5 THEN 'DRIFT_WARNING'
    ELSE 'STABLE'
  END AS mql_model_status,
  
  -- Alert status for SQL model
  CASE
    WHEN SAFE_DIVIDE(r.recent_sql_mae, b.baseline_sql_mae) > 2.0 THEN 'RETRAIN_RECOMMENDED'
    WHEN SAFE_DIVIDE(r.recent_sql_mae, b.baseline_sql_mae) > 1.5 THEN 'DRIFT_WARNING'
    ELSE 'STABLE'
  END AS sql_model_status,
  
  -- Alert status for SQO model (V2 Challenger - Bottom of Funnel)
  CASE
    WHEN SAFE_DIVIDE(r.recent_sqos_mae, b.baseline_sqos_mae) > 2.0 THEN 'RETRAIN_RECOMMENDED'
    WHEN SAFE_DIVIDE(r.recent_sqos_mae, b.baseline_sqos_mae) > 1.5 THEN 'DRIFT_WARNING'
    ELSE 'STABLE'
  END AS sqo_model_status,  -- V2 Challenger Model drift status
  
  CURRENT_TIMESTAMP() AS evaluated_at
  
FROM recent_period r
CROSS JOIN baseline_period b;

