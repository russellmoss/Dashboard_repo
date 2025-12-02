-- ============================================================================
-- Pipeline Forecasting Feasibility Study - SQL Queries
-- Dataset: savvy-gtm-analytics.savvy_analytics
-- ============================================================================

-- ============================================================================
-- QUESTION 1: Field Reliability
-- For all OPEN SQOs, what percentage have CloseDate and Earliest_Anticipated_Start_Date__c populated?
-- ============================================================================

WITH Open_SQOs AS (
  SELECT 
    o.Full_Opportunity_ID__c,
    o.CloseDate,
    o.Earliest_Anticipated_Start_Date__c,
    o.StageName,
    o.IsClosed,
    o.advisor_join_date__c
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  INNER JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
    ON o.OwnerId = u.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND LOWER(o.SQL__c) = 'yes'
    AND u.Is_SGM__c = TRUE
    AND u.IsActive = TRUE
    AND o.IsClosed = FALSE
    AND o.advisor_join_date__c IS NULL
    AND o.StageName NOT IN ('Closed Lost', 'On Hold')
    AND o.StageName IS NOT NULL
)
SELECT 
  COUNT(*) AS total_open_sqos,
  COUNT(CloseDate) AS sqos_with_closedate,
  COUNT(Earliest_Anticipated_Start_Date__c) AS sqos_with_earliest_start_date,
  ROUND(COUNT(CloseDate) * 100.0 / COUNT(*), 2) AS pct_with_closedate,
  ROUND(COUNT(Earliest_Anticipated_Start_Date__c) * 100.0 / COUNT(*), 2) AS pct_with_earliest_start_date,
  COUNT(CASE WHEN CloseDate IS NOT NULL AND Earliest_Anticipated_Start_Date__c IS NOT NULL THEN 1 END) AS sqos_with_both,
  ROUND(COUNT(CASE WHEN CloseDate IS NOT NULL AND Earliest_Anticipated_Start_Date__c IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS pct_with_both,
  COUNT(CASE WHEN CloseDate IS NULL AND Earliest_Anticipated_Start_Date__c IS NULL THEN 1 END) AS sqos_with_neither,
  ROUND(COUNT(CASE WHEN CloseDate IS NULL AND Earliest_Anticipated_Start_Date__c IS NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS pct_with_neither
FROM Open_SQOs;


-- ============================================================================
-- QUESTION 2: Historical Accuracy
-- For joined opportunities, what is the average difference between CloseDate and advisor_join_date__c?
-- ============================================================================

SELECT 
  COUNT(*) AS total_joined_deals,
  COUNT(CloseDate) AS deals_with_closedate,
  ROUND(AVG(DATE_DIFF(advisor_join_date__c, CloseDate, DAY)), 2) AS avg_days_difference,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, CloseDate, DAY), 100)[OFFSET(50)], 2) AS median_days_difference,
  ROUND(STDDEV(DATE_DIFF(advisor_join_date__c, CloseDate, DAY)), 2) AS stddev_days_difference,
  -- Distribution breakdown
  COUNT(CASE WHEN DATE_DIFF(advisor_join_date__c, CloseDate, DAY) = 0 THEN 1 END) AS exact_match,
  COUNT(CASE WHEN ABS(DATE_DIFF(advisor_join_date__c, CloseDate, DAY)) <= 7 THEN 1 END) AS within_7_days,
  COUNT(CASE WHEN ABS(DATE_DIFF(advisor_join_date__c, CloseDate, DAY)) <= 30 THEN 1 END) AS within_30_days,
  COUNT(CASE WHEN DATE_DIFF(advisor_join_date__c, CloseDate, DAY) < 0 THEN 1 END) AS closedate_before_join,
  COUNT(CASE WHEN DATE_DIFF(advisor_join_date__c, CloseDate, DAY) > 0 THEN 1 END) AS closedate_after_join
FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
WHERE o.recordtypeid = '012Dn000000mrO3IAI'
  AND LOWER(o.SQL__c) = 'yes'
  AND o.advisor_join_date__c IS NOT NULL
  AND o.CloseDate IS NOT NULL;


-- ============================================================================
-- QUESTION 3: Cycle Time Baseline
-- Average and median time from Date_Became_SQO__c to advisor_join_date__c for deals closed in last 12 months
-- ============================================================================

SELECT 
  COUNT(*) AS total_deals,
  ROUND(AVG(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY)), 2) AS avg_cycle_time_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(50)], 2) AS median_cycle_time_days,
  ROUND(STDDEV(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY)), 2) AS stddev_cycle_time_days,
  -- Percentiles
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(25)], 2) AS p25_cycle_time_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(75)], 2) AS p75_cycle_time_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(90)], 2) AS p90_cycle_time_days
FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
WHERE o.recordtypeid = '012Dn000000mrO3IAI'
  AND LOWER(o.SQL__c) = 'yes'
  AND o.advisor_join_date__c IS NOT NULL
  AND o.Date_Became_SQO__c IS NOT NULL
  AND o.advisor_join_date__c >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH);


-- ============================================================================
-- QUESTION 4: Stage Velocity
-- Calculate average time spent in each stage for won deals
-- Note: We use available date fields as proxies since explicit stage entry dates aren't available
-- ============================================================================

