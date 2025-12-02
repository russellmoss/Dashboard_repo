-- PRODUCTION FIX: trailing_rates_features with correct SQO date attribution
-- This properly uses Date_Became_SQO__c for SQO attribution (not FilterDate)

CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
PARTITION BY date_day
CLUSTER BY Channel_Grouping_Name, Original_source AS

WITH 
-- Active SGA/SGM cohort (excluding Savvy Marketing/Operations)
active_cohort AS (
  SELECT DISTINCT Name 
  FROM `savvy-gtm-analytics.SavvyGTMData.User`
  WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) 
    AND IsActive = TRUE
    AND Name NOT IN ('Savvy Marketing', 'Savvy Operations')
),

-- Use vw_daily_stage_counts which already has correct date attribution
-- This view uses:
-- - MQL: DATE(mql_stage_entered_ts)
-- - SQL: DATE(converted_date_raw)
-- - SQO: DATE(Date_Became_SQO__c) ✅ CORRECT
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

-- Filter for active SGA/SGM owners only (by joining with funnel data)
filtered_counts AS (
  SELECT DISTINCT
    d.date_day,
    d.Channel_Grouping_Name,
    d.Original_source,
    d.mqls_daily,
    d.sqls_daily,
    d.sqos_daily
  FROM daily_counts d
  INNER JOIN `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
    ON (d.date_day IN (
      DATE(f.mql_stage_entered_ts),
      DATE(f.converted_date_raw),
      DATE(f.Date_Became_SQO__c),
      DATE(f.stage_entered_contacting__c),
      DATE(f.FilterDate)
    ))
    AND d.Channel_Grouping_Name = f.Channel_Grouping_Name
    AND d.Original_source = f.Original_source
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
),

-- Generate date spine for all dates since 2024-05-01
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-05-01', CURRENT_DATE(), INTERVAL 1 DAY)) AS date_day
),

-- Get all segment combinations
all_segments AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source
  FROM filtered_counts
),

-- Full matrix
full_matrix AS (
  SELECT d.date_day, s.Channel_Grouping_Name, s.Original_source
  FROM date_spine d
  CROSS JOIN all_segments s
),

-- Backfill counts
daily_progressions AS (
  SELECT
    f.date_day,
    f.Channel_Grouping_Name,
    f.Original_source,
    COALESCE(c.mqls_daily, 0) AS mql_count,
    COALESCE(c.sqls_daily, 0) AS sql_count,
    COALESCE(c.sqos_daily, 0) AS sqo_count
  FROM full_matrix f
  LEFT JOIN filtered_counts c
    ON f.date_day = c.date_day
    AND f.Channel_Grouping_Name = c.Channel_Grouping_Name
    AND f.Original_source = c.Original_source
)

-- Final calculation: Use current date and calculate rolling sums
SELECT 
  CURRENT_DATE() AS date_day,
  Channel_Grouping_Name,
  Original_source,
  
  -- Raw rates (60-day window for SQL→SQO)
  NULL AS c2m_rate_30d_raw,
  NULL AS m2s_rate_30d_raw,
  SAFE_DIVIDE(
    SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sqo_count ELSE 0 END),
    SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_count ELSE 0 END)
  ) AS s2q_rate_60d_raw,
  
  -- Smoothed rates
  NULL AS c2m_rate_30d_smooth,
  NULL AS m2s_rate_30d_smooth,
  (SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sqo_count ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_count ELSE 0 END) + 10, 0)
  AS s2q_rate_60d_smooth,
  
  -- Selected rate
  (SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sqo_count ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_count ELSE 0 END) + 10, 0)
  AS s2q_rate_selected,
  
  NULL AS m2s_rate_selected,
  NULL AS c2m_rate_selected,
  NULL AS backoff_level,
  SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_count ELSE 0 END) AS s2q_den_60d

FROM daily_progressions
GROUP BY 1, 2, 3

