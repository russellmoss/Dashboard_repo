SELECT
  -- Channel + drill keys
  CASE
    WHEN LOWER(f.Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
    WHEN LOWER(f.Channel_Grouping_Name) = 'outbound'  THEN 'Outbound'
    WHEN LOWER(f.Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
    WHEN f.Channel_Grouping_Name IS NULL OR LOWER(f.Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
    ELSE f.Channel_Grouping_Name
  END AS channel_grouping_name,
  f.Original_source AS lead_original_source,

  -- Identity & Details for Tables
  f.Full_prospect_id__c,
  f.Opp_Name,
  f.Full_Opportunity_ID__c,
  f.SGA_Owner_Name__c,
  f.Opportunity_Owner_Name__c AS sgm_name,
  f.StageName, -- MODIFIED: Added the StageName field

  -- Stage flags
  CAST(f.is_contacted AS INT64) AS is_contacted,
  CAST(f.is_mql AS INT64)       AS is_mql,
  CAST(f.is_sql AS INT64)       AS is_sql,
  CAST(f.is_sqo AS INT64)       AS is_sqo,
  CAST(f.is_joined AS INT64)    AS is_joined,

  -- Outcomes
  f.Amount,
  f.Underwritten_AUM__c,

  -- Date range dimensions
  f.FilterDate,
  f.mql_stage_entered_ts,
  f.converted_date_raw,
  f.Date_Became_SQO__c,
  f.advisor_join_date__c,
  f.Stage_Entered_Signed__c

  -- REMOVED: The custom 'status' field is no longer needed

FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` AS f
