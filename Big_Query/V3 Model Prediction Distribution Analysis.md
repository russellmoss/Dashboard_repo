# V3 Model Prediction Distribution Analysis

**Report Date:** Generated on execution  
**Model:** `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest`  
**Analysis Period:** October 2025 (31 days)  
**Purpose:** Diagnose aggregation problem and identify optimal threshold for filtering noise

---

## Executive Summary

The V3 model is producing thousands of small fractional predictions across all segment-day combinations. When summed without filtering, this results in a forecast of **528.31 SQLs**, far exceeding the actual **89 SQLs** for October 2025.

**Key Finding:**
- **Noise Detection:** The model predicts an average of **0.267 SQLs** for segments with actual = 0
- **Signal Detection:** The model predicts an average of **0.911 SQLs** for segments with actual > 0
- **Optimal Threshold:** A threshold of **0.25** filters out most noise while preserving signal, resulting in a forecast of **229.09 SQLs** (still high, but closer to actual)

**Recommendation:** Apply a threshold of **0.25** to filter predictions, though this still results in significant over-prediction. The fundamental issue is that the model predicts positive values for nearly all segment-day combinations.

---

## Query 1: Prediction vs. Actual Analysis Table

**Table Created:** `savvy-gtm-analytics.savvy_forecast.tof_v3_prediction_analysis`

This table contains predictions and actuals for every segment-day combination in October 2025.

**Total Rows:** 1,930 segment-days  
**Rows with Actual SQLs > 0:** 20 (1.0% of total)  
**Rows with Actual SQLs = 0/Null:** 1,910 (99.0% of total)  
**Total Actual SQLs:** 21 (Note: Training data shows 21, but using 89 as ground truth per user requirement)

**Note:** The table was created using ML.PREDICT on the actual October 2025 data from the training table, as ML.FORECAST does not work with BOOSTED_TREE_REGRESSOR models.

---

## Query 2: Prediction Distribution for "Actual = 0" Rows (Noise)

### Statistics for Segments with No Actual SQLs

| Metric | Value |
|--------|-------|
| **Total Rows** | 1,910 |
| **Average Prediction** | 0.267 SQLs |
| **Minimum Prediction** | 0.171 SQLs |
| **25th Percentile (P25)** | 0.171 SQLs |
| **Median (P50)** | 0.171 SQLs |
| **75th Percentile (P75)** | 0.205 SQLs |
| **90th Percentile (P90)** | 0.891 SQLs |
| **95th Percentile (P95)** | 1.007 SQLs |
| **Maximum Prediction** | 1.239 SQLs |

### Analysis

**Noise Characteristics:**
- **Baseline Noise:** Most predictions cluster around **0.17-0.21 SQLs** (P25-P75 range)
- **Noise Amplification:** When summed across 1,910 rows, even 0.17 SQLs per row = **~325 SQLs** of pure noise
- **High-Value Outliers:** Some segments get predictions up to **1.24 SQLs** even with actual = 0 (likely due to high lag features from previous activity)

**Key Insight:** The regression model predicts continuous positive values even for segments that should be 0. This is expected behavior for regression models on sparse data - they don't naturally predict exactly zero.

---

## Query 3: Prediction Distribution for "Actual > 0" Rows (Signal)

### Statistics for Segments with Actual SQLs

| Metric | Value |
|--------|-------|
| **Total Rows** | 20 |
| **Average Prediction** | 0.911 SQLs |
| **Minimum Prediction** | 0.306 SQLs |
| **25th Percentile (P25)** | 0.879 SQLs |
| **Median (P50)** | 0.909 SQLs |
| **75th Percentile (P75)** | 1.020 SQLs |
| **Maximum Prediction** | 1.089 SQLs |

### Analysis

**Signal Characteristics:**
- **Average Signal:** Model predicts **0.911 SQLs** on average for segments with actual SQLs
- **Signal Range:** Predictions range from **0.31 to 1.09 SQLs** for actual SQL segments
- **Signal vs Noise:** Average signal (0.911) is **3.4x higher** than average noise (0.267)

**Key Insight:** The model does distinguish signal from noise (signal predictions are 3.4x higher), but the separation is not large enough to filter perfectly with a single threshold.

---

## Query 4: Forecast Totals with Different Thresholds

### Comparison Table

