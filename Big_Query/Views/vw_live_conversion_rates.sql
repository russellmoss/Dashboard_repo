-- Live Rolling Conversion Rates View
-- Calculates 90-day rolling average conversion rates for:
--   1. Contacted → MQL
--   2. MQL → SQL
--   3. SQL → SQO (business-approved: SQL__c = 'Yes')
--
-- Updates automatically as new data arrives
-- Uses 90-day rolling window to balance recency with stability

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_live_conversion_rates` AS

WITH
-- Get recent funnel data with conversion flags
funnel_data AS (
  SELECT
    DATE(CreatedDate) AS created_date,
    -- Contacted: Has Stage_Entered_Call_Scheduled__c
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    CASE WHEN IsConverted = TRUE THEN 1 ELSE 0 END AS is_sql,
    -- Get SQO conversion (need to join with Opportunity)
    l.Id AS lead_id
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
  WHERE DATE(CreatedDate) >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)  -- 180 days for rolling window
    AND DATE(CreatedDate) < CURRENT_DATE()
    -- Exclude impossible dates (data quality)
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(CreatedDate))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
),

-- Get SQO conversions (business-approved definition: SQL__c = 'Yes')
sqo_conversions AS (
  SELECT DISTINCT
    l.Id AS lead_id,
    CASE WHEN o.SQL__c = 'Yes' AND o.Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END AS is_sqo
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
  INNER JOIN `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
    ON l.ConvertedOpportunityId = o.Id
  WHERE DATE(l.CreatedDate) >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
    AND l.IsConverted = TRUE  -- SQLs only
),

-- Combine funnel data with SQO conversions
combined_data AS (
  SELECT
    f.*,
    COALESCE(s.is_sqo, 0) AS is_sqo
  FROM funnel_data f
  LEFT JOIN sqo_conversions s
    ON f.lead_id = s.lead_id
),

-- Calculate rolling 90-day conversion rates
rolling_rates AS (
  SELECT
    CURRENT_DATE() AS rate_date,
    
    -- Contacted → MQL Rate (per vw_sga_funnel: SUM(is_mql) / SUM(is_contacted))
    SAFE_DIVIDE(
      SUM(is_mql),
      SUM(is_contacted)
    ) AS contacted_to_mql_rate,
    
    SUM(CASE WHEN is_contacted = 1 THEN 1 ELSE 0 END) AS contacted_count,
    SUM(CASE WHEN is_contacted = 1 AND is_mql = 1 THEN 1 ELSE 0 END) AS mql_count,
    
    -- MQL → SQL Rate
    SAFE_DIVIDE(
      SUM(CASE WHEN is_mql = 1 AND is_sql = 1 THEN 1 ELSE 0 END),
      SUM(CASE WHEN is_mql = 1 THEN 1 ELSE 0 END)
    ) AS mql_to_sql_rate,
    
    SUM(CASE WHEN is_mql = 1 THEN 1 ELSE 0 END) AS mql_denominator,
    SUM(CASE WHEN is_mql = 1 AND is_sql = 1 THEN 1 ELSE 0 END) AS sql_count,
    
    -- SQL → SQO Rate (business-approved: SQL__c = 'Yes')
    SAFE_DIVIDE(
      SUM(CASE WHEN is_sql = 1 AND is_sqo = 1 THEN 1 ELSE 0 END),
      SUM(CASE WHEN is_sql = 1 THEN 1 ELSE 0 END)
    ) AS sql_to_sqo_rate,
    
    SUM(CASE WHEN is_sql = 1 THEN 1 ELSE 0 END) AS sql_denominator,
    SUM(CASE WHEN is_sql = 1 AND is_sqo = 1 THEN 1 ELSE 0 END) AS sqo_count,
    
    -- Rolling window period
    DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AS window_start,
    CURRENT_DATE() AS window_end
    
  FROM combined_data
  WHERE created_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)  -- Last 90 days
)

SELECT
  rate_date,
  COALESCE(contacted_to_mql_rate, 0) AS contacted_to_mql_rate,
  COALESCE(mql_to_sql_rate, 0) AS mql_to_sql_rate,
  COALESCE(sql_to_sqo_rate, 0) AS sql_to_sqo_rate,
  contacted_count,
  mql_count,
  sql_count,
  sqo_count,
  window_start,
  window_end,
  CURRENT_TIMESTAMP() AS last_updated
FROM rolling_rates;

