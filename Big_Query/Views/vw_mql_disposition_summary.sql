-- MQL Disposition Summary View
-- Quarter-level summary showing total MQLs and top dispositions
-- Simplified view for quick quarter-over-quarter comparison
-- Shows ALL MQLs, not just non-converting ones

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_summary` AS

WITH
-- 1. Base MQL data with filters applied (ALL MQLs)
MQL_Base AS (
  SELECT
    DATE_TRUNC(DATE(mql_stage_entered_ts), QUARTER) AS mql_quarter,
    CONCAT(
      EXTRACT(YEAR FROM DATE(mql_stage_entered_ts)),
      ' ',
      CASE 
        WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 1 THEN 'Q1'
        WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 2 THEN 'Q2'
        WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 3 THEN 'Q3'
        WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 4 THEN 'Q4'
      END
    ) AS quarter_display,
    COALESCE(Disposition__c, 'No Disposition') AS disposition,
    primary_key,
    is_sql
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE is_mql = 1
    AND COALESCE(SGA_Owner_Name__c, '') != 'Savvy Operations'
    AND mql_stage_entered_ts IS NOT NULL
),

-- 2. Calculate disposition counts per quarter (for ALL MQLs)
Disposition_Counts AS (
  SELECT
    mql_quarter,
    quarter_display,
    disposition,
    COUNT(DISTINCT primary_key) AS disposition_count
  FROM MQL_Base
  GROUP BY 1, 2, 3
),

-- 2b. Calculate conversion metrics
Conversion_Metrics AS (
  SELECT
    mql_quarter,
    quarter_display,
    COUNT(DISTINCT primary_key) AS total_mqls,
    COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END) AS total_converted,
    COUNT(DISTINCT CASE WHEN is_sql = 0 THEN primary_key END) AS total_not_converted,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END), COUNT(DISTINCT primary_key)) * 100, 2) AS overall_conversion_rate_pct
  FROM MQL_Base
  GROUP BY 1, 2
),

-- 3. Get top disposition per quarter
Top_Dispositions AS (
  SELECT
    mql_quarter,
    quarter_display,
    disposition AS top_disposition,
    disposition_count AS top_disposition_count,
    RANK() OVER (PARTITION BY mql_quarter ORDER BY disposition_count DESC) AS rnk
  FROM Disposition_Counts
),

-- 4. Combine conversion metrics with top disposition
Quarter_Summary AS (
  SELECT
    cm.mql_quarter,
    cm.quarter_display,
    cm.total_mqls,
    cm.total_converted,
    cm.total_not_converted,
    cm.overall_conversion_rate_pct,
    td.top_disposition,
    td.top_disposition_count,
    ROUND(SAFE_DIVIDE(td.top_disposition_count, cm.total_mqls) * 100, 2) AS top_disposition_pct,
    (SELECT COUNT(DISTINCT disposition) FROM MQL_Base m2 WHERE m2.mql_quarter = cm.mql_quarter) AS unique_disposition_count
  FROM Conversion_Metrics cm
  LEFT JOIN Top_Dispositions td
    ON cm.mql_quarter = td.mql_quarter
    AND cm.quarter_display = td.quarter_display
    AND td.rnk = 1
)

SELECT
  mql_quarter,
  quarter_display,
  total_mqls,
  total_converted,
  total_not_converted,
  overall_conversion_rate_pct,
  top_disposition,
  top_disposition_count,
  top_disposition_pct,
  unique_disposition_count
FROM Quarter_Summary
ORDER BY mql_quarter DESC

