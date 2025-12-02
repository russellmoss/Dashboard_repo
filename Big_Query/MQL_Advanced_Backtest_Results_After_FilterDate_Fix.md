# MQL Advanced Backtest Results - After FilterDate Fix

**Date:** Generated after FilterDate fix  
**Backtest Period:** July 1 - September 30, 2025 (Q3 2025)  
**Fix Applied:** Using `FilterDate` for date attribution (aligned with production views)

---

## Executive Summary

**Results After FilterDate Fix:**
- **Total Actual MQLs:** 547
- **Dynamic Causal Forecast:** 806.71 MQLs (+47.5% error) ✅ **Improved!**
- **ARIMA_PLUS Forecast:** 0 MQLs (no forecasts available) ⚠️

**Improvement:** Error reduced from +58.9% to +47.5% (-11.4 p.p. improvement)

---

## Comparison: Before vs After FilterDate Fix

| Metric | Before Fix | After Fix | Change |
|--------|-----------|-----------|--------|
| **Total Forecast** | 869.36 MQLs | 806.71 MQLs | **-62.65 MQLs** ✅ |
| **Percent Error** | +58.9% | +47.5% | **-11.4 p.p.** ✅ |
| **MAE** | 5.24 | 4.56 | **-0.68** ✅ |
| **RMSE** | 7.05 | 6.34 | **-0.71** ✅ |
| **Avg Predicted C2M Rate** | 24.9% | 25.8% | +0.9 p.p. ⚠️ |

---

## Rate Analysis

### Predicted Rates (Q3 2025 Forecast)
- **Average:** 25.8%
- **Median:** 22.3%
- **Range:** 22.3% - 42.6%
- **Std Dev:** 5.7%

### Historical Rates (Training Data - Pre Q3 2025)
- **Average:** 8.8%
- **Median:** 3.5%
- **Range:** 0% - 100%
- **Total Days with Rate:** 368 days

**Issue:** Predicted rates (25.8%) are still **much higher** than historical (8.8%), explaining the over-prediction.

---

## Performance Metrics

| Metric | Dynamic Causal Model | ARIMA_PLUS | Winner |
|--------|---------------------|------------|--------|
| **Total Forecast** | 806.71 MQLs | 0 MQLs ⚠️ | Dynamic Causal (by default) |
| **Absolute Error** | +259.71 MQLs | -547 MQLs | Dynamic Causal ✅ |
| **Percent Error** | +47.5% | -100% | Dynamic Causal ✅ |
| **MAE** | 4.56 | 5.95 | **Dynamic Causal ✅** |
| **RMSE** | 6.34 | 8.50 | **Dynamic Causal ✅** |

---

## Key Findings

### 1. FilterDate Fix Helped ✅
- **Error reduced** from 58.9% to 47.5% (-11.4 p.p.)
- **MAE improved** from 5.24 to 4.56 (-0.68)
- **RMSE improved** from 7.05 to 6.34 (-0.71)
- **Total forecast reduced** from 869.36 to 806.71 (-62.65 MQLs)

### 2. Rate Model Still Over-Predicts ⚠️
- **Predicted average:** 25.8% vs **Historical average:** 8.8%
- **Predicted median:** 22.3% vs **Historical median:** 3.5%
- **Gap:** Still ~17 p.p. higher than historical average

### 3. Why Rates Are Still High?
Possible reasons:
1. **Daily variance:** Some days have very few contacted leads → high rate variance
2. **Model learning from outliers:** Model may be picking up days with high rates
3. **Rate bounds needed:** No constraint to prevent unrealistic rates (>20%)
4. **Regularization needed:** May need more L1/L2 regularization

---

## Next Steps to Further Improve

### 1. Constrain Rate Predictions
```sql
-- Add rate bounds (e.g., 0-0.15 or 0-0.20)
CASE
  WHEN predicted_rate > 0.20 THEN 0.20  -- Cap at 20%
  WHEN predicted_rate < 0 THEN 0  -- Floor at 0%
  ELSE predicted_rate
END AS predicted_c2m_rate_bounded
```

### 2. Filter Low-Volume Days from Training
```sql
-- Only train on days with sufficient contacted volume (e.g., > 5 leads)
WHERE daily_c2m_rate IS NOT NULL
  AND contacted_leads_count >= 5  -- Filter low-volume days
```

### 3. Use Logit Transformation
```sql
-- Transform rate to logit scale for training (bounds 0-1)
LOG(daily_c2m_rate / (1 - daily_c2m_rate)) AS logit_c2m_rate
-- Then inverse-transform predictions back
```

### 4. Increase Regularization
```sql
-- Increase L1/L2 regularization to prevent overfitting
l1_reg=0.2,  -- Increase from 0.1
l2_reg=2.0,  -- Increase from 1.0
```

### 5. Use Weighted Training
```sql
-- Weight training by sample size (days with more leads get higher weight)
-- Days with few leads have unreliable rates
```

---

## Comparison to Production Rate

According to `vw_live_conversion_rates`:
- **Production C2M Rate:** ~4.35% (90-day rolling average)

**Our Historical Training Data:**
- **Average:** 8.8%
- **Median:** 3.5%

**Our Predicted Rates:**
- **Average:** 25.8%
- **Median:** 22.3%

**Gap to Production:**
- Production: 4.35%
- Historical Median: 3.5% ✅ (close!)
- Predicted: 25.8% ❌ (way too high!)

**Conclusion:** The historical median (3.5%) is close to production (4.35%), but the predicted rates are way too high. The model needs constraints or better regularization.

---

## Recommendations

### Immediate Actions:
1. ✅ **Apply rate bounds:** Cap predicted rates at 15-20%
2. ✅ **Filter low-volume days:** Only train on days with >5 contacted leads
3. ✅ **Re-train and re-test:** See if this improves predictions

### Model Improvements:
1. **Increase regularization** (L1=0.2, L2=2.0)
2. **Use logit transformation** for rate predictions
3. **Weight training by sample size** (days with more leads = higher weight)

### Alternative Approach:
- **Consider using static hybrid rate** (like SQL→SQO model) instead of predicting rate dynamically
- The daily rate may be too volatile to predict accurately

---

**Status:** ✅ FilterDate Fix Applied - Error Reduced by 11.4 p.p., but rates still need constraints

**Next:** Apply rate bounds and filter low-volume days, then re-test




















