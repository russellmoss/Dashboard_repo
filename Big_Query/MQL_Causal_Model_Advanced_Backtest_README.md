# MQL Causal Model Advanced Backtest - Q3 2025

**Objective:** Test an advanced challenger model that predicts both contacted volume AND the Contacted-to-MQL conversion rate using ML regressors.

**Advanced Architecture:** `Predicted_MQLs = Predict(Contacted_Volume) * Predict(Contacted_to_MQL_Rate)`

**Comparison:** Dynamic Causal Model (Volume × Rate predictions) vs ARIMA_PLUS vs Actuals

---

## Overview

This advanced backtest validates a more sophisticated causal MQL forecasting approach:
- **Volume Model:** Predicts daily contacted volume (same as basic causal model)
- **Rate Model:** Predicts daily C2M conversion rate (NEW - dynamically predicts rate instead of using static/hybrid rate)
- **Final Forecast:** `predicted_contacted_volume × predicted_c2m_rate`

Both models use the same BOOSTED_TREE_REGRESSOR methodology that successfully worked for V3.1 SQL model.

---

## Key Innovation

**Previous Approach (Basic Causal):**
- `Predicted_MQLs = Predict(Contacted_Volume) * Static_Hybrid_Rate`
- Uses a single conversion rate (trailing 90-day or fallback)

**New Approach (Advanced Causal):**
- `Predicted_MQLs = Predict(Contacted_Volume) * Predict(Contacted_to_MQL_Rate)`
- Dynamically predicts the conversion rate itself
- Rate can vary by day based on:
  - Temporal patterns (day of week, month, seasonality)
  - Historical rate patterns (lagged rates)
  - Volume patterns (contacted volume can affect conversion rate)

---

## Execution Steps

The SQL file `MQL_Causal_Model_Advanced_Backtest_Q3_2025.sql` contains all steps:

### Step 1: Create Training Data View for Contacted Volume ✅
**View:** `vw_tof_contacted_volume_training`

- Aggregates `is_contacted` by day
- Target: `target_contacted_volume` (daily count)
- Features: Temporal + lagged volume features

---

### Step 2: Create Training Data View for C2M Rate ✅
**View:** `vw_tof_c2m_rate_training` **NEW**

**Key Differences:**
- **Target:** `daily_c2m_rate` (calculated as `mql_count / contacted_count` per day)
- **Excludes:** Days with zero contacted volume (no valid rate)
- **Features:**
  - Temporal features (same as volume model)
  - **Lagged rate features:** `c2m_rate_7day_avg_lag1`, `c2m_rate_28day_avg_lag1`
  - **Lagged volume features:** `contacted_7day_avg_lag1`, `contacted_28day_avg_lag1` (volume can affect rate)

**Rate Calculation:**
```sql
daily_c2m_rate = CASE
  WHEN contacted_count > 0 THEN mql_count / contacted_count
  ELSE NULL  -- Exclude days with no contacted volume
END
```

---

### Step 3: Train Contacted Volume Regressor ✅
**Model:** `model_tof_contacted_regressor_v1`

- Predicts daily contacted volume
- Same as basic causal model

---

### Step 4: Train C2M Rate Regressor ✅
**Model:** `model_tof_c2m_rate_regressor_v1` **NEW**

- **Type:** `BOOSTED_TREE_REGRESSOR`
- **Target:** `daily_c2m_rate` (conversion rate, typically 0-1)
- **Features:**
  - Temporal: `day_of_week`, `day_of_month`, `month`, `year`, `is_weekend`
  - Rate Lags: `c2m_rate_7day_avg_lag1`, `c2m_rate_28day_avg_lag1`
  - Volume Lags: `contacted_7day_avg_lag1`, `contacted_28day_avg_lag1`
- **Training Data:** Pre-Q3 2025 only (`WHERE date_day < '2025-07-01'`)

---

### Step 5: Generate Backtest Predictions ✅
**Table:** `tof_advanced_backtest_q3_2025`

