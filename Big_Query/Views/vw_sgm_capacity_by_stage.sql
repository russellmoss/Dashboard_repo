-- vw_sgm_capacity_by_stage: SGM Capacity Model with Stage Breakdown
-- Provides detailed metrics by SGM and Stage for capacity planning
-- Use this view for pivot tables in Looker Studio showing stage breakdown

WITH Active_SGMs AS (
  SELECT DISTINCT
    u.Name AS sgm_name,
    u.Id AS sgm_user_id
  FROM `savvy-gtm-analytics.SavvyGTMData.User` u
  WHERE u.Is_SGM__c = TRUE 
    AND u.IsActive = TRUE
    AND u.Name NOT IN ('Savvy Marketing', 'Savvy Operations')
),

Opp_Base AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.CreatedDate AS Opp_CreatedDate,
    o.Underwritten_AUM__c,
    o.Margin_AUM__c,
    o.Amount,
    o.StageName,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Signed__c,
    o.advisor_join_date__c,
    o.SQL__c AS SQO_raw,
    o.IsClosed,
    o.CloseDate,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    opp_owner_user.Id AS sgm_user_id,
    COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM,
    CASE WHEN LOWER(o.SQL__c) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    CASE WHEN o.StageName = 'Signed' THEN 1 ELSE 0 END AS is_signed,
    DATE_TRUNC(DATE(o.CreatedDate), MONTH) AS opp_created_month,
    DATE_TRUNC(DATE(o.CreatedDate), QUARTER) AS opp_created_quarter,
    EXTRACT(YEAR FROM DATE(o.CreatedDate)) AS opp_created_year
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
)

SELECT
  o.sgm_name,
  o.sgm_user_id,
  COALESCE(o.StageName, 'Unknown') AS stage_name,
  -- Time dimensions
  o.opp_created_month,
  o.opp_created_quarter,
  o.opp_created_year,
  -- Count metrics
  COUNT(DISTINCT o.Full_Opportunity_ID__c) AS opportunity_count,
  COUNT(DISTINCT CASE WHEN o.is_sqo = 1 THEN o.Full_Opportunity_ID__c END) AS sqo_count,
  COUNT(DISTINCT CASE WHEN o.is_signed = 1 THEN o.Full_Opportunity_ID__c END) AS signed_count,
  COUNT(DISTINCT CASE WHEN o.is_joined = 1 THEN o.Full_Opportunity_ID__c END) AS joined_count,
  -- AUM metrics
  SUM(o.Underwritten_AUM__c) AS total_aum,
  SUM(o.Margin_AUM__c) AS total_margin_aum,
  SUM(o.Opportunity_AUM) AS total_opportunity_aum,
  -- Open vs Closed
  COUNT(DISTINCT CASE WHEN o.IsClosed = FALSE THEN o.Full_Opportunity_ID__c END) AS open_opportunity_count,
  COUNT(DISTINCT CASE WHEN o.IsClosed = TRUE THEN o.Full_Opportunity_ID__c END) AS closed_opportunity_count,
  -- Average AUM per opportunity in this stage
  CASE 
    WHEN COUNT(DISTINCT o.Full_Opportunity_ID__c) > 0 
    THEN SUM(o.Underwritten_AUM__c) / COUNT(DISTINCT o.Full_Opportunity_ID__c)
    ELSE 0 
  END AS avg_aum_per_opp,
  CASE 
    WHEN COUNT(DISTINCT o.Full_Opportunity_ID__c) > 0 
    THEN SUM(o.Margin_AUM__c) / COUNT(DISTINCT o.Full_Opportunity_ID__c)
    ELSE 0 
  END AS avg_margin_aum_per_opp
FROM Opp_Base o
INNER JOIN Active_SGMs sgm
  ON o.sgm_name = sgm.sgm_name
GROUP BY
  o.sgm_name,
  o.sgm_user_id,
  o.StageName,
  o.opp_created_month,
  o.opp_created_quarter,
  o.opp_created_year
ORDER BY
  o.sgm_name,
  o.opp_created_quarter DESC,
  o.StageName

