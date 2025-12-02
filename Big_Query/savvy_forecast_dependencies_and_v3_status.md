# savvy_forecast Dataset: Dependencies and V3 Model Status

**Generated:** Using BigQuery MCP tools  
**Dataset:** `savvy-gtm-analytics.savvy_forecast`

---

## Dependencies on `sql_sqo_propensity_training_v2`

### Objects That Use `sql_sqo_propensity_training_v2`

| Object Name | Type | Relationship | Purpose |
|-------------|------|--------------|---------|
| **`model_sql_sqo_propensity_v2`** | MODEL | **Trained on** `sql_sqo_propensity_training_v2` | V2 SQL-to-SQO propensity classifier model |

**Summary:**
- ✅ **Only 1 object depends on `sql_sqo_propensity_training_v2`**: `model_sql_sqo_propensity_v2`
- This is the V2 SQL-to-SQO conversion model (predicts if an SQL will become an SQO)
- **No views or other tables** reference `sql_sqo_propensity_training_v2` directly
- Created: October 31, 2025 (1,551 training rows)

---

## Most Up-to-Date V3 Model

### Latest V3 ToF Model

| Model Name | Type | Training Data | Status | Description |
|------------|------|---------------|--------|-------------|
| **`model_tof_sql_regressor_v3_daily`** | MODEL | `tof_v3_daily_training_data_FINAL` | ✅ **LATEST** | **Production-ready daily regression model** |

### All V3 Models (By Recency)

| Model Name | Training Data | Creation Time | Status |
|------------|---------------|---------------|--------|
| **`model_tof_sql_regressor_v3_daily`** | `tof_v3_daily_training_data_FINAL` | Most Recent | ✅ **LATEST** - Daily regression |
| `model_tof_sql_backtest_daily` | `tof_v3_daily_training_data_FINAL` | Most Recent | ✅ Backtest version |
| `model_tof_sql_classifier_v3_calibrated` | `tof_v3_daily_training_data` (segment) | Earlier | ❌ FAILED - Calibration issues |
| `model_tof_sql_classifier_v3` | `tof_v3_daily_training_data` (segment) | Earlier | ❌ FAILED - Probability calibration |
| `model_tof_sql_backtest_classifier_calibrated` | `tof_v3_daily_training_data` (segment) | Earlier | ❌ FAILED - Calibration issues |
| `model_tof_sql_forecast_v3` | `tof_v3_daily_training_data` (segment) | Earliest | ❌ FAILED - Segment sparsity |

### V3 Training Tables

| Table Name | Rows | Purpose | Status |
|------------|------|---------|--------|
| **`tof_v3_daily_training_data_FINAL`** | 633 | **Latest** - Daily aggregated training data | ✅ **ACTIVE** |
| `tof_v3_daily_training_data` | 272,190 | Segment-level training data (abandoned) | ❌ DEPRECATED |

---

## Model Architecture Evolution

### V3 Model Journey

1. **First Attempt: Segment-Level Regressor**
   - Model: `model_tof_sql_forecast_v3`
   - Issue: ❌ Failed due to 99.75% data sparsity
   - Result: Over-prediction (2,870 SQLs vs 89 actual)

2. **Second Attempt: Segment-Level Classifier**
   - Models: `model_tof_sql_classifier_v3`, `model_tof_sql_classifier_v3_calibrated`
   - Issue: ❌ Probability calibration destroyed by class weights
   - Result: Catastrophic over-prediction (1,757-13,260 SQLs vs 89 actual)

3. **Third Attempt: Daily Regression (CURRENT)**
   - Model: `model_tof_sql_regressor_v3_daily`
   - Approach: ✅ Daily aggregation (no segments)
   - Result: Realistic forecast (16.6 SQLs vs 89 actual, -81.4% error)
   - Status: ⚠️ Under-predicts but magnitude is realistic

---

## Key Relationships

### V2 Model (SQL-to-SQO Conversion)
- **Training Table:** `sql_sqo_propensity_training_v2`
- **Model:** `model_sql_sqo_propensity_v2`
- **Purpose:** Predicts if an SQL will convert to SQO
- **Status:** ✅ Active (validated model)

### V3 Model (ToF SQL Forecasting)
- **Training Table:** `tof_v3_daily_training_data_FINAL`
- **Model:** `model_tof_sql_regressor_v3_daily`
- **Purpose:** Predicts daily total SQL counts
- **Status:** ⚠️ Validated but under-predicts (needs improvement)

---

## Production Objects Summary

### Active Models

| Model | Purpose | Training Table | Status |
|-------|---------|----------------|--------|
| `model_sql_sqo_propensity_v2` | SQL→SQO conversion | `sql_sqo_propensity_training_v2` | ✅ Production |
| `model_tof_sql_regressor_v3_daily` | Daily SQL forecast | `tof_v3_daily_training_data_FINAL` | ⚠️ Active (needs tuning) |

### Deprecated/Failed Models

| Model | Issue | Status |
|-------|-------|--------|
| `model_tof_sql_forecast_v3` | Segment sparsity | ❌ Deprecated |
| `model_tof_sql_classifier_v3` | Probability calibration | ❌ Deprecated |
| `model_tof_sql_classifier_v3_calibrated` | Probability calibration | ❌ Deprecated |
| `model_tof_sql_backtest_classifier_calibrated` | Probability calibration | ❌ Deprecated |

---

## Recommendations

1. **For `sql_sqo_propensity_training_v2`:**
   - Only `model_sql_sqo_propensity_v2` depends on it
   - Safe to modify/update if model is retrained
   - No other downstream dependencies

2. **For V3 Models:**
   - **Use `model_tof_sql_regressor_v3_daily`** as the production model
   - Consider archiving/removing failed segment-level models
   - Continue tuning daily model to improve accuracy

3. **Data Lineage:**
   - V2 model: SQLs → SQOs (conversion prediction)
   - V3 model: Daily SQL counts (volume forecasting)
   - Models are independent - V2 operates on SQL level, V3 operates on daily aggregate level

---

**Report Generated:** Using BigQuery MCP catalog search and table metadata queries