**Process:**
1. Generate features for Q3 2025 dates (both volume and rate)
2. Calculate lag features using historical data + future dates
3. Use `ML.PREDICT` on both models:
   - `model_tof_contacted_regressor_v1` → `predicted_contacted_volume`
   - `model_tof_c2m_rate_regressor_v1` → `predicted_c2m_rate`
4. Calculate: `dynamic_causal_mql_forecast = predicted_contacted_volume × predicted_c2m_rate`

**Output Columns:**
- `date_day`
- `predicted_contacted_volume`
- `predicted_c2m_rate`
- `dynamic_causal_mql_forecast`

---

### Step 6: Validation Query ✅
**Table:** `tof_advanced_backtest_validation_q3_2025`

Combines:
- Dynamic Causal Forecast (from Step 5)
- ARIMA_PLUS Forecast (from `daily_forecasts` or `ML.FORECAST`)
- Actual MQLs (from `Lead` table)

---

### Step 7: Final Comparison Summary ✅

**Metrics:**
- Total Actual MQLs
- Total Dynamic Causal Forecast
- Total ARIMA_PLUS Forecast
- Percent Errors (both models)
- MAE and RMSE (both models)
- **Winner:** Model with lower absolute percent error
- **Error Reduction:** How much the dynamic model improves over ARIMA

---

## Advantages of Dynamic Rate Prediction

1. **Temporal Patterns:**
   - Conversion rates may vary by day of week, month, or season
   - ML model can learn these patterns automatically

2. **Volume Effects:**
   - Higher contacted volume may affect conversion rates (diminishing returns, quality vs quantity)
   - Model includes volume lag features to capture this

3. **Rate Trends:**
   - Conversion rates may trend up or down over time
   - Lagged rate features capture recent rate patterns

4. **Holiday Effects:**
   - Rates may be different during holidays or special periods
   - Temporal features help capture these

---

## Expected Output

### Summary Table:
| Metric | Dynamic Causal | ARIMA_PLUS |
|--------|----------------|------------|
| Total Forecast | [X.XX] | [X.XX] |
| % Error | [X.XX%] | [X.XX%] |
| MAE | [X.XX] | [X.XX] |
| RMSE | [X.XX] | [X.XX] |
| Winner | ✅ or ❌ | ✅ or ❌ |
| Error Reduction | [X.XX p.p.] | - |

### Daily Breakdown:
- Day-by-day comparison
- Shows `predicted_contacted_volume` and `predicted_c2m_rate` for each day
- Identifies which model wins each day

---

## Comparison to Basic Causal Model

| Approach | Volume Prediction | Rate Method | Complexity |
|----------|------------------|-------------|------------|
| **Basic Causal** | ML Regressor | Static Hybrid Rate | Lower |
| **Advanced Causal** | ML Regressor | ML Regressor (Dynamic) | Higher |

**Question:** Does predicting the rate dynamically improve accuracy over using a static hybrid rate?

**This backtest will answer:** Compare Advanced Causal vs ARIMA_PLUS vs Basic Causal (if available)

---

## Files Created

1. **Views:**
   - `vw_tof_contacted_volume_training`
   - `vw_tof_c2m_rate_training` **NEW**

2. **Models:**
   - `model_tof_contacted_regressor_v1`
   - `model_tof_c2m_rate_regressor_v1` **NEW**

3. **Tables:**
   - `tof_advanced_backtest_q3_2025`
   - `tof_advanced_backtest_validation_q3_2025`

---

## Next Steps After Backtest

1. **If Dynamic Causal Model Wins:**
   - Compare against Basic Causal Model (static hybrid rate)
   - Integrate both models into production if superior
   - Create production views for rate predictions

2. **If ARIMA_PLUS Wins:**
   - Analyze why dynamic rate prediction didn't help
   - Consider: Is rate too volatile to predict accurately?
   - May need more features or different approach

3. **Model Improvements:**
   - Add segment-level rate prediction (super-segments)
   - Experiment with rate bounds (0-1 constraint)
   - Consider rate smoothing techniques

---

**Status:** ✅ Ready for Execution

