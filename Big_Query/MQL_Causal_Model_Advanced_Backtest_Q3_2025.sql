-- ============================================================================
-- MQL Causal Model Advanced Backtest: Q3 2025
-- Architecture: Predicted_MQLs = Predict(Contacted_Volume) * Predict(Contacted_to_MQL_Rate)
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Training Data View for Contacted Volume Regressor
-- ============================================================================

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training` AS
WITH
-- 1. Get all leads with contacted flag (excluding impossible dates)
-- FIXED: Use FilterDate for date attribution (aligned with production views)
leads_base AS (
  SELECT
    DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) AS filter_date,
    1 AS is_contacted
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) >= '2024-01-01'
    AND DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) <= CURRENT_DATE()
    AND stage_entered_contacting__c IS NOT NULL  -- Only leads that were contacted
    -- Exclude impossible dates (data quality)
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(stage_entered_contacting__c))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
),

-- 2. Create a full date spine (using filter_date now)
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT MIN(filter_date) FROM leads_base),
    (SELECT MAX(filter_date) FROM leads_base),
    INTERVAL 1 DAY
  )) AS date_day
),

-- 3. Aggregate contacted counts by DAY (using FilterDate)
daily_aggregates AS (
  SELECT
    date_spine.date_day,
    SUM(leads_base.is_contacted) AS target_contacted_volume
  FROM date_spine
  LEFT JOIN leads_base
    ON date_spine.date_day = leads_base.filter_date
  GROUP BY 1
),

-- 4. Create temporal and lagged features (similar to V3.1)
final_features AS (
  SELECT
    *,
    -- Temporal Features
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month,
    EXTRACT(YEAR FROM date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    
    -- Lagged Features (GLOBAL Rolling Averages)
    AVG(target_contacted_volume) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS contacted_7day_avg_lag1,
    
    AVG(target_contacted_volume) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS contacted_28day_avg_lag1
    
  FROM daily_aggregates
)
SELECT * FROM final_features
WHERE date_day >= DATE_ADD((SELECT MIN(date_day) FROM daily_aggregates), INTERVAL 28 DAY);  -- Exclude first 28 days (no lag features)


-- ============================================================================
-- STEP 2: Create Training Data View for C2M Rate Regressor
-- ============================================================================

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_tof_c2m_rate_training` AS
WITH
-- 1. Get daily contacted and MQL counts
-- For C2M rate: Of leads contacted on day X, how many also became MQL (progression-based)
-- FIXED: Use FilterDate for date attribution (aligned with production views)
daily_funnel_counts AS (
  SELECT
    DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) AS filter_date,
    COUNT(DISTINCT Full_prospect_id__c) AS contacted_count,
    COUNT(DISTINCT CASE 
      WHEN stage_entered_contacting__c IS NOT NULL THEN Full_prospect_id__c 
    END) AS contacted_leads_count,
    COUNT(DISTINCT CASE 
      WHEN stage_entered_contacting__c IS NOT NULL 
        AND Stage_Entered_Call_Scheduled__c IS NOT NULL 
      THEN Full_prospect_id__c 
    END) AS mql_count_from_contacted
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) >= '2024-01-01'
    AND DATE(GREATEST(
      IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
      IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
    )) <= CURRENT_DATE()
    AND stage_entered_contacting__c IS NOT NULL  -- Only leads that were contacted
    -- Exclude impossible dates (data quality)
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(stage_entered_contacting__c))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
  GROUP BY 1
),

-- 2. Create a full date spine (using filter_date now)
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT MIN(filter_date) FROM daily_funnel_counts),
    (SELECT MAX(filter_date) FROM daily_funnel_counts),
    INTERVAL 1 DAY
  )) AS date_day
),

-- 3. Calculate daily C2M conversion rate
-- Rate = Of leads with FilterDate on day X that were contacted, what % also became MQL (progression-based)
-- FIXED: Using FilterDate for date attribution (aligned with production views)
daily_rates AS (
  SELECT
    date_spine.date_day,
    COALESCE(dfc.contacted_leads_count, 0) AS contacted_count,
    COALESCE(dfc.mql_count_from_contacted, 0) AS mql_count_from_contacted,
    -- Calculate conversion rate (only for days with contacted > 0)
    -- This is progression-based: leads contacted (FilterDate = day X) that became MQL (ever)
    CASE
      WHEN COALESCE(dfc.contacted_leads_count, 0) > 0 THEN 
        SAFE_DIVIDE(COALESCE(dfc.mql_count_from_contacted, 0), COALESCE(dfc.contacted_leads_count, 0))
      ELSE NULL  -- No rate if no contacted volume
    END AS daily_c2m_rate
  FROM date_spine
  LEFT JOIN daily_funnel_counts dfc
    ON date_spine.date_day = dfc.filter_date
),

