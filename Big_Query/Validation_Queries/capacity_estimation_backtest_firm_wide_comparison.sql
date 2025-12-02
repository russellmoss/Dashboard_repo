-- Capacity Estimation Backtest: Firm-Wide vs Individual Metrics Comparison
-- This query compares three approaches:
-- 1. Current: Deal-level Margin_AUM estimates + Firm-wide stage probabilities (baseline)
-- 2. Firm-Wide: Firm-wide average Margin_AUM + Firm-wide stage probabilities
-- 3. Hybrid: Individual Margin_AUM (for low-volatility SGMs) + Firm-wide (for others) + Firm-wide stage probabilities
--
-- Tests impact of using firm-wide metrics on forecast accuracy

WITH Quarter_Periods AS (
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

-- Get firm-wide averages (calculated at each quarter start for historical accuracy)
Firm_Wide_Averages AS (
  SELECT
    q.quarter_start,
    -- Calculate firm-wide average Margin_AUM for deals that joined before this quarter
    ROUND(AVG(CASE 
      WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 
      THEN o.Margin_AUM__c / 1000000.0 
      ELSE NULL 
    END), 2) AS firm_avg_margin_aum,
    -- Calculate firm-wide conversion rate for SQOs before this quarter
    CASE 
      WHEN COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) > 0
      THEN COUNT(DISTINCT CASE 
        WHEN LOWER(o.SQL__c) = 'yes' 
          AND o.Date_Became_SQO__c IS NOT NULL 
          AND o.advisor_join_date__c IS NOT NULL 
        THEN o.Full_Opportunity_ID__c 
      END) / COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL THEN o.Full_Opportunity_ID__c END)
      ELSE NULL
    END AS firm_avg_conversion_rate
  FROM Quarter_Periods q
  CROSS JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND o.Date_Became_SQO__c IS NOT NULL
    AND DATE(o.Date_Became_SQO__c) < q.quarter_start  -- Historical data only
  GROUP BY q.quarter_start
),

-- Get SGM-level averages for hybrid approach (only for low-volatility SGMs)
SGM_Individual_Averages AS (
  SELECT
    q.quarter_start,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    -- Individual average Margin_AUM (for deals that joined before this quarter)
    ROUND(AVG(CASE 
      WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 
      THEN o.Margin_AUM__c / 1000000.0 
      ELSE NULL 
    END), 2) AS individual_avg_margin_aum,
    -- Count of joined deals (for reliability check)
    COUNT(DISTINCT CASE 
      WHEN o.advisor_join_date__c IS NOT NULL 
        AND o.Margin_AUM__c IS NOT NULL 
        AND o.Margin_AUM__c > 0
      THEN o.Full_Opportunity_ID__c 
    END) AS historical_joined_count,
    -- Calculate CV for Margin_AUM (volatility measure)
    CASE 
      WHEN COUNT(DISTINCT CASE WHEN o.advisor_join_date__c IS NOT NULL AND o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Full_Opportunity_ID__c END) >= 3
      THEN ROUND(
        STDDEV(CASE WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c / 1000000.0 ELSE NULL END) / 
        NULLIF(AVG(CASE WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c / 1000000.0 ELSE NULL END), 0),
        3
      )
      ELSE NULL
    END AS margin_aum_cv
  FROM Quarter_Periods q
  CROSS JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND o.Date_Became_SQO__c IS NOT NULL
    AND DATE(o.Date_Became_SQO__c) < q.quarter_start  -- Historical data only
  GROUP BY q.quarter_start, sgm_name
  HAVING sgm_name IS NOT NULL
),

-- Get deals that joined in each quarter
Joined_Deals_With_Forecast AS (
  SELECT
    q.quarter_start,
    q.quarter_end,
    q.next_quarter_start,
    q.next_quarter_end,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    o.Full_Opportunity_ID__c,
    o.Margin_AUM__c / 1000000.0 AS actual_margin_aum_millions,
    -- Deal-level estimated Margin_AUM (CURRENT APPROACH)
    CASE
      WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c / 1000000
      WHEN o.Underwritten_AUM__c IS NOT NULL AND o.Underwritten_AUM__c > 0 THEN (o.Underwritten_AUM__c / 3.125) / 1000000
      WHEN o.Amount IS NOT NULL AND o.Amount > 0 THEN (o.Amount / 3.22) / 1000000
      ELSE 0
    END AS estimated_margin_aum_deal_level,
    -- Stage probability (firm-wide, same for all approaches)
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
    -- Forecast quarter
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
    AND DATE(o.Date_Became_SQO__c) <= q.quarter_start
),

-- Calculate forecasts using different approaches
Forecast_Comparisons AS (
  SELECT
    j.quarter_start,
    j.sgm_name,
    fw.firm_avg_margin_aum,
    sgm.individual_avg_margin_aum,
    sgm.margin_aum_cv,
    sgm.historical_joined_count,
    -- APPROACH 1: Current (Deal-level estimates)
    j.estimated_margin_aum_deal_level AS margin_aum_approach_1,
    -- APPROACH 2: Firm-wide average
    COALESCE(fw.firm_avg_margin_aum, 0) AS margin_aum_approach_2,
    -- APPROACH 3: Hybrid (Individual if low volatility, else firm-wide)
    CASE
      WHEN sgm.historical_joined_count >= 10 
        AND sgm.margin_aum_cv < 0.5 
        AND sgm.individual_avg_margin_aum IS NOT NULL
      THEN sgm.individual_avg_margin_aum
      ELSE COALESCE(fw.firm_avg_margin_aum, 0)
    END AS margin_aum_approach_3,
    j.stage_probability,
    j.forecast_quarter,
    j.actual_margin_aum_millions
  FROM Joined_Deals_With_Forecast j
  LEFT JOIN Firm_Wide_Averages fw
    ON j.quarter_start = fw.quarter_start
  LEFT JOIN SGM_Individual_Averages sgm
    ON j.quarter_start = sgm.quarter_start
    AND j.sgm_name = sgm.sgm_name
  WHERE j.sgm_name IS NOT NULL
),

