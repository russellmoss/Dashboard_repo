CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` AS
WITH Lead_Base AS (
  SELECT
    l.Full_prospect_id__c,
    l.Name AS Prospect_Name,
    l.FirstName,
    l.LastName,
    l.CreatedDate,
    l.OwnerID,
    l.SGA_Owner_Name__c,
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
    ) AS FilterDate,
    -- Lead Owner User fields
    lead_owner.Id AS Lead_Owner_Id,
    lead_owner.IsSGA__c AS Lead_Owner_IsSGA__c,
    lead_owner.Is_SGM__c AS Lead_Owner_Is_SGM__c,
    lead_owner.IsActive AS Lead_Owner_IsActive,
    lead_owner.FirstName AS Lead_Owner_FirstName,
    lead_owner.LastName AS Lead_Owner_LastName
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` lead_owner
    ON l.OwnerID = lead_owner.Id
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
    o.CloseDate, -- *** FIELD ADDED HERE ***
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
    -- Opportunity Owner User fields
    opp_owner_user.Id AS Opp_Owner_Id,
    opp_owner_user.IsSGA__c AS Opp_Owner_IsSGA__c,
    opp_owner_user.Is_SGM__c AS Opp_Owner_Is_SGM__c,
    opp_owner_user.IsActive AS Opp_Owner_IsActive,
    opp_owner_user.FirstName AS Opp_Owner_FirstName,
    opp_owner_user.LastName AS Opp_Owner_LastName
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
    ON o.SGA__c = sga_user.Id
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
)