-- 4. Create temporal and lagged features (same as volume model)
-- Lag features are based on rate, not volume
final_features AS (
  SELECT
    *,
    -- Temporal Features
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month,
    EXTRACT(YEAR FROM date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    
    -- Lagged Features (Rolling Averages of RATE)
    AVG(daily_c2m_rate) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS c2m_rate_7day_avg_lag1,
    
    AVG(daily_c2m_rate) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS c2m_rate_28day_avg_lag1,
    
    -- Also include contacted volume lag features (volume can affect rate)
    AVG(contacted_count) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS contacted_7day_avg_lag1,
    
    AVG(contacted_count) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS contacted_28day_avg_lag1
    
  FROM daily_rates
)
SELECT * FROM final_features
WHERE date_day >= DATE_ADD((SELECT MIN(date_day) FROM daily_rates), INTERVAL 28 DAY)  -- Exclude first 28 days
  AND daily_c2m_rate IS NOT NULL;  -- Only include days with valid conversion rates


-- ============================================================================
-- STEP 3: Train Contacted Volume Regressor Model
-- ============================================================================

CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_contacted_regressor_v1`
OPTIONS(
  model_type='BOOSTED_TREE_REGRESSOR',
  input_label_cols=['target_contacted_volume'],
  data_split_method='SEQ',
  data_split_col='date_day',
  data_split_eval_fraction=0.2,
  enable_global_explain=TRUE,
  max_iterations=100,
  early_stop=TRUE,
  learn_rate=0.05,
  l1_reg=0.1,
  l2_reg=1.0,
  subsample=0.8,
  max_tree_depth=6
) AS
SELECT
  target_contacted_volume,
  date_day,
  day_of_week,
  day_of_month,
  month,
  year,
  is_weekend,
  contacted_7day_avg_lag1,
  contacted_28day_avg_lag1
FROM `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training`
WHERE target_contacted_volume IS NOT NULL
  AND date_day < '2025-07-01';  -- Train only on pre-Q3 2025 data for backtest


-- ============================================================================
-- STEP 4: Train C2M Rate Regressor Model
-- ============================================================================

CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_c2m_rate_regressor_v1`
OPTIONS(
  model_type='BOOSTED_TREE_REGRESSOR',
  input_label_cols=['daily_c2m_rate'],
  data_split_method='SEQ',
  data_split_col='date_day',
  data_split_eval_fraction=0.2,
  enable_global_explain=TRUE,
  max_iterations=100,
  early_stop=TRUE,
  learn_rate=0.05,
  l1_reg=0.1,
  l2_reg=1.0,
  subsample=0.8,
  max_tree_depth=6
) AS
SELECT
  daily_c2m_rate,
  date_day,
  day_of_week,
  day_of_month,
  month,
  year,
  is_weekend,
  c2m_rate_7day_avg_lag1,
  c2m_rate_28day_avg_lag1,
  contacted_7day_avg_lag1,
  contacted_28day_avg_lag1
FROM `savvy-gtm-analytics.savvy_forecast.vw_tof_c2m_rate_training`
WHERE daily_c2m_rate IS NOT NULL
  AND date_day < '2025-07-01';  -- Train only on pre-Q3 2025 data for backtest


-- ============================================================================
-- STEP 5: Generate Backtest Predictions for Q3 2025
-- ============================================================================

-- Create a table to store backtest predictions
CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_advanced_backtest_q3_2025` AS
WITH
-- Generate date spine for Q3 2025
q3_dates AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-07-01', '2025-09-30', INTERVAL 1 DAY)) AS date_day
),

-- Get historical data to calculate lag features for the forecast period
historical_volume_data AS (
  SELECT
    date_day,
    target_contacted_volume
  FROM `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training`
  WHERE date_day < '2025-07-01'
),

historical_rate_data AS (
  SELECT
    date_day,
    daily_c2m_rate,
    contacted_count
  FROM `savvy-gtm-analytics.savvy_forecast.vw_tof_c2m_rate_training`
  WHERE date_day < '2025-07-01'
),

-- Combine historical + future dates for lag calculation (Volume)
full_timeline_volume AS (
  SELECT date_day, target_contacted_volume
  FROM historical_volume_data
  UNION ALL
  SELECT date_day, NULL AS target_contacted_volume
  FROM q3_dates
),

-- Combine historical + future dates for lag calculation (Rate)
full_timeline_rate AS (
  SELECT date_day, daily_c2m_rate, contacted_count
  FROM historical_rate_data
  UNION ALL
  SELECT date_day, NULL AS daily_c2m_rate, NULL AS contacted_count
  FROM q3_dates
),

-- Generate features for volume forecast (including lag features)
volume_forecast_features AS (
  SELECT
    date_day,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month,
    EXTRACT(YEAR FROM date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    -- Calculate lagged features using window that includes historical data
    AVG(target_contacted_volume) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS contacted_7day_avg_lag1,
    AVG(target_contacted_volume) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS contacted_28day_avg_lag1
  FROM full_timeline_volume
),

-- Generate features for rate forecast (including lag features)
rate_forecast_features AS (
  SELECT
    date_day,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month,
    EXTRACT(YEAR FROM date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    -- Lagged rate features
    AVG(daily_c2m_rate) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS c2m_rate_7day_avg_lag1,
    AVG(daily_c2m_rate) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS c2m_rate_28day_avg_lag1,
    -- Lagged volume features (volume can affect rate)
    AVG(contacted_count) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS contacted_7day_avg_lag1,
    AVG(contacted_count) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS contacted_28day_avg_lag1
  FROM full_timeline_rate
),

-- Generate volume predictions
volume_predictions AS (
  SELECT
    date_day,
    predicted_target_contacted_volume AS predicted_contacted_volume
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_contacted_regressor_v1`,
    (SELECT * FROM volume_forecast_features WHERE date_day >= '2025-07-01' AND date_day <= '2025-09-30')
  )
),