WITH Joined_Deals AS (
  SELECT 
    o.Full_Opportunity_ID__c,
    o.Date_Became_SQO__c,
    o.Qualification_Call_Date__c,
    o.Stage_Entered_Signed__c,
    o.advisor_join_date__c,
    o.StageName
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND LOWER(o.SQL__c) = 'yes'
    AND o.advisor_join_date__c IS NOT NULL
    AND o.advisor_join_date__c >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
)
SELECT 
  'Discovery (SQO to Qual Call)' AS stage_segment,
  COUNT(CASE WHEN Qualification_Call_Date__c IS NOT NULL THEN 1 END) AS deals_with_data,
  ROUND(AVG(DATE_DIFF(DATE(Qualification_Call_Date__c), DATE(Date_Became_SQO__c), DAY)), 2) AS avg_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Qualification_Call_Date__c), DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(50)], 2) AS median_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Qualification_Call_Date__c), DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(25)], 2) AS p25_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Qualification_Call_Date__c), DATE(Date_Became_SQO__c), DAY), 100)[OFFSET(75)], 2) AS p75_days
FROM Joined_Deals
WHERE Qualification_Call_Date__c IS NOT NULL

UNION ALL

SELECT 
  'Negotiating to Signed (Signed Entry to Join)' AS stage_segment,
  COUNT(CASE WHEN Stage_Entered_Signed__c IS NOT NULL THEN 1 END) AS deals_with_data,
  ROUND(AVG(DATE_DIFF(advisor_join_date__c, DATE(Stage_Entered_Signed__c), DAY)), 2) AS avg_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Stage_Entered_Signed__c), DAY), 100)[OFFSET(50)], 2) AS median_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Stage_Entered_Signed__c), DAY), 100)[OFFSET(25)], 2) AS p25_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(advisor_join_date__c, DATE(Stage_Entered_Signed__c), DAY), 100)[OFFSET(75)], 2) AS p75_days
FROM Joined_Deals
WHERE Stage_Entered_Signed__c IS NOT NULL

UNION ALL

SELECT 
  'Sales Process (Qual Call to Signed)' AS stage_segment,
  COUNT(CASE WHEN Qualification_Call_Date__c IS NOT NULL AND Stage_Entered_Signed__c IS NOT NULL THEN 1 END) AS deals_with_data,
  ROUND(AVG(DATE_DIFF(DATE(Stage_Entered_Signed__c), Qualification_Call_Date__c, DAY)), 2) AS avg_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Stage_Entered_Signed__c), Qualification_Call_Date__c, DAY), 100)[OFFSET(50)], 2) AS median_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Stage_Entered_Signed__c), Qualification_Call_Date__c, DAY), 100)[OFFSET(25)], 2) AS p25_days,
  ROUND(APPROX_QUANTILES(DATE_DIFF(DATE(Stage_Entered_Signed__c), Qualification_Call_Date__c, DAY), 100)[OFFSET(75)], 2) AS p75_days
FROM Joined_Deals
WHERE Qualification_Call_Date__c IS NOT NULL 
  AND Stage_Entered_Signed__c IS NOT NULL;


-- ============================================================================
-- RECOMMENDED: Calculate Projected_Close_Date for Open SQOs
-- ============================================================================

SELECT 
  o.Full_Opportunity_ID__c,
  o.Name AS opportunity_name,
  o.Date_Became_SQO__c,
  o.CloseDate,
  o.Earliest_Anticipated_Start_Date__c,
  DATE_DIFF(CURRENT_DATE(), DATE(o.Date_Became_SQO__c), DAY) AS days_open_since_sqo,
  
  -- Option 1: Simple calculation using median cycle time (70 days)
  DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) AS projected_close_simple,
  
  -- Option 2: Adjust based on days already open
  DATE_ADD(CURRENT_DATE(), INTERVAL (70 - DATE_DIFF(CURRENT_DATE(), DATE(o.Date_Became_SQO__c), DAY)) DAY) AS projected_close_adjusted,
  
  -- Option 3: Hybrid approach (use CloseDate if within 30 days of calculated, otherwise use calculated)
  CASE
    WHEN o.CloseDate IS NOT NULL 
      AND ABS(DATE_DIFF(o.CloseDate, DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY), DAY)) <= 30
    THEN o.CloseDate
    WHEN o.Earliest_Anticipated_Start_Date__c IS NOT NULL
      AND ABS(DATE_DIFF(o.Earliest_Anticipated_Start_Date__c, DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY), DAY)) <= 30
    THEN o.Earliest_Anticipated_Start_Date__c
    ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY)
  END AS projected_close_hybrid,
  
  -- Quarter classification
  CASE
    WHEN DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
      AND DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) < DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 1 QUARTER)
    THEN 'Current Quarter'
    WHEN DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) >= DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 1 QUARTER)
      AND DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) < DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 2 QUARTER)
    THEN 'Next Quarter'
    ELSE 'Beyond Next Quarter'
  END AS forecast_quarter

FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
INNER JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
  ON o.OwnerId = u.Id
WHERE o.recordtypeid = '012Dn000000mrO3IAI'
  AND LOWER(o.SQL__c) = 'yes'
  AND u.Is_SGM__c = TRUE
  AND u.IsActive = TRUE
  AND o.IsClosed = FALSE
  AND o.advisor_join_date__c IS NULL
  AND o.StageName NOT IN ('Closed Lost', 'On Hold')
  AND o.StageName IS NOT NULL
ORDER BY projected_close_hybrid;

