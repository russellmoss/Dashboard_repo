-- Forecast Accuracy Validation Query
-- This query tests the accuracy of the quarterly forecast by comparing:
-- 1. Forecasted join date vs actual join date
-- 2. Forecasted quarter vs actual quarter
-- 3. Accuracy by stage
-- 4. Accuracy by SGM
--
-- Uses historical data: Deals that have already joined
-- Simulates what the forecast would have predicted at the time they were in pipeline

WITH Current_Date_Context AS (
  SELECT
    CURRENT_DATE() AS current_date,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) AS current_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS current_quarter_end,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS next_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 6 MONTH) AS next_quarter_end
),

-- Get historical deals that have joined (for validation)
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
    -- Calculate what stage the deal was in 30 days before joining (simulating forecast point)
    -- For simplicity, we'll use the stage entry dates to determine stage at forecast point
    o.Margin_AUM__c,
    o.Underwritten_AUM__c,
    o.Amount,
    -- Estimated Margin_AUM__c using fallback logic:
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
    -- Only include deals that joined in last 12 months for relevance
    AND o.advisor_join_date__c >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),

-- Calculate forecasted join date using the same logic as the forecast view
Forecast_Calculations AS (
  SELECT
    h.*,
    c.current_date,
    c.current_quarter_start,
    c.current_quarter_end,
    c.next_quarter_start,
    c.next_quarter_end,
    -- Calculate forecasted join date using same logic as forecast view
    CASE
      -- Signed: 16 days from stage entry
      WHEN h.Stage_Entered_Signed__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Signed__c), INTERVAL 16 DAY)
      -- Negotiating: 37 days from stage entry
      WHEN h.Stage_Entered_Negotiating__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Negotiating__c), INTERVAL 37 DAY)
      -- Sales Process: 69 days from stage entry
      WHEN h.Stage_Entered_Sales_Process__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY)
      -- Discovery: 62 days from stage entry
      WHEN h.Stage_Entered_Discovery__c IS NOT NULL 
        THEN DATE_ADD(DATE(h.Stage_Entered_Discovery__c), INTERVAL 62 DAY)
      -- Default: SQO date + 70 days
      ELSE DATE_ADD(DATE(h.Date_Became_SQO__c), INTERVAL 70 DAY)
    END AS forecasted_join_date,
    -- Determine forecasted quarter
    CASE
      WHEN h.Stage_Entered_Signed__c IS NOT NULL THEN
        CASE
          WHEN DATE_ADD(DATE(h.Stage_Entered_Signed__c), INTERVAL 16 DAY) <= c.current_quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(h.Stage_Entered_Signed__c), INTERVAL 16 DAY) <= c.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN h.Stage_Entered_Negotiating__c IS NOT NULL THEN
        CASE
          WHEN DATE_ADD(DATE(h.Stage_Entered_Negotiating__c), INTERVAL 37 DAY) <= c.current_quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(h.Stage_Entered_Negotiating__c), INTERVAL 37 DAY) <= c.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN h.Stage_Entered_Sales_Process__c IS NOT NULL THEN
        CASE
          WHEN DATE_ADD(DATE(h.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY) <= c.current_quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(h.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY) <= c.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN h.Stage_Entered_Discovery__c IS NOT NULL THEN
        CASE
          WHEN DATE_ADD(DATE(h.Stage_Entered_Discovery__c), INTERVAL 62 DAY) <= c.current_quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(h.Stage_Entered_Discovery__c), INTERVAL 62 DAY) <= c.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      ELSE
        CASE
          WHEN DATE_ADD(DATE(h.Date_Became_SQO__c), INTERVAL 70 DAY) <= c.current_quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(h.Date_Became_SQO__c), INTERVAL 70 DAY) <= c.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
    END AS forecasted_quarter
  FROM Historical_Joined_Deals h
  CROSS JOIN Current_Date_Context c
),

-- Calculate accuracy metrics
Accuracy_Metrics AS (
  SELECT
    *,
    -- Days difference between forecasted and actual
    DATE_DIFF(actual_join_date, forecasted_join_date, DAY) AS days_difference,
    -- Was forecasted quarter correct?
    CASE
      WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = actual_join_quarter THEN 1
      ELSE 0
    END AS quarter_correct,
    -- Was forecasted quarter within one quarter (current or next)?
    CASE
      WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = actual_join_quarter THEN 1
      WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = DATE_ADD(actual_join_quarter, INTERVAL 3 MONTH) THEN 1
      WHEN DATE_TRUNC(forecasted_join_date, QUARTER) = DATE_SUB(actual_join_quarter, INTERVAL 3 MONTH) THEN 1
      ELSE 0
    END AS quarter_within_one,
    -- Determine which stage was used for forecast
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 'Signed'
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 'Negotiating'
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 'Sales Process'
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 'Discovery'
      ELSE 'Default (SQO+70)'
    END AS forecast_stage_used
  FROM Forecast_Calculations
)

