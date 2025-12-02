-- ============================================================================
-- MQL Causal Model Backtest: Q3 2025
-- Architecture: Predicted_MQLs = Predict(Contacted_Volume) * Hybrid_Contacted_to_MQL_Rate
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Training Data View for Contacted Volume Regressor
-- ============================================================================

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training` AS
WITH
-- 1. Get all leads with contacted flag (excluding impossible dates)
leads_base AS (
  SELECT
    DATE(stage_entered_contacting__c) AS contacted_date,
    1 AS is_contacted
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(stage_entered_contacting__c) >= '2024-01-01'
    AND DATE(stage_entered_contacting__c) <= CURRENT_DATE()
    AND stage_entered_contacting__c IS NOT NULL
    -- Exclude impossible dates (data quality)
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(stage_entered_contacting__c))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
),

-- 2. Create a full date spine
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT MIN(contacted_date) FROM leads_base),
    (SELECT MAX(contacted_date) FROM leads_base),
    INTERVAL 1 DAY
  )) AS date_day
),

-- 3. Aggregate contacted counts by DAY
daily_aggregates AS (
  SELECT
    date_spine.date_day,
    SUM(leads_base.is_contacted) AS target_contacted_volume
  FROM date_spine
  LEFT JOIN leads_base
    ON date_spine.date_day = leads_base.contacted_date
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
-- STEP 2: Train the Contacted Volume Regressor Model
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
-- STEP 3: Generate Contacted Volume Predictions for Q3 2025 Backtest Period
-- ============================================================================

-- Create a table to store backtest predictions
CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_contacted_backtest_q3_2025` AS
WITH
-- Generate date spine for Q3 2025
q3_dates AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-07-01', '2025-09-30', INTERVAL 1 DAY)) AS date_day
),

-- Get historical data to calculate lag features for the forecast period
historical_data AS (
  SELECT
    date_day,
    target_contacted_volume
  FROM `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training`
  WHERE date_day < '2025-07-01'
),

-- Combine historical + future dates for lag calculation
full_timeline AS (
  SELECT date_day, target_contacted_volume
  FROM historical_data
  UNION ALL
  SELECT date_day, NULL AS target_contacted_volume
  FROM q3_dates
),

-- Generate features for forecast period (including lag features)
forecast_features AS (
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
  FROM full_timeline
)

-- Generate predictions for Q3 2025
SELECT
  date_day,
  predicted_target_contacted_volume AS predicted_contacted_volume
FROM ML.PREDICT(
  MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_contacted_regressor_v1`,
  (SELECT * FROM forecast_features WHERE date_day >= '2025-07-01' AND date_day <= '2025-09-30')
);


-- ============================================================================
-- STEP 4: Create Hybrid Contacted-to-MQL Conversion Rate
-- Mimicking the logic of vw_hybrid_conversion_rates for SQL→SQO
-- ============================================================================

CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_hybrid_c2m_rate_q3_2025` AS
WITH
-- 1. Get actual contacted volume distribution (last 90 days before Q3 2025) for weighting
-- Using daily stage counts for consistency
recent_contacted_distribution AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    SUM(mqls_daily) / NULLIF(SUM(mqls_daily) OVER (), 0) AS contacted_fraction  -- Will use actual contacted volume
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE date_day >= DATE_SUB('2025-07-01', INTERVAL 90 DAY)
    AND date_day < '2025-07-01'
  GROUP BY Channel_Grouping_Name, Original_source
),

