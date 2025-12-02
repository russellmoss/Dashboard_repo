-- Conversion Rates View for Looker Dashboard
-- Aggregated view providing numerators and denominators for all conversion rates
-- Uses progression-based logic as defined in conversion_rate_calculations.md
-- Date attribution: FilterDate (cohort-based)

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates` AS

WITH BaseFunnel AS (
  -- Base CTE: Full query from vw_funnel_lead_to_joined_v2.sql
  -- Modified to include missing Opportunity stage entry fields
  WITH Lead_Base AS (
    SELECT
      l.Full_prospect_id__c,
      l.Name AS Prospect_Name,
      l.FirstName,
      l.LastName,
      l.CreatedDate,
      l.OwnerID,
      -- Get Owner Name (can be SGA or other owner types)
      sga_user.Name AS SGA_Owner_Name__c,
      l.Company,
      l.lead_list_name__c,
      l.Experimentation_Tag__c,
      l.LeadSource AS Lead_Original_Source,
      l.External_Agency__c,
      l.Disposition__c,
      l.Status,
      l.stage_entered_contacting__c,
      l.Initial_Call_Scheduled_Date__c,
      l.stage_entered_new__c,
      l.Stage_Entered_Call_Scheduled__c AS mql_stage_entered_ts,
      l.ConvertedDate AS converted_date_raw,
      l.IsConverted AS is_converted_raw,
      l.ConvertedOpportunityId AS converted_oppty_id,
      CASE WHEN l.stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
      CASE WHEN l.Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
      CASE WHEN l.initial_call_scheduled_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_initial_call,
      FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(l.initial_call_scheduled_date__c), WEEK(MONDAY))) AS Week_Bucket_MQL_Call,
      DATE_TRUNC(DATE(l.Stage_Entered_Contacting__c), WEEK(MONDAY)) AS Week_Bucket_MQL_Date,
      CASE WHEN l.IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql,
      FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(l.ConvertedDate), WEEK(MONDAY))) AS Week_Bucket_SQL,
      DATE_TRUNC(DATE(l.ConvertedDate), WEEK(MONDAY)) AS Week_Bucket_SQL_Date,
      GREATEST(
        IFNULL(l.CreatedDate, TIMESTAMP('1900-01-01')),
        IFNULL(l.stage_entered_new__c, TIMESTAMP('1900-01-01')),
        IFNULL(l.stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
      ) AS FilterDate
    FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
      ON l.OwnerId = sga_user.Id
  ),

  Opp_Base AS (
    SELECT
      o.Full_Opportunity_ID__c,
      o.Name AS Opp_Name,
      o.CreatedDate AS Opp_CreatedDate,
      sga_user.Name AS sga_name_from_opp,
      CASE WHEN opp_owner_user.is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
      o.Amount,
      o.Underwritten_AUM__c,
      o.Opportunity_Owner_Name__c,
      o.Stage_Entered_Signed__c,
      o.StageName,
      o.Closed_Lost_Reason__c,
      o.Closed_Lost_Details__c,
      o.IsClosed,
      o.CloseDate,
      o.SQL__c AS SQO_raw,
      o.Date_Became_SQO__c,
      o.LeadSource AS Opp_Original_Source,
      o.External_Agency__c,
      o.advisor_join_date__c,
      o.Qualification_Call_Date__c,
      o.Firm_Name__c,
      o.Firm_Type__c,
      o.City_State__c,
      o.Office_Address__c,
      o.NextStep,
      o.Earliest_Anticipated_Start_Date__c,
      o.OwnerId,
      -- Add missing stage entry fields for Post-SQO conversion rates
      o.Stage_Entered_Discovery__c,
      o.Stage_Entered_Sales_Process__c,
      o.Stage_Entered_Negotiating__c,
      o.Stage_Entered_Joined__c
    FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
      ON o.SGA__c = sga_user.Id
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
      ON o.OwnerId = opp_owner_user.Id
    WHERE o.recordtypeid = '012Dn000000mrO3IAI'
  )

  SELECT
    -- Composite Primary Key
    COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key,
    
    -- Lead fields
    l.Full_prospect_id__c,
    l.Prospect_Name,
    l.FirstName,
    l.LastName,
    COALESCE(o.Opp_Name, l.Prospect_Name) AS advisor_name,
    l.CreatedDate,
    l.OwnerID,
    CASE
      WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
      WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
      ELSE l.SGA_Owner_Name__c
    END AS SGA_Owner_Name__c,
    l.Company,
    l.lead_list_name__c,
    l.Experimentation_Tag__c,
    l.Lead_Original_Source AS Lead_Original_Source,
    l.Disposition__c,
    l.Status,
    l.stage_entered_contacting__c,
    l.Initial_Call_Scheduled_Date__c,
    l.is_contacted,
    l.mql_stage_entered_ts,
    l.is_mql,
    l.is_initial_call,
    l.Week_Bucket_MQL_Call,
    l.Week_Bucket_MQL_Date,
    l.converted_date_raw,
    l.is_converted_raw,
    l.is_sql,
    l.Week_Bucket_SQL,
    l.Week_Bucket_SQL_Date,
    l.converted_oppty_id,
    
    -- FilterDate with fallback for opportunity-only records
    COALESCE(
      l.FilterDate,
      o.Opp_CreatedDate,
      o.Date_Became_SQO__c,
      TIMESTAMP(o.advisor_join_date__c)
    ) AS FilterDate,

    -- Opportunity fields
    o.Full_Opportunity_ID__c,
    o.Opp_Name,
    o.Opp_CreatedDate,
    o.Amount,
    o.Underwritten_AUM__c,
    COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM,
    o.StageName,
    CASE
      WHEN o.StageName = 'Qualifying' THEN 1
      WHEN o.StageName = 'Discovery' THEN 2
      WHEN o.StageName = 'Sales Process' THEN 3
      WHEN o.StageName = 'Negotiating' THEN 4
      WHEN o.StageName = 'Signed' THEN 5
      WHEN o.StageName = 'On Hold' THEN 6
      WHEN o.StageName = 'Closed' THEN 7
      ELSE NULL
    END AS StageName_code,
    o.isClosed,
    o.CloseDate,
    o.Opportunity_Owner_Name__c,
    o.sgm_name,
    o.Stage_Entered_Signed__c,
    o.Closed_Lost_Reason__c,
    o.Closed_Lost_Details__c,
    o.Qualification_Call_Date__c,
    CASE WHEN o.Qualification_Call_Date__c IS NOT NULL THEN 1 ELSE 0 END AS is_Qual_call,
    FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(o.Qualification_Call_Date__c), WEEK(MONDAY))) AS Week_Bucket_Qual_Call,
    FORMAT_TIMESTAMP('%b', o.Date_Became_SQO__c) AS Month_bucket_SQO,
    FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(o.Date_Became_SQO__c), WEEK(MONDAY))) AS Week_bucket_SQO,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), WEEK(MONDAY)) AS Week_Bucket_SQO_Date,
    o.Firm_Name__c,
    o.Firm_Type__c,
    o.City_State__c,
    o.Office_Address__c,
    o.NextStep,
    o.Earliest_Anticipated_Start_Date__c,
    
    -- Stage entry fields for Post-SQO conversion rates
    o.Stage_Entered_Discovery__c,
    o.Stage_Entered_Sales_Process__c,
    o.Stage_Entered_Negotiating__c,
    o.Stage_Entered_Joined__c,

    -- Attribution & outcomes
    IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(o.Opp_Original_Source, l.Lead_Original_Source, 'Unknown') AS Original_source,
    COALESCE(o.External_Agency__c, l.External_Agency__c) AS External_Agency__c,
    o.SQO_raw,
    o.Date_Became_SQO__c,
    o.advisor_join_date__c,
    
    -- Existing flags
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    
    -- Conversion tracking fields
    CASE
      WHEN o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined' THEN 'Joined'
      WHEN CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 'SQO'
      WHEN l.is_sql = 1 THEN 'SQL'
      WHEN l.is_mql = 1 THEN 'MQL'
      ELSE NULL
    END AS TOF_Stage,
    
    CASE
      WHEN o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined' THEN 'Joined'
      WHEN CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN
        CASE
          WHEN l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost' THEN 'Closed'
          WHEN l.Disposition__c IS NULL 
            AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
          THEN 'Open'
          ELSE 'Closed'
        END
      WHEN l.is_sql = 1 THEN
        CASE
          WHEN l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost' THEN 'Closed'
          WHEN l.Disposition__c IS NULL 
            AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
          THEN 'Open'
          ELSE 'Closed'
        END
      WHEN l.is_mql = 1 THEN
        CASE
          WHEN l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost' THEN 'Closed'
          WHEN l.Disposition__c IS NULL
            AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
          THEN 'Open'
          ELSE 'Closed'
        END
      ELSE NULL
    END AS Conversion_Status,
    
    CASE WHEN l.is_mql = 1 AND l.is_sql = 1 THEN 1 ELSE 0 END AS Converted_from_mql,
    CASE WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 1 ELSE 0 END AS Converted_from_sql,
    
    CASE 
      WHEN l.is_mql = 0 THEN 'Stage not entered'
      WHEN l.is_mql = 1 AND (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') THEN 'Converted'
      WHEN l.is_mql = 1 AND l.is_sql = 1 
        AND l.Disposition__c IS NULL
        AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
      THEN 'Converted'
      WHEN l.is_mql = 1 AND l.is_sql = 1 
        AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
      THEN 'Closed'
      WHEN l.is_mql = 1 AND l.is_sql = 0 
        AND l.Disposition__c IS NULL
      THEN 'Open'
      WHEN l.is_mql = 1 AND l.is_sql = 0 
        AND l.Disposition__c IS NOT NULL
      THEN 'Closed'
      ELSE 'Stage not entered'
    END AS MQL_conversion_status,
    
    CASE 
      WHEN l.is_sql = 0 THEN 'Stage not entered'
      WHEN l.is_sql = 1 AND (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') THEN 'Converted'
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 
        AND l.Disposition__c IS NULL
        AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
      THEN 'Converted'
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1
        AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
      THEN 'Closed'
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0 
        AND l.Disposition__c IS NULL
        AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
      THEN 'Open'
      WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0
        AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
      THEN 'Closed'
      ELSE 'Stage not entered'
    END AS SQL_conversion_status

  FROM Lead_Base l
  FULL OUTER JOIN Opp_Base o
    ON l.converted_oppty_id = o.Full_Opportunity_ID__c
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
    ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
),

FunnelWithFlags AS (
  SELECT
    *,
    
    -- Event-based cohort months for accurate date attribution
    -- Each conversion rate should be grouped by when they entered the prior stage
    DATE_TRUNC(DATE(stage_entered_contacting__c), MONTH) AS contacted_cohort_month,
    DATE_TRUNC(DATE(mql_stage_entered_ts), MONTH) AS mql_cohort_month,
    DATE_TRUNC(DATE(converted_date_raw), MONTH) AS sql_cohort_month,
    DATE_TRUNC(DATE(Date_Became_SQO__c), MONTH) AS sqo_cohort_month,
    -- Post-SQO cohort months for accurate date attribution
    DATE_TRUNC(DATE(Stage_Entered_Discovery__c), MONTH) AS discovery_cohort_month,
    DATE_TRUNC(DATE(Stage_Entered_Sales_Process__c), MONTH) AS sales_process_cohort_month,
    DATE_TRUNC(DATE(Stage_Entered_Negotiating__c), MONTH) AS negotiating_cohort_month,
    DATE_TRUNC(DATE(Stage_Entered_Signed__c), MONTH) AS signed_cohort_month,
    
    -- Post-SQO Stage Flags (from conversion_rate_calculations.md)
    CASE WHEN Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END AS is_qualifying,
    CASE WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 1 ELSE 0 END AS is_discovery,
    CASE WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 1 ELSE 0 END AS is_sales_process,
    CASE WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 1 ELSE 0 END AS is_negotiating,
    CASE WHEN Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS is_signed,
    
    -- Pre-SQO Eligibility Flags (denominators)
    CASE WHEN CreatedDate IS NOT NULL THEN 1 ELSE 0 END AS eligible_for_created_conversions,
    -- UPDATED: Include ALL contacted leads (Option A: all leads moved into contacting)
    -- Logic: "Of everyone we contacted, what % became MQL?"
    -- This is tied to contacted_cohort_month for accurate date attribution
    CASE 
      WHEN is_contacted = 1 
      THEN 1 
      ELSE 0 
    END AS eligible_for_contacted_conversions,
    -- UPDATED: Only include MQLs with final outcome (became SQL or has Disposition__c) - excludes open MQLs
    CASE 
      WHEN is_mql = 1 
        AND (is_sql = 1 OR Disposition__c IS NOT NULL)
      THEN 1 
      ELSE 0 
    END AS eligible_for_mql_conversions,
    -- UPDATED: Only include SQLs with final outcome (became SQO or has Disposition__c/Closed Lost) - excludes open SQLs
    CASE 
      WHEN is_sql = 1 
        AND (
          (advisor_join_date__c IS NOT NULL OR StageName = 'Joined') OR  -- Converted: Joined
          (CASE WHEN LOWER(SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1) OR  -- Converted: SQO
          (Disposition__c IS NOT NULL OR StageName = 'Closed Lost')  -- Closed
        )
      THEN 1 
      ELSE 0 
    END AS eligible_for_sql_conversions,
    
    -- Post-SQO Eligibility Flags (denominators)
    -- Note: Must reference underlying fields directly, not the aliases defined above
    -- UPDATED: Only include SQOs with final outcome (joined or closed lost) - excludes open SQOs
    CASE 
      WHEN is_sqo = 1 
        AND (is_joined = 1 OR StageName = 'Closed Lost')
      THEN 1 
      ELSE 0 
    END AS eligible_for_sqo_conversions,
    CASE WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 1 ELSE 0 END AS eligible_for_discovery_conversions,
    CASE WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 1 ELSE 0 END AS eligible_for_sales_process_conversions,
    CASE WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 1 ELSE 0 END AS eligible_for_negotiating_conversions,
    CASE WHEN Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS eligible_for_signed_conversions,
    
    -- Pre-SQO Progression Flags (numerators)
    -- Note: Must reference underlying fields directly, not the aliases defined above
    CASE WHEN CreatedDate IS NOT NULL AND is_contacted = 1 THEN 1 ELSE 0 END AS created_to_contacted_progression,
    CASE WHEN is_contacted = 1 AND is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression,
    CASE WHEN is_mql = 1 AND is_sql = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression,
    
    -- Post-SQO Progression Flags (numerators)
    -- Note: Must reference underlying fields directly for eligibility checks
    CASE WHEN is_sqo = 1 AND Stage_Entered_Discovery__c IS NOT NULL THEN 1 ELSE 0 END AS sqo_to_discovery_progression,
    CASE WHEN Stage_Entered_Discovery__c IS NOT NULL AND Stage_Entered_Sales_Process__c IS NOT NULL THEN 1 ELSE 0 END AS discovery_to_sales_process_progression,
    CASE WHEN Stage_Entered_Sales_Process__c IS NOT NULL AND Stage_Entered_Negotiating__c IS NOT NULL THEN 1 ELSE 0 END AS sales_process_to_negotiating_progression,
    CASE WHEN Stage_Entered_Negotiating__c IS NOT NULL AND Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS negotiating_to_signed_progression,
    CASE WHEN Stage_Entered_Signed__c IS NOT NULL AND is_joined = 1 THEN 1 ELSE 0 END AS signed_to_joined_progression,
    
    -- Combined Progression Flags
    CASE WHEN is_sqo = 1 AND Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS sqo_to_signed_progression,
    CASE WHEN is_sqo = 1 AND is_joined = 1 THEN 1 ELSE 0 END AS sqo_to_joined_progression
    
  FROM BaseFunnel
)

SELECT
  -- Grouping dimensions
  -- UPDATED: Use event-based cohort months for each conversion rate
  -- FilterDate cohort_month kept for backward compatibility
  DATE_TRUNC(DATE(FilterDate), MONTH) AS cohort_month,
  -- Created cohort month for created-to-contacted scorecard (based on CreatedDate)
  DATE_TRUNC(DATE(CreatedDate), MONTH) AS created_cohort_month,
  -- Event-based cohort months for accurate date attribution
  -- Contacted→MQL: Group by when they were contacted
  contacted_cohort_month,
  -- MQL→SQL: Group by when they became MQL
  mql_cohort_month,
  -- SQL→SQO: Group by when they became SQL
  sql_cohort_month,
  -- SQO→Joined: Group by when they became SQO
  sqo_cohort_month,
  -- Post-SQO cohort months for accurate date attribution
  -- Discovery→Sales Process: Group by when they entered Discovery
  discovery_cohort_month,
  -- Sales Process→Negotiating: Group by when they entered Sales Process
  sales_process_cohort_month,
  -- Negotiating→Signed: Group by when they entered Negotiating
  negotiating_cohort_month,
  -- Signed→Joined: Group by when they entered Signed
  signed_cohort_month,
  -- Unified date dimension for combined charts
  -- NOTE: This field uses COALESCE to pick the first available date
  -- For accurate conversion rate analysis, you should use the specific cohort_month fields:
  -- - contacted_cohort_month for Contacted→MQL
  -- - mql_cohort_month for MQL→SQL  
  -- - sql_cohort_month for SQL→SQO
  -- - sqo_cohort_month for SQO→Joined
  -- 
  -- For combined charts in Looker Studio, create a calculated field using a parameter:
  -- CASE 
  --   WHEN @conversion_rate_type = 'Contacted to MQL' THEN contacted_cohort_month
  --   WHEN @conversion_rate_type = 'MQL to SQL' THEN mql_cohort_month
  --   WHEN @conversion_rate_type = 'SQL to SQO' THEN sql_cohort_month
  --   ELSE cohort_month
  -- END
  COALESCE(
    contacted_cohort_month,
    mql_cohort_month,
    sql_cohort_month,
    sqo_cohort_month,
    discovery_cohort_month,
    sales_process_cohort_month,
    negotiating_cohort_month,
    signed_cohort_month,
    DATE_TRUNC(DATE(FilterDate), MONTH)
  ) AS conversion_rate_date,
  SGA_Owner_Name__c,
  sgm_name,
  Original_source,
  Channel_Grouping_Name,
  -- Opportunity AUM for filtering (in millions)
  -- Note: This is aggregated using MAX, but for filtering in Looker Studio,
  -- you should filter on the underlying Opportunity_AUM field from vw_funnel_lead_to_joined_v2
  -- This field is included here for reference but filtering should be done at the data source level
  MAX(CASE 
    WHEN Opportunity_AUM IS NULL THEN NULL
    ELSE ROUND(Opportunity_AUM / 1000000, 2)
  END) AS Opportunity_AUM_M,
  
  -- Pre-SQO Denominators (Lead-based, use SUM) - These are also volume metrics
  SUM(eligible_for_created_conversions) AS created_denominator,
  SUM(eligible_for_created_conversions) AS created_volume,
  SUM(eligible_for_contacted_conversions) AS contacted_denominator,
  SUM(eligible_for_contacted_conversions) AS contacted_volume,
  SUM(eligible_for_mql_conversions) AS mql_denominator,
  SUM(eligible_for_mql_conversions) AS mql_volume,
  SUM(eligible_for_sql_conversions) AS sql_denominator,
  SUM(eligible_for_sql_conversions) AS sql_volume,
  
  -- Pre-SQO Numerators (Lead-based, use SUM)
  SUM(created_to_contacted_progression) AS created_to_contacted_numerator,
  SUM(contacted_to_mql_progression) AS contacted_to_mql_numerator,
  SUM(mql_to_sql_progression) AS mql_to_sql_numerator,
  
  -- SQL to SQO (Uses Opportunity ID, use COUNT DISTINCT)
  -- UPDATED: Uses eligible_for_sql_conversions which excludes open SQLs (only includes SQLs with final outcome)
  COUNT(DISTINCT CASE 
               WHEN eligible_for_sql_conversions = 1
                AND Full_Opportunity_ID__c IS NOT NULL 
               THEN Full_Opportunity_ID__c 
             END) AS sql_to_sqo_denominator,
  COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sql_to_sqo_numerator,
  
  -- Post-SQO Denominators (Uses Opportunity ID, use COUNT DISTINCT) - These are also volume metrics
  COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_volume,
  COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS qualifying_volume,
  COUNT(DISTINCT CASE WHEN eligible_for_discovery_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS discovery_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_discovery_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS discovery_volume,
  COUNT(DISTINCT CASE WHEN eligible_for_sales_process_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sales_process_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_sales_process_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sales_process_volume,
  COUNT(DISTINCT CASE WHEN eligible_for_negotiating_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS negotiating_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_negotiating_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS negotiating_volume,
  COUNT(DISTINCT CASE WHEN eligible_for_signed_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS signed_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_signed_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS signed_volume,
  
  -- Post-SQO Numerators (Uses Opportunity ID, use COUNT DISTINCT)
  COUNT(DISTINCT CASE WHEN sqo_to_discovery_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_to_discovery_numerator,
  COUNT(DISTINCT CASE WHEN discovery_to_sales_process_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS discovery_to_sales_process_numerator,
  COUNT(DISTINCT CASE WHEN sales_process_to_negotiating_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sales_process_to_negotiating_numerator,
  COUNT(DISTINCT CASE WHEN negotiating_to_signed_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS negotiating_to_signed_numerator,
  COUNT(DISTINCT CASE WHEN signed_to_joined_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS signed_to_joined_numerator,
  
  -- Combined Rates Denominators (Uses Opportunity ID, use COUNT DISTINCT)
  COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_to_signed_denominator,
  COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_to_joined_denominator,
  
  -- Combined Rates Numerators (Uses Opportunity ID, use COUNT DISTINCT)
  COUNT(DISTINCT CASE WHEN sqo_to_signed_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_to_signed_numerator,
  COUNT(DISTINCT CASE WHEN sqo_to_joined_progression = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                     THEN Full_Opportunity_ID__c END) AS sqo_to_joined_numerator

FROM FunnelWithFlags
WHERE SGA_Owner_Name__c IS NOT NULL 
  AND SGA_Owner_Name__c != 'Savvy Operations'  -- Exclude Savvy Operations (not an SGA)
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15

