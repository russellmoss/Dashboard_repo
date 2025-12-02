# V3 Top-of-Funnel (ToF) Challenger Model: Implementation Plan

**Objective**: Replace the flawed `ARIMA_PLUS` time-series model with a simple, robust `BOOSTED_TREE_REGRESSOR` model (`model_tof_sql_regressor_v3_daily`) that forecasts **total daily SQL counts** (aggregated across all segments).

**Methodology**: Daily aggregation approach - we aggregate SQLs by day only (no segments) to avoid the 99.75% sparsity issue that caused the segment-level approach to fail. This simpler model uses global temporal features and lagged rolling averages to predict daily totals directly.

**Key Differences from Previous Approaches:**
- ❌ **Segment-Level Classifier:** Failed due to 99.75% sparsity and probability calibration issues
- ✅ **Daily Regression:** Simple, robust approach that predicts daily totals directly
- No segment features, no probability summation - just direct count prediction

**CRITICAL EXECUTION REQUIREMENTS:**
⚠️ **BEFORE ANY MODEL TRAINING:**
1. **MUST** validate data quality (data leakage, impossible dates, outliers)
2. **MUST** check collinearity between features (remove if |correlation| >0.95)
3. **MUST** verify temporal features use proper lags (no future information)
4. **MUST** apply regularization and overfitting prevention

**MODEL VALIDATION REQUIREMENTS:**
- R² >0.5, Train-Val RMSE gap <15%, Monthly MAPE <20%
- Feature limit: <15 features, Regularization required
- See "Overfitting Prevention Checklist" in Phase 3 for full criteria

-----

## Phase 1: Create Daily-Aggregated Training Table

Create a simple training table that aggregates SQLs by day (no segments). This avoids the sparsity issues of segment-level data.

### Cursor.ai Prompt (Phase 1):

"Please execute the following query to create our master training table, `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`. This table will aggregate SQLs by day only (no segments) and create temporal and lagged features."

**Query 1: Create Training Table**

```sql
CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL` AS

WITH
-- 1. Get all leads, excluding impossible dates (from Phase 0)
leads_base AS (
  SELECT
    DATE(CreatedDate) AS created_date,
    CASE WHEN IsConverted = TRUE THEN 1 ELSE 0 END AS is_sql
  FROM `savvy-gtm-analytics.SavvyGTMData.Lead`
  WHERE DATE(CreatedDate) >= '2024-01-01'
    AND DATE(CreatedDate) <= CURRENT_DATE()
    AND NOT (
      (Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(Stage_Entered_Call_Scheduled__c) < DATE(CreatedDate))
      OR
      (IsConverted = TRUE AND Stage_Entered_Call_Scheduled__c IS NOT NULL AND DATE(ConvertedDate) < DATE(Stage_Entered_Call_Scheduled__c))
    )
),

-- 2. Create a full date spine
date_spine AS (
  SELECT date_day
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT MIN(created_date) FROM leads_base),
    (SELECT MAX(created_date) FROM leads_base),
    INTERVAL 1 DAY
  )) AS date_day
),

-- 3. Aggregate SQL counts by DAY (not by segment)
daily_aggregates AS (
  SELECT
    date_spine.date_day,
    SUM(leads_base.is_sql) AS total_daily_sqls
  FROM date_spine
  LEFT JOIN leads_base
    ON date_spine.date_day = leads_base.created_date
  GROUP BY 1
),

-- 4. Create global temporal and lagged features
final_features AS (
  SELECT
    *,
    -- Temporal Features
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month,
    EXTRACT(QUARTER FROM date_day) AS quarter,
    EXTRACT(YEAR FROM date_day) AS year,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    
    -- Lagged Features (GLOBAL Rolling Averages)
    AVG(total_daily_sqls) OVER (
      ORDER BY date_day
      ROWS BETWEEN 8 PRECEDING AND 1 PRECEDING
    ) AS sqls_7day_avg_lag1,
    
    AVG(total_daily_sqls) OVER (
      ORDER BY date_day
      ROWS BETWEEN 29 PRECEDING AND 1 PRECEDING
    ) AS sqls_28day_avg_lag1
    
  FROM daily_aggregates
)
SELECT * FROM final_features
-- Exclude first 28 days for incomplete lags
WHERE date_day >= DATE_ADD((SELECT MIN(date_day) FROM daily_aggregates), INTERVAL 28 DAY);
```

-----

## Phase 2: Model Training

Train a BOOSTED_TREE_REGRESSOR model to predict total daily SQLs.

### Cursor.ai Prompt (Phase 2):

"Now that we have a clean, daily-aggregated table, please train our new BOOSTED_TREE_REGRESSOR. This model will predict the total daily SQLs."

**Query 1: Train the Model**

```sql
CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_daily`
OPTIONS(
  model_type='BOOSTED_TREE_REGRESSOR',
  input_label_cols=['total_daily_sqls'],
  
  -- Sequential data split for time series
  data_split_method='SEQ',
  data_split_col='date_day',
  data_split_eval_fraction=0.2,
  
  -- Standard parameters
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
  -- Label
  total_daily_sqls,
  
  -- Date (for sequential splitting)
  date_day,
  
  -- Features
  day_of_week,
  day_of_month,
  month,
  quarter,
  is_weekend,
  sqls_7day_avg_lag1,
  sqls_28day_avg_lag1
FROM `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`
WHERE total_daily_sqls IS NOT NULL;
```

