WITH
-- 1. Date spine for every day in Q4
Date_Spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-10-01', '2025-12-31', INTERVAL 1 DAY)) AS date_day
),

-- 2. Get funnel data with stage flags
Funnel_With_Flags AS (
  SELECT
    *
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
),

-- 3. Daily actuals by stage
Daily_Actuals AS (
  -- MQLs
  SELECT DATE(mql_stage_entered_ts) AS date_day, Channel_Grouping_Name, Original_source, 
         'mqls' AS stage, COUNT(DISTINCT Full_prospect_id__c) AS daily_count
  FROM Funnel_With_Flags
  WHERE is_mql = 1 AND DATE(mql_stage_entered_ts) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- SQLs
  SELECT DATE(converted_date_raw) AS date_day, Channel_Grouping_Name, Original_source,
         'sqls' AS stage, COUNT(DISTINCT Full_prospect_id__c) AS daily_count
  FROM Funnel_With_Flags
  WHERE is_sql = 1 AND DATE(converted_date_raw) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- SQOs
  SELECT DATE(Date_Became_SQO__c) AS date_day, Channel_Grouping_Name, Original_source,
         'sqos' AS stage, COUNT(DISTINCT Full_Opportunity_ID__c) AS daily_count
  FROM Funnel_With_Flags
  WHERE is_sqo = 1 AND DATE(Date_Became_SQO__c) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  -- Joined
  SELECT DATE(advisor_join_date__c) AS date_day, Channel_Grouping_Name, Original_source,
         'joined' AS stage, COUNT(DISTINCT Full_Opportunity_ID__c) AS daily_count
  FROM Funnel_With_Flags
  WHERE is_joined = 1 AND DATE(advisor_join_date__c) BETWEEN '2025-10-01' AND '2025-12-31'
  GROUP BY 1, 2, 3
),

-- 4. Cumulative actuals
Cumulative_Actuals AS (
  SELECT 
    d.date_day,
    dims.Channel_Grouping_Name AS channel_grouping_name,
    dims.Original_source AS original_source,
    dims.stage,
    SUM(SUM(COALESCE(a.daily_count, 0))) OVER (
      PARTITION BY dims.Channel_Grouping_Name, dims.Original_source, dims.stage 
      ORDER BY d.date_day
    ) AS cumulative_actual
  FROM Date_Spine d
  CROSS JOIN (
    -- Include sources that have actuals
    SELECT DISTINCT Channel_Grouping_Name, Original_source, stage 
    FROM Daily_Actuals
    
    UNION DISTINCT
    
    -- Also include ALL sources from forecast (even with zero actuals)
    SELECT DISTINCT
      COALESCE(cg.Channel_Grouping_Name, CASE WHEN Channel = 'Inbound' THEN 'Marketing' ELSE Channel END) AS Channel_Grouping_Name,
      original_source AS Original_source,
      CASE
        WHEN LOWER(stage) = 'mql' THEN 'mqls'
        WHEN LOWER(stage) = 'sql' THEN 'sqls'
        WHEN LOWER(stage) = 'sqo' THEN 'sqos'
        WHEN LOWER(stage) = 'joined' THEN 'joined'
        ELSE LOWER(stage)
      END AS stage
    FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast` f
    LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` cg
      ON f.original_source = cg.Original_Source_Salesforce
    WHERE metric = 'Cohort_source'
      AND original_source != 'All'
      AND month_key IN ('2025-10', '2025-11', '2025-12')
  ) dims
  LEFT JOIN Daily_Actuals a
    ON d.date_day = a.date_day
    AND dims.Channel_Grouping_Name = a.Channel_Grouping_Name
    AND dims.Original_source = a.Original_source
    AND dims.stage = a.stage
  GROUP BY 1, 2, 3, 4
),

-- 5. Get MONTHLY forecast targets for stepped progression (WITH DEDUPLICATION)
Monthly_Forecast_Targets AS (
  SELECT
    COALESCE(cg.Channel_Grouping_Name, CASE WHEN Channel = 'Inbound' THEN 'Marketing' ELSE Channel END) AS channel_grouping_name,
    original_source,
    CASE
      WHEN LOWER(stage) = 'mql' THEN 'mqls'
      WHEN LOWER(stage) = 'sql' THEN 'sqls'
      WHEN LOWER(stage) = 'sqo' THEN 'sqos'
      ELSE LOWER(stage)
    END AS stage,
    month_key,
    SUM(CAST(forecast_value AS INT64)) AS monthly_forecast  -- SUM to handle duplicates
  FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast` f
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` cg
    ON f.original_source = cg.Original_Source_Salesforce
  WHERE metric = 'Cohort_source'
    AND original_source != 'All'
    AND month_key IN ('2025-10', '2025-11', '2025-12')
  GROUP BY 1, 2, 3, 4  -- GROUP BY to deduplicate
),

