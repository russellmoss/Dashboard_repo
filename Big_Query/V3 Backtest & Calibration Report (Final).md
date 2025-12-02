# V3 Backtest & Calibration Report (Final)

**Report Date:** Generated on execution  
**Backtest Period:** October 2025 (31 days)  
**Model:** `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_classifier_calibrated`  
**Calibration Change:** Removed `auto_class_weights=TRUE` to improve probability calibration  
**Forecast Method:** Sum of predicted probabilities from binary classifier

---

## Executive Summary

The V3 classifier model was retrained **without class weights** to improve probability calibration. Unfortunately, the calibrated model **still shows severe probability calibration issues**, predicting extremely high probabilities (~99.5%) for both positive and negative cases. The forecast error remains catastrophic at **14,798%** (13,260 SQLs vs 89 actual).

**Key Findings:**
- ❌ **V3 Forecast:** 13,260 SQLs (vs 89 actual) - **14,798% error**
- ⚠️ **V1 Forecast:** 35 SQLs (vs 89 actual) - **-60.7% error**
- ❌ **Probability Calibration:** Still inverted - predicts 99.5% for negative cases, 90.6% for positive cases
- ❌ **Root Cause:** Removing class weights made the problem worse - model now heavily favors majority class

---

## Backtest Comparison Results

### Final Comparison Table

| Model | Forecasted SQLs | Actual SQLs | Absolute Error | Relative Error |
|-------|----------------|-------------|----------------|----------------|
| **V1 (ARIMA_PLUS)** | 35 | 89 | -54 | **-60.7%** |
| **V3 (Calibrated Classifier)** | **13,260** | 89 | +13,171 | **+14,798%** |

### Analysis

**V1 (ARIMA_PLUS) Performance:**
- Under-predicted by 54 SQLs (60.7% error)
- Forecast: 35 SQLs vs Actual: 89 SQLs
- **Status:** Under-forecast, but reasonable magnitude

**V3 (Calibrated Classifier) Performance:**
- Over-predicted by 13,171 SQLs (14,798% error)
- Forecast: 13,260 SQLs vs Actual: 89 SQLs
- **Status:** ❌ **FAILED** - Removing class weights made the problem worse

**Comparison to Previous Model (with class weights):**
- Previous (with weights): 1,757 SQLs forecast (1,874% error)
- Current (without weights): 13,260 SQLs forecast (14,798% error)
- **Removing class weights INCREASED the error by 8x**

---

## Probability Calibration Analysis

### Prediction Distribution by Cohort

| Cohort | Total Rows | Avg Predicted Probability | Median (p50) | p95 Percentile |
|--------|------------|--------------------------|--------------|----------------|
| **Actual = 0 (Noise)** | 13,294 | **99.5%** | - | - |
| **Actual > 0 (Signal)** | 36 | **90.6%** | - | - |

### Critical Findings

**❌ Probability Calibration is Still Completely Broken:**

1. **For Negative Cases (actual = 0):**
   - Average predicted probability: **99.5%**
   - **Status:** ❌ **CRITICALLY WRONG** - Should be near 0%
   - This is even worse than before (was 97% with class weights)

2. **For Positive Cases (actual > 0):**
   - Average predicted probability: **90.6%**
   - **Status:** ⚠️ Better than before (was 32%), but still not well-calibrated

3. **Overall:**
   - Model predicts **99.5% probability** that SQLs will occur, even when they don't
   - This causes massive over-prediction when probabilities are summed
   - Removing class weights made the calibration worse, not better

---

## Root Cause Analysis

### Why Removing Class Weights Made It Worse

1. **Without Class Weights:**
   - Model heavily favors majority class (99% negative cases)
   - Learns to predict "no SQLs" for almost everything
   - But probabilities are still miscalibrated - predicts 99.5% for negative class

2. **With Class Weights (Previous):**
   - Model balances class importance
   - Better at identifying positive cases (32% prob when actual > 0)
   - But still predicts 97% for negative cases

