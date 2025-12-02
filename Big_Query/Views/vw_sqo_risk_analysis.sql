-- SQO Risk Analysis View
-- Identifies SQOs that may be at risk and need attention
-- Used for LLM analysis: "What SQOs seem like they may be at risk?"

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_sqo_risk_analysis` AS

WITH sqo_risk AS (
  SELECT
    f.Full_Opportunity_ID__c,
    f.Opp_Name,
    f.Channel_Grouping_Name,
    f.Original_source,
    f.Opportunity_Owner_Name__c,
    f.SGA_Owner_Name__c,
    
    -- Dates
    f.converted_date_raw AS sql_date,
    f.Date_Became_SQO__c AS sqo_date,
    o.Stage_Entered_Discovery__c AS discovery_date,
    o.Stage_Entered_Sales_Process__c AS sales_process_date,
    o.Stage_Entered_Negotiating__c AS negotiating_date,
    f.advisor_join_date__c AS joined_date,
    o.LastModifiedDate,
    
    -- Current status
    f.StageName,
    f.Amount,
    f.Underwritten_AUM__c,
    f.is_joined,
    
    -- Risk metrics
    DATE_DIFF(CURRENT_DATE(), DATE(f.Date_Became_SQO__c), DAY) AS days_since_sqo,
    DATE_DIFF(CURRENT_DATE(), DATE(f.converted_date_raw), DAY) AS days_since_sql,
    DATE_DIFF(CURRENT_DATE(), DATE(o.LastModifiedDate), DAY) AS days_since_last_modified,
    
    -- Stage progression checks
    CASE WHEN o.Stage_Entered_Discovery__c IS NULL THEN 1 ELSE 0 END AS not_in_discovery,
    CASE WHEN o.Stage_Entered_Sales_Process__c IS NULL THEN 1 ELSE 0 END AS not_in_sales_process,
    CASE WHEN f.advisor_join_date__c IS NULL THEN 1 ELSE 0 END AS not_joined
    
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` f
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    ON f.Full_Opportunity_ID__c = o.Full_Opportunity_ID__c
  WHERE f.is_sqo = 1
    AND f.Date_Became_SQO__c IS NOT NULL
    AND f.advisor_join_date__c IS NULL  -- Only active SQOs (not yet joined)
),

-- Add channel-level conversion rates for context
channel_rates AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    COUNT(DISTINCT CASE WHEN is_sql = 1 THEN Full_Opportunity_ID__c END) AS total_sqls,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END) AS total_sqos,
    COUNT(DISTINCT CASE WHEN is_joined = 1 THEN Full_Opportunity_ID__c END) AS total_joined,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END),
      COUNT(DISTINCT CASE WHEN is_sql = 1 THEN Full_Opportunity_ID__c END)
    ) AS avg_sql_to_sqo_rate,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN is_joined = 1 THEN Full_Opportunity_ID__c END),
      COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)
    ) AS avg_sqo_to_joined_rate
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE converted_date_raw >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
  GROUP BY 1, 2
)

SELECT
  r.*,
  cr.avg_sql_to_sqo_rate AS channel_avg_sql_to_sqo_rate,
  cr.avg_sqo_to_joined_rate AS channel_avg_sqo_to_joined_rate,
  
  -- Risk score (higher = more risk)
  (
    CASE WHEN r.days_since_sqo > 90 THEN 3 ELSE 0 END +
    CASE WHEN r.days_since_sqo > 60 THEN 2 ELSE 0 END +
    CASE WHEN r.days_since_sqo > 30 THEN 1 ELSE 0 END +
    CASE WHEN r.days_since_last_modified > 30 THEN 2 ELSE 0 END +
    CASE WHEN r.days_since_last_modified > 14 THEN 1 ELSE 0 END +
    CASE WHEN r.not_in_discovery = 1 AND r.days_since_sqo > 30 THEN 2 ELSE 0 END +
    CASE WHEN r.not_in_sales_process = 1 AND r.days_since_sqo > 60 THEN 1 ELSE 0 END
  ) AS risk_score,
  
  -- Risk category
  CASE
    WHEN (
      CASE WHEN r.days_since_sqo > 90 THEN 3 ELSE 0 END +
      CASE WHEN r.days_since_sqo > 60 THEN 2 ELSE 0 END +
      CASE WHEN r.days_since_last_modified > 30 THEN 2 ELSE 0 END +
      CASE WHEN r.not_in_discovery = 1 AND r.days_since_sqo > 30 THEN 2 ELSE 0 END
    ) >= 5 THEN 'High Risk'
    WHEN (
      CASE WHEN r.days_since_sqo > 60 THEN 2 ELSE 0 END +
      CASE WHEN r.days_since_last_modified > 14 THEN 1 ELSE 0 END +
      CASE WHEN r.not_in_discovery = 1 AND r.days_since_sqo > 30 THEN 2 ELSE 0 END
    ) >= 3 THEN 'Medium Risk'
    WHEN r.days_since_sqo > 30 OR r.days_since_last_modified > 14 THEN 'Low Risk'
    ELSE 'Normal'
  END AS risk_category,
  
  -- Recommendations
  CASE
    WHEN r.days_since_last_modified > 30 THEN 'Needs immediate rep follow-up - no activity in 30+ days'
    WHEN r.not_in_discovery = 1 AND r.days_since_sqo > 30 THEN 'Stuck at SQO stage - should have moved to Discovery'
    WHEN r.days_since_sqo > 90 THEN 'Very old SQO - review for potential close or re-engagement'
    WHEN r.days_since_sqo > 60 THEN 'SQO aging - check for blockers'
    ELSE 'Monitor'
  END AS recommendation
  
FROM sqo_risk r
LEFT JOIN channel_rates cr
  ON r.Channel_Grouping_Name = cr.Channel_Grouping_Name
  AND r.Original_source = cr.Original_source
ORDER BY risk_score DESC, days_since_sqo DESC;





