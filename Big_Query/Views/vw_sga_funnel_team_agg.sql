-- vw_sga_funnel_team_agg (v3 - Aligned with corrected conversion rate logic)
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
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
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
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
    ON o.SGA__c = u.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
),

Combined_Data AS (
  SELECT
    l.Full_prospect_id__c,
    o.Full_Opportunity_ID__c,
    COALESCE(
      l.FilterDate,
      o.Opp_CreatedDate,
      TIMESTAMP(o.Date_Became_SQO__c),
      TIMESTAMP(o.advisor_join_date__c)
    ) AS FilterDate,
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
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    o.SQO_raw
  FROM Lead_Base l
  FULL OUTER JOIN Opp_Base o
    ON l.converted_oppty_id = o.Full_Opportunity_ID__c
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
    ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
),

-- Add funnel entry point analysis for proper conversion rate calculations
Funnel_Entry_Analysis AS (
  SELECT
    cd.*,
    -- Determine funnel entry point
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
    
    -- Flags for proper conversion rate calculations
    CASE WHEN cd.is_contacted = 1 THEN 1 ELSE 0 END AS eligible_for_contacted_conversions,
    CASE WHEN cd.is_mql = 1 THEN 1 ELSE 0 END AS eligible_for_mql_conversions,
    CASE WHEN cd.is_sql = 1 THEN 1 ELSE 0 END AS eligible_for_sql_conversions,
    CASE WHEN cd.is_sqo = 1 THEN 1 ELSE 0 END AS eligible_for_sqo_conversions,
    
    -- Progression flags for accurate conversion rates
    CASE WHEN cd.is_contacted = 1 AND cd.is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression,
    CASE WHEN cd.is_contacted = 1 AND cd.is_sql = 1 THEN 1 ELSE 0 END AS contacted_to_sql_progression,
    CASE WHEN cd.is_contacted = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS contacted_to_sqo_progression,
    CASE WHEN cd.is_mql = 1 AND cd.is_sql = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression,
    CASE WHEN cd.is_mql = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS mql_to_sqo_progression,
    CASE WHEN cd.is_sql = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS sql_to_sqo_progression

  FROM Combined_Data cd
),

Filtered_Data AS (
  SELECT fea.*
  FROM Funnel_Entry_Analysis fea
  INNER JOIN Active_SGA_SGM_Users a
    ON fea.SGA_Owner_Name__c = a.Name
)

-- Final aggregation with corrected conversion rates
SELECT
  DATE(FilterDate) as FilterDate,
  Channel_Grouping_Name,
  Original_source,
  
  -- Core counts (unchanged)
  COUNT(DISTINCT Full_prospect_id__c) as team_prospects,
  SUM(is_contacted) as team_contacted,
  SUM(is_mql) as team_mql,
  SUM(is_sql) as team_sql,
  COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END) as team_sqo,
  COUNT(DISTINCT CASE WHEN is_sqo IN (0,1) THEN Full_Opportunity_ID__c END) as team_sqo_evaluated,
  COUNT(DISTINCT CASE WHEN is_joined = 1 THEN Full_Opportunity_ID__c END) as team_joined,
  COUNT(DISTINCT CASE WHEN is_sqo = 0 THEN Full_Opportunity_ID__c END) as team_sqo_no,
  COUNT(DISTINCT CASE WHEN is_sqo IS NULL AND is_sql = 1 THEN Full_Opportunity_ID__c END) as team_sqo_pending,
  
  -- Funnel entry point analysis
  SUM(CASE WHEN funnel_entry_point = 'Entered at MQL' THEN 1 ELSE 0 END) as entered_at_mql_count,
  SUM(CASE WHEN funnel_entry_point = 'Normal flow: Contacted -> MQL' THEN 1 ELSE 0 END) as normal_flow_count,
  SUM(CASE WHEN funnel_entry_point = 'Entered at Contacted only' THEN 1 ELSE 0 END) as contacted_only_count,
  SUM(CASE WHEN funnel_entry_point = 'Entered at SQL' THEN 1 ELSE 0 END) as entered_at_sql_count,
  SUM(CASE WHEN funnel_entry_point = 'Entered at SQO' THEN 1 ELSE 0 END) as entered_at_sqo_count,
  SUM(CASE WHEN funnel_entry_point = 'No progression' THEN 1 ELSE 0 END) as no_progression_count,
  
  -- Traditional (problematic) conversion rates for comparison
  ROUND(SUM(is_mql)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as traditional_contacted_to_mql_rate,
  ROUND(SUM(is_sql)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as traditional_contacted_to_sql_rate,
  ROUND(COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as traditional_contacted_to_sqo_rate,
  -- Corrected conversion rates (only count actual progressions)
  ROUND(SUM(contacted_to_mql_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_mql_rate,
  ROUND(SUM(contacted_to_sql_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_sql_rate,
  ROUND(SUM(contacted_to_sqo_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_sqo_rate,
  
  -- Stage-to-stage conversion rates
  ROUND(SUM(mql_to_sql_progression) / NULLIF(SUM(eligible_for_mql_conversions), 0), 2) as mql_to_sql_rate,
  ROUND(SUM(mql_to_sqo_progression)/ NULLIF(SUM(eligible_for_mql_conversions), 0), 2) as mql_to_sqo_rate,
  ROUND(SUM(sql_to_sqo_progression)/ NULLIF(SUM(eligible_for_sql_conversions), 0), 2) as sql_to_sqo_rate,
  
  -- SQO evaluation rate (like forecast view)
  ROUND(COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)/ NULLIF(COUNT(DISTINCT CASE WHEN is_sqo IN (0,1) THEN Full_Opportunity_ID__c END), 0), 2) as sqo_evaluation_rate

FROM Filtered_Data
GROUP BY 1, 2, 3