-- 6. Calculate cumulative monthly targets (NO ROLLUP - just source level)
Cumulative_Monthly_Targets AS (
  SELECT
    channel_grouping_name,
    original_source,
    stage,
    month_key,
    monthly_forecast,
    SUM(monthly_forecast) OVER (
      PARTITION BY channel_grouping_name, original_source, stage 
      ORDER BY month_key
    ) AS cumulative_target
  FROM Monthly_Forecast_Targets
),

-- 7. Get forecast and prediction data from main view
Forecast_Data AS (
  SELECT 
    channel_grouping_name,
    original_source,
    stage,
    forecast_value,
    predicted_value,
    stddev_daily
  FROM `savvy-gtm-analytics.savvy_analytics.vw_forecast_vs_actuals`
),

-- 8. Current actual values (as of today)
Current_Actuals AS (
  SELECT
    channel_grouping_name,
    original_source,
    stage,
    cumulative_actual AS current_actual
  FROM Cumulative_Actuals
  WHERE date_day = CURRENT_DATE()
),

-- 9. Calculate daily growth volatility
Historical_Daily_Volatility AS (
  SELECT
    channel_grouping_name,
    original_source,
    stage,
    STDDEV(daily_growth) AS stddev_daily_growth
  FROM (
    SELECT 
      channel_grouping_name,
      original_source,
      stage,
      cumulative_actual - LAG(cumulative_actual) OVER (
        PARTITION BY channel_grouping_name, original_source, stage 
        ORDER BY date_day
      ) AS daily_growth
    FROM Cumulative_Actuals
    WHERE date_day <= CURRENT_DATE()
  )
  WHERE daily_growth IS NOT NULL
  GROUP BY 1, 2, 3
),

-- 10. Combine all data with stepped target calculation
Combined_Data AS (
  SELECT
    a.date_day,
    a.channel_grouping_name,
    a.original_source,
    a.stage,
    
    -- Actual value (only up to today)
    CASE 
      WHEN a.date_day <= CURRENT_DATE() THEN a.cumulative_actual
      ELSE NULL
    END AS actual_value,
    
    -- Predicted value with lag-aware start dates per stage
    CASE
      WHEN a.date_day <= CURRENT_DATE() THEN a.cumulative_actual
      ELSE 
        COALESCE(c.current_actual, 0) + 
        (GREATEST(0, DATE_DIFF(a.date_day,
                               CASE 
                                 WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                                 WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                                 ELSE CURRENT_DATE()
                               END,
                               DAY))
         * SAFE_DIVIDE(
             COALESCE(f.predicted_value, 0) - COALESCE(c.current_actual, 0), 
             GREATEST(1,
               DATE_DIFF(
                 DATE('2025-12-31'),
                 CASE 
                   WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                   WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                   ELSE CURRENT_DATE()
                 END,
                 DAY)
             )
           )
        )
    END AS predicted_value,
    
    -- Lower bound with lag-aware start
    CASE 
      WHEN a.date_day <= CURRENT_DATE() THEN a.cumulative_actual
      ELSE 
        GREATEST(
          COALESCE(c.current_actual, 0),
          COALESCE(c.current_actual, 0) + 
          (GREATEST(0, DATE_DIFF(a.date_day,
                                 CASE 
                                   WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                                   WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                                   ELSE CURRENT_DATE()
                                 END,
                                 DAY))
           * SAFE_DIVIDE(
               COALESCE(f.predicted_value, 0) - COALESCE(c.current_actual, 0), 
               GREATEST(1,
                 DATE_DIFF(
                   DATE('2025-12-31'),
                   CASE 
                     WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                     WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                     ELSE CURRENT_DATE()
                   END,
                   DAY)
               )
             )
          ) -
          (1.96 * COALESCE(v.stddev_daily_growth, 0) * SQRT(GREATEST(0, DATE_DIFF(a.date_day, CURRENT_DATE(), DAY))))
        )
    END AS predicted_lower,
    
    -- Upper bound with lag-aware start
    CASE 
      WHEN a.date_day <= CURRENT_DATE() THEN a.cumulative_actual
      ELSE 
        COALESCE(c.current_actual, 0) + 
        (GREATEST(0, DATE_DIFF(a.date_day,
                               CASE 
                                 WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                                 WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                                 ELSE CURRENT_DATE()
                               END,
                               DAY))
         * SAFE_DIVIDE(
             COALESCE(f.predicted_value, 0) - COALESCE(c.current_actual, 0), 
             GREATEST(1,
               DATE_DIFF(
                 DATE('2025-12-31'),
                 CASE 
                   WHEN a.stage = 'sqls' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
                   WHEN a.stage = 'sqos' THEN DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY)
                   ELSE CURRENT_DATE()
                 END,
                 DAY)
             )
           )
        ) +
        (1.96 * COALESCE(v.stddev_daily_growth, 0) * SQRT(GREATEST(0, DATE_DIFF(a.date_day, CURRENT_DATE(), DAY))))
    END AS predicted_upper,
    
    -- CORRECTED Target line (stepped monthly progression)
    CASE 
      -- October: Linear from 0 to Oct target
      WHEN a.date_day <= DATE('2025-10-31') THEN
        COALESCE(
          (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
           WHERE t.channel_grouping_name = a.channel_grouping_name 
           AND t.original_source = a.original_source
           AND t.stage = a.stage
           AND t.month_key = '2025-10'), 0
        ) * DATE_DIFF(a.date_day, DATE('2025-09-30'), DAY) / 31.0
        
      -- November: Linear from Oct target to Nov target
      WHEN a.date_day <= DATE('2025-11-30') THEN
        COALESCE(
          (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
           WHERE t.channel_grouping_name = a.channel_grouping_name 
           AND t.original_source = a.original_source
           AND t.stage = a.stage
           AND t.month_key = '2025-10'), 0
        ) +
        (
          COALESCE(
            (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
             WHERE t.channel_grouping_name = a.channel_grouping_name 
             AND t.original_source = a.original_source
             AND t.stage = a.stage
             AND t.month_key = '2025-11'), 0
          ) -
          COALESCE(
            (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
             WHERE t.channel_grouping_name = a.channel_grouping_name 
             AND t.original_source = a.original_source
             AND t.stage = a.stage
             AND t.month_key = '2025-10'), 0
          )
        ) * DATE_DIFF(a.date_day, DATE('2025-10-31'), DAY) / 30.0
        
      -- December: Linear from Nov target to Dec target
      ELSE
        COALESCE(
          (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
           WHERE t.channel_grouping_name = a.channel_grouping_name 
           AND t.original_source = a.original_source
           AND t.stage = a.stage
           AND t.month_key = '2025-11'), 0
        ) +
        (
          COALESCE(
            (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
             WHERE t.channel_grouping_name = a.channel_grouping_name 
             AND t.original_source = a.original_source
             AND t.stage = a.stage
             AND t.month_key = '2025-12'), 0
          ) -
          COALESCE(
            (SELECT cumulative_target FROM Cumulative_Monthly_Targets t
             WHERE t.channel_grouping_name = a.channel_grouping_name 
             AND t.original_source = a.original_source
             AND t.stage = a.stage
             AND t.month_key = '2025-11'), 0
          )
        ) * DATE_DIFF(a.date_day, DATE('2025-11-30'), DAY) / 31.0
    END AS target_value
    
  FROM Cumulative_Actuals a
  LEFT JOIN Forecast_Data f
    ON a.channel_grouping_name = f.channel_grouping_name
    AND a.original_source = f.original_source
    AND a.stage = f.stage
  LEFT JOIN Current_Actuals c
    ON a.channel_grouping_name = c.channel_grouping_name
    AND a.original_source = c.original_source
    AND a.stage = c.stage
  LEFT JOIN Historical_Daily_Volatility v
    ON a.channel_grouping_name = v.channel_grouping_name
    AND a.original_source = v.original_source
    AND a.stage = v.stage
)

