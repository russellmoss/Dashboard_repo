-- This view unpivots the main funnel table to create a single timeline of events.
-- Each UNION ALL block represents a distinct funnel stage, anchored to its specific event date.
WITH base AS (
  SELECT
    -- Channel remap: include NULL/Other in Ecosystem
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound'  THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS channel_grouping_name,

    Original_source AS lead_original_source,
    Full_prospect_id__c,

    -- Flags from funnel view
    CAST(is_contacted AS INT64) AS is_contacted,
    CAST(is_mql AS INT64) AS is_mql,
    CAST(is_sql AS INT64) AS is_sql,
    CAST(is_sqo AS INT64) AS is_sqo,
    CAST(is_joined AS INT64) AS is_joined,

    -- Outcomes
    Underwritten_AUM__c,

    -- Stage dates (use DATE() to normalize types)
    DATE(FilterDate) AS filter_date_d,
    DATE(mql_stage_entered_ts) AS mql_stage_entered_d,
    DATE(converted_date_raw) AS converted_date_d,
    DATE(Date_Became_SQO__c) AS date_became_sqo_d,
    DATE(advisor_join_date__c) AS advisor_join_date_d,
    DATE(Stage_Entered_Signed__c) AS stage_entered_signed_d
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
)

-- 1) Prospects & Contacted rows (event_date = FilterDate)
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  filter_date_d AS event_date,

  1 AS prospects,
  is_contacted AS contacted,
  0 AS mql,
  0 AS sql,
  0 AS sqo,
  0 AS joined,
  CAST(0 AS NUMERIC) AS signed_aum
FROM base
WHERE filter_date_d IS NOT NULL
  -- FIX: Exclude records with no valid prospect ID to ensure accurate counts
  AND Full_prospect_id__c IS NOT NULL

UNION ALL

-- 2) MQL rows (event_date = mql_stage_entered_ts)
-- FIX: Separated MQL into its own block to align with scorecard logic
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  mql_stage_entered_d AS event_date,

  0 AS prospects,
  0 AS contacted,
  is_mql AS mql,
  0 AS sql,
  0 AS sqo,
  0 AS joined,
  CAST(0 AS NUMERIC) AS signed_aum
FROM base
WHERE mql_stage_entered_d IS NOT NULL

UNION ALL

-- 3) SQL rows (event_date = converted_date_raw)
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  converted_date_d AS event_date,

  0 AS prospects,
  0 AS contacted,
  0 AS mql,
  is_sql AS sql,
  0 AS sqo,
  0 AS joined,
  CAST(0 AS NUMERIC) AS signed_aum
FROM base
WHERE converted_date_d IS NOT NULL

UNION ALL

-- 4) SQO rows (event_date = Date_Became_SQO__c)
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  date_became_sqo_d AS event_date,

  0 AS prospects,
  0 AS contacted,
  0 AS mql,
  0 AS sql,
  is_sqo AS sqo,
  0 AS joined,
  CAST(0 AS NUMERIC) AS signed_aum
FROM base
WHERE date_became_sqo_d IS NOT NULL

UNION ALL

-- 5) Joined rows (event_date = advisor_join_date__c)
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  advisor_join_date_d AS event_date,

  0 AS prospects,
  0 AS contacted,
  0 AS mql,
  0 AS sql,
  0 AS sqo,
  is_joined AS joined,
  CAST(0 AS NUMERIC) AS signed_aum
FROM base
WHERE advisor_join_date_d IS NOT NULL

UNION ALL

-- 6) Signed AUM rows (event_date = Stage_Entered_Signed__c)
SELECT
  channel_grouping_name,
  lead_original_source,
  Full_prospect_id__c,
  stage_entered_signed_d AS event_date,

  0 AS prospects,
  0 AS contacted,
  0 AS mql,
  0 AS sql,
  0 AS sqo,
  0 AS joined,
  COALESCE(Underwritten_AUM__c, 0) AS signed_aum
FROM base
WHERE stage_entered_signed_d IS NOT NULL
