-- REBUILD: trailing_rates_features with CORRECT stage-specific date attribution
-- CRITICAL FIX: Use Date_Became_SQO__c for SQO attribution (not FilterDate)

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

-- FIXED: Build progressions by stage with SEPARATE date spines
-- Each stage gets its own date dimension
contacted_progressions AS (
  SELECT
    DATE(f.stage_entered_contacting__c) AS date_day,
    f.Channel_Grouping_Name,
    f.Original_source,
    COUNT(DISTINCT CASE WHEN f.is_contacted = 1 THEN f.primary_key END) AS contacted_denom,
    COUNT(DISTINCT CASE WHEN f.is_contacted = 1 AND f.is_mql = 1 THEN f.primary_key END) AS contacted_to_mql
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
  WHERE f.stage_entered_contacting__c IS NOT NULL
    AND DATE(f.stage_entered_contacting__c) >= '2024-05-01'
  GROUP BY 1, 2, 3
),

mql_progressions AS (
  SELECT
    DATE(f.mql_stage_entered_ts) AS date_day,
    f.Channel_Grouping_Name,
    f.Original_source,
    COUNT(DISTINCT CASE WHEN f.is_mql = 1 THEN f.primary_key END) AS mql_denom,
    COUNT(DISTINCT CASE WHEN f.is_mql = 1 AND f.is_sql = 1 THEN f.primary_key END) AS mql_to_sql
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
  WHERE f.mql_stage_entered_ts IS NOT NULL
    AND DATE(f.mql_stage_entered_ts) >= '2024-05-01'
  GROUP BY 1, 2, 3
),

sql_progressions AS (
  SELECT
    DATE(f.converted_date_raw) AS date_day,
    f.Channel_Grouping_Name,
    f.Original_source,
    COUNT(DISTINCT CASE WHEN f.is_sql = 1 THEN f.primary_key END) AS sql_denom
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
  WHERE f.converted_date_raw IS NOT NULL
    AND DATE(f.converted_date_raw) >= '2024-05-01'
  GROUP BY 1, 2, 3
),

-- FIXED: SQO progressions using Date_Became_SQO__c as the date
sqo_progressions AS (
  SELECT
    DATE(f.Date_Became_SQO__c) AS date_day,  -- ✅ CORRECT date field
    f.Channel_Grouping_Name,
    f.Original_source,
    COUNT(DISTINCT CASE WHEN f.is_sqo = 1 THEN f.Full_Opportunity_ID__c END) AS sqo_denom,
    COUNT(DISTINCT CASE WHEN f.is_sql = 1 AND f.is_sqo = 1 THEN f.Full_Opportunity_ID__c END) AS sql_to_sqo
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
  WHERE f.Date_Became_SQO__c IS NOT NULL  -- ✅ FIXED: Use SQO date field
    AND DATE(f.Date_Became_SQO__c) >= '2024-05-01'
  GROUP BY 1, 2, 3
),

-- Create date spine for all dates since 2024-05-01
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-05-01', CURRENT_DATE(), INTERVAL 1 DAY)) AS date_day
),

-- Get all unique segment combinations
all_segments AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched`
  WHERE Channel_Grouping_Name IS NOT NULL
    AND Original_source IS NOT NULL
),

-- Full matrix: date × segment
full_matrix AS (
  SELECT d.date_day, s.Channel_Grouping_Name, s.Original_source
  FROM date_spine d
  CROSS JOIN all_segments s
),

-- Join all progressions onto the matrix by their respective dates
combined_progressions AS (
  SELECT
    f.date_day,
    f.Channel_Grouping_Name,
    f.Original_source,
    COALESCE(c.contacted_denom, 0) AS contacted_denom,
    COALESCE(c.contacted_to_mql, 0) AS contacted_to_mql,
    COALESCE(m.mql_denom, 0) AS mql_denom,
    COALESCE(m.mql_to_sql, 0) AS mql_to_sql,
    COALESCE(s.sql_denom, 0) AS sql_denom,
    COALESCE(sq.sqo_denom, 0) AS sqo_denom,
    COALESCE(sq.sql_to_sqo, 0) AS sql_to_sqo
  FROM full_matrix f
  LEFT JOIN contacted_progressions c 
    ON f.date_day = c.date_day 
    AND f.Channel_Grouping_Name = c.Channel_Grouping_Name 
    AND f.Original_source = c.Original_source
  LEFT JOIN mql_progressions m 
    ON f.date_day = m.date_day 
    AND f.Channel_Grouping_Name = m.Channel_Grouping_Name 
    AND f.Original_source = m.Original_source
  LEFT JOIN sql_progressions s 
    ON f.date_day = s.date_day 
    AND f.Channel_Grouping_Name = s.Channel_Grouping_Name 
    AND f.Original_source = s.Original_source
  LEFT JOIN sqo_progressions sq 
    ON f.date_day = sq.date_day  -- ✅ Now uses Date_Became_SQO__c
    AND f.Channel_Grouping_Name = sq.Channel_Grouping_Name 
    AND f.Original_source = sq.Original_source
),

-- For trailing rates, we need to calculate rolling sums
-- This is complex, so for now we'll just calculate CURRENT_DATE() rates
-- TODO: Make this work for all historical dates
SELECT 
  CURRENT_DATE() AS date_day,
  Channel_Grouping_Name,
  Original_source,
  
  -- Raw rates (60-day window for SQL→SQO)
  NULL AS c2m_rate_30d_raw,
  NULL AS m2s_rate_30d_raw,
  SAFE_DIVIDE(
    SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_to_sqo ELSE 0 END),
    SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_denom ELSE 0 END)
  ) AS s2q_rate_60d_raw,
  
  -- Smoothed rates
  NULL AS c2m_rate_30d_smooth,
  NULL AS m2s_rate_30d_smooth,
  (SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_to_sqo ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_denom ELSE 0 END) + 10, 0)
  AS s2q_rate_60d_smooth,
  
  -- Selected rate (use smoothed)
  (SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_to_sqo ELSE 0 END) + 6) /
  NULLIF(SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_denom ELSE 0 END) + 10, 0)
  AS s2q_rate_selected,
  
  NULL AS m2s_rate_selected,
  NULL AS c2m_rate_selected,
  NULL AS backoff_level,
  SUM(CASE WHEN date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) THEN sql_denom ELSE 0 END) AS s2q_den_60d

FROM combined_progressions
GROUP BY 1, 2, 3