3. **Fundamental Issue:**
   - **Neither approach produces well-calibrated probabilities for aggregation**
   - Binary classifier probabilities are not designed for direct summation
   - The model architecture itself may be incompatible with probability-based forecasting

### Model Architecture Limitations

**Binary Classifier for Count Forecasting:**
- Binary classifiers predict "will this event occur?" (yes/no probability)
- They are not designed to predict "how many events will occur?"
- Summing probabilities assumes each prediction is independent and well-calibrated
- For sparse, imbalanced data, this assumption breaks down completely

---

## Comparison: All Model Versions

| Model Version | Forecast | Error | Avg Prob (Actual=0) | Avg Prob (Actual>0) | Status |
|---------------|----------|-------|---------------------|---------------------|--------|
| **V1 (ARIMA_PLUS)** | 35 | -60.7% | - | - | ⚠️ Under-predicts |
| **V3 (with class weights)** | 1,757 | +1,874% | 97.0% | 32.4% | ❌ Over-predicts |
| **V3 (no class weights)** | 13,260 | +14,798% | 99.5% | 90.6% | ❌ **WORST** |

### Key Insight

**Removing class weights made the calibration WORSE:**
- Increased forecast error from 1,874% to 14,798% (8x worse)
- Increased average probability for negative cases from 97% to 99.5%
- Model now predicts even higher probabilities across the board

---

## Recommendations

### Immediate Actions

1. ❌ **DO NOT use this classifier approach for probability-based forecasting**
   - Both versions (with and without class weights) fail catastrophically
   - Binary classifier architecture is fundamentally incompatible with probability summation

2. **Alternative Approaches:**
   - **Option A: Count-Based Regression** - Use regression model with regularization (but this had aggregation issues too)
   - **Option B: Threshold-Based Counting** - Use classifier to identify "likely" segments, then count predictions above threshold
   - **Option C: Expected Value Calculation** - Use P(has_sql) × average_sqls_when_positive for each segment
   - **Option D: Two-Stage Model** - Classifier identifies segments, separate count model predicts quantities

### Probability Calibration Techniques (If Continuing)

1. **Platt Scaling:**
   - Apply logistic regression to calibrate probabilities
   - Requires validation set with known outcomes

2. **Isotonic Regression:**
   - Non-parametric probability calibration
   - May help with severe miscalibration

3. **Calibration Plot Analysis:**
   - Analyze probability bins vs actual outcomes
   - Identify calibration curve and apply correction

### Architecture Change Recommendations

1. **Hybrid Approach:**
   - Stage 1: Classifier identifies segment-days likely to have SQLs
   - Stage 2: Regression model predicts SQL counts for identified segment-days
   - Sum Stage 2 predictions for final forecast

2. **Poisson or Negative Binomial Regression:**
   - Designed for count data (non-negative integers)
   - Natural fit for SQL count forecasting
   - Handles sparse data better than binary classification

3. **Ensemble Approach:**
   - Combine multiple model types
   - Use classifier for segmentation, regression for counts
   - Weighted average of predictions

---

## Conclusion

**Backtest Status:** ❌ **FAILED** (Both Versions)

Both versions of the V3 classifier model (with and without class weights) **fail catastrophically** for probability-based forecasting. Removing class weights made the problem significantly worse, increasing forecast error from 1,874% to 14,798%.

**Key Lessons:**
1. Binary classifier probabilities are not suitable for direct aggregation
2. Removing class weights worsens probability calibration for imbalanced data
3. The model architecture itself (binary classification) is incompatible with count forecasting via probability summation
4. Alternative approaches (regression, threshold-based, hybrid) are required

**Next Steps:**
- Abandon probability summation approach with binary classifiers
- Explore count-based regression models (Poisson, Negative Binomial)
- Consider hybrid two-stage approach (classifier + count model)
- Apply probability calibration techniques if continuing with classifiers

---

**Report Status:** ❌ **BACKTEST FAILED - ARCHITECTURE INCOMPATIBLE WITH PROBABILITY AGGREGATION**

