-- SQO Velocity Analysis View
-- Tracks how fast SQOs move through the funnel stages
-- Used for LLM analysis: "What SQOs moved the fastest last week?"

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_sqo_velocity_analysis` AS

WITH sqo_velocity AS (
  SELECT
    f.Full_Opportunity_ID__c,
    f.Opp_Name,
    f.Channel_Grouping_Name,
    f.Original_source,
    f.Opportunity_Owner_Name__c,
    f.SGA_Owner_Name__c,
    
    -- Stage dates
    f.FilterDate AS prospect_date,
    f.stage_entered_contacting__c AS contacted_date,
    f.mql_stage_entered_ts AS mql_date,
    f.converted_date_raw AS sql_date,
    f.Date_Became_SQO__c AS sqo_date,
    f.Stage_Entered_Discovery__c AS discovery_date,
    f.Stage_Entered_Sales_Process__c AS sales_process_date,
    f.Stage_Entered_Negotiating__c AS negotiating_date,
    f.advisor_join_date__c AS joined_date,
    
    -- Velocity metrics (days between stages)
    DATE_DIFF(DATE(f.converted_date_raw), DATE(f.mql_stage_entered_ts), DAY) AS days_mql_to_sql,
    DATE_DIFF(DATE(f.Date_Became_SQO__c), DATE(f.converted_date_raw), DAY) AS days_sql_to_sqo,
    DATE_DIFF(DATE(f.Date_Became_SQO__c), DATE(f.mql_stage_entered_ts), DAY) AS days_mql_to_sqo,
    DATE_DIFF(DATE(f.Stage_Entered_Discovery__c), DATE(f.Date_Became_SQO__c), DAY) AS days_sqo_to_discovery,
    DATE_DIFF(DATE(f.Stage_Entered_Sales_Process__c), DATE(f.Date_Became_SQO__c), DAY) AS days_sqo_to_sales_process,
    DATE_DIFF(DATE(f.advisor_join_date__c), DATE(f.Date_Became_SQO__c), DAY) AS days_sqo_to_joined,
    
    -- Overall velocity (Prospect to SQO)
    DATE_DIFF(DATE(f.Date_Became_SQO__c), DATE(f.FilterDate), DAY) AS days_prospect_to_sqo,
    
    -- Current status
    f.is_sqo,
    f.is_joined,
    f.StageName,
    f.Amount,
    f.Underwritten_AUM__c,
    
    -- Week bucket for filtering
    DATE_TRUNC(DATE(f.Date_Became_SQO__c), WEEK(MONDAY)) AS sqo_week,
    DATE_TRUNC(DATE(f.converted_date_raw), WEEK(MONDAY)) AS sql_week,
    
    -- Risk indicators
    CASE 
      WHEN f.Date_Became_SQO__c IS NOT NULL 
        AND f.advisor_join_date__c IS NULL 
        AND DATE_DIFF(CURRENT_DATE(), DATE(f.Date_Became_SQO__c), DAY) > 60 
      THEN 1 
      ELSE 0 
    END AS is_stale_sqo,
    
    CASE 
      WHEN f.Date_Became_SQO__c IS NOT NULL 
        AND f.Stage_Entered_Discovery__c IS NULL 
        AND DATE_DIFF(CURRENT_DATE(), DATE(f.Date_Became_SQO__c), DAY) > 30 
      THEN 1 
      ELSE 0 
    END AS is_stuck_at_sqo
    
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` f
  WHERE f.is_sqo = 1
    AND f.Date_Became_SQO__c IS NOT NULL
)

SELECT
  *,
  -- Velocity score (lower is faster, normalized)
  CASE 
    WHEN days_sql_to_sqo <= 7 THEN 'Very Fast'
    WHEN days_sql_to_sqo <= 14 THEN 'Fast'
    WHEN days_sql_to_sqo <= 30 THEN 'Normal'
    WHEN days_sql_to_sqo <= 60 THEN 'Slow'
    ELSE 'Very Slow'
  END AS velocity_category,
  
  -- Percentile ranking (for comparison)
  PERCENTILE_CONT(days_sql_to_sqo, 0.5) OVER (PARTITION BY Channel_Grouping_Name, Original_source) AS median_days_sql_to_sqo_by_channel,
  PERCENTILE_CONT(days_sql_to_sqo, 0.5) OVER () AS median_days_sql_to_sqo_overall
  
FROM sqo_velocity
ORDER BY sqo_date DESC, days_sql_to_sqo ASC;