-- Aggregate forecasts by approach
Quarterly_Forecast_vs_Actual AS (
  SELECT
    quarter_start,
    sgm_name,
    -- APPROACH 1: Current (Deal-level)
    SUM(margin_aum_approach_1 * stage_probability) AS forecasted_capacity_approach_1,
    SUM(CASE 
      WHEN forecast_quarter = 'Current Quarter' 
      THEN margin_aum_approach_1 * stage_probability 
      ELSE 0 
    END) AS forecasted_current_quarter_approach_1,
    SUM(CASE 
      WHEN forecast_quarter = 'Next Quarter' 
      THEN margin_aum_approach_1 * stage_probability 
      ELSE 0 
    END) AS forecasted_next_quarter_approach_1,
    -- APPROACH 2: Firm-wide
    SUM(margin_aum_approach_2 * stage_probability) AS forecasted_capacity_approach_2,
    SUM(CASE 
      WHEN forecast_quarter = 'Current Quarter' 
      THEN margin_aum_approach_2 * stage_probability 
      ELSE 0 
    END) AS forecasted_current_quarter_approach_2,
    SUM(CASE 
      WHEN forecast_quarter = 'Next Quarter' 
      THEN margin_aum_approach_2 * stage_probability 
      ELSE 0 
    END) AS forecasted_next_quarter_approach_2,
    -- APPROACH 3: Hybrid
    SUM(margin_aum_approach_3 * stage_probability) AS forecasted_capacity_approach_3,
    SUM(CASE 
      WHEN forecast_quarter = 'Current Quarter' 
      THEN margin_aum_approach_3 * stage_probability 
      ELSE 0 
    END) AS forecasted_current_quarter_approach_3,
    SUM(CASE 
      WHEN forecast_quarter = 'Next Quarter' 
      THEN margin_aum_approach_3 * stage_probability 
      ELSE 0 
    END) AS forecasted_next_quarter_approach_3,
    -- Actual
    SUM(actual_margin_aum_millions) AS actual_joined_margin_aum
  FROM Forecast_Comparisons
  GROUP BY quarter_start, sgm_name
)

-- Compare all three approaches
SELECT
  '=== APPROACH 1: CURRENT (Deal-Level Margin_AUM) ===' AS approach,
  'Overall Capacity' AS metric,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_capacity_approach_1), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_capacity_approach_1) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_capacity_approach_1) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_capacity_approach_1 - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_capacity_approach_1 - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_capacity_approach_1 - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_capacity_approach_1, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_capacity_approach_1, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_capacity_approach_1 > 0

UNION ALL

SELECT
  '=== APPROACH 2: FIRM-WIDE (Firm-Wide Average Margin_AUM) ===' AS approach,
  'Overall Capacity' AS metric,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_capacity_approach_2), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_capacity_approach_2) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_capacity_approach_2) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_capacity_approach_2 - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_capacity_approach_2 - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_capacity_approach_2 - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_capacity_approach_2, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_capacity_approach_2, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_capacity_approach_2 > 0

UNION ALL

SELECT
  '=== APPROACH 3: HYBRID (Individual for Low-Volatility SGMs, Firm-Wide for Others) ===' AS approach,
  'Overall Capacity' AS metric,
  COUNT(*) AS quarter_sgm_combinations,
  ROUND(SUM(forecasted_capacity_approach_3), 2) AS total_forecasted,
  ROUND(SUM(actual_joined_margin_aum), 2) AS total_actual,
  ROUND(SUM(forecasted_capacity_approach_3) - SUM(actual_joined_margin_aum), 2) AS total_error,
  ROUND((SUM(forecasted_capacity_approach_3) - SUM(actual_joined_margin_aum)) / NULLIF(SUM(actual_joined_margin_aum), 0) * 100, 2) AS pct_error,
  ROUND(AVG(ABS(forecasted_capacity_approach_3 - actual_joined_margin_aum)), 2) AS mae,
  ROUND(SQRT(AVG(POW(forecasted_capacity_approach_3 - actual_joined_margin_aum, 2))), 2) AS rmse,
  ROUND(AVG(forecasted_capacity_approach_3 - actual_joined_margin_aum), 2) AS bias,
  ROUND(SUM(LEAST(forecasted_capacity_approach_3, actual_joined_margin_aum)) / NULLIF(SUM(GREATEST(forecasted_capacity_approach_3, actual_joined_margin_aum)), 0) * 100, 2) AS accuracy_pct
FROM Quarterly_Forecast_vs_Actual
WHERE actual_joined_margin_aum > 0 OR forecasted_capacity_approach_3 > 0

ORDER BY 
  CASE approach
    WHEN '=== APPROACH 1: CURRENT (Deal-Level Margin_AUM) ===' THEN 1
    WHEN '=== APPROACH 2: FIRM-WIDE (Firm-Wide Average Margin_AUM) ===' THEN 2
    WHEN '=== APPROACH 3: HYBRID (Individual for Low-Volatility SGMs, Firm-Wide for Others) ===' THEN 3
  END

