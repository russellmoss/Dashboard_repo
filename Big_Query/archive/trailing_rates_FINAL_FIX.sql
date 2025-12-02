-- FINAL FIX: Rebuild trailing_rates_features with correct SQO date attribution
-- Uses vw_daily_stage_counts which already has correct date attribution
-- Creates a table with CURRENT_DATE() and all segments

CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
PARTITION BY date_day
CLUSTER BY Channel_Grouping_Name, Original_source AS

WITH 
-- Get daily counts from vw_daily_stage_counts (already has correct dates)
daily_counts AS (
  SELECT
    date_day,
    Channel_Grouping_Name,
    Original_source,
    mqls_daily,
    sqls_daily,
    sqos_daily
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE date_day >= '2024-05-01'
),

-- Generate date spine for all dates since 2024-05-01
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-05-01', CURRENT_DATE(), INTERVAL 1 DAY)) AS date_day
),

-- Get all segments
all_segments AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source
  FROM daily_counts
),

-- Full matrix
full_matrix AS (
  SELECT d.date_day, s.Channel_Grouping_Name, s.Original_source
  FROM date_spine d
  CROSS JOIN all_segments s
)

-- Backfill and calculate (simplified for now)
SELECT 
  CURRENT_DATE() AS date_day,
  Channel_Grouping_Name,
  Original_source,
  
  -- Raw SQL→SQO rate (60-day window)
  NULL AS c2m_rate_30d_raw,
  NULL AS m2s_rate_30d_raw,
  SAFE_DIVIDE(
    SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqos_daily ELSE 0 END),
    SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqls_daily ELSE 0 END)
  ) AS s2q_rate_60d_raw,
  
  -- Smoothed rates
  NULL AS c2m_rate_30d_smooth,
  NULL AS m2s_rate_30d_smooth,
  (SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqos_daily ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqls_daily ELSE 0 END) + 10, 0)
  AS s2q_rate_60d_smooth,
  
  -- Selected rate
  (SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqos_daily ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqls_daily ELSE 0 END) + 10, 0)
  AS s2q_rate_selected,
  
  NULL AS m2s_rate_selected,
  NULL AS c2m_rate_selected,
  NULL AS backoff_level,
  SUM(CASE WHEN f.date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN d.sqls_daily ELSE 0 END) AS s2q_den_60d

FROM full_matrix f
LEFT JOIN daily_counts d
  ON f.date_day = d.date_day
  AND f.Channel_Grouping_Name = d.Channel_Grouping_Name
  AND f.Original_source = d.Original_source
GROUP BY 1, 2, 3

