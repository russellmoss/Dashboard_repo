-- Source Performance Summary View (Aggregated by Source)
-- This view provides a clean summary of actual vs forecast by original source
-- Perfect for Looker Studio tables showing performance by source
-- Use this when you want to see totals by source without daily granularity

WITH
-- 1. Get actual data aggregated by source for the period
Actual_Summary AS (
  SELECT
    COALESCE(Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    COUNT(CASE WHEN is_sql = 1 AND DATE(converted_date_raw) BETWEEN '2025-10-01' AND '2025-12-31' THEN 1 END) AS sql_actual,
    COUNT(CASE WHEN is_sqo = 1 AND DATE(Date_Became_SQO__c) BETWEEN '2025-10-01' AND '2025-12-31' THEN 1 END) AS sqo_actual,
    COUNT(CASE WHEN is_joined = 1 AND DATE(advisor_join_date__c) BETWEEN '2025-10-01' AND '2025-12-31' THEN 1 END) AS joined_actual,
    SUM(CASE 
      WHEN StageName != 'Closed Lost' 
        AND DATE(Stage_Entered_Signed__c) BETWEEN '2025-10-01' AND '2025-12-31'
      THEN Opportunity_AUM 
      ELSE 0 
    END) AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  GROUP BY 1, 2
),

-- 2. Get forecast data aggregated by source for the period
Forecast_Summary AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    ROUND(SUM(sql_forecast), 0) AS sql_forecast,
    ROUND(SUM(sqo_forecast), 0) AS sqo_forecast,
    ROUND(SUM(joined_forecast), 0) AS joined_forecast,
    0 AS aum_forecast  -- No AUM forecast available
  FROM `savvy-gtm-analytics.savvy_analytics.vw_daily_forecast`
  WHERE date_day BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2
),

-- 3. Get all unique channel/source combinations
All_Combinations AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source FROM Actual_Summary
  UNION DISTINCT
  SELECT DISTINCT Channel_Grouping_Name, Original_source FROM Forecast_Summary
)

-- 4. Final output with actual and forecast side by side
SELECT
  a.Channel_Grouping_Name,
  a.Original_source,
  
  -- Actual metrics
  COALESCE(actual.sql_actual, 0) AS sql_actual,
  COALESCE(actual.sqo_actual, 0) AS sqo_actual,
  COALESCE(actual.joined_actual, 0) AS joined_actual,
  COALESCE(actual.aum_actual, 0) AS aum_actual,
  
  -- Forecast metrics
  COALESCE(forecast.sql_forecast, 0) AS sql_forecast,
  COALESCE(forecast.sqo_forecast, 0) AS sqo_forecast,
  COALESCE(forecast.joined_forecast, 0) AS joined_forecast,
  COALESCE(forecast.aum_forecast, 0) AS aum_forecast,
  
  -- Variance calculations
  COALESCE(actual.sql_actual, 0) - COALESCE(forecast.sql_forecast, 0) AS sql_variance,
  COALESCE(actual.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, 0) AS sqo_variance,
  COALESCE(actual.joined_actual, 0) - COALESCE(forecast.joined_forecast, 0) AS joined_variance,
  
  -- Variance percentages (avoid division by zero)
  CASE 
    WHEN COALESCE(forecast.sql_forecast, 0) > 0 
    THEN ROUND(((COALESCE(actual.sql_actual, 0) - COALESCE(forecast.sql_forecast, 0)) / COALESCE(forecast.sql_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS sql_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.sqo_forecast, 0) > 0 
    THEN ROUND(((COALESCE(actual.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, 0)) / COALESCE(forecast.sqo_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS sqo_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.joined_forecast, 0) > 0 
    THEN ROUND(((COALESCE(actual.joined_actual, 0) - COALESCE(forecast.joined_forecast, 0)) / COALESCE(forecast.joined_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS joined_variance_pct,
  
  -- Performance indicators
  CASE 
    WHEN COALESCE(actual.sql_actual, 0) >= COALESCE(forecast.sql_forecast, 0) THEN 'Above Target'
    WHEN COALESCE(actual.sql_actual, 0) > 0 THEN 'Below Target'
    ELSE 'No Activity'
  END AS sql_performance,
  
  CASE 
    WHEN COALESCE(actual.sqo_actual, 0) >= COALESCE(forecast.sqo_forecast, 0) THEN 'Above Target'
    WHEN COALESCE(actual.sqo_actual, 0) > 0 THEN 'Below Target'
    ELSE 'No Activity'
  END AS sqo_performance,
  
  CASE 
    WHEN COALESCE(actual.joined_actual, 0) >= COALESCE(forecast.joined_forecast, 0) THEN 'Above Target'
    WHEN COALESCE(actual.joined_actual, 0) > 0 THEN 'Below Target'
    ELSE 'No Activity'
  END AS joined_performance

FROM All_Combinations a
LEFT JOIN Actual_Summary actual
  ON a.Channel_Grouping_Name = actual.Channel_Grouping_Name
  AND a.Original_source = actual.Original_source
LEFT JOIN Forecast_Summary forecast
  ON a.Channel_Grouping_Name = forecast.Channel_Grouping_Name
  AND a.Original_source = forecast.Original_source

ORDER BY a.Channel_Grouping_Name, a.Original_source
