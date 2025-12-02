-- vw_stage_to_joined_probability: Lookup view for stage-to-joined probability
-- Calculates the probability that an opportunity in a given stage will eventually reach 'Joined'
-- Formula: (Count of opps that reached this Stage AND became Joined) / (Count of opps that reached this Stage with final outcome)
-- UPDATED: Only includes opportunities with final outcome (Joined or Closed Lost) - excludes open opportunities

WITH Stage_Opportunities AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.StageName,
    o.advisor_join_date__c,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Discovery__c,
    o.Stage_Entered_Sales_Process__c,
    o.Stage_Entered_Negotiating__c,
    o.Stage_Entered_Signed__c,
    o.IsClosed,
    -- Determine which stages this opportunity has been in
    CASE WHEN o.Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END AS was_in_qualifying,
    CASE WHEN o.Stage_Entered_Discovery__c IS NOT NULL THEN 1 ELSE 0 END AS was_in_discovery,
    CASE WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL THEN 1 ELSE 0 END AS was_in_sales_process,
    CASE WHEN o.Stage_Entered_Negotiating__c IS NOT NULL THEN 1 ELSE 0 END AS was_in_negotiating,
    CASE WHEN o.Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS was_in_signed,
    -- Did this opportunity become Joined?
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS became_joined,
    -- UPDATED: Only include opportunities with final outcome (joined or closed lost) - excludes open opportunities
    CASE 
      WHEN o.advisor_join_date__c IS NOT NULL THEN 1  -- Joined
      WHEN o.StageName = 'Closed Lost' THEN 1  -- Closed Lost
      ELSE 0  -- Open (excluded)
    END AS has_final_outcome
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
),

Stage_Stats AS (
  SELECT
    'Qualifying' AS StageName,
    -- UPDATED: Only count opportunities with final outcome (joined or closed lost) - excludes open opportunities
    COUNT(CASE WHEN has_final_outcome = 1 THEN 1 END) AS total_opps_reached_stage,
    SUM(became_joined) AS opps_that_joined
  FROM Stage_Opportunities
  WHERE was_in_qualifying = 1
  
  UNION ALL
  
  SELECT
    'Discovery' AS StageName,
    -- UPDATED: Only count opportunities with final outcome (joined or closed lost) - excludes open opportunities
    COUNT(CASE WHEN has_final_outcome = 1 THEN 1 END) AS total_opps_reached_stage,
    SUM(became_joined) AS opps_that_joined
  FROM Stage_Opportunities
  WHERE was_in_discovery = 1
  
  UNION ALL
  
  SELECT
    'Sales Process' AS StageName,
    -- UPDATED: Only count opportunities with final outcome (joined or closed lost) - excludes open opportunities
    COUNT(CASE WHEN has_final_outcome = 1 THEN 1 END) AS total_opps_reached_stage,
    SUM(became_joined) AS opps_that_joined
  FROM Stage_Opportunities
  WHERE was_in_sales_process = 1
  
  UNION ALL
  
  SELECT
    'Negotiating' AS StageName,
    -- UPDATED: Only count opportunities with final outcome (joined or closed lost) - excludes open opportunities
    COUNT(CASE WHEN has_final_outcome = 1 THEN 1 END) AS total_opps_reached_stage,
    SUM(became_joined) AS opps_that_joined
  FROM Stage_Opportunities
  WHERE was_in_negotiating = 1
  
  UNION ALL
  
  SELECT
    'Signed' AS StageName,
    -- UPDATED: Only count opportunities with final outcome (joined or closed lost) - excludes open opportunities
    COUNT(CASE WHEN has_final_outcome = 1 THEN 1 END) AS total_opps_reached_stage,
    SUM(became_joined) AS opps_that_joined
  FROM Stage_Opportunities
  WHERE was_in_signed = 1
)

SELECT
  StageName,
  CASE 
    WHEN total_opps_reached_stage > 0 
    THEN CAST(opps_that_joined AS FLOAT64) / CAST(total_opps_reached_stage AS FLOAT64)
    ELSE 0.0
  END AS probability_to_join
FROM Stage_Stats
ORDER BY 
  CASE StageName
    WHEN 'Qualifying' THEN 1
    WHEN 'Discovery' THEN 2
    WHEN 'Sales Process' THEN 3
    WHEN 'Negotiating' THEN 4
    WHEN 'Signed' THEN 5
    ELSE 6
  END

