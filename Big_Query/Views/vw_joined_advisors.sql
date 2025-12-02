-- vw_joined_advisors: View of advisors who have ACTUALLY joined Savvy
-- Definition: o.StageName = 'Joined' AND a.Status__c = 'Joined'
-- Includes Account-level fields for roster reporting in Looker Studio

WITH Opp_Base AS (
  SELECT
    o.Id AS Opportunity_Id,
    o.Full_Opportunity_ID__c,
    o.Name AS Opp_Name,
    o.CreatedDate AS Opp_CreatedDate,
    o.AccountId,
    o.LeadSource AS Opp_LeadSource,
    o.External_Agency__c,
    o.advisor_join_date__c,
    o.Date_Became_SQO__c,
    o.StageName,
    o.Amount,
    o.Underwritten_AUM__c,
    o.Qualification_Call_Date__c,
    o.Firm_Name__c,
    o.Firm_Type__c,
    o.City_State__c,
    o.OwnerId,
    -- SGA Owner from Opportunity
    sga_user.Name AS sga_name_from_opp,
    -- SGM Owner from Opportunity Owner
    CASE WHEN opp_owner_user.is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
    ON o.SGA__c = sga_user.Id
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.StageName = 'Joined'
),

Account_Base AS (
  SELECT
    a.Id AS Account_Id,
    a.Name,
    a.AccountSource,
    a.Full_Account_ID__c,
    a.Total_Underwritten_AUM__c,
    a.Account_Total_AUM__c,
    a.Account_Total_ARR__c,
    a.BillingCity,
    a.BillingState,
    a.ShippingCity,
    a.ShippingState,
    a.Status__c
  FROM `savvy-gtm-analytics.SavvyGTMData.Account` a
  WHERE a.Status__c = 'Joined'
),

-- State normalization: Convert full state names to 2-letter codes
State_Normalized AS (
  SELECT
    ab.*,
    -- Normalize state: Convert full names to 2-letter codes, use ShippingState as fallback if BillingState is NULL
    CASE 
      -- If already a 2-letter code, return uppercase
      WHEN LENGTH(COALESCE(ab.BillingState, ab.ShippingState)) = 2 
        THEN UPPER(COALESCE(ab.BillingState, ab.ShippingState))
      -- Full state name mappings (only check if length > 2)
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'ALABAMA' THEN 'AL'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'ALASKA' THEN 'AK'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'ARIZONA' THEN 'AZ'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'ARKANSAS' THEN 'AR'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'CALIFORNIA' THEN 'CA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'COLORADO' THEN 'CO'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'CONNECTICUT' THEN 'CT'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'DELAWARE' THEN 'DE'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'FLORIDA' THEN 'FL'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'GEORGIA' THEN 'GA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'HAWAII' THEN 'HI'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'IDAHO' THEN 'ID'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'ILLINOIS' THEN 'IL'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'INDIANA' THEN 'IN'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'IOWA' THEN 'IA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'KANSAS' THEN 'KS'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'KENTUCKY' THEN 'KY'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'LOUISIANA' THEN 'LA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MAINE' THEN 'ME'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MARYLAND' THEN 'MD'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MASSACHUSETTS' THEN 'MA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MICHIGAN' THEN 'MI'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MINNESOTA' THEN 'MN'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MISSISSIPPI' THEN 'MS'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MISSOURI' THEN 'MO'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'MONTANA' THEN 'MT'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEBRASKA' THEN 'NE'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEVADA' THEN 'NV'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEW HAMPSHIRE' THEN 'NH'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEW JERSEY' THEN 'NJ'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEW MEXICO' THEN 'NM'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NEW YORK' THEN 'NY'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NORTH CAROLINA' THEN 'NC'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'NORTH DAKOTA' THEN 'ND'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'OHIO' THEN 'OH'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'OKLAHOMA' THEN 'OK'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'OREGON' THEN 'OR'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'PENNSYLVANIA' THEN 'PA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'RHODE ISLAND' THEN 'RI'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'SOUTH CAROLINA' THEN 'SC'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'SOUTH DAKOTA' THEN 'SD'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'TENNESSEE' THEN 'TN'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'TEXAS' THEN 'TX'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'UTAH' THEN 'UT'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'VERMONT' THEN 'VT'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'VIRGINIA' THEN 'VA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'WASHINGTON' THEN 'WA'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'WEST VIRGINIA' THEN 'WV'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'WISCONSIN' THEN 'WI'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) = 'WYOMING' THEN 'WY'
      WHEN UPPER(COALESCE(ab.BillingState, ab.ShippingState)) IN ('DISTRICT OF COLUMBIA', 'WASHINGTON DC') THEN 'DC'
      ELSE COALESCE(ab.BillingState, ab.ShippingState)  -- Return original if no match (handles edge cases)
    END AS State_Normalized
  FROM Account_Base ab
),

Lead_Base AS (
  SELECT
    l.Full_prospect_id__c,
    l.LeadSource AS Lead_Original_Source,
    l.External_Agency__c AS Lead_External_Agency__c,
    l.ConvertedOpportunityId AS converted_oppty_id,
    l.SGA_Owner_Name__c AS Lead_SGA_Owner_Name__c
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
)

SELECT
  -- Primary Keys
  o.Full_Opportunity_ID__c,
  a.Account_Id,
  a.Full_Account_ID__c,
  
  -- Account Fields (for roster reporting)
  a.Name AS Account_Name,
  a.AccountSource,
  a.Total_Underwritten_AUM__c,
  a.Account_Total_AUM__c,
  a.Account_Total_ARR__c,
  -- City: Use BillingCity, fallback to ShippingCity if NULL
  COALESCE(a.BillingCity, a.ShippingCity) AS BillingCity,
  -- State: Normalized to 2-letter code, use ShippingState as fallback if BillingState is NULL
  a.State_Normalized AS BillingState,
  
  -- Opportunity Fields (for context)
  o.Opp_Name,
  o.Opp_CreatedDate,
  o.advisor_join_date__c,
  o.Date_Became_SQO__c,
  o.Amount,
  o.Underwritten_AUM__c,
  o.Qualification_Call_Date__c,
  o.Firm_Name__c,
  o.Firm_Type__c,
  o.City_State__c,
  
  -- Owner Information
  CASE
    WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
    WHEN l.Lead_SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
    ELSE l.Lead_SGA_Owner_Name__c
  END AS SGA_Owner_Name__c,
  o.sgm_name,
  
  -- Attribution Fields
  -- Original_Source: Use Opportunity.LeadSource (as specified by user)
  COALESCE(o.Opp_LeadSource, l.Lead_Original_Source, 'Unknown') AS Original_Source,
  COALESCE(o.External_Agency__c, l.Lead_External_Agency__c) AS External_Agency__c,
  
  -- Channel Grouping (aligned with vw_funnel_lead_to_joined_v2.sql)
  IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
  
  -- Lead Attribution (for reference)
  l.Full_prospect_id__c,
  l.Lead_Original_Source

FROM Opp_Base o
INNER JOIN State_Normalized a
  ON o.AccountId = a.Account_Id
LEFT JOIN Lead_Base l
  ON o.Full_Opportunity_ID__c = l.converted_oppty_id
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
  ON COALESCE(o.Opp_LeadSource, l.Lead_Original_Source) = g.Original_Source_Salesforce

