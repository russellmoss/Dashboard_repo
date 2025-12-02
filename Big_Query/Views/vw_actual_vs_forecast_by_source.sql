-- Unified Actual vs Forecast View by Original Source
-- This view combines actual data from vw_funnel_lead_to_joined_v2 with forecast data from vw_daily_forecast
-- Allows for single table in Looker Studio instead of multiple scorecards

WITH
Source_Channel_Map AS (
  SELECT
    Original_Source_Salesforce AS original_source,
    Channel_Grouping_Name
  FROM `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping`
),
-- 1. Actual data aggregated by original source and date
-- Use separate queries for each metric to ensure proper date attribution
-- NOTE: No date restriction on actuals - show all available actual data regardless of forecast range
Actual_Data AS (
  -- SQL data
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, 'Unknown') AS Original_source,
    DATE(converted_date_raw) AS date_day,
    COUNT(CASE WHEN is_sql = 1 THEN 1 END) AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  LEFT JOIN Source_Channel_Map map
    ON v.Original_source = map.original_source
  WHERE converted_date_raw IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- SQO data (use Date_Became_SQO__c as the date)
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, 'Unknown') AS Original_source,
    DATE(Date_Became_SQO__c) AS date_day,
    0 AS sql_actual,
    COUNT(CASE WHEN is_sqo = 1 THEN 1 END) AS sqo_actual,
    0 AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  LEFT JOIN Source_Channel_Map map
    ON v.Original_source = map.original_source
  WHERE Date_Became_SQO__c IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- Joined data (use advisor_join_date__c as the date)
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, 'Unknown') AS Original_source,
    DATE(advisor_join_date__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    COUNT(CASE WHEN is_joined = 1 THEN 1 END) AS joined_actual,
    0 AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  LEFT JOIN Source_Channel_Map map
    ON v.Original_source = map.original_source
  WHERE advisor_join_date__c IS NOT NULL
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- AUM data (use Stage_Entered_Signed__c as the date)
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, 'Unknown') AS Original_source,
    DATE(Stage_Entered_Signed__c) AS date_day,
    0 AS sql_actual,
    0 AS sqo_actual,
    0 AS joined_actual,
    SUM(CASE 
      WHEN StageName != 'Closed Lost' AND Stage_Entered_Signed__c IS NOT NULL 
      THEN Opportunity_AUM 
      ELSE 0 
    END) AS aum_actual
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  LEFT JOIN Source_Channel_Map map
    ON v.Original_source = map.original_source
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

-- 4. Generate date spine dynamically from actual data dates + forecast dates
-- This ensures we have rows for any date with actual data, even outside the forecast range
Date_Spine AS (
  SELECT DISTINCT date_day
  FROM Actual_Aggregated
  
  UNION DISTINCT
  
  SELECT DISTINCT date_day
  FROM Forecast_Data
),

-- 5. Get all unique channel/source combinations
Channel_Source_Combinations AS (
  SELECT DISTINCT
    Channel_Grouping_Name,
    Original_source
  FROM Actual_Aggregated
  
  UNION DISTINCT
  
  SELECT DISTINCT
    Channel_Grouping_Name,
    Original_source
  FROM Forecast_Data
),

-- 6. Create full cross join of dates, channels, and sources
Full_Matrix AS (
  SELECT
    d.date_day,
    c.Channel_Grouping_Name,
    c.Original_source
  FROM Date_Spine d
  CROSS JOIN Channel_Source_Combinations c
)

-- 7. Final output combining actual and forecast data
SELECT
  f.date_day,
  f.Channel_Grouping_Name,
  f.Original_source,
  
  -- Actual metrics
  COALESCE(a.sql_actual, 0) AS sql_actual,
  COALESCE(a.sqo_actual, 0) AS sqo_actual,
  COALESCE(a.joined_actual, 0) AS joined_actual,
  COALESCE(a.aum_actual, 0) AS aum_actual,
  
  -- Forecast metrics
  COALESCE(forecast.sql_forecast, 0) AS sql_forecast,
  COALESCE(forecast.sqo_forecast, 0) AS sqo_forecast,
  COALESCE(forecast.joined_forecast, 0) AS joined_forecast,
  COALESCE(forecast.aum_forecast, 0) AS aum_forecast,
  
  -- Variance calculations
  COALESCE(a.sql_actual, 0) - COALESCE(forecast.sql_forecast, 0) AS sql_variance,
  COALESCE(a.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, 0) AS sqo_variance,
  COALESCE(a.joined_actual, 0) - COALESCE(forecast.joined_forecast, 0) AS joined_variance,
  
  -- Variance percentages (avoid division by zero)
  CASE 
    WHEN COALESCE(forecast.sql_forecast, 0) > 0 
    THEN ROUND(((COALESCE(a.sql_actual, 0) - COALESCE(forecast.sql_forecast, 0)) / COALESCE(forecast.sql_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS sql_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.sqo_forecast, 0) > 0 
    THEN ROUND(((COALESCE(a.sqo_actual, 0) - COALESCE(forecast.sqo_forecast, 0)) / COALESCE(forecast.sqo_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS sqo_variance_pct,
  
  CASE 
    WHEN COALESCE(forecast.joined_forecast, 0) > 0 
    THEN ROUND(((COALESCE(a.joined_actual, 0) - COALESCE(forecast.joined_forecast, 0)) / COALESCE(forecast.joined_forecast, 0)) * 100, 1)
    ELSE NULL 
  END AS joined_variance_pct,
  
  -- NOTE: Performance indicator arrows (📈/📉/➡️) are intentionally not emitted here.
  -- Implement them in Looker Studio as metric-calculated fields using SUM(actual) vs SUM(forecast)
  -- to avoid row-level aggregation issues and keep totals consistent. Example (SQL):
  -- CASE
  --   WHEN SUM(sql_forecast) IS NULL OR SUM(sql_actual) IS NULL THEN '— No Data'
  --   WHEN SUM(sql_forecast) = 0 AND SUM(sql_actual) = 0 THEN '➡️ On Target'
  --   WHEN SUM(sql_forecast) = 0 AND SUM(sql_actual) != 0 THEN '📈 (vs 0)'
  --   WHEN SUM(sql_actual) > SUM(sql_forecast) THEN '📈 ' || CAST(ROUND(((SUM(sql_actual)-SUM(sql_forecast))/NULLIF(SUM(sql_forecast),0))*100,1) AS STRING) || '%'
  --   WHEN SUM(sql_actual) < SUM(sql_forecast) THEN '📉 ' || CAST(ROUND(((SUM(sql_actual)-SUM(sql_forecast))/NULLIF(SUM(sql_forecast),0))*100,1) AS STRING) || '%'
  --   WHEN SUM(sql_actual) = SUM(sql_forecast) THEN '➡️ On Target'
  --   ELSE '— No Data'
  -- END

FROM Full_Matrix f
LEFT JOIN Actual_Aggregated a
  ON f.date_day = a.date_day
  AND f.Channel_Grouping_Name = a.Channel_Grouping_Name
  AND f.Original_source = a.Original_source
LEFT JOIN Forecast_Data forecast
  ON f.date_day = forecast.date_day
  AND f.Channel_Grouping_Name = forecast.Channel_Grouping_Name
  AND f.Original_source = forecast.Original_source

ORDER BY f.date_day, f.Channel_Grouping_Name, f.Original_source

