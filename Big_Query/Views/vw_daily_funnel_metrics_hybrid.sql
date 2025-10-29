-- This final version sources all data directly from vw_funnel_lead_to_joined_v2 and
-- includes its own logic for the 'is_sqo' flag to prevent errors.
-- FIX: Uses primary_key instead of Full_prospect_id__c to properly handle opportunity-only records

WITH base_data AS (
  -- Create a base CTE to handle all logic in one place
  SELECT
    primary_key,
    Full_prospect_id__c,
    Underwritten_AUM__c,
    -- Flags from source view
    is_contacted,
    is_mql,
    is_sql,
    is_joined,
    -- Calculate the is_sqo flag directly from the raw field
    CASE WHEN LOWER(SQO_raw) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    -- Dimensions
    Original_source AS lead_original_source,
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound'  THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS channel_grouping_name,
    -- Dates
    DATE(FilterDate) AS filter_date,
    DATE(mql_stage_entered_ts) AS mql_date,
    DATE(converted_date_raw) AS sql_date,
    DATE(Date_Became_SQO__c) AS sqo_date,
    DATE(advisor_join_date__c) AS joined_date,
    DATE(Stage_Entered_Signed__c) AS signed_date
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
),

dates_and_dims AS (
  -- Create a unified list of all possible dates, channels, and sources
  SELECT DISTINCT event_date, channel_grouping_name, lead_original_source FROM (
    SELECT filter_date AS event_date, channel_grouping_name, lead_original_source FROM base_data WHERE filter_date IS NOT NULL UNION ALL
    SELECT mql_date, channel_grouping_name, lead_original_source FROM base_data WHERE mql_date IS NOT NULL UNION ALL
    SELECT sql_date, channel_grouping_name, lead_original_source FROM base_data WHERE sql_date IS NOT NULL UNION ALL
    SELECT sqo_date, channel_grouping_name, lead_original_source FROM base_data WHERE sqo_date IS NOT NULL UNION ALL
    SELECT joined_date, channel_grouping_name, lead_original_source FROM base_data WHERE joined_date IS NOT NULL UNION ALL
    SELECT signed_date, channel_grouping_name, lead_original_source FROM base_data WHERE signed_date IS NOT NULL
  )
),

prospects_daily AS (
  SELECT filter_date AS event_date, channel_grouping_name, lead_original_source,
    COUNT(DISTINCT Full_prospect_id__c) AS prospects,
    COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN Full_prospect_id__c END) AS contacted
  FROM base_data WHERE filter_date IS NOT NULL AND Full_prospect_id__c IS NOT NULL GROUP BY 1, 2, 3
),
mql_daily AS (
  SELECT mql_date AS event_date, channel_grouping_name, lead_original_source,
    COUNT(DISTINCT primary_key) AS mqls
  FROM base_data WHERE is_mql = 1 AND mql_date IS NOT NULL GROUP BY 1, 2, 3
),
sql_daily AS (
  SELECT sql_date AS event_date, channel_grouping_name, lead_original_source,
    COUNT(DISTINCT primary_key) AS sqls
  FROM base_data WHERE is_sql = 1 AND sql_date IS NOT NULL GROUP BY 1, 2, 3
),
sqo_daily AS (
  SELECT sqo_date AS event_date, channel_grouping_name, lead_original_source,
    COUNT(DISTINCT primary_key) AS sqos
  FROM base_data WHERE is_sqo = 1 AND sqo_date IS NOT NULL GROUP BY 1, 2, 3
),
joined_daily AS (
  SELECT joined_date AS event_date, channel_grouping_name, lead_original_source,
    COUNT(DISTINCT primary_key) AS joined
  FROM base_data WHERE is_joined = 1 AND joined_date IS NOT NULL GROUP BY 1, 2, 3
),
aum_daily AS (
  SELECT signed_date AS event_date, channel_grouping_name, lead_original_source,
    SUM(Underwritten_AUM__c) AS signed_aum
  FROM base_data WHERE signed_date IS NOT NULL GROUP BY 1, 2, 3
)

-- Final SELECT: Join all daily metrics onto the master list
SELECT
  d.event_date,
  d.channel_grouping_name,
  d.lead_original_source,
  COALESCE(p.prospects, 0) AS prospects,
  COALESCE(p.contacted, 0) AS contacted,
  COALESCE(m.mqls, 0) AS mqls,
  COALESCE(s.sqls, 0) AS sqls,
  COALESCE(sq.sqos, 0) AS sqos,
  COALESCE(j.joined, 0) AS joined,
  COALESCE(a.signed_aum, 0) AS signed_aum
FROM dates_and_dims d
LEFT JOIN prospects_daily p ON d.event_date = p.event_date AND d.channel_grouping_name = p.channel_grouping_name AND d.lead_original_source = p.lead_original_source
LEFT JOIN mql_daily m ON d.event_date = m.event_date AND d.channel_grouping_name = m.channel_grouping_name AND d.lead_original_source = m.lead_original_source
LEFT JOIN sql_daily s ON d.event_date = s.event_date AND d.channel_grouping_name = s.channel_grouping_name AND d.lead_original_source = s.lead_original_source
LEFT JOIN sqo_daily sq ON d.event_date = sq.event_date AND d.channel_grouping_name = sq.channel_grouping_name AND d.lead_original_source = sq.lead_original_source
LEFT JOIN joined_daily j ON d.event_date = j.event_date AND d.channel_grouping_name = j.channel_grouping_name AND d.lead_original_source = j.lead_original_source
LEFT JOIN aum_daily a ON d.event_date = a.event_date AND d.channel_grouping_name = a.channel_grouping_name AND d.lead_original_source = a.lead_original_source;