-- 11. Final pivot for Looker Studio
SELECT
  date_day,
  channel_grouping_name,
  original_source,
  
  -- MQL metrics
  MAX(CASE WHEN stage = 'mqls' THEN actual_value END) AS mqls_actual,
  MAX(CASE WHEN stage = 'mqls' THEN predicted_value END) AS mqls_predicted,
  MAX(CASE WHEN stage = 'mqls' THEN predicted_lower END) AS mqls_lower,
  MAX(CASE WHEN stage = 'mqls' THEN predicted_upper END) AS mqls_upper,
  MAX(CASE WHEN stage = 'mqls' THEN target_value END) AS mqls_target,
  
  -- SQL metrics
  MAX(CASE WHEN stage = 'sqls' THEN actual_value END) AS sqls_actual,
  MAX(CASE WHEN stage = 'sqls' THEN predicted_value END) AS sqls_predicted,
  MAX(CASE WHEN stage = 'sqls' THEN predicted_lower END) AS sqls_lower,
  MAX(CASE WHEN stage = 'sqls' THEN predicted_upper END) AS sqls_upper,
  MAX(CASE WHEN stage = 'sqls' THEN target_value END) AS sqls_target,
  
  -- SQO metrics
  MAX(CASE WHEN stage = 'sqos' THEN actual_value END) AS sqos_actual,
  MAX(CASE WHEN stage = 'sqos' THEN predicted_value END) AS sqos_predicted,
  MAX(CASE WHEN stage = 'sqos' THEN predicted_lower END) AS sqos_lower,
  MAX(CASE WHEN stage = 'sqos' THEN predicted_upper END) AS sqos_upper,
  MAX(CASE WHEN stage = 'sqos' THEN target_value END) AS sqos_target,
  
  -- Joined metrics
  MAX(CASE WHEN stage = 'joined' THEN actual_value END) AS joined_actual,
  MAX(CASE WHEN stage = 'joined' THEN predicted_value END) AS joined_predicted,
  MAX(CASE WHEN stage = 'joined' THEN predicted_lower END) AS joined_lower,
  MAX(CASE WHEN stage = 'joined' THEN predicted_upper END) AS joined_upper,
  MAX(CASE WHEN stage = 'joined' THEN target_value END) AS joined_target
  
FROM Combined_Data
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3