-- Summary Statistics
SELECT
  '=== OVERALL ACCURACY ===' AS metric_type,
  NULL AS stage_name,
  COUNT(*) AS total_deals,
  ROUND(AVG(ABS(days_difference)), 2) AS avg_absolute_days_error,
  ROUND(APPROX_QUANTILES(ABS(days_difference), 100)[OFFSET(50)], 2) AS median_absolute_days_error,
  ROUND(AVG(days_difference), 2) AS avg_days_error,
  SUM(quarter_correct) AS deals_with_correct_quarter,
  ROUND(SUM(quarter_correct) * 100.0 / COUNT(*), 2) AS quarter_accuracy_pct,
  SUM(quarter_within_one) AS deals_within_one_quarter,
  ROUND(SUM(quarter_within_one) * 100.0 / COUNT(*), 2) AS within_one_quarter_accuracy_pct,
  COUNT(CASE WHEN ABS(days_difference) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(days_difference) <= 14 THEN 1 END) AS within_14_days,
  COUNT(CASE WHEN ABS(days_difference) <= 30 THEN 1 END) AS within_30_days,
  ROUND(SUM(estimated_margin_aum), 2) AS total_margin_aum_millions
FROM Accuracy_Metrics

UNION ALL

-- Accuracy by Stage
SELECT
  '=== BY STAGE ===' AS metric_type,
  forecast_stage_used AS stage_name,
  COUNT(*) AS total_deals,
  ROUND(AVG(ABS(days_difference)), 2) AS avg_absolute_days_error,
  ROUND(APPROX_QUANTILES(ABS(days_difference), 100)[OFFSET(50)], 2) AS median_absolute_days_error,
  ROUND(AVG(days_difference), 2) AS avg_days_error,
  SUM(quarter_correct) AS deals_with_correct_quarter,
  ROUND(SUM(quarter_correct) * 100.0 / COUNT(*), 2) AS quarter_accuracy_pct,
  SUM(quarter_within_one) AS deals_within_one_quarter,
  ROUND(SUM(quarter_within_one) * 100.0 / COUNT(*), 2) AS within_one_quarter_accuracy_pct,
  COUNT(CASE WHEN ABS(days_difference) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(days_difference) <= 14 THEN 1 END) AS within_14_days,
  COUNT(CASE WHEN ABS(days_difference) <= 30 THEN 1 END) AS within_30_days,
  ROUND(SUM(estimated_margin_aum), 2) AS total_margin_aum_millions
FROM Accuracy_Metrics
GROUP BY forecast_stage_used

UNION ALL

-- Accuracy by SGM (top 10 by deal count)
SELECT
  '=== BY SGM (Top 10) ===' AS metric_type,
  sgm_name AS stage_name,
  COUNT(*) AS total_deals,
  ROUND(AVG(ABS(days_difference)), 2) AS avg_absolute_days_error,
  ROUND(APPROX_QUANTILES(ABS(days_difference), 100)[OFFSET(50)], 2) AS median_absolute_days_error,
  ROUND(AVG(days_difference), 2) AS avg_days_error,
  SUM(quarter_correct) AS deals_with_correct_quarter,
  ROUND(SUM(quarter_correct) * 100.0 / COUNT(*), 2) AS quarter_accuracy_pct,
  SUM(quarter_within_one) AS deals_within_one_quarter,
  ROUND(SUM(quarter_within_one) * 100.0 / COUNT(*), 2) AS within_one_quarter_accuracy_pct,
  COUNT(CASE WHEN ABS(days_difference) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(days_difference) <= 14 THEN 1 END) AS within_14_days,
  COUNT(CASE WHEN ABS(days_difference) <= 30 THEN 1 END) AS within_30_days,
  ROUND(SUM(estimated_margin_aum), 2) AS total_margin_aum_millions
FROM Accuracy_Metrics
WHERE sgm_name IS NOT NULL
GROUP BY sgm_name
HAVING COUNT(*) >= 3  -- Only SGMs with at least 3 deals
ORDER BY COUNT(*) DESC
LIMIT 10

ORDER BY 
  CASE metric_type
    WHEN '=== OVERALL ACCURACY ===' THEN 1
    WHEN '=== BY STAGE ===' THEN 2
    WHEN '=== BY SGM (Top 10) ===' THEN 3
  END,
  stage_name

