# MQL Causal Model Backtest - Q3 2025

**Objective:** Replace `model_arima_mqls` with a causal model using the same BOOSTED_TREE_REGRESSOR methodology that successfully worked for V3.1 SQL model.

**New Architecture:** `Predicted_MQLs = Predict(Contacted_Volume) * Hybrid_Contacted_to_MQL_Rate`

---

## Overview

This backtest validates the new causal MQL forecasting approach against:
- **Old Model:** ARIMA_PLUS (`model_arima_mqls`)
- **Actuals:** Historical MQL data for Q3 2025 (July 1 - September 30, 2025)

---

## Execution Steps

The SQL file `MQL_Causal_Model_Backtest_Q3_2025.sql` contains all steps in sequence:

### Step 1: Create Training Data View ✅
**View:** `vw_tof_contacted_volume_training`

- Aggregates `is_contacted` by day (mirrors V3.1 structure)
- Includes temporal features: `day_of_week`, `day_of_month`, `month`, `year`, `is_weekend`
- Includes lagged features: `contacted_7day_avg_lag1`, `contacted_28day_avg_lag1`
- Excludes first 28 days (no lag features available)
- **Target Variable:** `target_contacted_volume` (daily count of leads that entered "Contacted" stage)

**SQL Definition:**
```sql
CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_forecast.vw_tof_contacted_volume_training` AS
-- (See full SQL in MQL_Causal_Model_Backtest_Q3_2025.sql)
```

---

### Step 2: Train Contacted Volume Regressor ✅
**Model:** `model_tof_contacted_regressor_v1`

- **Type:** `BOOSTED_TREE_REGRESSOR`
- **Training Data:** Pre-Q3 2025 data only (`WHERE date_day < '2025-07-01'`)
- **Split Method:** Sequential (`SEQ`) on `date_day`
- **Eval Fraction:** 0.2
- **Regularization:** L1=0.1, L2=1.0
- **Max Tree Depth:** 6
- **Early Stopping:** Enabled

**Training Query:**
```sql
CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_tof_contacted_regressor_v1`
OPTIONS(...)
AS
SELECT ... FROM vw_tof_contacted_volume_training
WHERE date_day < '2025-07-01';
```

---

### Step 3: Generate Contacted Volume Predictions ✅
**Table:** `tof_contacted_backtest_q3_2025`

- Uses `ML.PREDICT` to forecast contacted volume for each day in Q3 2025
- Calculates lag features using historical data + future dates
- Stores predictions in a table for joining with conversion rates

**Key Features:**
- Generates features for Q3 2025 dates
- Calculates `contacted_7day_avg_lag1` and `contacted_28day_avg_lag1` using window functions
- Includes historical data to ensure accurate lag calculations

---

### Step 4: Create Hybrid Contacted-to-MQL Conversion Rate ✅
**Table:** `tof_hybrid_c2m_rate_q3_2025`

**Logic (mimics `vw_hybrid_conversion_rates`):**
1. **Trailing Rate:** Calculate 90-day rolling C2M rate (before Q3 2025)
2. **Fallback Rate:** Use historical rate (4.35% from historical analysis)
3. **Hybrid Rate:** Use trailing if sample size >= 50, otherwise fallback

**Formula:**
```sql
hybrid_c2m_rate = CASE
  WHEN trailing_sample_size >= 50 THEN trailing_c2m_rate
  ELSE 0.0435  -- Historical fallback
END
```

**Output:**
- `hybrid_c2m_rate`: Single rate for Q3 2025 backtest period
- `rate_source`: "Trailing Rate (90-day)" or "Historical Fallback Rate (4.35%)"

---

### Step 5: Validation Query ✅
**Table:** `tof_mql_backtest_validation_q3_2025`

Combines all forecasts and actuals:

**Columns:**
- `date_day`: Daily date for Q3 2025
- `predicted_contacted_volume`: From Step 3 (model predictions)
- `hybrid_c2m_rate`: From Step 4 (conversion rate)
- `causal_mql_forecast`: `predicted_contacted_volume * hybrid_c2m_rate` ✅ **NEW MODEL**
- `arima_mql_forecast`: From `daily_forecasts` table or `ML.FORECAST` ✅ **OLD MODEL**
- `actual_mqls`: Historical actuals from `Lead` table ✅ **GROUND TRUTH**

---

### Step 6: Final Comparison Summary ✅

**Metrics Calculated:**
- Total Actual MQLs
- Total Causal MQL Forecast (new model)
- Total ARIMA MQL Forecast (old model)
- Absolute Errors (both models)
- Percent Errors (both models)
- MAE (Mean Absolute Error)
- RMSE (Root Mean Squared Error)
- **Winner:** Model with lower absolute percent error

---

## How to Execute

1. **Run the SQL file sequentially:**
   ```sql
   -- Execute MQL_Causal_Model_Backtest_Q3_2025.sql
   -- All steps run in order
   ```

2. **Check results:**
   ```sql
   -- Final summary
   SELECT * FROM `savvy-gtm-analytics.savvy_forecast.tof_mql_backtest_validation_q3_2025`
   ORDER BY date_day;
   
   -- Comparison summary
   -- (Last query in the SQL file)
   ```

3. **Analyze daily breakdown:**
   ```sql
   -- Daily errors
   SELECT
     date_day,
     actual_mqls,
     causal_mql_forecast,
     arima_mql_forecast,
     causal_mql_forecast - actual_mqls AS causal_error,
     arima_mql_forecast - actual_mqls AS arima_error
   FROM `savvy-gtm-analytics.savvy_forecast.tof_mql_backtest_validation_q3_2025`
   ORDER BY date_day;
   ```

---

## Expected Output

### Summary Table:
| Metric | Value |
|--------|-------|
| Total Actual MQLs | [Q3 2025 actual] |
| Total Causal MQL Forecast | [New model prediction] |
| Total ARIMA MQL Forecast | [Old model prediction] |
| Causal % Error | [X.XX%] |
| ARIMA % Error | [X.XX%] |
| Winner | Causal Model ✅ or ARIMA_PLUS ✅ |

### Daily Breakdown:
- Day-by-day comparison showing which model performed better on each day
- Cumulative error tracking

---

## Next Steps After Backtest

1. **If Causal Model Wins:**
   - Integrate into production (replace `model_arima_mqls`)
   - Update `vw_production_forecast` to use new model
   - Create `vw_hybrid_c2m_rates` view (similar to `vw_hybrid_conversion_rates`)

2. **If ARIMA_PLUS Wins:**
   - Analyze why causal model underperformed
   - Consider feature engineering improvements
   - May need segment-level contacted volume prediction

3. **Model Improvements:**
   - Add segment-level features (super-segments like V3.1)
   - Experiment with different lag windows
   - Consider holiday effects (if not already included)

---

## Files Created

1. **View:** `vw_tof_contacted_volume_training`
2. **Model:** `model_tof_contacted_regressor_v1`
3. **Tables:**
   - `tof_contacted_backtest_q3_2025`
   - `tof_hybrid_c2m_rate_q3_2025`
   - `tof_mql_backtest_validation_q3_2025`

---

**Status:** ✅ Ready for Execution