SELECT
  -- Composite Primary Key that works for both leads and opportunities
  COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key,
  -- SQO Primary Key: Always use opportunity ID for SQO counting to ensure one SQO = one opportunity
  o.Full_Opportunity_ID__c AS sqo_primary_key,
  
  -- Lead fields
  l.Full_prospect_id__c,
  l.Prospect_Name,
  l.FirstName,
  l.LastName,
  COALESCE(o.Opp_Name, l.Prospect_Name) AS advisor_name,
  l.CreatedDate,
  l.OwnerID,
  -- Lead Owner User fields
  l.Lead_Owner_Id,
  l.Lead_Owner_IsSGA__c,
  l.Lead_Owner_Is_SGM__c,
  l.Lead_Owner_IsActive,
  l.Lead_Owner_FirstName,
  l.Lead_Owner_LastName,
  -- Prioritize opportunity's SGA for SQOs (only when lead name matches opp name); otherwise preserve lead's SGA
  -- Uses flexible name matching to handle cases where names have different suffixes/prefixes
  CASE
    WHEN LOWER(o.SQO_raw) = 'yes' 
      AND (l.Prospect_Name IS NULL 
           OR l.Prospect_Name = o.Opp_Name 
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL AND STARTS_WITH(o.Opp_Name, l.Prospect_Name))
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL 
               AND (STARTS_WITH(l.Prospect_Name, SPLIT(o.Opp_Name, ' - ')[OFFSET(0)])
                    OR (ARRAY_LENGTH(SPLIT(o.Opp_Name, ' ')) >= 2 
                        AND STARTS_WITH(l.Prospect_Name, CONCAT(SPLIT(o.Opp_Name, ' ')[OFFSET(0)], ' ', SPLIT(o.Opp_Name, ' ')[OFFSET(1)])))))
           OR o.Opp_Name IS NULL)
    THEN o.sga_name_from_opp  -- SQOs use opportunity SGA (only for primary lead)
    WHEN o.Full_Opportunity_ID__c IS NOT NULL AND l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp  -- Opportunity-only records
    WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
    ELSE l.SGA_Owner_Name__c  -- Non-SQO records use lead's SGA
  END AS SGA_Owner_Name__c,
  -- SGA User fields (based on SGA_Owner_Name__c, not Owner)
  sga_user_check.Id AS SGA_User_Id,
  sga_user_check.IsSGA__c AS SGA_IsSGA__c,
  sga_user_check.Is_SGM__c AS SGA_Is_SGM__c,
  sga_user_check.IsActive AS SGA_IsActive,
  CASE 
    WHEN (sga_user_check.IsSGA__c = TRUE OR sga_user_check.Is_SGM__c = TRUE) AND sga_user_check.IsActive = TRUE 
    THEN TRUE 
    ELSE FALSE 
  END AS SGA_IsActiveSGA,
  -- Simple boolean fields for filtering (based on SGA user)
  CASE WHEN sga_user_check.IsSGA__c = TRUE THEN TRUE ELSE FALSE END AS is_SGA,
  CASE WHEN sga_user_check.Is_SGM__c = TRUE THEN TRUE ELSE FALSE END AS is_SGM,
  CASE WHEN sga_user_check.IsActive = TRUE THEN TRUE ELSE FALSE END AS is_Active,
  l.Company,
  l.lead_list_name__c,
  l.Experimentation_Tag__c,
  l.Lead_Original_Source,
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
  
  -- *** NEW CALCULATED FIELD ADDED HERE ***
  COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM,
  
  o.StageName,

  -- *** ADDED THIS BLOCK FOR SORTING ***
  CASE
    WHEN o.StageName = 'Qualifying' THEN 1
    WHEN o.StageName = 'Discovery' THEN 2
    WHEN o.StageName = 'Sales Process' THEN 3
    WHEN o.StageName = 'Negotiating' THEN 4
    WHEN o.StageName = 'Signed' THEN 5
    WHEN o.StageName = 'On Hold' THEN 6
    WHEN o.StageName = 'Closed' THEN 7
    ELSE NULL -- Any other stages (or NULLs) won't have a code
  END AS StageName_code,
  
  o.isClosed,
  o.CloseDate, -- *** FIELD ADDED HERE ***
  o.Opportunity_Owner_Name__c,
  o.sgm_name,
  -- Opportunity Owner User fields
  o.Opp_Owner_Id,
  o.Opp_Owner_IsSGA__c,
  o.Opp_Owner_Is_SGM__c,
  o.Opp_Owner_IsActive,
  o.Opp_Owner_FirstName,
  o.Opp_Owner_LastName,
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

  -- Attribution & outcomes
  IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
  COALESCE(o.Opp_Original_Source, l.Lead_Original_Source, 'Unknown') AS Original_source,
  COALESCE(o.External_Agency__c, l.External_Agency__c) AS External_Agency__c,
  o.SQO_raw,
  o.Date_Became_SQO__c,
  o.advisor_join_date__c,
  
  -- *** NEW: is_joined calculated in BigQuery (not Looker) ***
  CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
  
  -- *** Conversion tracking fields ***
  -- SQO binary flag: Only mark as SQO if opportunity is SQO AND (lead name matches opp name OR no lead exists)
  -- Uses flexible name matching to handle cases where names have different suffixes/prefixes
  -- Examples: "Tyler Brooks Re-Engaged" (lead) vs "Tyler Brooks - 11/25" (opp)
  -- Logic: Check if lead name starts with the core name from opp (before " - " or first 2 words)
  -- Safety: Check array length before accessing OFFSET(1) to avoid out-of-bounds errors
  CASE 
    WHEN LOWER(o.SQO_raw) = 'yes' 
      AND (l.Prospect_Name IS NULL 
           OR l.Prospect_Name = o.Opp_Name 
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL AND STARTS_WITH(o.Opp_Name, l.Prospect_Name))
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL 
               AND (STARTS_WITH(l.Prospect_Name, SPLIT(o.Opp_Name, ' - ')[OFFSET(0)])
                    OR (ARRAY_LENGTH(SPLIT(o.Opp_Name, ' ')) >= 2 
                        AND STARTS_WITH(l.Prospect_Name, CONCAT(SPLIT(o.Opp_Name, ' ')[OFFSET(0)], ' ', SPLIT(o.Opp_Name, ' ')[OFFSET(1)])))))
           OR o.Opp_Name IS NULL)
    THEN 1 
    ELSE 0 
  END AS is_sqo,
  
  -- TOF Stage field for unified funnel view
  CASE
    WHEN o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined' THEN 'Joined'
    WHEN CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 'SQO'
    WHEN l.is_sql = 1 THEN 'SQL'
    WHEN l.is_mql = 1 THEN 'MQL'
    ELSE NULL
  END AS TOF_Stage,
  
  -- Unified Conversion Status (Open/Closed/Joined) for all stages
  CASE
    -- Joined records are always "Joined" regardless of funnel stage
    WHEN o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined' THEN 'Joined'
    
    -- SQO Conversion Status
    WHEN CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN
      CASE
        WHEN l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost' THEN 'Closed'
        WHEN l.Disposition__c IS NULL 
          AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
        THEN 'Open'
        ELSE 'Closed'
      END
    
    -- SQL Conversion Status
    WHEN l.is_sql = 1 THEN
      CASE
        WHEN l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost' THEN 'Closed'
        WHEN l.Disposition__c IS NULL 
          AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
        THEN 'Open'
        ELSE 'Closed'
      END
    
    -- MQL Conversion Status
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
  
  -- Binary conversion flags
  CASE WHEN l.is_mql = 1 AND l.is_sql = 1 THEN 1 ELSE 0 END AS Converted_from_mql,
  CASE WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 1 ELSE 0 END AS Converted_from_sql,
  
  -- MQL Conversion Status (Converted/Closed/Open/Stage not entered)
  CASE 
    WHEN l.is_mql = 0 THEN 'Stage not entered'  -- Not an MQL, so no status
    WHEN l.is_mql = 1 AND (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') THEN 'Converted'  -- Joined = Converted regardless
    WHEN l.is_mql = 1 AND l.is_sql = 1 
      AND l.Disposition__c IS NULL
      AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
    THEN 'Converted'  -- MQL that converted to SQL and still active (not closed/joined)
    WHEN l.is_mql = 1 AND l.is_sql = 1 
      AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
    THEN 'Closed'  -- MQL that converted to SQL but got closed lost
    WHEN l.is_mql = 1 AND l.is_sql = 0 
      AND l.Disposition__c IS NULL
    THEN 'Open'  -- MQL but hasn't converted to SQL yet and not closed
    WHEN l.is_mql = 1 AND l.is_sql = 0 
      AND l.Disposition__c IS NOT NULL
    THEN 'Closed'  -- MQL that didn't convert and got closed
    ELSE 'Stage not entered'
  END AS MQL_conversion_status,
  
  -- SQL Conversion Status (Converted/Closed Lost/Open)
  -- Uses same logic as conversion_status: Converted when SQO, Closed Lost when disposition/closed, Open otherwise
  CASE
    -- Converted: When SQL has become SQO
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 THEN 'Converted'
    -- Closed Lost: When there's a disposition or StageName is Closed Lost
    WHEN l.is_sql = 1 AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost') THEN 'Closed Lost'
    -- Open: When they have SQL'd but haven't converted to SQO and haven't closed lost
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0 
     AND (l.Disposition__c IS NULL AND (o.StageName IS NULL OR o.StageName != 'Closed Lost'))
    THEN 'Open'
    ELSE NULL
  END AS SQL_conversion_status

FROM Lead_Base l
FULL OUTER JOIN Opp_Base o
  ON l.converted_oppty_id = o.Full_Opportunity_ID__c
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
  ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user_check
  ON CASE
    WHEN LOWER(o.SQO_raw) = 'yes' 
      AND (l.Prospect_Name IS NULL 
           OR l.Prospect_Name = o.Opp_Name 
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL AND STARTS_WITH(o.Opp_Name, l.Prospect_Name))
           OR (l.Prospect_Name IS NOT NULL AND o.Opp_Name IS NOT NULL 
               AND (STARTS_WITH(l.Prospect_Name, SPLIT(o.Opp_Name, ' - ')[OFFSET(0)])
                    OR (ARRAY_LENGTH(SPLIT(o.Opp_Name, ' ')) >= 2 
                        AND STARTS_WITH(l.Prospect_Name, CONCAT(SPLIT(o.Opp_Name, ' ')[OFFSET(0)], ' ', SPLIT(o.Opp_Name, ' ')[OFFSET(1)])))))
           OR o.Opp_Name IS NULL)
    THEN o.sga_name_from_opp  -- SQOs use opportunity SGA (only for primary lead)
    WHEN o.Full_Opportunity_ID__c IS NOT NULL AND l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp  -- Opportunity-only records
    WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
    ELSE l.SGA_Owner_Name__c  -- Non-SQO records use lead's SGA
  END = sga_user_check.Name
