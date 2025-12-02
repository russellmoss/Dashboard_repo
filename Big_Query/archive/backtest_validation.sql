-- Walk-forward backtest for the *complete, fixed* hybrid model
DECLARE start_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY);
DECLARE end_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- Staging table for per-window forecasts
CREATE TEMP TABLE backtest_window_predictions (
  train_end_date DATE,
  forecast_date DATE,
  Channel_Grouping_Name STRING,
  Original_source STRING,
  mqls_forecast FLOAT64,
  sqls_forecast FLOAT64,
  sqos_forecast FLOAT64,
  mqls_actual FLOAT64,
  sqls_actual FLOAT64,
  sqos_actual FLOAT64
);

-- Iterate weekly
FOR rec IN (
  SELECT 
    DATE_SUB(d, INTERVAL 1 DAY) AS train_end_date,
    d AS forecast_start_date
  FROM UNNEST(GENERATE_DATE_ARRAY(start_date, end_date, INTERVAL 7 DAY)) AS d
) DO

  -- 1. Train ARIMA MQL model (no regressors)
  EXECUTE IMMEDIATE '''
    CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls_bt`
    OPTIONS(
      model_type = 'ARIMA_PLUS',
      time_series_timestamp_col = 'date_day',
      time_series_data_col = 'mqls_daily',
      time_series_id_col = [''Channel_Grouping_Name'', ''Original_source''],
      horizon = 7,
      auto_arima = TRUE,
      auto_arima_max_order = 5,
      decompose_time_series = TRUE,
      clean_spikes_and_dips = TRUE
    ) AS
    SELECT date_day, Channel_Grouping_Name, Original_source, mqls_daily
    FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
    WHERE date_day <= "''' || CAST(rec.train_end_date AS STRING) || '''"
      AND Channel_Grouping_Name IS NOT NULL AND Original_source IS NOT NULL''';

  -- 2. Train ARIMA SQL model (no regressors)
  EXECUTE IMMEDIATE '''
    CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls_bt`
    OPTIONS(
      model_type = 'ARIMA_PLUS',
      time_series_timestamp_col = 'date_day',
      time_series_data_col = 'sqls_daily',
      time_series_id_col = [''Channel_Grouping_Name'', ''Original_source''],
      horizon = 7,
      auto_arima = TRUE,
      auto_arima_max_order = 5,
      decompose_time_series = TRUE,
      clean_spikes_and_dips = TRUE
    ) AS
    SELECT date_day, Channel_Grouping_Name, Original_source, sqls_daily
    FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
    WHERE date_day <= "''' || CAST(rec.train_end_date AS STRING) || '''"
      AND Channel_Grouping_Name IS NOT NULL AND Original_source IS NOT NULL''';

  -- 3. Train Propensity Model (fixed version)
  EXECUTE IMMEDIATE '''
    CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_bt`
    OPTIONS(
      model_type = 'BOOSTED_TREE_CLASSIFIER',
      input_label_cols = ['label'],
      enable_global_explain = TRUE,
      auto_class_weights = TRUE,
      max_iterations = 50,
      learn_rate = 0.05,
      max_tree_depth = 6
    ) AS
    SELECT
      label,
      COALESCE(trailing_sql_sqo_rate, 0.0) AS trailing_sql_sqo_rate,
      COALESCE(trailing_mql_sql_rate, 0.0) AS trailing_mql_sql_rate,
      same_day_sql_count,
      sql_count_7d,
      day_of_week,
      month,
      is_business_day,
      log_rep_years,
      log_rep_aum,
      log_rep_clients,
      rep_aum_growth_1y,
      rep_hnw_client_count,
      log_firm_aum,
      log_firm_reps,
      firm_aum_growth_1y,
      is_lead_converted,
      is_opp_direct,
      combined_growth,
      days_in_sql_stage,
      mapping_confidence
    FROM `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training`
    WHERE label IS NOT NULL AND sql_date <= "''' || CAST(rec.train_end_date AS STRING) || '''"''';

  -- 4. Generate forecasts for the next 7 days
  INSERT INTO backtest_window_predictions (train_end_date, forecast_date, Channel_Grouping_Name, Original_source, mqls_forecast, sqls_forecast)
  SELECT
    rec.train_end_date,
    CAST(f_mql.forecast_timestamp AS DATE) AS forecast_date,
    COALESCE(f_mql.Channel_Grouping_Name, f_sql.Channel_Grouping_Name) AS Channel_Grouping_Name,
    COALESCE(f_mql.Original_source, f_sql.Original_source) AS Original_source,
    GREATEST(0, f_mql.forecast_value) AS mqls_forecast,
    GREATEST(0, f_sql.forecast_value) AS sqls_forecast
  FROM ML.FORECAST(MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls_bt`) f_mql
  FULL OUTER JOIN ML.FORECAST(MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls_bt`) f_sql
    ON f_mql.Channel_Grouping_Name = f_sql.Channel_Grouping_Name
    AND f_mql.Original_source = f_sql.Original_source
    AND f_mql.forecast_timestamp = f_sql.forecast_timestamp;

  -- 5. Build features for propensity model
  CREATE TEMP TABLE propensity_input_bt AS
  WITH 
  segment_enrichment_bt AS (
    SELECT 
      Channel_Grouping_Name, Original_source,
      AVG(log_rep_years) AS avg_log_rep_years,
      AVG(log_rep_aum) AS avg_log_rep_aum,
      AVG(log_rep_clients) AS avg_log_rep_clients,
      AVG(COALESCE(rep_aum_growth_1y, 0)) AS avg_rep_aum_growth_1y,
      AVG(COALESCE(rep_hnw_client_count, 0)) AS avg_rep_hnw_client_count,
      AVG(log_firm_aum) AS avg_log_firm_aum,
      AVG(log_firm_reps) AS avg_log_firm_reps,
      AVG(COALESCE(firm_aum_growth_1y, 0)) AS avg_firm_aum_growth_1y,
      AVG(is_lead_converted) AS avg_is_lead_converted,
      AVG(is_opp_direct) AS avg_is_opp_direct,
      AVG(COALESCE(combined_growth, 0)) AS avg_combined_growth,
      AVG(mapping_confidence) AS avg_mapping_confidence
    FROM `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training`
    WHERE sql_date <= rec.train_end_date
    GROUP BY 1,2
  )
  SELECT
    p.forecast_date,
    p.Channel_Grouping_Name,
    p.Original_source,
    p.sqls_forecast,
    COALESCE(r.s2q_rate_selected, 0.0) AS trailing_sql_sqo_rate,
    COALESCE(r.m2s_rate_selected, 0.0) AS trailing_mql_sql_rate,
    CAST(ROUND(p.sqls_forecast) AS INT64) AS same_day_sql_count,
    CAST(ROUND(p.sqls_forecast) AS INT64) AS sql_count_7d,
    CAST(EXTRACT(DAYOFWEEK FROM p.forecast_date) AS INT64) AS day_of_week,
    CAST(EXTRACT(MONTH FROM p.forecast_date) AS INT64) AS month,
    CAST(CASE WHEN EXTRACT(DAYOFWEEK FROM p.forecast_date) IN (1, 7) THEN 0 ELSE 1 END AS INT64) AS is_business_day,
    COALESCE(se.avg_log_rep_years, 0.0) AS log_rep_years,
    COALESCE(se.avg_log_rep_aum, 0.0) AS log_rep_aum,
    COALESCE(se.avg_log_rep_clients, 0.0) AS log_rep_clients,
    COALESCE(se.avg_rep_aum_growth_1y, 0.0) AS rep_aum_growth_1y,
    CAST(COALESCE(se.avg_rep_hnw_client_count, 0.0) AS INT64) AS rep_hnw_client_count,
    COALESCE(se.avg_log_firm_aum, 0.0) AS log_firm_aum,
    COALESCE(se.avg_log_firm_reps, 0.0) AS log_firm_reps,
    COALESCE(se.avg_firm_aum_growth_1y, 0.0) AS firm_aum_growth_1y,
    CAST(COALESCE(se.avg_is_lead_converted, 0.0) AS INT64) AS is_lead_converted,
    CAST(COALESCE(se.avg_is_opp_direct, 0.0) AS INT64) AS is_opp_direct,
    COALESCE(se.avg_combined_growth, 0.0) AS combined_growth,
    CAST(0 AS INT64) AS days_in_sql_stage,
    COALESCE(se.avg_mapping_confidence, 0.0) AS avg_mapping_confidence
  FROM backtest_window_predictions p
  LEFT JOIN `savvy-gtm-analytics.savvy_forecast.trailing_rates_features` r
    ON r.date_day = rec.train_end_date
    AND p.Channel_Grouping_Name = r.Channel_Grouping_Name
    AND p.Original_source = r.Original_source
  LEFT JOIN segment_enrichment_bt se
    ON p.Channel_Grouping_Name = se.Channel_Grouping_Name
    AND p.Original_source = se.Original_source
  WHERE p.train_end_date = rec.train_end_date;

  -- 6. Predict SQOs for the 7-day window
  CREATE TEMP TABLE sqo_predictions_bt AS
  SELECT
    i.forecast_date,
    i.Channel_Grouping_Name,
    i.Original_source,
    (i.sqls_forecast * predicted_label_probs[OFFSET(1)].prob) AS sqos_forecast
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_bt`,
    (
      SELECT 
        * EXCEPT(avg_mapping_confidence),
        avg_mapping_confidence AS mapping_confidence
      FROM propensity_input_bt
    )
  ) p
  JOIN propensity_input_bt i
    ON i.Channel_Grouping_Name = p.Channel_Grouping_Name
    AND i.Original_source = p.Original_source
    AND i.forecast_date = p.forecast_date;

  -- 7. Merge SQO forecasts and all actuals into the staging table
  UPDATE backtest_window_predictions t
  SET 
    t.sqos_forecast = p.sqos_forecast,
    t.mqls_actual = a.mqls_daily,
    t.sqls_actual = a.sqls_daily,
    t.sqos_actual = a.sqos_daily
  FROM sqo_predictions_bt p
  JOIN `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts` a
    ON p.forecast_date = a.date_day
    AND p.Channel_Grouping_Name = a.Channel_Grouping_Name
    AND p.Original_source = a.Original_source
  WHERE t.train_end_date = rec.train_end_date
    AND t.forecast_date = p.forecast_date
    AND t.Channel_Grouping_Name = p.Channel_Grouping_Name
    AND t.Original_source = p.Original_source;

END FOR;

-- 8. Create the final summary report
CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.backtest_results` AS
SELECT
  Channel_Grouping_Name,
  Original_source,
  COUNT(DISTINCT train_end_date) AS num_backtests,
  
  -- MAPE (Mean Absolute Percentage Error)
  AVG(ABS(mqls_actual - mqls_forecast) / NULLIF(mqls_actual, 0)) AS mqls_mape,
  AVG(ABS(sqls_actual - sqls_forecast) / NULLIF(sqls_actual, 0)) AS sqls_mape,
  AVG(ABS(sqos_actual - sqos_forecast) / NULLIF(sqos_actual, 0)) AS sqos_mape,
  
  -- MAE (Mean Absolute Error)
  AVG(ABS(mqls_actual - mqls_forecast)) AS mqls_mae,
  AVG(ABS(sqls_actual - sqls_forecast)) AS sqls_mae,
  AVG(ABS(sqos_actual - sqos_forecast)) AS sqos_mae,
  
  -- Totals
  SUM(mqls_actual) AS total_mqls_actual,
  SUM(mqls_forecast) AS total_mqls_forecast,
  SUM(sqls_actual) AS total_sqls_actual,
  SUM(sqls_forecast) AS total_sqls_forecast,
  SUM(sqos_actual) AS total_sqos_actual,
  SUM(sqos_forecast) AS total_sqos_forecast,
  
  CURRENT_TIMESTAMP() AS backtest_run_time
FROM backtest_window_predictions
WHERE mqls_actual IS NOT NULL OR sqls_actual IS NOT NULL OR sqos_actual IS NOT NULL
GROUP BY 1, 2
ORDER BY sqos_mape DESC;

