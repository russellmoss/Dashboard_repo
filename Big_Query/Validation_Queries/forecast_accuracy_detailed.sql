-- Forecast Accuracy Validation - Detailed View
-- Shows individual deal-level forecast accuracy for deeper analysis
-- Useful for identifying patterns and outliers

WITH Current_Date_Context AS (
  SELECT
    CURRENT_DATE() AS current_date,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) AS current_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS current_quarter_end,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS next_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 6 MONTH) AS next_quarter_end
),

Historical_Joined_Deals AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.Name AS opportunity_name,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    o.StageName,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Discovery__c,
    o.Stage_Entered_Sales_Process__c,
    o.Stage_Entered_Negotiating__c,
    o.Stage_Entered_Signed__c,
    o.advisor_join_date__c AS actual_join_date,
    DATE_TRUNC(DATE(o.advisor_join_date__c), QUARTER) AS actual_join_quarter,
    o.Margin_AUM__c,
    o.Underwritten_AUM__c,
    o.Amount,
    CASE
      WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c / 1000000
      WHEN o.Underwritten_AUM__c IS NOT NULL AND o.Underwritten_AUM__c > 0 THEN (o.Underwritten_AUM__c / 3.125) / 1000000
      WHEN o.Amount IS NOT NULL AND o.Amount > 0 THEN (o.Amount / 3.22) / 1000000
      ELSE 0
    END AS estimated_margin_aum
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND LOWER(o.SQL__c) = 'yes'
    AND o.advisor_join_date__c IS NOT NULL
    AND o.Date_Became_SQO__c IS NOT NULL
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND o.advisor_join_date__c >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),

Forecast_Calculations AS (
  SELECT
    h.*,
    CASE
      WHEN h.Stage_Entered_Signed__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Signed__c), INTERVAL 16 DAY)
      WHEN h.Stage_Entered_Negotiating__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Negotiating__c), INTERVAL 37 DAY)
      WHEN h.Stage_Entered_Sales_Process__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY)
      WHEN h.Stage_Entered_Discovery__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Discovery__c), INTERVAL 62 DAY)
      ELSE DATE_ADD(DATE(h.Date_Became_SQO__c), INTERVAL 70 DAY)
    END AS forecasted_join_date,
    CASE
      WHEN h.Stage_Entered_Signed__c IS NOT NULL THEN 'Signed'
      WHEN h.Stage_Entered_Negotiating__c IS NOT NULL THEN 'Negotiating'
      WHEN h.Stage_Entered_Sales_Process__c IS NOT NULL THEN 'Sales Process'
      WHEN h.Stage_Entered_Discovery__c IS NOT NULL THEN 'Discovery'
      ELSE 'Default (SQO+70)'
    END AS forecast_stage_used
  FROM Historical_Joined_Deals h
  CROSS JOIN Current_Date_Context c
)

SELECT
  sgm_name,
  opportunity_name,
  forecast_stage_used,
  Date_Became_SQO__c AS sqo_date,
  actual_join_date,
  forecasted_join_date,
  DATE_DIFF(actual_join_date, forecasted_join_date, DAY) AS days_difference,
  CASE
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) < -30 THEN 'Forecast Too Late (>30 days early)'
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) < -14 THEN 'Forecast Too Late (14-30 days early)'
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) < -7 THEN 'Forecast Too Late (7-14 days early)'
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) <= 7 THEN 'Accurate (±7 days)'
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) <= 14 THEN 'Forecast Too Early (7-14 days late)'
    WHEN DATE_DIFF(actual_join_date, forecasted_join_date, DAY) <= 30 THEN 'Forecast Too Early (14-30 days late)'
    ELSE 'Forecast Too Early (>30 days late)'
  END AS accuracy_category,
  DATE_TRUNC(forecasted_join_date, QUARTER) AS forecasted_quarter,
  actual_join_quarter,
  CASE
    WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = actual_join_quarter THEN 'Correct Quarter'
    WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = DATE_ADD(actual_join_quarter, INTERVAL 3 MONTH) THEN 'One Quarter Early'
    WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = DATE_SUB(actual_join_quarter, INTERVAL 3 MONTH) THEN 'One Quarter Late'
    ELSE 'Wrong Quarter'
  END AS quarter_accuracy,
  estimated_margin_aum
FROM Forecast_Calculations
ORDER BY ABS(days_difference) DESC, sgm_name, opportunity_name

