-- Simple forecast regeneration with October-inclusive training
DELETE FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE forecast_date = CURRENT_DATE();

INSERT INTO `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WITH 
mql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS mqls_forecast_raw,
    prediction_interval_lower_bound AS mqls_lower_raw,
    prediction_interval_upper_bound AS mqls_upper_raw
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
sql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS sqls_forecast_raw,
    prediction_interval_lower_bound AS sqls_lower_raw,
    prediction_interval_upper_bound AS sqls_upper_raw
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
caps AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    mql_cap_recommended,
    sql_cap_recommended,
    sqo_cap_recommended
  FROM `savvy-gtm-analytics.savvy_forecast.daily_cap_reference`
),
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
  FROM mql_forecast m
  FULL OUTER JOIN sql_forecast s
    ON m.Channel_Grouping_Name = s.Channel_Grouping_Name
    AND m.Original_source = s.Original_source
    AND m.date_day = s.date_day
  LEFT JOIN caps c
    ON COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) = c.Channel_Grouping_Name
    AND COALESCE(m.Original_source, s.Original_source) = c.Original_source
),
trailing_rates_latest AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    s2q_rate_selected AS sql_to_sqo_rate
  FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
  WHERE date_day = CURRENT_DATE()
)
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

