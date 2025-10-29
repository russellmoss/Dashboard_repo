-- Source Performance Summary View
-- This view provides a clean summary of actual vs forecast by original source
-- Perfect for Looker Studio tables showing performance by source
-- Date filtering should be done in Looker Studio using date_day dimension

WITH
-- 1. Get actual data aggregated by source and date
Actual_Data AS (
  SELECT
    COALESCE(Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(converted_date_raw) AS date_day,
    COUNT(CASE WHEN is_sql = 1 THEN 1 END) AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE converted_date_raw IS NOT NULL
    AND DATE(converted_date_raw) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  SELECT
    COALESCE(Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(Date_Became_SQO__c) AS date_day,
    0 AS sql_actual,
    COUNT(CASE WHEN is_sqo = 1 THEN 1 END) AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Date_Became_SQO__c IS NOT NULL
    AND DATE(Date_Became_SQO__c) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  SELECT
    COALESCE(Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(advisor_join_date__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    COUNT(CASE WHEN is_joined = 1 THEN 1 END) AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE advisor_join_date__c IS NOT NULL
    AND DATE(advisor_join_date__c) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  SELECT
    COALESCE(Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(Stage_Entered_Signed__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    SUM(CASE 
      WHEN StageName != 'Closed Lost' 
      THEN Opportunity_AUM 
      ELSE 0 
    END) AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Stage_Entered_Signed__c IS NOT NULL
    AND DATE(Stage_Entered_Signed__c) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
),

-- 2. Aggregate actual data by source and date
Actual_Summary AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    SUM(sql_actual) AS sql_actual,
    SUM(sqo_actual) AS sqo_actual,
    SUM(joined_actual) AS joined_actual,
    SUM(aum_actual) AS aum_actual
  FROM Actual_Data
  GROUP BY 1, 2, 3
),

-- 3. Get forecast data aggregated by source and date
Forecast_Summary AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    ROUND(SUM(sql_forecast), 0) AS sql_forecast,
    ROUND(SUM(sqo_forecast), 0) AS sqo_forecast,
    ROUND(SUM(joined_forecast), 0) AS joined_forecast,
    0 AS aum_forecast  -- No AUM forecast available
  FROM `savvy-gtm-analytics.savvy_analytics.vw_daily_forecast`
  WHERE date_day BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
),

-- 4. Generate date spine for the full period
Date_Spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-10-01', '2025-12-31', INTERVAL 1 DAY)) AS date_day
),

-- 5. Get all unique channel/source combinations
All_Combinations AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source FROM Actual_Summary
  UNION DISTINCT
  SELECT DISTINCT Channel_Grouping_Name, Original_source FROM Forecast_Summary
),

-- 6. Create full matrix of dates, channels, and sources
Full_Matrix AS (
  SELECT
    d.date_day,
    c.Channel_Grouping_Name,
    c.Original_source
  FROM Date_Spine d
  CROSS JOIN All_Combinations c
)

-- 7. Final output with actual and forecast side by side
SELECT
  f.date_day,
  f.Channel_Grouping_Name,
  f.Original_source,
  
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

FROM Full_Matrix f
LEFT JOIN Actual_Summary actual
  ON f.date_day = actual.date_day
  AND f.Channel_Grouping_Name = actual.Channel_Grouping_Name
  AND f.Original_source = actual.Original_source
LEFT JOIN Forecast_Summary forecast
  ON f.date_day = forecast.date_day
  AND f.Channel_Grouping_Name = forecast.Channel_Grouping_Name
  AND f.Original_source = forecast.Original_source

ORDER BY f.date_day, f.Channel_Grouping_Name, f.Original_source