-- Generate rate predictions
rate_predictions AS (
  SELECT
    date_day,
    predicted_daily_c2m_rate AS predicted_c2m_rate
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_c2m_rate_regressor_v1`,
    (SELECT * FROM rate_forecast_features WHERE date_day >= '2025-07-01' AND date_day <= '2025-09-30')
  )
)

-- Combine volume and rate predictions
SELECT
  COALESCE(vp.date_day, rp.date_day) AS date_day,
  COALESCE(vp.predicted_contacted_volume, 0) AS predicted_contacted_volume,
  COALESCE(rp.predicted_c2m_rate, 0) AS predicted_c2m_rate,
  COALESCE(vp.predicted_contacted_volume, 0) * COALESCE(rp.predicted_c2m_rate, 0) AS dynamic_causal_mql_forecast
FROM volume_predictions vp
FULL OUTER JOIN rate_predictions rp
  ON vp.date_day = rp.date_day;


-- ============================================================================
-- STEP 6: Validation Query - Compare All Models
-- ============================================================================

CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_advanced_backtest_validation_q3_2025` AS
WITH
-- 1. Get dynamic causal forecast from Step 5
dynamic_causal_forecast AS (
  SELECT
    date_day,
    predicted_contacted_volume,
    predicted_c2m_rate,
    dynamic_causal_mql_forecast
  FROM `savvy-gtm-analytics.savvy_forecast.tof_advanced_backtest_q3_2025`
),

-- 2. Get old ARIMA_PLUS MQL forecast for Q3 2025
arima_forecast AS (
  -- Try to get from daily_forecasts first
  SELECT
    CAST(date_day AS DATE) AS date_day,
    SUM(mqls_forecast) AS arima_mql_forecast
  FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  WHERE forecast_date = (
    SELECT MAX(forecast_date) 
    FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
    WHERE date_day <= '2025-07-01'  -- Forecast generated before Q3
  )
    AND date_day >= '2025-07-01'
    AND date_day <= '2025-09-30'
  GROUP BY date_day
  
  -- If no pre-generated forecasts, uncomment below to generate on-the-fly:
  -- UNION ALL
  -- SELECT
  --   CAST(forecast_timestamp AS DATE) AS date_day,
  --   forecast_value AS arima_mql_forecast
  -- FROM ML.FORECAST(
  --   MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
  --   STRUCT(92 AS horizon, 0.9 AS confidence_level)  -- 92 days for Q3 2025
  -- )
  -- WHERE CAST(forecast_timestamp AS DATE) >= '2025-07-01'
  --   AND CAST(forecast_timestamp AS DATE) <= '2025-09-30'
),

-- 3. Get actual MQLs for Q3 2025
actual_mqls AS (
  SELECT
    DATE(Stage_Entered_Call_Scheduled__c) AS mql_date,
    COUNT(DISTINCT Full_prospect_id__c) AS actual_mqls
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(Stage_Entered_Call_Scheduled__c) >= '2025-07-01'
    AND DATE(Stage_Entered_Call_Scheduled__c) <= '2025-09-30'
    AND Stage_Entered_Call_Scheduled__c IS NOT NULL
    -- Exclude impossible dates
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(CreatedDate))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
  GROUP BY 1
)

-- Combine all forecasts and actuals
SELECT
  COALESCE(dcf.date_day, af.date_day, am.mql_date) AS date_day,
  COALESCE(dcf.predicted_contacted_volume, 0) AS predicted_contacted_volume,
  COALESCE(dcf.predicted_c2m_rate, 0) AS predicted_c2m_rate,
  COALESCE(dcf.dynamic_causal_mql_forecast, 0) AS dynamic_causal_mql_forecast,
  COALESCE(af.arima_mql_forecast, 0) AS arima_mql_forecast,
  COALESCE(am.actual_mqls, 0) AS actual_mqls