-- 2. Get trailing rates for Contacted → MQL by Channel/Source (if available)
-- For now, we'll use a global rate, but this structure allows for segment-specific rates
trailing_c2m_rates AS (
  SELECT
    DATE(stage_entered_contacting__c) AS contacted_date,
    CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
    COALESCE(
      (SELECT Channel_Grouping_Name FROM `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` 
       WHERE Original_Source_Salesforce = l.LeadSource),
      'Other'
    ) AS Channel_Grouping_Name,
    COALESCE(l.LeadSource, 'Unknown') AS Original_source
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead` l
  WHERE DATE(stage_entered_contacting__c) >= DATE_SUB('2025-07-01', INTERVAL 90 DAY)
    AND DATE(stage_entered_contacting__c) < '2025-07-01'
    AND stage_entered_contacting__c IS NOT NULL
    -- Exclude impossible dates
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(stage_entered_contacting__c))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
),

-- 3. Calculate global trailing conversion rate (last 90 days)
trailing_c2m_rate_global AS (
  SELECT
    SAFE_DIVIDE(
      SUM(is_mql),
      COUNT(*)
    ) AS trailing_c2m_rate,
    COUNT(*) AS trailing_sample_size
  FROM trailing_c2m_rates
),

-- 4. Historical fallback rate (4.35% from historical data)
historical_fallback_rate AS (
  SELECT 0.0435 AS fallback_c2m_rate
),

-- 5. Hybrid rate: Use trailing if sample size >= 50, otherwise fallback
-- (Similar logic to vw_hybrid_conversion_rates but simplified for C2M)
hybrid_rate AS (
  SELECT
    '2025-07-01' AS backtest_period_start,
    '2025-09-30' AS backtest_period_end,
    CASE
      WHEN tr.trailing_sample_size >= 50 THEN tr.trailing_c2m_rate
      ELSE hf.fallback_c2m_rate
    END AS hybrid_c2m_rate,
    tr.trailing_c2m_rate,
    hf.fallback_c2m_rate,
    tr.trailing_sample_size,
    CASE
      WHEN tr.trailing_sample_size >= 50 THEN 'Trailing Rate (90-day)'
      ELSE 'Historical Fallback Rate (4.35%)'
    END AS rate_source
  FROM trailing_c2m_rate_global tr
  CROSS JOIN historical_fallback_rate hf
)

SELECT * FROM hybrid_rate;


-- ============================================================================
-- STEP 5: Validation Query - Compare All Models
-- ============================================================================

CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_mql_backtest_validation_q3_2025` AS
WITH
-- 1. Get predicted contacted volume from Step 3
contacted_predictions AS (
  SELECT
    date_day,
    predicted_contacted_volume
  FROM `savvy-gtm-analytics.savvy_forecast.tof_contacted_backtest_q3_2025`
),

-- 2. Get hybrid conversion rate from Step 4
hybrid_rate AS (
  SELECT hybrid_c2m_rate
  FROM `savvy-gtm-analytics.savvy_forecast.tof_hybrid_c2m_rate_q3_2025`
  LIMIT 1
),

-- 3. Calculate new Causal MQL Forecast
causal_forecast AS (
  SELECT
    cp.date_day,
    cp.predicted_contacted_volume,
    hr.hybrid_c2m_rate,
    cp.predicted_contacted_volume * hr.hybrid_c2m_rate AS causal_mql_forecast
  FROM contacted_predictions cp
  CROSS JOIN hybrid_rate hr
),

-- 4. Get old ARIMA_PLUS MQL forecast for Q3 2025
-- Option A: If forecasts exist in daily_forecasts table (pre-generated)
-- Option B: Generate forecasts using ML.FORECAST (if model exists)
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

-- 5. Get actual MQLs for Q3 2025
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

-- 6. Combine all forecasts and actuals
SELECT
  COALESCE(cf.date_day, af.date_day, am.mql_date) AS date_day,
  COALESCE(cf.predicted_contacted_volume, 0) AS predicted_contacted_volume,
  COALESCE(cf.hybrid_c2m_rate, 0) AS hybrid_c2m_rate,
  COALESCE(cf.causal_mql_forecast, 0) AS causal_mql_forecast,
  COALESCE(af.arima_mql_forecast, 0) AS arima_mql_forecast,
  COALESCE(am.actual_mqls, 0) AS actual_mqls
FROM causal_forecast cf
FULL OUTER JOIN arima_forecast af
  ON cf.date_day = af.date_day
FULL OUTER JOIN actual_mqls am
  ON COALESCE(cf.date_day, af.date_day) = am.mql_date;


-- ============================================================================
-- STEP 6: Final Comparison Summary
-- ============================================================================

SELECT
  'Q3 2025 Backtest Summary' AS report_type,
  SUM(actual_mqls) AS total_actual_mqls,
  SUM(causal_mql_forecast) AS total_causal_mql_forecast,
  SUM(arima_mql_forecast) AS total_arima_mql_forecast,
  SUM(causal_mql_forecast) - SUM(actual_mqls) AS causal_absolute_error,
  SUM(arima_mql_forecast) - SUM(actual_mqls) AS arima_absolute_error,
  SAFE_DIVIDE(
    SUM(causal_mql_forecast) - SUM(actual_mqls),
    SUM(actual_mqls)
  ) * 100 AS causal_percent_error,
  SAFE_DIVIDE(
    SUM(arima_mql_forecast) - SUM(actual_mqls),
    SUM(actual_mqls)
  ) * 100 AS arima_percent_error,
  -- MAE (Mean Absolute Error)
  AVG(ABS(causal_mql_forecast - actual_mqls)) AS causal_mae,
  AVG(ABS(arima_mql_forecast - actual_mqls)) AS arima_mae,
  -- RMSE (Root Mean Squared Error)
  SQRT(AVG(POWER(causal_mql_forecast - actual_mqls, 2))) AS causal_rmse,
  SQRT(AVG(POWER(arima_mql_forecast - actual_mqls, 2))) AS arima_rmse,
  -- Winner
  CASE
    WHEN ABS(SAFE_DIVIDE(SUM(causal_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls))) < 
         ABS(SAFE_DIVIDE(SUM(arima_mql_forecast) - SUM(actual_mqls), SUM(actual_mqls)))
    THEN 'Causal Model ✅'
    ELSE 'ARIMA_PLUS ✅'
  END AS winner
FROM `savvy-gtm-analytics.savvy_forecast.tof_mql_backtest_validation_q3_2025`
WHERE actual_mqls > 0 OR causal_mql_forecast > 0 OR arima_mql_forecast > 0;


-- ============================================================================
-- BONUS: Daily Breakdown for Analysis
-- ============================================================================

SELECT
  date_day,
  actual_mqls,
  causal_mql_forecast,
  arima_mql_forecast,
  causal_mql_forecast - actual_mqls AS causal_daily_error,
  arima_mql_forecast - actual_mqls AS arima_daily_error,
  SAFE_DIVIDE(causal_mql_forecast - actual_mqls, actual_mqls) * 100 AS causal_daily_pct_error,
  SAFE_DIVIDE(arima_mql_forecast - actual_mqls, actual_mqls) * 100 AS arima_daily_pct_error
FROM `savvy-gtm-analytics.savvy_forecast.tof_mql_backtest_validation_q3_2025`
WHERE actual_mqls > 0 OR causal_mql_forecast > 0 OR arima_mql_forecast > 0
ORDER BY date_day;

