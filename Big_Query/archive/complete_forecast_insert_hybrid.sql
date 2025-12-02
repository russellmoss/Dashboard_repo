-- Step 5.1: Hybrid Forecast Pipeline
-- Combines ARIMA models for healthy segments with heuristic for sparse segments

-- Delete any existing forecast for today
DELETE FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE forecast_date = CURRENT_DATE();

-- Now insert the hybrid forecast
INSERT INTO `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WITH 
-- Get ARIMA forecasts for healthy segments
arima_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS mqls_forecast_raw,
    prediction_interval_lower_bound AS mqls_lower_raw,
    prediction_interval_upper_bound AS mqls_upper_raw,
    'ARIMA' AS forecast_method
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
arima_sql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS sqls_forecast_raw,
    prediction_interval_lower_bound AS sqls_lower_raw,
    prediction_interval_upper_bound AS sqls_upper_raw,
    'ARIMA' AS forecast_method
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
-- Get heuristic forecasts for sparse segments
heuristic_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    mqls_forecast AS mqls_forecast_raw,
    mqls_forecast * 0.7 AS mqls_lower_raw,
    mqls_forecast * 1.3 AS mqls_upper_raw,
    'Heuristic' AS forecast_method
  FROM `savvy-gtm-analytics.savvy_forecast.vw_heuristic_forecast`
  WHERE date_day >= CURRENT_DATE()
),
heuristic_sql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    sqls_forecast AS sqls_forecast_raw,
    sqls_forecast * 0.7 AS sqls_lower_raw,
    sqls_forecast * 1.3 AS sqls_upper_raw,
    'Heuristic' AS forecast_method
  FROM `savvy-gtm-analytics.savvy_forecast.vw_heuristic_forecast`
  WHERE date_day >= CURRENT_DATE()
),
-- Get caps
caps AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    mql_cap_recommended,
    sql_cap_recommended,
    sqo_cap_recommended
  FROM `savvy-gtm-analytics.savvy_forecast.daily_cap_reference`
),
-- Combine all forecasts
all_forecasts AS (
  SELECT
    COALESCE(am.Channel_Grouping_Name, hm.Channel_Grouping_Name) AS Channel_Grouping_Name,
    COALESCE(am.Original_source, hm.Original_source) AS Original_source,
    COALESCE(am.date_day, hm.date_day) AS date_day,
    COALESCE(am.mqls_forecast_raw, hm.mqls_forecast_raw, 0) AS mqls_forecast_raw,
    COALESCE(am.mqls_lower_raw, hm.mqls_lower_raw, 0) AS mqls_lower_raw,
    COALESCE(am.mqls_upper_raw, hm.mqls_upper_raw, 0) AS mqls_upper_raw,
    COALESCE(am.forecast_method, hm.forecast_method) AS mql_method
  FROM arima_forecast am
  FULL OUTER JOIN heuristic_forecast hm
    ON am.Channel_Grouping_Name = hm.Channel_Grouping_Name
    AND am.Original_source = hm.Original_source
    AND am.date_day = hm.date_day
),
all_sql_forecasts AS (
  SELECT
    COALESCE(am.Channel_Grouping_Name, hm.Channel_Grouping_Name) AS Channel_Grouping_Name,
    COALESCE(am.Original_source, hm.Original_source) AS Original_source,
    COALESCE(am.date_day, hm.date_day) AS date_day,
    COALESCE(am.sqls_forecast_raw, hm.sqls_forecast_raw, 0) AS sqls_forecast_raw,
    COALESCE(am.sqls_lower_raw, hm.sqls_lower_raw, 0) AS sqls_lower_raw,
    COALESCE(am.sqls_upper_raw, hm.sqls_upper_raw, 0) AS sqls_upper_raw,
    COALESCE(am.forecast_method, hm.forecast_method) AS sql_method
  FROM arima_sql_forecast am
  FULL OUTER JOIN heuristic_sql_forecast hm
    ON am.Channel_Grouping_Name = hm.Channel_Grouping_Name
    AND am.Original_source = hm.Original_source
    AND am.date_day = hm.date_day
),
-- Apply caps
capped_forecasts AS (
  SELECT
    COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) AS Channel_Grouping_Name,
    COALESCE(m.Original_source, s.Original_source) AS Original_source,
    COALESCE(m.date_day, s.date_day) AS date_day,
    LEAST(GREATEST(0, m.mqls_forecast_raw), COALESCE(c.mql_cap_recommended, 10)) AS mqls_forecast,
    GREATEST(0, m.mqls_lower_raw) AS mqls_lower,
    LEAST(m.mqls_upper_raw, COALESCE(c.mql_cap_recommended, 10) * 1.5) AS mqls_upper,
    LEAST(GREATEST(0, s.sqls_forecast_raw), COALESCE(c.sql_cap_recommended, 5)) AS sqls_forecast,
    GREATEST(0, s.sqls_lower_raw) AS sqls_lower,
    LEAST(s.sqls_upper_raw, COALESCE(c.sql_cap_recommended, 5) * 1.5) AS sqls_upper,
    COALESCE(c.mql_cap_recommended, 10) AS mql_cap_applied,
    COALESCE(c.sql_cap_recommended, 5) AS sql_cap_applied,
    COALESCE(c.sqo_cap_recommended, 3) AS sqo_cap_applied
  FROM all_forecasts m
  FULL OUTER JOIN all_sql_forecasts s
    ON m.Channel_Grouping_Name = s.Channel_Grouping_Name
    AND m.Original_source = s.Original_source
    AND m.date_day = s.date_day
  LEFT JOIN caps c
    ON COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) = c.Channel_Grouping_Name
    AND COALESCE(m.Original_source, s.Original_source) = c.Original_source
),
-- Get conversion rates
trailing_rates_latest AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    s2q_rate_selected AS sql_to_sqo_rate
  FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
  WHERE date_day = CURRENT_DATE()
)
-- Final output
SELECT 
  CURRENT_DATE() AS forecast_date,
  CURRENT_TIMESTAMP() AS forecast_version,
  c.Channel_Grouping_Name,
  c.Original_source,
  c.date_day,
  c.mqls_forecast,
  c.mqls_lower,
  c.mqls_upper,
  c.sqls_forecast,
  c.sqls_lower,
  c.sqls_upper,
  -- Use segment-specific conversion rate
  COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) AS sqos_forecast,
  GREATEST(0, COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) * 0.7) AS sqos_lower,
  COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) * 1.3 AS sqos_upper,
  c.mql_cap_applied,
  c.sql_cap_applied,
  c.sqo_cap_applied AS sqo_cap_applied
FROM capped_forecasts c
LEFT JOIN trailing_rates_latest r
  ON c.Channel_Grouping_Name = r.Channel_Grouping_Name
  AND c.Original_source = r.Original_source;

