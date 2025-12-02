-- Forecast Accuracy by Time Period
-- Analyzes forecast accuracy trends over time to identify if accuracy is improving/degrading
-- Groups by month/quarter of actual join date

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
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    o.StageName,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Discovery__c,
    o.Stage_Entered_Sales_Process__c,
    o.Stage_Entered_Negotiating__c,
    o.Stage_Entered_Signed__c,
    o.advisor_join_date__c AS actual_join_date,
    DATE_TRUNC(DATE(o.advisor_join_date__c), QUARTER) AS actual_join_quarter,
    DATE_TRUNC(DATE(o.advisor_join_date__c), MONTH) AS actual_join_month,
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
),

Accuracy_Metrics AS (
  SELECT
    *,
    DATE_DIFF(actual_join_date, forecasted_join_date, DAY) AS days_difference,
    CASE
      WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = actual_join_quarter THEN 1
      ELSE 0
    END AS quarter_correct
  FROM Forecast_Calculations
)

-- Accuracy by Quarter
SELECT
  'By Quarter' AS grouping_type,
  CAST(actual_join_quarter AS STRING) AS time_period,
  COUNT(*) AS total_deals,
  ROUND(AVG(ABS(days_difference)), 2) AS avg_absolute_days_error,
  ROUND(APPROX_QUANTILES(ABS(days_difference), 100)[OFFSET(50)], 2) AS median_absolute_days_error,
  ROUND(AVG(days_difference), 2) AS avg_days_error,
  SUM(quarter_correct) AS deals_with_correct_quarter,
  ROUND(SUM(quarter_correct) * 100.0 / COUNT(*), 2) AS quarter_accuracy_pct,
  COUNT(CASE WHEN ABS(days_difference) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(days_difference) <= 14 THEN 1 END) AS within_14_days,
  COUNT(CASE WHEN ABS(days_difference) <= 30 THEN 1 END) AS within_30_days,
  ROUND(SUM(estimated_margin_aum), 2) AS total_margin_aum_millions
FROM Accuracy_Metrics
GROUP BY actual_join_quarter

UNION ALL

-- Accuracy by Month
SELECT
  'By Month' AS grouping_type,
  CAST(actual_join_month AS STRING) AS time_period,
  COUNT(*) AS total_deals,
  ROUND(AVG(ABS(days_difference)), 2) AS avg_absolute_days_error,
  ROUND(APPROX_QUANTILES(ABS(days_difference), 100)[OFFSET(50)], 2) AS median_absolute_days_error,
  ROUND(AVG(days_difference), 2) AS avg_days_error,
  SUM(quarter_correct) AS deals_with_correct_quarter,
  ROUND(SUM(quarter_correct) * 100.0 / COUNT(*), 2) AS quarter_accuracy_pct,
  COUNT(CASE WHEN ABS(days_difference) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(days_difference) <= 14 THEN 1 END) AS within_14_days,
  COUNT(CASE WHEN ABS(days_difference) <= 30 THEN 1 END) AS within_30_days,
  ROUND(SUM(estimated_margin_aum), 2) AS total_margin_aum_millions
FROM Accuracy_Metrics
GROUP BY actual_join_month
HAVING COUNT(*) >= 3  -- Only show months with at least 3 deals

ORDER BY grouping_type, time_period DESC