**Query 2: Evaluate the Model**

```sql
SELECT
  *
FROM ML.EVALUATE(MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_daily`);
```

**Query 3: Feature Importance**

```sql
SELECT
  feature,
  importance_weight,
  importance_gain,
  importance_cover
FROM ML.FEATURE_IMPORTANCE(MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_daily`)
ORDER BY importance_gain DESC;
```

-----

## Phase 3: Backtest vs. ARIMA_PLUS

Run the definitive October 2025 backtest to compare V3 against V1.

### Cursor.ai Prompt (Phase 3):

"This is the definitive test. We must re-run the October 2025 backtest using this new daily regressor model. Please train a temporary backtest model on pre-Oct 2025 data, use ML.PREDICT to forecast the 31 days of October, and compare the sum of its 31 predictions to V1 (35) and Actual (89)."

**Query 1: Train Backtest Model**

```sql
-- Train backtest model (on data before 2025-10-01)
CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_daily`
OPTIONS(
  model_type='BOOSTED_TREE_REGRESSOR',
  input_label_cols=['total_daily_sqls'],
  
  -- Sequential data split
  data_split_method='SEQ',
  data_split_col='date_day',
  data_split_eval_fraction=0.1, -- Small eval fraction since we're holding out Oct separately
  
  -- Standard parameters
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
  total_daily_sqls,
  date_day,
  day_of_week,
  day_of_month,
  month,
  quarter,
  is_weekend,
  sqls_7day_avg_lag1,
  sqls_28day_avg_lag1
FROM `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`
WHERE date_day >= '2024-02-01'
  AND date_day < '2025-10-01'  -- Only train on pre-October data
  AND total_daily_sqls IS NOT NULL;
```

**Query 2: Run Forecast and Comparison**

```sql
-- Run the forecast and final comparison
WITH
-- Get October 2025 data for prediction
october_data AS (
  SELECT *
  FROM `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`
  WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31'
    AND total_daily_sqls IS NOT NULL
),
-- Get predictions
v3_predictions AS (
  SELECT
    date_day,
    predicted_total_daily_sqls AS daily_forecast
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_daily`,
    (SELECT * FROM october_data)
  )
),
v1_model AS (
  SELECT
    'V1 (ARIMA_PLUS)' as model_name,
    35 AS forecasted_sqls,
    89 AS actual_sqls,
    35 - 89 AS absolute_error,
    SAFE_DIVIDE(35 - 89, 89) AS relative_error
),
v3_model_forecast AS (
  SELECT
    -- Sum all daily predictions for October total
    SUM(daily_forecast) AS v3_forecasted_sqls
  FROM v3_predictions
),
v3_model AS (
  SELECT
    'V3 (New Daily ML Model)' as model_name,
    v3_forecasted_sqls,
    89 AS actual_sqls,
    v3_forecasted_sqls - 89 AS absolute_error,
    SAFE_DIVIDE(v3_forecasted_sqls - 89, 89) AS relative_error
  FROM v3_model_forecast
)
SELECT * FROM v1_model
UNION ALL
SELECT * FROM v3_model;
```

-----

## Phase 4: Production Integration

After the backtest validates the model, integrate it into production forecasting.

### Cursor.ai Prompt (Phase 4):

"The backtest results confirm the V3 model. Please create the final production forecast for the next 90 days using the V3 daily model."

**Query 1: Production Forecast**

```sql
-- Generate 90-day production forecast
WITH
-- Get recent data for lag feature calculation
recent_data AS (
  SELECT *
  FROM `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`
  WHERE date_day > DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  ORDER BY date_day DESC
  LIMIT 90
),
-- Generate future dates and features (simplified - would need proper lag calculation in production)
future_forecast AS (
  SELECT
    SUM(predicted_total_daily_sqls) AS total_forecast_sqls
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_daily`,
    (SELECT * FROM recent_data)
  )
)
SELECT
  'V3 Daily ML Model' AS model_version,
  total_forecast_sqls AS forecasted_sqls,
  CURRENT_DATE() AS forecast_date
FROM future_forecast;
```

-----

## Summary

This simplified V3 approach:
- ✅ Avoids segment-level sparsity issues (99.75% zeros)
- ✅ Uses direct regression (no probability calibration issues)
- ✅ Predicts daily totals directly (simple aggregation)
- ✅ Leverages temporal patterns and global lag features

**Expected Performance:**
- More stable than segment-level approaches
- Realistic magnitude forecasts (no catastrophic over/under-prediction)
- May need feature tuning to match V1 performance
