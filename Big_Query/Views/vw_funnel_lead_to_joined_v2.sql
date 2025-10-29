WITH Lead_Base AS (
  SELECT
    Full_prospect_id__c,
    Name AS Prospect_Name,
    FirstName,
    LastName,
    CreatedDate,
    OwnerID,
    SGA_Owner_Name__c,
    Company,
    lead_list_name__c,
    Experimentation_Tag__c,
    LeadSource AS Lead_Original_Source,
    External_Agency__c,
    Disposition__c,
    Status,
    stage_entered_contacting__c,
    Initial_Call_Scheduled_Date__c,
    stage_entered_new__c,
    Stage_Entered_Call_Scheduled__c AS mql_stage_entered_ts,
    ConvertedDate AS converted_date_raw,
    IsConverted AS is_converted_raw,
    ConvertedOpportunityId AS converted_oppty_id,
    CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    CASE WHEN initial_call_scheduled_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_initial_call,
    FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(initial_call_scheduled_date__c), WEEK(MONDAY))) AS Week_Bucket_MQL_Call,
    DATE_TRUNC(DATE(Stage_Entered_Contacting__c), WEEK(MONDAY)) AS Week_Bucket_MQL_Date,
    CASE WHEN IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql,
    FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(ConvertedDate), WEEK(MONDAY))) AS Week_Bucket_SQL,
    DATE_TRUNC(DATE(ConvertedDate), WEEK(MONDAY)) AS Week_Bucket_SQL_Date,
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
    o.Name AS Opp_Name,
    o.CreatedDate AS Opp_CreatedDate,
    sga_user.Name AS sga_name_from_opp,
    manager_user.Name AS sgm_name,
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
    o.OwnerId
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
    ON o.SGA__c = sga_user.Id
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` manager_user
    ON opp_owner_user.ManagerId = manager_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
)

SELECT
  -- Composite Primary Key that works for both leads and opportunities
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
  -- SQO binary flag
  CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
  
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
  
  -- SQL Conversion Status (Converted/Closed/Open/Stage not entered)
  CASE 
    WHEN l.is_sql = 0 THEN 'Stage not entered'  -- Not an SQL, so no status
    WHEN l.is_sql = 1 AND (o.advisor_join_date__c IS NOT NULL OR o.StageName = 'Joined') THEN 'Converted'  -- Joined = Converted regardless
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1 
      AND l.Disposition__c IS NULL
      AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
    THEN 'Converted'  -- SQL that converted to SQO and still active (not closed/joined)
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 1
      AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
    THEN 'Closed'  -- SQL that converted to SQO but got closed lost
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0 
      AND l.Disposition__c IS NULL
      AND (o.StageName IS NULL OR (o.StageName != 'Closed Lost' AND o.StageName != 'Joined'))
    THEN 'Open'  -- SQL but hasn't converted to SQO yet and not closed/joined
    WHEN l.is_sql = 1 AND CASE WHEN LOWER(o.SQO_raw) = 'yes' THEN 1 ELSE 0 END = 0
      AND (l.Disposition__c IS NOT NULL OR o.StageName = 'Closed Lost')
    THEN 'Closed'  -- SQL that didn't convert to SQO and got closed
    ELSE 'Stage not entered'
  END AS SQL_conversion_status

FROM Lead_Base l
FULL OUTER JOIN Opp_Base o
  ON l.converted_oppty_id = o.Full_Opportunity_ID__c
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
  ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
