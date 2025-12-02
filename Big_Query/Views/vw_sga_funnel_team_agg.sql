-- vw_sga_funnel_team_agg (v3 - Aligned with corrected conversion rate logic)
-- UPDATED: Includes all owners (not just SGAs/SGMs), excludes "Savvy Operations"
-- IsActive and IsSGA__c fields are included for filtering in Looker Studio
WITH Valid_Users AS (
  SELECT DISTINCT
    Name,
    IsSGA__c,
    Is_SGM__c,
    IsActive
  FROM
    `savvy-gtm-analytics.SavvyGTMData.User`
  WHERE
    Name != 'Savvy Operations'  -- Exclude Savvy Operations (not an SGA)
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
    Disposition__c,
    Status,
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
    o.advisor_join_date__c,
    o.StageName
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
    -- Event-based cohort months for accurate date attribution (month-level grouping)
    -- Each conversion rate should be grouped by when they entered the prior stage
    DATE_TRUNC(DATE(l.stage_entered_contacting__c), MONTH) AS contacted_cohort_month,
    DATE_TRUNC(DATE(l.mql_stage_entered_ts), MONTH) AS mql_cohort_month,
    DATE_TRUNC(DATE(l.converted_date_raw), MONTH) AS sql_cohort_month,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), MONTH) AS sqo_cohort_month,
    -- Event-based dates for day-level filtering (use these for exact date ranges like Feb 15 - Nov 24)
    DATE(l.stage_entered_contacting__c) AS contacted_date,
    DATE(l.mql_stage_entered_ts) AS mql_date,
    DATE(l.converted_date_raw) AS sql_date,
    DATE(o.Date_Became_SQO__c) AS sqo_date,
    CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      ELSE l.SGA_Owner_Name__c
    END AS SGA_Owner_Name__c,
    -- Include IsSGA__c, Is_SGM__c, and IsActive for filtering in Looker Studio
    -- Get from User table based on SGA_Owner_Name__c
    u_all.IsSGA__c,
    u_all.Is_SGM__c,
    u_all.IsActive,
    IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) AS Original_source,
    l.is_contacted,
    -- Keep raw flags for backward compatibility
    l.is_mql AS is_mql_raw,
    l.is_sql AS is_sql_raw,
    CASE
      WHEN LOWER(o.SQO_raw) = 'yes' THEN 1
      WHEN LOWER(o.SQO_raw) = 'no' THEN 0
      ELSE NULL
    END AS is_sqo_raw,
    -- Progression-based flags (aligned with vw_conversion_rates logic)
    -- is_mql: Should be based on Stage_Entered_Call_Scheduled__c, NOT requiring contacted
    -- This matches vw_conversion_rates logic where is_mql = CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END
    l.is_mql AS is_mql,
    -- is_sql: Progression-based (MQL->SQL) for MQL-to-SQL calculation
    CASE WHEN l.is_mql = 1 AND l.is_sql = 1 THEN 1 ELSE 0 END AS is_sql_progression,
    -- is_sql: For SQL-to-SQO denominator, only include SQLs with final outcomes (Converted or Closed)
    -- This ensures SUM(is_sqo)/SUM(is_sql) matches vw_conversion_rates logic
    CASE 
      WHEN l.is_sql = 1 AND (
        (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') OR  -- Converted: Joined
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 AND l.Disposition__c IS NULL AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))) OR  -- Converted: SQO and active
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')) OR  -- Closed: SQO but closed
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0 AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost'))  -- Closed: No SQO and closed
      ) THEN 1 
      ELSE 0 
    END AS is_sql,
    CASE 
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 1
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'no' THEN 1 ELSE 0 END = 1 THEN 0
      ELSE NULL
    END AS is_sqo,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    o.SQO_raw,
    l.Disposition__c,
    l.Status,
    o.StageName,
    o.advisor_join_date__c
  FROM Lead_Base l
  FULL OUTER JOIN Opp_Base o
    ON l.converted_oppty_id = o.Full_Opportunity_ID__c
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
    ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` u_all
    ON CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      ELSE l.SGA_Owner_Name__c
    END = u_all.Name
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
    
    -- SQL Conversion Status (Converted/Closed/Open/Stage not entered)
    CASE 
      WHEN cd.is_sql_raw = 0 THEN 'Stage not entered'
      WHEN cd.is_sql_raw = 1 AND (cd.advisor_join_date__c IS NOT NULL OR cd.StageName = 'Joined') THEN 'Converted'
      WHEN cd.is_sql_raw = 1 AND cd.is_sqo = 1 
        AND cd.Disposition__c IS NULL
        AND (cd.StageName IS NULL OR (cd.StageName != 'Closed Lost' AND cd.StageName != 'Joined'))
      THEN 'Converted'
      WHEN cd.is_sql_raw = 1 AND cd.is_sqo = 1
        AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost')
      THEN 'Closed'
      WHEN cd.is_sql_raw = 1 AND cd.is_sqo = 0 
        AND cd.Disposition__c IS NULL
        AND (cd.StageName IS NULL OR (cd.StageName != 'Closed Lost' AND cd.StageName != 'Joined'))
      THEN 'Open'
      WHEN cd.is_sql_raw = 1 AND cd.is_sqo = 0
        AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost')
      THEN 'Closed'
      ELSE 'Stage not entered'
    END AS SQL_conversion_status,
    
    -- Flags for proper conversion rate calculations
    -- UPDATED: Include ALL contacted leads (Option A: all leads moved into contacting)
    -- Logic: "Of everyone we contacted, what % became MQL?"
    -- This is tied to contacted_date for accurate date attribution
    CASE 
      WHEN cd.is_contacted = 1 
      THEN 1 
      ELSE 0 
    END AS eligible_for_contacted_conversions,
    -- UPDATED: Only include MQLs with final outcome (became SQL or has Disposition__c) - excludes open MQLs
    CASE 
      WHEN cd.is_mql = 1 
        AND (cd.is_sql_raw = 1 OR cd.Disposition__c IS NOT NULL)
      THEN 1 
      ELSE 0 
    END AS eligible_for_mql_conversions,
    -- THIS IS THE NEW (CORRECTED) DENOMINATOR: Only include SQLs with final outcome (Converted or Closed)
    -- Note: Using is_sql_raw to check if SQL exists, then checking final outcome status
    CASE 
      WHEN cd.is_sql_raw = 1 AND (
        (cd.advisor_join_date__c IS NOT NULL OR cd.StageName = 'Joined') OR  -- Converted: Joined
        (cd.is_sqo = 1 AND cd.Disposition__c IS NULL AND (cd.StageName IS NULL OR (cd.StageName != 'Closed Lost' AND cd.StageName != 'Joined'))) OR  -- Converted: SQO and active
        (cd.is_sqo = 1 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost')) OR  -- Closed: SQO but closed
        (cd.is_sqo = 0 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost'))  -- Closed: No SQO and closed
      ) THEN 1 
      ELSE 0 
    END AS eligible_for_sql_conversions,
    -- UPDATED: Only include SQOs with final outcome (joined or closed lost) - excludes open SQOs
    CASE 
      WHEN cd.is_sqo = 1 
        AND (cd.is_joined = 1 OR cd.StageName = 'Closed Lost')
      THEN 1 
      ELSE 0 
    END AS eligible_for_sqo_conversions,
    
    -- Progression flags for accurate conversion rates
    CASE WHEN cd.is_contacted = 1 AND cd.is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression,
    CASE WHEN cd.is_contacted = 1 AND cd.is_sql_progression = 1 THEN 1 ELSE 0 END AS contacted_to_sql_progression,
    CASE WHEN cd.is_contacted = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS contacted_to_sqo_progression,
    CASE WHEN cd.is_mql = 1 AND cd.is_sql_progression = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression,
    CASE WHEN cd.is_mql = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS mql_to_sqo_progression,
    CASE WHEN cd.is_sql = 1 AND cd.is_sqo = 1 THEN 1 ELSE 0 END AS sql_to_sqo_progression

  FROM Combined_Data cd
),

Filtered_Data AS (
  SELECT fea.*
  FROM Funnel_Entry_Analysis fea
  INNER JOIN Valid_Users a
    ON fea.SGA_Owner_Name__c = a.Name
  WHERE fea.SGA_Owner_Name__c IS NOT NULL 
    AND fea.SGA_Owner_Name__c != 'Savvy Operations'  -- Exclude Savvy Operations (not an SGA)
)

-- Final aggregation with corrected conversion rates
SELECT
  DATE(FilterDate) as FilterDate,
  -- Event-based cohort months for accurate date attribution (month-level grouping)
  -- Contacted→MQL: Group by when they were contacted
  contacted_cohort_month,
  -- MQL→SQL: Group by when they became MQL
  mql_cohort_month,
  -- SQL→SQO: Group by when they became SQL
  sql_cohort_month,
  -- SQO→Joined: Group by when they became SQO
  sqo_cohort_month,
  -- Event-based dates for day-level filtering (use these for exact date ranges like Feb 15 - Nov 24)
  -- Note: These are included in GROUP BY so Looker Studio can filter on them at the detail level
  -- Contacted→MQL: Use contacted_date for day-level filtering
  contacted_date,
  -- MQL→SQL: Use mql_date for day-level filtering
  mql_date,
  -- SQL→SQO: Use sql_date for day-level filtering
  sql_date,
  -- SQO→Joined: Use sqo_date for day-level filtering
  sqo_date,
  Channel_Grouping_Name,
  Original_source,
  -- Include IsSGA__c, Is_SGM__c, and IsActive for filtering in Looker Studio
  IsSGA__c,
  Is_SGM__c,
  IsActive,
  
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
  -- Also provide numerator and denominator for precise aggregation (avoids rounding errors)
  SUM(contacted_to_mql_progression) as contacted_to_mql_numerator,
  SUM(eligible_for_contacted_conversions) as contacted_to_mql_denominator,
  ROUND(SUM(contacted_to_mql_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_mql_rate,
  SUM(contacted_to_sql_progression) as contacted_to_sql_numerator,
  ROUND(SUM(contacted_to_sql_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_sql_rate,
  SUM(contacted_to_sqo_progression) as contacted_to_sqo_numerator,
  -- Note: contacted_to_sqo_denominator is the same as contacted_to_mql_denominator (eligible_for_contacted_conversions)
  ROUND(SUM(contacted_to_sqo_progression)/ NULLIF(SUM(eligible_for_contacted_conversions), 0), 2) as corrected_contacted_to_sqo_rate,
  
  -- Stage-to-stage conversion rates
  -- Note: For MQL-to-SQL, use SUM(is_sql_progression)/SUM(is_mql) to match progression logic
  -- Also provide numerator and denominator for precise aggregation (avoids rounding errors)
  SUM(mql_to_sql_progression) as mql_to_sql_numerator,
  SUM(eligible_for_mql_conversions) as mql_to_sql_denominator,
  ROUND(SUM(mql_to_sql_progression) / NULLIF(SUM(eligible_for_mql_conversions), 0), 2) as mql_to_sql_rate,
  ROUND(SUM(mql_to_sqo_progression)/ NULLIF(SUM(eligible_for_mql_conversions), 0), 2) as mql_to_sqo_rate,
  -- SQL-to-SQO rate: Use corrected denominator (only SQLs with final outcomes)
  -- Note: SUM(is_sqo)/SUM(is_sql) now matches vw_conversion_rates logic (is_sql only includes SQLs with final outcomes)
  -- Also provide numerator and denominator for precise aggregation (avoids rounding errors)
  SUM(sql_to_sqo_progression) as sql_to_sqo_numerator,
  SUM(eligible_for_sql_conversions) as sql_to_sqo_denominator,
  ROUND(SUM(sql_to_sqo_progression)/ NULLIF(SUM(eligible_for_sql_conversions), 0), 2) as sql_to_sqo_rate,
  
  -- SQO evaluation rate (like forecast view)
  ROUND(COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)/ NULLIF(COUNT(DISTINCT CASE WHEN is_sqo IN (0,1) THEN Full_Opportunity_ID__c END), 0), 2) as sqo_evaluation_rate

FROM Filtered_Data
GROUP BY 
  DATE(FilterDate),
  contacted_cohort_month,
  mql_cohort_month,
  sql_cohort_month,
  sqo_cohort_month,
  contacted_date,
  mql_date,
  sql_date,
  sqo_date,
  Channel_Grouping_Name,
  Original_source,
  IsSGA__c,
  Is_SGM__c,
  IsActive

