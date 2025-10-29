-- vw_sga_funnel_improved (adds funnel-entry and progression flags for correct conversion rates)
WITH Active_SGA_SGM_Users AS (
  SELECT DISTINCT
    Name
  FROM
    `savvy-gtm-analytics.SavvyGTMData.User`
  WHERE
    (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE
),

Lead_Base AS (
  SELECT
    Full_prospect_id__c,
    CreatedDate,
    SGA_Owner_Name__c,
    LeadSource AS Lead_Original_Source,
    stage_entered_contacting__c,
    stage_entered_new__c,
    Stage_Entered_Call_Scheduled__c AS mql_stage_entered_ts,
    ConvertedDate AS converted_date_raw,
    IsConverted AS is_converted_raw,
    ConvertedOpportunityId AS converted_oppty_id,
    CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    CASE WHEN IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql,
    GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    ) AS FilterDate
  FROM
    `savvy-gtm-analytics.SavvyGTMData.Lead`
),

Opp_Base AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.CreatedDate AS Opp_CreatedDate,
    u.Name AS sga_name_from_opp,
    o.SQL__c AS SQO_raw,
    o.Date_Became_SQO__c,
    o.LeadSource AS Opp_Original_Source,
    o.advisor_join_date__c
  FROM
    `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
      ON o.SGA__c = u.Id
  WHERE
    o.recordtypeid = '012Dn000000mrO3IAI'
),

Combined_Data AS (
  SELECT
    COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS unique_id,
    l.Full_prospect_id__c,
    o.Full_Opportunity_ID__c,
    COALESCE(
      l.FilterDate,
      o.Opp_CreatedDate,
      TIMESTAMP(o.Date_Became_SQO__c),
      TIMESTAMP(o.advisor_join_date__c)
    ) AS FilterDate,
    l.stage_entered_contacting__c,
    l.mql_stage_entered_ts,
    l.converted_date_raw,
    o.Date_Became_SQO__c,
    o.advisor_join_date__c,
    CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      ELSE l.SGA_Owner_Name__c
    END AS SGA_Owner_Name__c,
    IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) AS Original_source,
    l.is_contacted,
    l.is_mql,
    l.is_sql,
    CASE
      WHEN LOWER(o.SQO_raw) = 'yes' THEN 1
      WHEN LOWER(o.SQO_raw) = 'no' THEN 0
      ELSE NULL
    END AS is_sqo,
    o.SQO_raw,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined
  FROM Lead_Base l
  FULL OUTER JOIN Opp_Base o
    ON l.converted_oppty_id = o.Full_Opportunity_ID__c
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
    ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
),

Funnel_Entry_Analysis AS (
  SELECT
    cd.*,
    'Active' AS owner_status,
    CASE 
      WHEN cd.is_contacted = 0 AND cd.is_mql = 1 AND cd.is_sql = 0 AND cd.is_sqo = 0 THEN 'Entered at MQL'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 0 AND cd.is_sql = 0 AND cd.is_sqo = 0 THEN 'Entered at Contacted only'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql = 0 AND cd.is_sqo = 0 THEN 'Normal flow: Contacted -> MQL'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql = 1 AND cd.is_sqo = 0 THEN 'Entered at SQL'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql = 0 AND cd.is_sqo = 1 THEN 'Entered at SQO'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql = 1 AND cd.is_sqo = 0 THEN 'Normal flow: Contacted -> MQL -> SQL'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql = 1 AND cd.is_sqo = 1 THEN 'Normal flow: Contacted -> MQL -> SQL -> SQO'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql = 0 AND cd.is_sqo = 0 THEN 'No progression'
      ELSE 'Other'
    END AS funnel_entry_point,
    CASE WHEN cd.is_contacted = 1 THEN 1 ELSE 0 END AS eligible_for_contacted_conversions,
    CASE WHEN cd.is_mql = 1 THEN 1 ELSE 0 END AS eligible_for_mql_conversions,
    CASE WHEN cd.is_sql = 1 THEN 1 ELSE 0 END AS eligible_for_sql_conversions,
    CASE WHEN cd.is_sqo = 1 THEN 1 ELSE 0 END AS eligible_for_sqo_conversions
  FROM Combined_Data cd
  INNER JOIN Active_SGA_SGM_Users a
    ON cd.SGA_Owner_Name__c = a.Name
)

SELECT 
  *,
  -- Progression flags
  CASE WHEN eligible_for_contacted_conversions = 1 AND is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression,
  CASE WHEN eligible_for_contacted_conversions = 1 AND is_sql = 1 THEN 1 ELSE 0 END AS contacted_to_sql_progression,
  CASE WHEN eligible_for_contacted_conversions = 1 AND is_sqo = 1 THEN 1 ELSE 0 END AS contacted_to_sqo_progression,
  CASE WHEN eligible_for_mql_conversions = 1 AND is_sql = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression,
  CASE WHEN eligible_for_mql_conversions = 1 AND is_sqo = 1 THEN 1 ELSE 0 END AS mql_to_sqo_progression,
  CASE WHEN eligible_for_sql_conversions = 1 AND is_sqo = 1 THEN 1 ELSE 0 END AS sql_to_sqo_progression,
  
  -- Pre-calculated conversion rates (for easy use in Looker)
  -- These will be NULL for individual records, but useful for aggregations
  NULL AS prospect_to_contact_rate,
  NULL AS contact_to_mql_rate_corrected,
  NULL AS mql_to_sql_rate,
  NULL AS sql_to_sqo_rate,
  NULL AS contact_to_sqo_rate_corrected
FROM Funnel_Entry_Analysis


