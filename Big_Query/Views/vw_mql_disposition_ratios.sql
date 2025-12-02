-- MQL Disposition Ratios View
-- Shows the ratio of different Disposition__c values over total MQLs by quarter
-- Helps analyze why MQL to SQL conversion rates changed over time
-- Shows: "Out of ALL MQLs, what percentage had each disposition?"
-- Filters: is_mql = 1, excludes SGA_Owner_Name__c = 'Savvy Operations'

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios` AS

WITH
-- 1. Base MQL data with filters applied (ALL MQLs, not just non-converting)
MQL_Base AS (
  SELECT
    DATE(mql_stage_entered_ts) AS mql_date,
    DATE_TRUNC(DATE(mql_stage_entered_ts), QUARTER) AS mql_quarter,
    EXTRACT(YEAR FROM DATE(mql_stage_entered_ts)) AS mql_year,
    CASE 
      WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 1 THEN 'Q1'
      WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 2 THEN 'Q2'
      WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 3 THEN 'Q3'
      WHEN EXTRACT(QUARTER FROM DATE(mql_stage_entered_ts)) = 4 THEN 'Q4'
    END AS quarter_label,
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
    Full_prospect_id__c,
    Prospect_Name,
    SGA_Owner_Name__c,
    Channel_Grouping_Name,
    Original_source,
    is_sql
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE is_mql = 1
    AND COALESCE(SGA_Owner_Name__c, '') != 'Savvy Operations'
    AND mql_stage_entered_ts IS NOT NULL
),

-- 2. Calculate total MQLs per quarter (ALL MQLs)
Quarter_Totals AS (
  SELECT
    mql_quarter,
    quarter_display,
    COUNT(DISTINCT primary_key) AS total_mqls
  FROM MQL_Base
  GROUP BY 1, 2
),

-- 3. Calculate disposition counts per quarter (for ALL MQLs with that disposition)
Disposition_Counts AS (
  SELECT
    mql_quarter,
    quarter_display,
    disposition,
    COUNT(DISTINCT primary_key) AS disposition_count,
    -- Also track how many with this disposition converted to SQL
    COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END) AS disposition_count_converted,
    COUNT(DISTINCT CASE WHEN is_sql = 0 THEN primary_key END) AS disposition_count_not_converted
  FROM MQL_Base
  GROUP BY 1, 2, 3
)

-- 4. Final output: Combine totals with disposition counts and calculate ratios
SELECT
  dt.mql_quarter,
  dt.quarter_display,
  dc.disposition,
  dt.total_mqls,
  dc.disposition_count,
  -- Ratio as decimal (0.0 to 1.0) - "Out of ALL MQLs, what % had this disposition?"
  ROUND(SAFE_DIVIDE(dc.disposition_count, dt.total_mqls), 4) AS disposition_ratio,
  -- Ratio as percentage (0.0 to 100.0)
  ROUND(SAFE_DIVIDE(dc.disposition_count, dt.total_mqls) * 100, 2) AS disposition_ratio_pct,
  -- Conversion metrics for this disposition
  dc.disposition_count_converted,
  dc.disposition_count_not_converted,
  -- Conversion rate for MQLs with this disposition
  ROUND(SAFE_DIVIDE(dc.disposition_count_converted, dc.disposition_count) * 100, 2) AS disposition_conversion_rate_pct,
  -- Rank dispositions within each quarter (1 = most common)
  RANK() OVER (PARTITION BY dt.mql_quarter ORDER BY dc.disposition_count DESC) AS disposition_rank

FROM Quarter_Totals dt
INNER JOIN Disposition_Counts dc
  ON dt.mql_quarter = dc.mql_quarter
  AND dt.quarter_display = dc.quarter_display

ORDER BY dt.mql_quarter DESC, dc.disposition_count DESC

