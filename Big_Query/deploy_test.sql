-- Deploy this to BigQuery to update the view
-- This is the COMPLETE view with BOTH fixes:
-- 1. Channel normalization
-- 2. All_Combinations CTE to include forecast-only rows

-- Unified Actual vs Forecast View by Original Source
-- This view combines actual data from vw_funnel_lead_to_joined_v2 with forecast data from vw_daily_forecast
-- Allows for single table in Looker Studio instead of multiple scorecards
-- Note: For dates without forecast data, actual values are used as fallback forecast
-- Channel normalization ensures Marketing/Outbound/Ecosystem match between actuals and forecasts

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast_by_source` AS

WITH
-- 1. Actual data aggregated by original source and date
-- Use separate queries for each metric to ensure proper date attribution
-- REMOVED hardcoded date filters to allow any date range filtering in Looker Studio
Actual_Data AS (
  -- SQL data
  SELECT
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound' THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(converted_date_raw) AS date_day,
    COUNT(CASE WHEN is_sql = 1 THEN 1 END) AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE converted_date_raw IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- SQO data (use Date_Became_SQO__c as the date)
  SELECT
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound' THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(Date_Became_SQO__c) AS date_day,
    0 AS sql_actual,
    COUNT(CASE WHEN is_sqo = 1 THEN 1 END) AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Date_Became_SQO__c IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- Joined data (use advisor_join_date__c as the date)
  SELECT
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound' THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(advisor_join_date__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    COUNT(CASE WHEN is_joined = 1 THEN 1 END) AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE advisor_join_date__c IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- AUM data (use Stage_Entered_Signed__c as the date)
  SELECT
    CASE
      WHEN LOWER(Channel_Grouping_Name) = 'marketing' THEN 'Marketing'
      WHEN LOWER(Channel_Grouping_Name) = 'outbound' THEN 'Outbound'
      WHEN LOWER(Channel_Grouping_Name) = 'ecosystem' THEN 'Ecosystem'
      WHEN Channel_Grouping_Name IS NULL OR LOWER(Channel_Grouping_Name) = 'other' THEN 'Ecosystem'
      ELSE Channel_Grouping_Name
    END AS Channel_Grouping_Name,
    COALESCE(Original_source, 'Unknown') AS Original_source,
    DATE(Stage_Entered_Signed__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    SUM(CASE 
      WHEN StageName != 'Closed Lost' AND Stage_Entered_Signed__c IS NOT NULL 
      THEN Opportunity_AUM 
      ELSE 0 
    END) AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Stage_Entered_Signed__c IS NOT NULL
  GROUP BY 1, 2, 3
),

-- 2. Aggregate actual data by source and date
Actual_Aggregated AS (
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

-- 3. Forecast data (already daily)
Forecast_Data AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    date_day,
    COALESCE(sql_forecast, 0) AS sql_forecast,
    COALESCE(sqo_forecast, 0) AS sqo_forecast,
    COALESCE(joined_forecast, 0) AS joined_forecast,
    0 AS aum_forecast  -- No AUM forecast available
  FROM `savvy-gtm-analytics.savvy_analytics.vw_daily_forecast`
),

-- 4. Create complete matrix of all dates, channels, and sources
-- This ensures we get both actual-only AND forecast-only rows
All_Combinations AS (
  SELECT DISTINCT
    date_day,
    Channel_Grouping_Name,
    Original_source
  FROM Actual_Aggregated
  
  UNION DISTINCT
  
  SELECT DISTINCT
    date_day,
    Channel_Grouping_Name,
    Original_source
  FROM Forecast_Data
)

-- 5. Final output combining actual and forecast data
-- For dates without forecast data, use actuals as the forecast fallback
SELECT
  comb.date_day,
  comb.Channel_Grouping_Name,
  comb.Original_source,
  
  -- Actual metrics
  COALESCE(a.sql_actual, 0) AS sql_actual,
  COALESCE(a.sqo_actual, 0) AS sqo_actual,
  COALESCE(a.joined_actual, 0) AS joined_actual,
  COALESCE(a.aum_actual, 0) AS aum_actual,
  
  -- Forecast metrics with fallback to actuals if no forecast exists
  COALESCE(forecast.sql_forecast, a.sql_actual) AS sql_forecast,
  COALESCE(forecast.sqo_forecast, a.sqo_actual) AS sqo_forecast,
  COALESCE(forecast.joined_forecast, a.joined_actual) AS joined_forecast,
  COALESCE(forecast.aum_forecast, a.aum_actual) AS aum_forecast,
  
  -- Variance calculations (will be 0 when actuals are used as forecast fallback)
  COALESCE(a.sql_actual, 0) - COALESCE(forecast.sql_forecast, a.sql_actual) AS sql_variance,
  COALESCE(a.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, a.sqo_actual) AS sqo_variance,
  COALESCE(a.joined_actual, 0) - COALESCE(forecast.joined_forecast, a.joined_actual) AS joined_variance,
  
  -- Variance percentages (avoid division by zero)
  CASE 
    WHEN COALESCE(forecast.sql_forecast, a.sql_actual) > 0 
    THEN ROUND(((COALESCE(a.sql_actual, 0) - COALESCE(forecast.sql_forecast, a.sql_actual)) / COALESCE(forecast.sql_forecast, a.sql_actual)) * 100, 1)
    ELSE NULL 
  END AS sql_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.sqo_forecast, a.sqo_actual) > 0 
    THEN ROUND(((COALESCE(a.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, a.sqo_actual)) / COALESCE(forecast.sqo_forecast, a.sqo_actual)) * 100, 1)
    ELSE NULL 
  END AS sqo_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.joined_forecast, a.joined_actual) > 0 
    THEN ROUND(((COALESCE(a.joined_actual, 0) - COALESCE(forecast.joined_forecast, a.joined_actual)) / COALESCE(forecast.joined_forecast, a.joined_actual)) * 100, 1)
    ELSE NULL 
  END AS joined_variance_pct

FROM All_Combinations comb
LEFT JOIN Actual_Aggregated a
  ON comb.date_day = a.date_day
  AND comb.Channel_Grouping_Name = a.Channel_Grouping_Name
  AND comb.Original_source = a.Original_source
LEFT JOIN Forecast_Data forecast
  ON comb.date_day = forecast.date_day
  AND comb.Channel_Grouping_Name = forecast.Channel_Grouping_Name
  AND comb.Original_source = forecast.Original_source

ORDER BY comb.date_day, comb.Channel_Grouping_Name, comb.Original_source