| Model Name | Threshold | Forecasted SQLs | Actual SQLs | Absolute Error | Relative Error % |
|------------|-----------|----------------|-------------|----------------|------------------|
| **V1 (ARIMA_PLUS)** | - | 35.0 | 89 | -54.0 | 60.7% |
| **V3 (ML Model) - No Threshold** | 0.0 | 528.31 | 89 | 439.31 | 493.6% |
| **V3 (ML Model) - Thresholded** | 0.05 | 528.31 | 89 | 439.31 | 493.6% |
| **V3 (ML Model) - Thresholded** | 0.10 | 528.31 | 89 | 439.31 | 493.6% |
| **V3 (ML Model) - Thresholded** | 0.15 | 528.31 | 89 | 439.31 | 493.6% |
| **V3 (ML Model) - Thresholded** | 0.20 | 283.53 | 89 | 194.53 | 218.6% |
| **V3 (ML Model) - Thresholded** | 0.25 | 229.09 | 89 | 140.09 | 157.4% |
| **V3 (ML Model) - Thresholded** | 0.30 | 229.09 | 89 | 140.09 | 157.4% |
| **V3 (ML Model) - Thresholded** | 0.40 | 228.17 | 89 | 139.17 | 156.4% |
| **V3 (ML Model) - Thresholded** | 0.50 | 228.17 | 89 | 139.17 | 156.4% |

### Analysis

**Threshold Effectiveness:**

1. **Thresholds 0.05 - 0.15:** No effect (predictions don't drop below these thresholds in aggregate)
2. **Threshold 0.20:** Significant reduction (528 → 284 SQLs, -46% reduction)
3. **Threshold 0.25:** Further reduction (528 → 229 SQLs, -57% reduction) - **OPTIMAL THRESHOLD**
4. **Thresholds 0.30 - 0.50:** Minimal additional reduction (229 → 228 SQLs)

**Key Finding:**
- **Best Threshold:** **0.25** provides the best balance, reducing forecast from 528 to 229 SQLs
- **Remaining Error:** Even with threshold 0.25, forecast is still **157.4% too high** (229 vs 89 actual)
- **V1 Comparison:** V1 ARIMA_PLUS (35 SQLs) is closer to actual (89 SQLs) with 60.7% error, but under-predicts

---

## Root Cause Analysis

### Problem: Regression Model on Sparse Data

The fundamental issue is that **BOOSTED_TREE_REGRESSOR** predicts continuous positive values for nearly all segment-day combinations. This is characteristic behavior for regression models on sparse count data:

1. **Training Data Sparsity:** 99% of segment-days have 0 SQLs, but the model learns to predict small positive averages
2. **No Natural Zero Prediction:** Regression models don't naturally predict exactly 0 - they predict expected values
3. **Aggregation Amplification:** When summing 1,930 segment-days, even small positive predictions (0.17-0.27 avg) accumulate to 528 total SQLs

### Why Thresholds Don't Fully Solve the Problem

Even with a threshold of 0.25:
- **Forecast:** 229 SQLs (still 2.6x actual)
- **Issue:** Many segments still pass the threshold (0.25-0.91 range) that shouldn't
- **Root Cause:** The separation between signal (0.91 avg) and noise (0.27 avg) is not large enough for perfect filtering

---

## Recommendations

### Immediate Fix: Apply Threshold 0.25

**Action:** Apply a threshold of **0.25** to all V3 model predictions before aggregation:

```sql
-- Example aggregation with threshold
SUM(CASE
  WHEN predicted_sqls < 0.25 THEN 0
  ELSE predicted_sqls
END) AS forecasted_sqls
```

**Result:** Reduces forecast from 528 to 229 SQLs (still 157% error, but better than 494%)

### Long-Term Solutions

1. **Consider Classification Model:** Build a binary classifier (SQL > 0 vs SQL = 0) to filter segments, then use regression only on predicted-positive segments
2. **Segment Filtering:** Only predict for segments with recent activity (e.g., SQLs in last 30 days)
3. **Alternative Aggregation:** Instead of summing all segments, use a different approach:
   - Round predictions to nearest integer
   - Only aggregate segments with predictions > 0.5
   - Use ensemble with classification model
4. **Model Architecture:** Consider a different model type that handles sparse count data better (e.g., Poisson regression or Zero-Inflated models)

---

## Conclusion

The V3 model's aggregation problem stems from summing thousands of small positive predictions across all segment-day combinations. While a threshold of **0.25** significantly reduces the error (from 494% to 157%), the fundamental issue remains: the regression model predicts positive values for segments that should be zero.

**Current Status:**
- ✅ **Noise Identified:** Average 0.27 SQLs prediction for segments with actual = 0
- ✅ **Signal Identified:** Average 0.91 SQLs prediction for segments with actual > 0
- ✅ **Threshold Found:** 0.25 provides best balance
- ⚠️ **Remaining Issue:** Even with threshold, forecast is 2.6x actual (229 vs 89)

**Next Steps:**
1. Apply threshold 0.25 in production forecasts
2. Consider alternative model architectures for sparse count data
3. Explore segment-level filtering before prediction
4. Test classification + regression ensemble approach

---

**Report End**

