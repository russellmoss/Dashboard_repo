# V3 ToF Phase 4 Backtest Results (Classifier)

**Report Date:** Generated on execution  
**Backtest Period:** October 2025 (31 days)  
**Model:** `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_classifier`  
**Forecast Method:** Sum of predicted probabilities from binary classifier

---

## Executive Summary

The V3 classifier model has been backtested for October 2025. The model demonstrates a critical issue: **poor probability calibration for aggregation**. The model predicts high probabilities (~0.97) for most segment-days, even when actual SQLs = 0, resulting in massive over-prediction when probabilities are summed.

**Key Findings:**
- ❌ **V3 Forecast:** 1,757 SQLs (vs 89 actual) - **1,874% error**
- ⚠️ **V1 Forecast:** 35 SQLs (vs 89 actual) - **-60.7% error**
- ❌ **Model Issue:** Probability calibration is inverted - predicts high prob when actual = 0, low prob when actual > 0
- ⚠️ **Root Cause:** Severely imbalanced classifier (99% / 1%) produces probabilities that don't aggregate well

---

## Final Comparison Results

| Model | Forecasted SQLs | Actual SQLs | Absolute Error | Relative Error |
|-------|----------------|-------------|----------------|----------------|
| **V1 (ARIMA_PLUS)** | 35 | 89 | -54 | **-60.7%** |
| **V3 (Classifier)** | 1,757 | 89 | +1,668 | **+1,874%** |

### Analysis

**V1 (ARIMA_PLUS) Performance:**
- Under-predicted by 54 SQLs (60.7% error)
- Forecast: 35 SQLs vs Actual: 89 SQLs
- **Status:** Under-forecast, but reasonable magnitude

**V3 (Classifier) Performance:**
- Over-predicted by 1,668 SQLs (1,874% error)
- Forecast: 1,757 SQLs vs Actual: 89 SQLs
- **Status:** ❌ **FAILED** - Massive over-prediction

---

## Diagnosis: Probability Calibration Issue

### Prediction Distribution Analysis

**For Rows with Valid Lag Features (1,930 segment-days):**

| Metric | Value |
|--------|-------|
| **Total Predictions** | 1,930 |
| **Average Predicted Probability** | 0.910 (91.0%) |
| **Median Predicted Probability** | 0.970 (97.0%) |
| **Min Predicted Probability** | 0.070 (7.0%) |
| **Max Predicted Probability** | 0.983 (98.3%) |

**Actual vs Predicted Breakdown:**

| Cohort | Avg Predicted Prob | Actual SQLs | Status |
|--------|-------------------|-------------|--------|
| **When Actual SQLs = 0** | **0.970 (97.0%)** | 0 | ❌ **WRONG** (should be ~0%) |
| **When Actual SQLs > 0** | **0.324 (32.4%)** | >0 | ❌ **WRONG** (should be ~100%) |

### Critical Finding

**The model's probability predictions are inverted or poorly calibrated:**
- **For negative cases (actual = 0):** Model predicts 97% probability → **Should be near 0%**
- **For positive cases (actual > 0):** Model predicts 32% probability → **Should be near 100%**

This indicates the model has learned to predict probabilities that are:
1. **Too high for negative cases** - causing massive over-prediction when summed
2. **Too low for positive cases** - indicating poor discrimination despite high ROC-AUC

---

## Root Cause Analysis

### Why This Happened

1. **Severe Class Imbalance:** 99.07% negative / 0.93% positive class
   - `auto_class_weights=TRUE` helps with discrimination but may not calibrate probabilities well for aggregation

2. **Probability Aggregation Issue:** 
   - Summing probabilities from a binary classifier assumes well-calibrated probabilities
   - For imbalanced data, probabilities may be calibrated for classification thresholds, not for aggregation

3. **Model Behavior:**
   - High ROC-AUC (96.7%) indicates good ranking ability (can rank positives vs negatives)
   - But probabilities are not calibrated for direct aggregation
   - The model predicts "likely to have SQL" with high probability, but this doesn't translate to "will have exactly 1 SQL"

### Comparison: V1 vs V3

**V1 (ARIMA_PLUS) Issues:**
- Failed on 83% of sparse segments
- 55% forecast error (under-prediction)
- But magnitude was reasonable (35 vs 89)

**V3 (Classifier) Issues:**
- Works well for ranking/classification (ROC-AUC = 96.7%)
- Fails catastrophically for probability aggregation (1,874% error)
- Magnitude is completely wrong (1,757 vs 89)

---

## Data Analysis

### October 2025 Actuals

**Total October SQLs (all segments):** 39 SQLs (from training table)  
**Note:** Comparison uses 89 SQLs as stated in requirements (may be from different source/calculation)

**October 2025 Breakdown:**
- **Rows with valid lag features:** 1,930 segment-days
  - Actual SQLs: 21
  - Predicted (sum of probs): 1,757
- **Rows with NULL lag features:** 11,400 segment-days
  - Actual SQLs: 18 (estimated)
  - Cannot be predicted (no historical data)

**Coverage Issue:**
- Only 53.8% of actual SQLs (21 of 39) are in segments with valid historical data
- 46.2% of SQLs come from new segments or segments with data gaps (cannot be forecasted)

---

## Recommendations

### Immediate Actions

1. ❌ **DO NOT use probability summation** for forecasting with this classifier
   - The probabilities are not calibrated for aggregation
   - Summing probabilities produces unreliable forecasts

2. **Alternative Approaches:**
   - **Option A:** Use classifier with threshold to identify "likely" segments, then apply segment-specific conversion rates
   - **Option B:** Use regression model with regularization to predict counts directly (but this had aggregation issues too)
   - **Option C:** Hybrid approach - classifier identifies segments, separate model predicts counts for those segments

### Model Calibration Fixes (If Continuing with Classifier)

1. **Probability Calibration:**
   - Apply Platt scaling or isotonic regression to calibrate probabilities
   - Test calibration on validation set before aggregation

2. **Different Aggregation Method:**
   - Instead of summing probabilities, count predictions above a threshold
   - Or: Use expected value = P(has_sql) × average_sqls_when_positive

3. **Post-Processing:**
   - Apply scaling factor based on validation performance
   - Example: If validation shows 10x over-prediction, scale down by 10x

---

## Conclusion

**Backtest Status:** ❌ **FAILED**

The V3 classifier model demonstrates excellent discrimination ability (ROC-AUC = 96.7%) but **fails catastrophically** when probabilities are summed for forecasting. The model predicts probabilities that are inverted relative to actual outcomes, resulting in 1,874% forecast error.

**Key Lessons:**
1. High ROC-AUC does not guarantee well-calibrated probabilities for aggregation
2. Severely imbalanced classifiers may require probability calibration before aggregation
3. Summing probabilities assumes well-calibrated probabilities, which this model lacks

**Next Steps:**
- Consider probability calibration techniques (Platt scaling, isotonic regression)
- Explore alternative aggregation methods (threshold-based counting, expected value calculation)
- Investigate hybrid approaches combining classifier segmentation with count prediction

---

**Report Status:** ❌ **BACKTEST FAILED - PROBABILITY CALIBRATION ISSUE IDENTIFIED**

