-- V3.1 SQL Forecast Distributed to Channel/Source Level
-- Takes V3.1 super-segment forecasts and distributes them proportionally
-- to Channel_Grouping_Name × Original_source granularity
--
-- Architecture:
--   1. Get V3.1 forecasts at super-segment level
--   2. Map super-segments to Channel/Source using historical distribution
--   3. Distribute forecast proportionally across Channel/Source combinations

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_v3_1_sql_forecast_by_channel_source` AS

WITH
-- Generate future dates for forecast
future_dates AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY),
    INTERVAL 1 DAY
  )) AS date_day
),

-- Get all super-segments
all_super_segments AS (
  SELECT DISTINCT super_segment
  FROM `savvy-gtm-analytics.savvy_forecast.tof_v3_1_daily_training_data`
),

-- Create full matrix of dates × super-segments
future_matrix AS (
  SELECT fd.date_day, ass.super_segment
  FROM future_dates fd
  CROSS JOIN all_super_segments ass
),

-- Generate features for V3.1 model prediction
forecast_features AS (
  SELECT
    fm.date_day,
    fm.super_segment,
    EXTRACT(DAYOFWEEK FROM fm.date_day) AS day_of_week,
    EXTRACT(DAY FROM fm.date_day) AS day_of_month,
    EXTRACT(MONTH FROM fm.date_day) AS month,
    EXTRACT(YEAR FROM fm.date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM fm.date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    -- Calculate lagged features using historical training data
    AVG(t.target_sqls) OVER (
      PARTITION BY fm.super_segment
      ORDER BY fm.date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS sqls_7day_avg_lag1,
    AVG(t.target_sqls) OVER (
      PARTITION BY fm.super_segment
      ORDER BY fm.date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS sqls_28day_avg_lag1
  FROM future_matrix fm
  LEFT JOIN `savvy-gtm-analytics.savvy_forecast.tof_v3_1_daily_training_data` t
    ON fm.date_day = t.date_day AND fm.super_segment = t.super_segment
),

-- Get V3.1 model predictions at super-segment level
v3_1_super_segment_forecasts AS (
  SELECT
    date_day,
    super_segment,
    predicted_target_sqls AS sqls_forecast_super_segment
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_1_final`,
    (SELECT * FROM forecast_features WHERE date_day >= CURRENT_DATE())
  )
),

-- Get mapping from super-segments to Channel/Source (historical distribution)
super_segment_mapping AS (
  SELECT
    super_segment,
    Channel_Grouping_Name,
    Original_source,
    normalized_fraction,
    super_segment_total,
    -- Calculate total combinations per super-segment for fallback
    COUNT(*) OVER (PARTITION BY super_segment) AS combinations_per_segment
  FROM `savvy-gtm-analytics.savvy_forecast.vw_super_segment_to_channel_source_mapping`
),

-- Distribute V3.1 forecasts from super-segments to Channel/Source
distributed_forecasts AS (
  SELECT
    v3f.date_day,
    sm.Channel_Grouping_Name,
    sm.Original_source,
    v3f.super_segment,
    v3f.sqls_forecast_super_segment,
    COALESCE(
      v3f.sqls_forecast_super_segment * sm.normalized_fraction,
      v3f.sqls_forecast_super_segment / sm.combinations_per_segment  -- Equal distribution fallback
    ) AS sqls_forecast
  FROM v3_1_super_segment_forecasts v3f
  INNER JOIN super_segment_mapping sm
    ON v3f.super_segment = sm.super_segment
)

SELECT
  date_day,
  Channel_Grouping_Name,
  Original_source,
  SUM(sqls_forecast) AS sqls_forecast_v3_1,
  MAX(super_segment) AS source_super_segment  -- For debugging
FROM distributed_forecasts
GROUP BY date_day, Channel_Grouping_Name, Original_source
ORDER BY date_day, Channel_Grouping_Name, Original_source;

