-- FIXED: This view creates a 90-day forecast for our 20 "sparse" segments
-- using a simple 30-day rolling average.
CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_heuristic_forecast` AS

WITH 
-- 1. Get the 4 "healthy" segments that ARIMA can handle
healthy_segments AS (
  SELECT DISTINCT Channel_Grouping_Name, Original_source
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE 
    (Channel_Grouping_Name = 'Outbound' AND Original_source = 'LinkedIn (Self Sourced)') OR
    (Channel_Grouping_Name = 'Outbound' AND Original_source = 'Provided Lead List') OR
    (Channel_Grouping_Name = 'Ecosystem' AND Original_source = 'Recruitment Firm') OR
    (Channel_Grouping_Name = 'Marketing' AND Original_source = 'Advisor Waitlist')
),

-- 2. Get historical averages for ALL segments (using most recent 30-day window)
recent_historical AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    AVG(mqls_daily) AS mqls_30day_avg,
    AVG(sqls_daily) AS sqls_30day_avg
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE date_day BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1, 2
),

-- 3. Filter to only sparse segments (exclude healthy ones)
sparse_averages AS (
  SELECT 
    rh.Channel_Grouping_Name,
    rh.Original_source,
    rh.mqls_30day_avg,
    rh.sqls_30day_avg
  FROM recent_historical rh
  LEFT JOIN healthy_segments h
    ON rh.Channel_Grouping_Name = h.Channel_Grouping_Name
    AND rh.Original_source = h.Original_source
  WHERE h.Channel_Grouping_Name IS NULL -- Only sparse segments
),

-- 4. Create a 90-day date spine for the forecast
date_spine AS (
  SELECT date_day
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      CURRENT_DATE(), 
      DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY), 
      INTERVAL 1 DAY
    )
  ) AS date_day
)

-- 5. Generate the 90-day forecast for all sparse segments
SELECT 
  d.date_day,
  sa.Channel_Grouping_Name,
  sa.Original_source,
  sa.mqls_30day_avg AS mqls_forecast,
  sa.sqls_30day_avg AS sqls_forecast
FROM 
  date_spine d
CROSS JOIN 
  sparse_averages sa;