FROM dynamic_causal_forecast dcf
FULL OUTER JOIN arima_forecast af
  ON dcf.date_day = af.date_day
FULL OUTER JOIN actual_mqls am
  ON COALESCE(dcf.date_day, af.date_day) = am.mql_date;


-- ============================================================================
-- STEP 7: Final Comparison Summary
-- ============================================================================

SELECT
  'Q3 2025 Advanced Backtest Summary' AS report_type,
  'Dynamic Causal Model (Predicted Volume × Predicted Rate) vs ARIMA_PLUS' AS comparison,
  
  -- Actuals
  SUM(actual_mqls) AS total_actual_mqls,
  
  -- Dynamic Causal Model (Advanced)
  SUM(dynamic_causal_mql_forecast) AS total_dynamic_causal_mql_forecast,
  SUM(dynamic_causal_mql_forecast) - SUM(actual_mqls) AS dynamic_causal_absolute_error,
  SAFE_DIVIDE(
    SUM(dynamic_causal_mql_forecast) - SUM(actual_mqls),
    SUM(actual_mqls)
  ) * 100 AS dynamic_causal_percent_error,
  
  -- ARIMA_PLUS (Old Model)
  SUM(arima_mql_forecast) AS total_arima_mql_forecast,
  SUM(arima_mql_forecast) - SUM(actual_mqls) AS arima_absolute_error,
  SAFE_DIVIDE(
    SUM(arima_mql_forecast) - SUM(actual_mqls),
    SUM(actual_mqls)
  ) * 100 AS arima_percent_error,
  
  -- Error Metrics
  -- MAE (Mean Absolute Error)
  AVG(ABS(dynamic_causal_mql_forecast - actual_mqls)) AS dynamic_causal_mae,
  AVG(ABS(arima_mql_forecast - actual_mqls)) AS arima_mae,
  
  -- RMSE (Root Mean Squared Error)
  SQRT(AVG(POWER(dynamic_causal_mql_forecast - actual_mqls, 2))) AS dynamic_causal_rmse,
  SQRT(AVG(POWER(arima_mql_forecast - actual_mqls, 2))) AS arima_rmse,
  
  -- Winner
  CASE
    WHEN ABS(SAFE_DIVIDE(SUM(dynamic_causal_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))) < 
         ABS(SAFE_DIVIDE(SUM(arima_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls)))
    THEN 'Dynamic Causal Model ✅'
    ELSE 'ARIMA_PLUS ✅'
  END AS winner,
  
  -- Improvement metrics
  ABS(SAFE_DIVIDE(SUM(arima_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))) - 
  ABS(SAFE_DIVIDE(SUM(dynamic_causal_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))) AS error_reduction_pct_points,
  
  SAFE_DIVIDE(
    ABS(SAFE_DIVIDE(SUM(arima_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))) - 
    ABS(SAFE_DIVIDE(SUM(dynamic_causal_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))),
    ABS(SAFE_DIVIDE(SUM(arima_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls)))
  ) * 100 AS error_reduction_pct

FROM `savvy-gtm-analytics.savvy_forecast.tof_advanced_backtest_validation_q3_2025`
WHERE actual_mqls > 0 OR dynamic_causal_mql_forecast > 0 OR arima_mql_forecast > 0;


-- ============================================================================
-- BONUS: Daily Breakdown for Analysis
-- ============================================================================

SELECT
  date_day,
  actual_mqls,
  dynamic_causal_mql_forecast,
  arima_mql_forecast,
  predicted_contacted_volume,
  predicted_c2m_rate,
  dynamic_causal_mql_forecast - actual_mqls AS dynamic_causal_daily_error,
  arima_mql_forecast - actual_mqls AS arima_daily_error,
  SAFE_DIVIDE(dynamic_causal_mql_forecast - actual_mqls, actual_mqls) * 100 AS dynamic_causal_daily_pct_error,
  SAFE_DIVIDE(arima_mql_forecast - actual_mqls, actual_mqls) * 100 AS arima_daily_pct_error,
  CASE
    WHEN ABS(SAFE_DIVIDE(dynamic_causal_mql_forecast - actual_mqls, actual_mqls)) < 
         ABS(SAFE_DIVIDE(arima_mql_forecast - actual_mqls, actual_mqls))
    THEN 'Dynamic Causal ✅'
    ELSE 'ARIMA ✅'
  END AS daily_winner
FROM `savvy-gtm-analytics.savvy_forecast.tof_advanced_backtest_validation_q3_2025`
WHERE actual_mqls > 0 OR dynamic_causal_mql_forecast > 0 OR arima_mql_forecast > 0
ORDER BY date_day;

