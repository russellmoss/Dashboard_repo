-- BigQuery Verification Queries
-- Dataset: savvy-gtm-analytics.savvy_forecast
-- Date: October 30, 2025

-- ===================================================================
-- VERIFICATION QUERY 1: Check current forecast data
-- ===================================================================
SELECT 
  'Current Forecast Status' AS check_type,
  COUNT(*) AS row_count,
  COUNT(DISTINCT forecast_date) AS unique_forecast_dates,
  MAX(forecast_date) AS latest_forecast_date,
  SUM(CASE WHEN forecast_date = CURRENT_DATE() THEN 1 ELSE 0 END) AS todays_forecasts
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`;

-- ===================================================================
-- VERIFICATION QUERY 2: Check trailing rates coverage
-- ===================================================================
SELECT 
  'Trailing Rates Status' AS check_type,
  COUNT(*) AS row_count,
  COUNT(DISTINCT date_day) AS unique_dates,
  MAX(date_day) AS latest_date,
  COUNT(DISTINCT Channel_Grouping_Name) AS unique_channels,
  COUNT(DISTINCT Original_source) AS unique_sources
FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- ===================================================================
-- VERIFICATION QUERY 3: Check production models exist
-- ===================================================================
-- Note: Run this in BigQuery Console to check model existence
-- SELECT model_name, model_type
-- FROM `savvy-gtm-analytics.savvy_forecast.INFORMATION_SCHEMA.MODELS`
-- WHERE model_name IN ('model_arima_mqls', 'model_arima_sqls', 'model_sql_sqo_propensity')
-- ORDER BY creation_time DESC;

-- ===================================================================
-- VERIFICATION QUERY 4: Check backtest results
-- ===================================================================
SELECT 
  'Backtest Status' AS check_type,
  COUNT(*) AS segment_count,
  COUNT(DISTINCT Channel_Grouping_Name) AS unique_channels,
  COUNT(DISTINCT Original_source) AS unique_sources,
  AVG(mqls_mae) AS avg_mql_mae,
  AVG(sqls_mae) AS avg_sql_mae,
  AVG(sqos_mae) AS avg_sqo_mae,
  MAX(backtest_run_time) AS latest_backtest
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`;

-- ===================================================================
-- VERIFICATION QUERY 5: Check training logs
-- ===================================================================
SELECT 
  'Training Logs Status' AS check_type,
  COUNT(*) AS total_logs,
  COUNT(DISTINCT train_date) AS unique_training_dates,
  MAX(train_date) AS latest_training,
  COUNTIF(status = 'SUCCESS') AS successful_trainings,
  COUNTIF(status = 'FAILURE') AS failed_trainings
FROM `savvy-gtm-analytics.savvy_forecast.model_training_log`
WHERE train_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- ===================================================================
-- VERIFICATION QUERY 6: Check production view accessibility
-- ===================================================================
SELECT 
  'Production View Status' AS check_type,
  COUNT(*) AS row_count,
  MIN(date_day) AS earliest_date,
  MAX(date_day) AS latest_date,
  COUNT(DISTINCT date_day) AS unique_dates,
  SUM(CASE WHEN data_type = 'ACTUAL' THEN 1 ELSE 0 END) AS actual_count,
  SUM(CASE WHEN data_type = 'FORECAST' THEN 1 ELSE 0 END) AS forecast_count
FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- ===================================================================
-- VERIFICATION QUERY 7: Check monitoring views work
-- ===================================================================
SELECT 
  'Model Performance' AS check_type,
  COUNT(*) AS segment_count,
  AVG(recent_mql_mae) AS avg_mql_mae,
  AVG(recent_sql_mae) AS avg_sql_mae,
  AVG(recent_sqo_mae) AS avg_sqo_mae,
  COUNTIF(mql_performance_status = 'GOOD') AS good_mql_segments,
  COUNTIF(sqo_performance_status = 'GOOD') AS good_sqo_segments
FROM `savvy-gtm-analytics.savvy_forecast.vw_model_performance`;

SELECT 
  'Data Quality Status' AS check_type,
  *
FROM `savvy-gtm-analytics.savvy_forecast.vw_data_quality_monitoring`;

SELECT 
  'Model Drift Status' AS check_type,
  *
FROM `savvy-gtm-analytics.savvy_forecast.vw_model_drift_alert`;

-- ===================================================================
-- VERIFICATION QUERY 8: Check for any references to backtest models
-- ===================================================================
-- Note: This checks if backtest models are referenced in training logs
SELECT 
  'Backtest Model References' AS check_type,
  COUNT(*) AS reference_count
FROM `savvy-gtm-analytics.savvy_forecast.model_training_log`
WHERE message LIKE '%backtest%' OR message LIKE '%_bt%'
  AND train_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY);

-- ===================================================================
-- VERIFICATION QUERY 9: Check production forecast sums
-- ===================================================================
WITH latest_forecast AS (
  SELECT forecast_date FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  ORDER BY forecast_date DESC LIMIT 1
)
SELECT 
  'Forecast Totals' AS check_type,
  forecast_date,
  COUNT(*) AS row_count,
  SUM(mqls_forecast) AS total_mqls,
  SUM(sqls_forecast) AS total_sqls,
  SUM(sqos_forecast) AS total_sqos,
  COUNT(DISTINCT Channel_Grouping_Name) AS unique_channels,
  COUNT(DISTINCT Original_source) AS unique_sources,
  COUNT(DISTINCT date_day) AS unique_dates
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
CROSS JOIN latest_forecast
WHERE forecast_date = latest_forecast.forecast_date
GROUP BY forecast_date;

-- ===================================================================
-- SUMMARY VERIFICATION
-- ===================================================================
-- Expected Results Summary:
-- ✅ daily_forecasts: Should have data for CURRENT_DATE
-- ✅ trailing_rates_features: Should have last 180 days of data
-- ✅ backtest_results: Should have results from recent backtest
-- ✅ model_training_log: Should have recent SUCCESS entries
-- ✅ vw_production_forecast: Should be accessible and have actuals + forecasts
-- ✅ Monitoring views: Should return data without errors
-- ✅ Forecast totals: Should sum to reasonable values (e.g., ~150-200 MQLs, ~80-100 SQLs, ~50-70 SQOs)

