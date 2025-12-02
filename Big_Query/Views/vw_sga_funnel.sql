-- vw_sga_funnel_improved (adds funnel-entry and progression flags for correct conversion rates)
-- UPDATED: Includes all owners (not just SGAs), excludes "Savvy Operations"
-- IsActive and IsSGA__c fields are included for filtering in Looker Studio
WITH Valid_Users AS (
  SELECT DISTINCT
    Name,
    Id,
    IsSGA__c,
    IsActive
  FROM
    `savvy-gtm-analytics.SavvyGTMData.User`
  WHERE
    Name != 'Savvy Operations'  -- Exclude Savvy Operations (not an SGA)
),

Lead_Base AS (
  SELECT
    l.Full_prospect_id__c,
    l.CreatedDate,
      -- Get Owner Name (can be SGA or other owner types)
      sga_user.Name AS SGA_Owner_Name__c,
    sga_user.IsSGA__c AS Lead_Owner_IsSGA,
    sga_user.IsActive AS Lead_Owner_IsActive,
    l.LeadSource AS Lead_Original_Source,
    l.stage_entered_contacting__c,
    l.stage_entered_new__c,
    l.Stage_Entered_Call_Scheduled__c AS mql_stage_entered_ts,
    l.ConvertedDate AS converted_date_raw,
    l.IsConverted AS is_converted_raw,
    l.ConvertedOpportunityId AS converted_oppty_id,
    l.Disposition__c,
    l.Status,
    CASE WHEN l.stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
    CASE WHEN l.Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    CASE WHEN l.IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql,
    GREATEST(
      IFNULL(l.CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(l.stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(l.stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    ) AS FilterDate
    FROM
    `savvy-gtm-analytics.SavvyGTMData.Lead` l
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
      ON l.OwnerId = sga_user.Id
),

Opp_Base AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.CreatedDate AS Opp_CreatedDate,
      -- Get SGA name from Opportunity (can be SGA or other owner types)
      sga_user.Name AS sga_name_from_opp,
    sga_user.IsSGA__c AS Opp_SGA_IsSGA,
    sga_user.IsActive AS Opp_SGA_IsActive,
    o.SQL__c AS SQO_raw,
    o.Date_Became_SQO__c,
    o.LeadSource AS Opp_Original_Source,
    o.advisor_join_date__c,
    o.StageName
    FROM
    `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
      ON o.SGA__c = sga_user.Id
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
    -- Only include SGA names (exclude SGMs and NULL values)
    -- Priority: Opportunity SGA > Lead SGA (if both are valid SGAs)
    CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c IS NOT NULL AND o.sga_name_from_opp IS NOT NULL THEN o.sga_name_from_opp  -- Prefer Opportunity SGA if both exist
      WHEN l.SGA_Owner_Name__c IS NOT NULL THEN l.SGA_Owner_Name__c
      WHEN o.sga_name_from_opp IS NOT NULL THEN o.sga_name_from_opp
      ELSE NULL
    END AS SGA_Owner_Name__c,
    -- Include IsSGA__c and IsActive for filtering in Looker Studio
    -- Use the Opportunity SGA status if available, otherwise Lead Owner status
    COALESCE(o.Opp_SGA_IsSGA, l.Lead_Owner_IsSGA) AS IsSGA__c,
    COALESCE(o.Opp_SGA_IsActive, l.Lead_Owner_IsActive) AS IsActive,
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
    -- Note: Using is_sql_raw check and is_sqo_raw for consistency with vw_sga_funnel_team_agg
    CASE 
      WHEN l.is_sql = 1 AND (
        (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') OR  -- Converted: Joined
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 WHEN LOWER(o.SQO_raw) = 'no' THEN 0 ELSE NULL END = 1 AND l.Disposition__c IS NULL AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))) OR  -- Converted: SQO and active
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 WHEN LOWER(o.SQO_raw) = 'no' THEN 0 ELSE NULL END = 1 AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')) OR  -- Closed: SQO but closed
        (CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 WHEN LOWER(o.SQO_raw) = 'no' THEN 0 ELSE NULL END = 0 AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost'))  -- Closed: No SQO and closed
      ) THEN 1 
      ELSE 0 
    END AS is_sql,
    CASE
      WHEN LOWER(o.SQO_raw) = 'yes' THEN 1
      WHEN LOWER(o.SQO_raw) = 'no' THEN 0
      ELSE NULL
    END AS is_sqo,
    o.SQO_raw,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    l.Disposition__c,
    l.Status,
    o.StageName
  FROM Lead_Base l
  FULL OUTER JOIN Opp_Base o
    ON l.converted_oppty_id = o.Full_Opportunity_ID__c
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
    ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
),

Funnel_Entry_Analysis AS (
  SELECT
    cd.* EXCEPT(is_sql),
    -- Override is_sql to match eligible_for_sql_conversions logic exactly
    -- This ensures SUM(is_sqo)/SUM(is_sql) matches vw_sga_funnel_team_agg.sql (69%)
    CASE 
      WHEN cd.is_sql_raw = 1 AND (
        (cd.advisor_join_date__c IS NOT NULL OR cd.StageName = 'Joined') OR  -- Converted: Joined
        (cd.is_sqo_raw = 1 AND cd.Disposition__c IS NULL AND (cd.StageName IS NULL OR (cd.StageName != 'Closed Lost' AND cd.StageName != 'Joined'))) OR  -- Converted: SQO and active
        (cd.is_sqo_raw = 1 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost')) OR  -- Closed: SQO but closed
        (cd.is_sqo_raw = 0 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost'))  -- Closed: No SQO and closed
      ) THEN 1 
      ELSE 0 
    END AS is_sql,
    'Active' AS owner_status,
    CASE 
      WHEN cd.is_contacted = 0 AND cd.is_mql = 1 AND cd.is_sql_raw = 0 AND cd.is_sqo_raw = 0 THEN 'Entered at MQL'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 0 AND cd.is_sql_raw = 0 AND cd.is_sqo_raw = 0 THEN 'Entered at Contacted only'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql_raw = 0 AND cd.is_sqo_raw = 0 THEN 'Normal flow: Contacted -> MQL'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql_raw = 1 AND cd.is_sqo_raw = 0 THEN 'Entered at SQL'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql_raw = 0 AND cd.is_sqo_raw = 1 THEN 'Entered at SQO'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql_raw = 1 AND cd.is_sqo_raw = 0 THEN 'Normal flow: Contacted -> MQL -> SQL'
      WHEN cd.is_contacted = 1 AND cd.is_mql = 1 AND cd.is_sql_raw = 1 AND cd.is_sqo_raw = 1 THEN 'Normal flow: Contacted -> MQL -> SQL -> SQO'
      WHEN cd.is_contacted = 0 AND cd.is_mql = 0 AND cd.is_sql_raw = 0 AND cd.is_sqo_raw = 0 THEN 'No progression'
      ELSE 'Other'
    END AS funnel_entry_point,
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
    -- This matches the is_sql calculation above
    CASE 
      WHEN cd.is_sql_raw = 1 AND (
        (cd.advisor_join_date__c IS NOT NULL OR cd.StageName = 'Joined') OR  -- Converted: Joined
        (cd.is_sqo_raw = 1 AND cd.Disposition__c IS NULL AND (cd.StageName IS NULL OR (cd.StageName != 'Closed Lost' AND cd.StageName != 'Joined'))) OR  -- Converted: SQO and active
        (cd.is_sqo_raw = 1 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost')) OR  -- Closed: SQO but closed
        (cd.is_sqo_raw = 0 AND (cd.Disposition__c IS NOT NULL OR cd.StageName = 'Closed Lost'))  -- Closed: No SQO and closed
      ) THEN 1 
      ELSE 0 
    END AS eligible_for_sql_conversions,
    -- UPDATED: Only include SQOs with final outcome (joined or closed lost) - excludes open SQOs
    CASE 
      WHEN cd.is_sqo = 1 
        AND (cd.is_joined = 1 OR cd.StageName = 'Closed Lost')
      THEN 1 
      ELSE 0 
    END AS eligible_for_sqo_conversions
  FROM Combined_Data cd
  INNER JOIN Valid_Users a
    ON cd.SGA_Owner_Name__c = a.Name
  WHERE cd.SGA_Owner_Name__c IS NOT NULL 
    AND cd.SGA_Owner_Name__c != 'Savvy Operations'  -- Exclude Savvy Operations (not an SGA)
)

SELECT 
  *,
  -- Progression flags
    -- Note: For contacted_to_mql, numerator is straightforward since denominator includes ALL contacted
    CASE WHEN is_contacted = 1 AND is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression,
    CASE WHEN eligible_for_contacted_conversions = 1 AND is_sql_progression = 1 THEN 1 ELSE 0 END AS contacted_to_sql_progression,
    CASE WHEN eligible_for_contacted_conversions = 1 AND is_sqo = 1 THEN 1 ELSE 0 END AS contacted_to_sqo_progression,
    CASE WHEN eligible_for_mql_conversions = 1 AND is_sql_progression = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression,
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


