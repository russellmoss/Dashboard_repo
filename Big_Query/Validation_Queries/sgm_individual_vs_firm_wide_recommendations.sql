-- SGM Individual vs Firm-Wide Metrics Recommendations
-- This query provides recommendations for when to use individual SGM metrics vs firm-wide averages
-- Based on volatility analysis and sample size

WITH SGM_Metrics AS (
  SELECT
    r.sgm_name,
    r.historical_joined_count_12m,
    r.avg_margin_aum_per_joined,
    r.sqo_to_joined_conversion_rate,
    r.historical_sqo_count_12m,
    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), DATE(u.CreatedDate), DAY) <= 90 THEN 1
      ELSE 0
    END AS is_on_ramp
  FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined` r
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
    ON r.sgm_user_id = u.Id
  WHERE r.IsActive = TRUE
    AND r.sgm_name IS NOT NULL
),

-- Get all joined deals with Margin_AUM
Joined_Deals AS (
  SELECT
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    o.Margin_AUM__c / 1000000.0 AS margin_aum_millions
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.StageName = 'Joined'
    AND o.advisor_join_date__c IS NOT NULL
    AND o.Margin_AUM__c IS NOT NULL
    AND o.Margin_AUM__c > 0
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND DATE(o.advisor_join_date__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),

-- Calculate Margin_AUM volatility per SGM
Margin_AUM_Stats AS (
  SELECT
    sgm_name,
    COUNT(*) AS joined_count,
    ROUND(AVG(margin_aum_millions), 2) AS avg_margin_aum,
    ROUND(STDDEV(margin_aum_millions), 2) AS stddev_margin_aum,
    ROUND(
      STDDEV(margin_aum_millions) / NULLIF(AVG(margin_aum_millions), 0),
      3
    ) AS cv_margin_aum
  FROM Joined_Deals
  WHERE sgm_name IS NOT NULL
  GROUP BY sgm_name
),

-- Calculate quarterly conversion rates
Quarterly_Conversion_Rates AS (
  SELECT
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), QUARTER) AS sqo_quarter,
    COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS sqos_in_quarter,
    COUNT(DISTINCT CASE 
      WHEN LOWER(o.SQL__c) = 'yes' 
        AND o.Date_Became_SQO__c IS NOT NULL 
        AND o.advisor_join_date__c IS NOT NULL 
      THEN o.Full_Opportunity_ID__c 
    END) AS joined_in_quarter
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY sgm_name, sqo_quarter
  HAVING sgm_name IS NOT NULL
    AND COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) > 0
),

-- Calculate conversion rate volatility
Conversion_Rate_Stats AS (
  SELECT
    sgm_name,
    COUNT(*) AS quarters_with_data,
    ROUND(AVG(joined_in_quarter / NULLIF(sqos_in_quarter, 0)), 4) AS avg_quarterly_conversion_rate,
    ROUND(STDDEV(joined_in_quarter / NULLIF(sqos_in_quarter, 0)), 4) AS stddev_quarterly_conversion_rate,
    ROUND(
      STDDEV(joined_in_quarter / NULLIF(sqos_in_quarter, 0)) / 
      NULLIF(AVG(joined_in_quarter / NULLIF(sqos_in_quarter, 0)), 0),
      3
    ) AS cv_conversion_rate
  FROM Quarterly_Conversion_Rates
  GROUP BY sgm_name
  HAVING COUNT(*) >= 2
),

-- Firm-wide averages
Firm_Wide_Metrics AS (
  SELECT
    ROUND(AVG(avg_margin_aum_per_joined), 2) AS firm_avg_margin_aum,
    ROUND(AVG(sqo_to_joined_conversion_rate), 4) AS firm_avg_conversion_rate
  FROM SGM_Metrics
  WHERE is_on_ramp = 0
    AND historical_joined_count_12m > 0
    AND avg_margin_aum_per_joined IS NOT NULL
    AND sqo_to_joined_conversion_rate IS NOT NULL
)

-- Final recommendations
SELECT
  m.sgm_name,
  m.is_on_ramp,
  m.historical_joined_count_12m,
  m.historical_sqo_count_12m,
  -- Current metrics
  ROUND(m.avg_margin_aum_per_joined, 2) AS current_individual_margin_aum,
  f.firm_avg_margin_aum AS firm_avg_margin_aum,
  ROUND(ABS(m.avg_margin_aum_per_joined - f.firm_avg_margin_aum) / NULLIF(f.firm_avg_margin_aum, 0) * 100, 1) AS margin_aum_pct_difference,
  ROUND(m.sqo_to_joined_conversion_rate, 4) AS current_individual_conversion_rate,
  f.firm_avg_conversion_rate AS firm_avg_conversion_rate,
  ROUND(ABS(m.sqo_to_joined_conversion_rate - f.firm_avg_conversion_rate) / NULLIF(f.firm_avg_conversion_rate, 0) * 100, 1) AS conversion_rate_pct_difference,
  -- Volatility metrics
  COALESCE(ma.cv_margin_aum, NULL) AS margin_aum_cv,
  COALESCE(cr.cv_conversion_rate, NULL) AS conversion_rate_cv,
  COALESCE(cr.quarters_with_data, 0) AS quarters_with_data,
  -- Recommendations
  CASE
    WHEN m.is_on_ramp = 1 THEN 'On Ramp - Use Firm-Wide'
    WHEN m.historical_joined_count_12m >= 10 
      AND COALESCE(ma.cv_margin_aum, 1) < 0.5 
      AND COALESCE(cr.cv_conversion_rate, 1) < 0.5 
      AND ABS(m.avg_margin_aum_per_joined - f.firm_avg_margin_aum) / NULLIF(f.firm_avg_margin_aum, 0) > 0.15
    THEN 'Use Individual (High sample, low volatility, different from firm)'
    WHEN m.historical_joined_count_12m >= 10 
      AND COALESCE(ma.cv_margin_aum, 1) < 0.5 
      AND COALESCE(cr.cv_conversion_rate, 1) >= 0.5
    THEN 'Hybrid: Individual Margin_AUM + Firm-Wide Conversion Rate'
    WHEN m.historical_joined_count_12m >= 10
      AND COALESCE(ma.cv_margin_aum, 1) < 0.7
    THEN 'Consider Individual (High sample, moderate volatility)'
    WHEN m.historical_joined_count_12m >= 5
      AND COALESCE(ma.cv_margin_aum, 1) < 0.5
    THEN 'Consider Individual (Medium sample, low volatility)'
    ELSE 'Use Firm-Wide (Insufficient sample or high volatility)'
  END AS recommendation,
  -- Which metrics to use
  CASE
    WHEN m.is_on_ramp = 1 THEN 'Firm-Wide (Both)'
    WHEN m.historical_joined_count_12m >= 10 
      AND COALESCE(ma.cv_margin_aum, 1) < 0.5 
      AND COALESCE(cr.cv_conversion_rate, 1) < 0.5 
      AND ABS(m.avg_margin_aum_per_joined - f.firm_avg_margin_aum) / NULLIF(f.firm_avg_margin_aum, 0) > 0.15
    THEN 'Individual (Both)'
    WHEN m.historical_joined_count_12m >= 10 
      AND COALESCE(ma.cv_margin_aum, 1) < 0.5 
      AND COALESCE(cr.cv_conversion_rate, 1) >= 0.5
    THEN 'Individual Margin_AUM + Firm-Wide Conversion Rate'
    ELSE 'Firm-Wide (Both)'
  END AS metrics_to_use
FROM SGM_Metrics m
CROSS JOIN Firm_Wide_Metrics f
LEFT JOIN Margin_AUM_Stats ma
  ON m.sgm_name = ma.sgm_name
LEFT JOIN Conversion_Rate_Stats cr
  ON m.sgm_name = cr.sgm_name
WHERE m.historical_joined_count_12m > 0
ORDER BY m.historical_joined_count_12m DESC, m.sgm_name

