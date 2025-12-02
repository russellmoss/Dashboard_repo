-- ===================================================================
-- BIGQUERY CLEANUP SCRIPT
-- Dataset: savvy-gtm-analytics.savvy_forecast
-- Date: October 30, 2025
-- Purpose: Remove obsolete development/test models and tables
-- ===================================================================

-- ⚠️ IMPORTANT: Review VERIFICATION_RESULTS.md before running
-- All production objects have been verified as healthy

-- ===================================================================
-- PHASE 1: Remove Development/Test Models (5 models)
-- ===================================================================

-- 1. Remove test model (replaced by production model)
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_simple`;

-- 2. Remove backtest ARIMA models (no longer needed)
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_arima_mqls_bt`;
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_arima_sqls_bt`;

-- 3. Remove backtest propensity model (no longer needed)
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_bt`;

-- 4. Remove explain-only model (feature importance check complete)
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_explain`;

-- ===================================================================
-- PHASE 2: Remove Obsolete Tables (1 table)
-- ===================================================================

-- 5. Remove old train/test split table (obsolete)
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_split`;

-- ===================================================================
-- PHASE 3: Remove Legacy Views (1 view)
-- ===================================================================

-- 6. Remove old capped forecasts view (superseded by vw_production_forecast)
DROP VIEW IF EXISTS `savvy-gtm-analytics.savvy_forecast.vw_forecasts_capped`;

-- ===================================================================
-- VERIFICATION: Count Remaining Objects
-- ===================================================================

-- After cleanup, run these queries to verify:
-- SELECT COUNT(*) as remaining_models
-- FROM `savvy-gtm-analytics.savvy_forecast.INFORMATION_SCHEMA.MODELS`;

-- SELECT COUNT(*) as remaining_tables
-- FROM `savvy-gtm-analytics.savvy_forecast.INFORMATION_SCHEMA.TABLES`
-- WHERE table_type = 'BASE TABLE';

-- SELECT COUNT(*) as remaining_views
-- FROM `savvy-gtm-analytics.savvy_forecast.INFORMATION_SCHEMA.TABLES`
-- WHERE table_type = 'VIEW';

-- Expected Results After Cleanup:
-- Models: 3 (down from 8)
-- Tables: 7 (down from 8)
-- Views: 12 (down from 13)
-- Total: 22 objects (down from 29)

-- ===================================================================
-- VERIFICATION: Test Production Objects Still Work
-- ===================================================================

-- After cleanup, run these queries to verify production objects:

-- 1. Test daily_forecasts table
-- SELECT COUNT(*) FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`;

-- 2. Test trailing_rates_features table
-- SELECT COUNT(*) FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
-- WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- 3. Test production view
-- SELECT COUNT(*) FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
-- WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- 4. Test monitoring views
-- SELECT * FROM `savvy-gtm-analytics.savvy_forecast.vw_model_performance` LIMIT 1;
-- SELECT * FROM `savvy-gtm-analytics.savvy_forecast.vw_data_quality_monitoring` LIMIT 1;
-- SELECT * FROM `savvy-gtm-analytics.savvy_forecast.vw_model_drift_alert` LIMIT 1;

-- ===================================================================
-- POST-CLEANUP VERIFICATION QUERIES
-- ===================================================================

-- Run these after cleanup to verify everything still works:

-- Query 1: Verify production forecast exists
SELECT 
  'Post-Cleanup: Forecast Status' AS check_type,
  COUNT(*) AS row_count,
  MAX(forecast_date) AS latest_forecast
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`;

-- Query 2: Verify trailing rates work
SELECT 
  'Post-Cleanup: Trailing Rates' AS check_type,
  COUNT(*) AS row_count,
  MAX(date_day) AS latest_date
FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- Query 3: Verify production view works
SELECT 
  'Post-Cleanup: Production View' AS check_type,
  COUNT(*) AS row_count,
  SUM(CASE WHEN data_type = 'ACTUAL' THEN 1 ELSE 0 END) AS actual_rows,
  SUM(CASE WHEN data_type = 'FORECAST' THEN 1 ELSE 0 END) AS forecast_rows
FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- Query 4: Verify monitoring views work
SELECT 
  'Post-Cleanup: Model Performance' AS check_type,
  COUNT(*) AS segment_count,
  AVG(recent_mql_mae) AS avg_mql_mae
FROM `savvy-gtm-analytics.savvy_forecast.vw_model_performance`;

-- ===================================================================
-- COMPLETION SUMMARY
-- ===================================================================

-- Objects Removed: 7
-- Models Removed: 5
-- Tables Removed: 1
-- Views Removed: 1

-- Objects Remaining: 22
-- Production Models: 3 (model_arima_mqls, model_arima_sqls, model_sql_sqo_propensity)
-- Production Tables: 7
-- Production Views: 12

-- Expected Benefits:
-- - Cleaner dataset (no obsolete objects)
-- - Less confusion (only production objects)
-- - Slightly lower storage costs
-- - Faster catalog queries

