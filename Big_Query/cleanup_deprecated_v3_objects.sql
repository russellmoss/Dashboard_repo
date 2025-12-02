-- ===================================================================
-- CLEANUP SCRIPT: Deprecated V3 and V1 Objects
-- Dataset: savvy-gtm-analytics.savvy_forecast
-- Date: Generated for cleanup
-- Purpose: Remove failed V3 models and deprecated objects
-- ===================================================================

-- ⚠️ IMPORTANT: Review dependencies before running
-- These objects are confirmed deprecated/failed and safe to delete

-- ===================================================================
-- PHASE 1: Remove Failed V3 Models (4 models)
-- ===================================================================

-- Remove failed segment-level V3 models
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_tof_sql_forecast_v3`;
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_tof_sql_classifier_v3`;
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_tof_sql_classifier_v3_calibrated`;
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_classifier_calibrated`;

-- ===================================================================
-- PHASE 2: Remove Deprecated V3 Tables (5 tables)
-- ===================================================================

-- Remove deprecated segment-level training table
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data`;

-- Remove old backtest result tables
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.tof_v3_backtest_results`;
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.tof_v3_backtest_results_corrected`;

-- Remove old prediction analysis tables
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.tof_v3_prediction_analysis`;
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.tof_v3_prediction_analysis_calibrated`;

-- ===================================================================
-- PHASE 3: Remove Deprecated V1 Objects (2 objects)
-- ===================================================================

-- Remove old V1 model (replaced by V2)
DROP MODEL IF EXISTS `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity`;

-- Remove old V1 training table (replaced by V2)
DROP TABLE IF EXISTS `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training`;

-- ===================================================================
-- SUMMARY
-- ===================================================================

-- Total Objects Removed: 11
-- Models Removed: 5 (4 V3 failed + 1 V1 deprecated)
-- Tables Removed: 6 (5 V3 deprecated + 1 V1 deprecated)

-- Remaining Active Objects:
-- Models: 
--   - model_sql_sqo_propensity_v2 (V2 - Active)
--   - model_tof_sql_regressor_v3_daily (V3 - Active)
--   - model_tof_sql_backtest_daily (V3 - Backtest only)
--   - model_arima_mqls (ARIMA - Active)
--   - model_arima_sqls (ARIMA - Active)
--
-- Tables:
--   - tof_v3_daily_training_data_FINAL (V3 - Active)
--   - sql_sqo_propensity_training_v2 (V2 - Active)
--   - daily_forecasts (Production)
--   - trailing_rates_features (Production)
--   - backtest_results (Monitoring)
--   - Other production tables

