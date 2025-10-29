-- Recruitment Firm Summary View
-- This view provides a comprehensive summary of all records with Original_source = 'Recruitment Firm'
SELECT
  DATE(COALESCE(CreatedDate, FilterDate)) AS Created_Date,
  Full_prospect_id__c AS Prospect_ID,
  External_Agency__c AS External_Agency,
  COALESCE(LastName, SPLIT(REGEXP_REPLACE(Opp_Name, r'\s*\(.*\)\s*', ''), ' ')[SAFE_OFFSET(1)]) AS Last_Name,
  COALESCE(FirstName, SPLIT(REGEXP_REPLACE(Opp_Name, r'\s*\(.*\)\s*', ''), ' ')[SAFE_OFFSET(0)]) AS First_Name,
  COALESCE(Company, Firm_Name__c) AS Company_Account,
  Status AS Prospect_Status,
  Disposition__c AS Disposition,
  converted_date_raw AS Converted_Date,
  
  -- SQO Status (yes, no, open but has not entered SQO, Open in SQO stage, Closed Lost, Joined)
  CASE
    WHEN StageName = 'Closed Lost' THEN 'Closed Lost'
    WHEN StageName = 'Joined' THEN 'Joined'
    WHEN Disposition__c IS NOT NULL THEN 'No'  -- If there's a disposition, they're closed
    WHEN LOWER(SQO_raw) = 'yes' AND StageName NOT IN ('Closed Lost', 'Joined') THEN 'Open in SQO stage'  -- SQO'd but still in process
    WHEN LOWER(SQO_raw) = 'no' THEN 'No'
    WHEN is_sql = 1 AND SQO_raw IS NULL AND is_sqo = 0 THEN 'Open in SQO stage'
    WHEN is_sql = 0 THEN 'Open but has not entered SQO'
    ELSE 'Open but has not entered SQO'
  END AS SQO,
  
  StageName AS Stage,
  Full_Opportunity_ID__c AS Full_Opportunity_ID,
  NextStep AS Next_Steps,
  Earliest_Anticipated_Start_Date__c AS Earliest_Anticipated_Start_Date

FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
WHERE Original_source = 'Recruitment Firm'

-- Query to verify the count and specific opportunity:
-- SELECT COUNT(*) as total_records FROM `savvy-gtm-analytics.savvy_analytics.vw_recruitment_firm_summary`  -- Should return 215
-- SELECT * FROM `savvy-gtm-analytics.savvy_analytics.vw_recruitment_firm_summary` WHERE Full_Opportunity_ID = '006VS00000RytRuYAJ'

