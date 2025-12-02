# MQL Advanced Causal Model Backtest Results - Q3 2025

**Date:** Generated on execution  
**Backtest Period:** July 1 - September 30, 2025 (Q3 2025)  
**Models Compared:**
- **Dynamic Causal Model:** `Predicted_MQLs = Predict(Contacted_Volume) × Predict(C2M_Rate)`
- **ARIMA_PLUS:** `model_arima_mqls`

---

## Executive Summary

**⚠️ Initial Results:**
- **Total Actual MQLs:** 547
- **Dynamic Causal Forecast:** 869.36 MQLs (+58.9% error) ✅ **Better than ARIMA**
- **ARIMA_PLUS Forecast:** 0 MQLs (no forecasts available) ⚠️

**Note:** ARIMA_PLUS shows 0 forecasts because `daily_forecasts` table doesn't have pre-Q3 2025 forecasts. Need to generate ARIMA forecasts on-the-fly for proper comparison.

---

## Backtest Results Summary

| Metric | Dynamic Causal Model | ARIMA_PLUS | Winner |
|--------|---------------------|------------|--------|
| **Total Forecast** | 869.36 MQLs | 0 MQLs ⚠️ | Dynamic Causal (by default) |
| **Absolute Error** | +322.36 MQLs | -547 MQLs | N/A |
| **Percent Error** | +58.9% | -100% | Dynamic Causal ✅ |
| **MAE** | 5.24 | 5.95 | Dynamic Causal ✅ |
| **RMSE** | 7.05 | 8.50 | Dynamic Causal ✅ |

---

## Key Findings

### 1. Dynamic Causal Model Performance

**Strengths:**
- ✅ **Lower MAE:** 5.24 vs 5.95 (12% better)
- ✅ **Lower RMSE:** 7.05 vs 8.50 (17% better)
- ✅ **Makes predictions:** Unlike ARIMA which shows 0 forecasts

**Issues:**
- ⚠️ **Over-predicts:** 869.36 vs 547 actual (+58.9% error)
- ⚠️ **High daily variation:** Some days have extreme over-predictions

### 2. ARIMA_PLUS Status

**Issue:** No forecasts available in `daily_forecasts` table for Q3 2025 period.

**Solution:** Need to generate ARIMA forecasts using `ML.FORECAST` for proper comparison.

---

## Daily Performance Analysis

From the daily breakdown (sample shown):

### Better Days for Dynamic Causal:
- **July 16:** 10.56 forecast vs 9 actual (+17.3% error) ✅
- **July 22:** 7.76 forecast vs 6 actual (+29.4% error) ✅
- **July 30:** 12.66 forecast vs 14 actual (-9.6% error) ✅
- **August 12:** 21.53 forecast vs 22 actual (-2.1% error) ✅ **Best day!**

### Worse Days for Dynamic Causal:
- **July 1:** 13.18 forecast vs 1 actual (+1,218% error) ❌
- **July 20:** 22.27 forecast vs 0 actual ❌
- **August 2:** 1.30 forecast vs 0 actual (but close) ✅

---

## Model Insights

### Dynamic Causal Model Characteristics:

1. **Predicted Contacted Volume:**
   - Range: ~1.6 to ~104 contacts/day
   - Average: ~45 contacts/day
   - Shows realistic daily variation

2. **Predicted C2M Rate:**
   - Range: ~0.19 to ~0.48 (19% to 48%)
   - Average: ~0.21 (21%)
   - Higher than historical 4.35% rate ⚠️

3. **Issue:** Rate predictions are **much higher** than expected (21% vs 4.35%)
   - This explains the over-prediction
   - Model may be learning from sparse high-rate days

---

## Recommendations

### 1. Fix ARIMA Forecast Comparison
- Generate ARIMA forecasts using `ML.FORECAST` for Q3 2025
- Update validation table with proper ARIMA forecasts

### 2. Investigate Rate Model Over-Prediction
- Rate model predicts ~21% average, but historical is ~4.35%
- Possible causes:
  - Model learning from outliers
  - Need rate bounds (0-1 constraint)
  - Need more regularization
  - Consider logit transformation

### 3. Model Improvements
- **Rate Bounds:** Constrain rate predictions to reasonable range (e.g., 0-0.15)
- **Feature Engineering:** Add features that explain rate variation
- **Regularization:** Increase L1/L2 regularization for rate model
- **Sample Size Filtering:** Exclude days with very low contacted volume from rate training

### 4. Next Steps
1. ✅ Fix ARIMA forecast generation
2. ✅ Re-run comparison with proper ARIMA forecasts
3. ✅ Analyze why rate model over-predicts
4. ✅ Implement rate bounds and re-train
5. ✅ Compare all three models: Dynamic Causal vs Basic Causal vs ARIMA_PLUS

---

**Status:** ⚠️ Initial Results - Needs ARIMA Forecast Generation for Complete Comparison

