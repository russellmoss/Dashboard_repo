-- Daily Forecast View for Looker Studio Cross-Filtering
-- This view calculates daily RATE forecast values (not cumulative)
-- Divides monthly forecasts by days in month to get daily rate
-- SUM across a date range gives the total forecast for that period

WITH
-- 1. Generate date spine for Q4 2025
Date_Spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-10-01', '2025-12-31', INTERVAL 1 DAY)) AS date_day
),

-- 2. Get monthly forecast targets from the forecast table (Cohort_source metric only)
Monthly_Forecast_Targets AS (
  SELECT
    COALESCE(cg.Channel_Grouping_Name, CASE WHEN Channel = 'Inbound' THEN 'Marketing' ELSE Channel END) AS channel_grouping_name,
    original_source,
    CASE
      WHEN LOWER(stage) = 'sql' THEN 'sqls'
      WHEN LOWER(stage) = 'sqo' THEN 'sqos'
      WHEN LOWER(stage) = 'joined' THEN 'joined'
      ELSE LOWER(stage)
    END AS stage,
    month_key,
    SUM(CAST(forecast_value AS INT64)) AS monthly_forecast,
    -- Calculate days in month
    CASE
      WHEN month_key = '2025-10' THEN 31
      WHEN month_key = '2025-11' THEN 30
      WHEN month_key = '2025-12' THEN 31
      ELSE 30
    END AS days_in_month
  FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast` f
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` cg
    ON f.original_source = cg.Original_Source_Salesforce
  WHERE metric = 'Cohort_source'
    AND original_source != 'All'
    AND month_key IN ('2025-10', '2025-11', '2025-12')
    AND LOWER(stage) IN ('sql', 'sqo', 'joined')
  GROUP BY 1, 2, 3, 4
),

-- 3. Calculate daily rate (forecast per day for each month)
Daily_Rates AS (
  SELECT
    d.date_day,
    m.channel_grouping_name,
    m.original_source,
    m.stage,
    m.monthly_forecast / m.days_in_month AS daily_rate
  FROM Date_Spine d
  INNER JOIN Monthly_Forecast_Targets m
    ON (d.date_day BETWEEN DATE('2025-10-01') AND DATE('2025-10-31') AND m.month_key = '2025-10')
    OR (d.date_day BETWEEN DATE('2025-11-01') AND DATE('2025-11-30') AND m.month_key = '2025-11')
    OR (d.date_day BETWEEN DATE('2025-12-01') AND DATE('2025-12-31') AND m.month_key = '2025-12')
),

-- 4. Pivot by stage to get sql_forecast, sqo_forecast, joined_forecast
Forecast_Detail AS (
  SELECT
    date_day,
    channel_grouping_name AS Channel_Grouping_Name,
    original_source AS Original_source,
    -- Add placeholder fields for blending with funnel view
    NULL AS TOF_Stage,
    NULL AS Conversion_Status,
    MAX(CASE WHEN stage = 'sqls' THEN daily_rate END) AS sql_forecast,
    MAX(CASE WHEN stage = 'sqos' THEN daily_rate END) AS sqo_forecast,
    MAX(CASE WHEN stage = 'joined' THEN daily_rate END) AS joined_forecast,
    0 AS is_total_row
  FROM Daily_Rates
  GROUP BY 1, 2, 3
)

-- Final output: Only source-level detail (let Looker Studio SUM them)
SELECT * FROM Forecast_Detail
ORDER BY 1, 2, 3