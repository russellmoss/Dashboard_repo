-- Capacity Estimation Backtest
-- This query backtests the accuracy of capacity estimates by:
-- 1. Looking at deals that actually joined in each quarter over the last 12 months
-- 2. Calculating what the weighted pipeline forecast would have been for those deals
-- 3. Comparing forecasted vs actual Margin_AUM
-- 4. Providing accuracy metrics
--
-- Tests:
-- - sgm_capacity_expected_joined_aum_millions_estimate (overall capacity)
-- - expected_to_join_this_quarter_margin_aum_millions (quarterly forecast)
-- - total_expected_next_quarter_margin_aum_millions (next quarter forecast)

WITH Quarter_Periods AS (
  -- Generate quarter periods for the last 12 months
  SELECT
    quarter_start,
    DATE_ADD(quarter_start, INTERVAL 3 MONTH) AS quarter_end,
    DATE_ADD(quarter_start, INTERVAL 3 MONTH) AS next_quarter_start,
    DATE_ADD(quarter_start, INTERVAL 6 MONTH) AS next_quarter_end
  FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 12 MONTH),
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    INTERVAL 1 QUARTER
  )) AS quarter_start
),

-- Get deals that joined in each quarter and calculate what forecast would have been
Joined_Deals_With_Forecast AS (
  SELECT
    q.quarter_start,
    q.quarter_end,
    q.next_quarter_start,
    q.next_quarter_end,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    o.Full_Opportunity_ID__c,
    o.Margin_AUM__c / 1000000.0 AS actual_margin_aum_millions,
    o.advisor_join_date__c,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Signed__c,
    o.Stage_Entered_Negotiating__c,
    o.Stage_Entered_Sales_Process__c,
    o.Stage_Entered_Discovery__c,
    -- Estimated Margin_AUM__c using fallback logic (what would have been used in forecast):
    CASE
      WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c / 1000000
      WHEN o.Underwritten_AUM__c IS NOT NULL AND o.Underwritten_AUM__c > 0 THEN (o.Underwritten_AUM__c / 3.125) / 1000000
      WHEN o.Amount IS NOT NULL AND o.Amount > 0 THEN (o.Amount / 3.22) / 1000000
      ELSE 0
    END AS estimated_margin_aum,
    -- Stage probability (what would have been used in forecast)
    -- Use the probability from the most advanced stage the deal was in
    -- Priority: Signed > Negotiating > Sales Process > Discovery > Default
    COALESCE(
      CASE
        WHEN o.Stage_Entered_Signed__c IS NOT NULL THEN signed_prob.probability_to_join
        WHEN o.Stage_Entered_Negotiating__c IS NOT NULL THEN negotiating_prob.probability_to_join
        WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL THEN sales_process_prob.probability_to_join
        WHEN o.Stage_Entered_Discovery__c IS NOT NULL THEN discovery_prob.probability_to_join
        ELSE default_prob.probability_to_join
      END,
      0
    ) AS stage_probability,
    -- Calculate what quarter this would have been forecasted for at quarter_start
    -- Use the stage entry dates to determine forecast quarter
    -- Only calculate if stage was entered before or during the quarter
    CASE
      WHEN o.Stage_Entered_Signed__c IS NOT NULL AND DATE(o.Stage_Entered_Signed__c) <= q.quarter_end THEN
        CASE
          WHEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 16 DAY) <= q.quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 16 DAY) <= q.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN o.Stage_Entered_Negotiating__c IS NOT NULL AND DATE(o.Stage_Entered_Negotiating__c) <= q.quarter_end THEN
        CASE
          WHEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 37 DAY) <= q.quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 37 DAY) <= q.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL AND DATE(o.Stage_Entered_Sales_Process__c) <= q.quarter_end THEN
        CASE
          WHEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY) <= q.quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 69 DAY) <= q.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN o.Stage_Entered_Discovery__c IS NOT NULL AND DATE(o.Stage_Entered_Discovery__c) <= q.quarter_end THEN
        CASE
          WHEN DATE_ADD(DATE(o.Stage_Entered_Discovery__c), INTERVAL 62 DAY) <= q.quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(o.Stage_Entered_Discovery__c), INTERVAL 62 DAY) <= q.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) <= q.quarter_end THEN
        CASE
          WHEN DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) <= q.quarter_end THEN 'Current Quarter'
          WHEN DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) <= q.next_quarter_end THEN 'Next Quarter'
          ELSE 'Beyond Next Quarter'
        END
      ELSE NULL
    END AS forecast_quarter
  FROM Quarter_Periods q
  INNER JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    ON DATE_TRUNC(DATE(o.advisor_join_date__c), QUARTER) = q.quarter_start
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` signed_prob
    ON signed_prob.StageName = 'Signed'
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` negotiating_prob
    ON negotiating_prob.StageName = 'Negotiating'
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` sales_process_prob
    ON sales_process_prob.StageName = 'Sales Process'
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` discovery_prob
    ON discovery_prob.StageName = 'Discovery'
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` default_prob
    ON default_prob.StageName = 'Qualifying'
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.StageName = 'Joined'
    AND o.advisor_join_date__c IS NOT NULL
    AND o.Margin_AUM__c IS NOT NULL
    AND o.Margin_AUM__c > 0
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND o.Date_Became_SQO__c IS NOT NULL
    AND DATE(o.Date_Became_SQO__c) <= q.quarter_start  -- Deal was SQO before quarter started
),

-- Aggregate forecasts and actuals by quarter and SGM
Quarterly_Forecast_vs_Actual AS (
  SELECT
    quarter_start,
    sgm_name,
    -- Overall capacity estimate (weighted pipeline for all active deals)
    SUM(estimated_margin_aum * stage_probability) AS forecasted_capacity,
    -- Current quarter forecast (deals forecasted to join this quarter)
    SUM(CASE 
      WHEN forecast_quarter = 'Current Quarter' 
      THEN estimated_margin_aum * stage_probability 
      ELSE 0 
    END) AS forecasted_current_quarter,
    -- Next quarter forecast (deals forecasted to join next quarter)
    SUM(CASE 
      WHEN forecast_quarter = 'Next Quarter' 
      THEN estimated_margin_aum * stage_probability 
      ELSE 0 
    END) AS forecasted_next_quarter,
    -- Actual joined Margin_AUM
    SUM(actual_margin_aum_millions) AS actual_joined_margin_aum
  FROM Joined_Deals_With_Forecast
  WHERE sgm_name IS NOT NULL
  GROUP BY quarter_start, sgm_name
)

-- Calculate accuracy metrics
SELECT
  '=== OVERALL CAPACITY ESTIMATE ACCURACY ===' AS metric_type,
  NULL AS sgm_name,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_capacity), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_capacity) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_capacity) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_capacity - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_capacity - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_capacity - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_capacity, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_capacity, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_capacity > 0

UNION ALL

SELECT
  '=== CURRENT QUARTER FORECAST ACCURACY ===' AS metric_type,
  NULL AS sgm_name,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_current_quarter), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_current_quarter) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_current_quarter) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_current_quarter - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_current_quarter - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_current_quarter - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_current_quarter, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_current_quarter, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_current_quarter > 0

UNION ALL

SELECT
  '=== NEXT QUARTER FORECAST ACCURACY ===' AS metric_type,
  NULL AS sgm_name,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_next_quarter), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_next_quarter) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_next_quarter) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_next_quarter - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_next_quarter - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_next_quarter - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_next_quarter, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_next_quarter, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_next_quarter > 0

ORDER BY 
  CASE metric_type
    WHEN '=== OVERALL CAPACITY ESTIMATE ACCURACY ===' THEN 1
    WHEN '=== CURRENT QUARTER FORECAST ACCURACY ===' THEN 2
    WHEN '=== NEXT QUARTER FORECAST ACCURACY ===' THEN 3
  END
