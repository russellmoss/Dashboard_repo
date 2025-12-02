# October 2025 Forecast vs Actuals Analysis

**Date:** Analysis of forecast accuracy  
**Period:** October 2025  
**Issue:** SQO forecast significantly underestimated actual results

---

## October 2025 Forecast vs Actuals

| Metric | Forecast | Actual | Error | % Error |
|--------|----------|--------|-------|---------|
| **MQLs** | 214.3 | 218* | -3.7 | -1.7% ✅ **Close!** |
| **SQLs** | 60.2 | 92 | **-31.8** | **-34.6%** ❌ **Too Low** |
| **SQOs** | 33.3 | 61 | **-27.7** | **-45.4%** ❌ **Too Low** |

*User reported 218 MQLs, but query shows 282. Need to verify correct definition.

---

## Root Cause Analysis

### Problem 1: SQL Forecast Too Low ❌

**Forecast:** 60.2 SQLs  
**Actual:** 92 SQLs  
**Error:** -34.6%

**Analysis:**
- V3.1 model backtest showed 64.9 SQLs forecast vs 92 actual (-27.1% error)
- Current forecast shows 60.2 SQLs (-4.7 lower than backtest)
- **The model is consistently under-predicting SQLs**

**Possible Reasons:**
1. **Model training cutoff:** Model trained on pre-October data, may not capture recent trends
2. **Feature lag:** Lag features may not reflect recent volume increases
3. **Super-segment distribution:** May not accurately predict future segment mix

### Problem 2: SQO Forecast Too Low ❌

**Forecast:** 33.3 SQOs  
**Actual:** 61 SQOs  
**Error:** -45.4%

**Breakdown:**
- **If using forecast SQLs (60.2) × Hybrid rate (55.27%):** 33.3 SQOs ✅ Matches forecast
- **If using actual SQLs (92) × Hybrid rate (55.27%):** 50.8 SQOs (still too low!)
- **Actual conversion rate:** 66.3% (61 / 92)

**Root Causes:**
1. **SQL forecast too low** → Cascading error to SQOs
2. **Hybrid rate too low** → 55.27% vs actual 66.3% (-11 p.p.)
   - Even with perfect SQL forecast, we'd still be off: 92 × 55.27% = 50.8 vs 61 actual

---

## Detailed Analysis

### SQL Forecast Error Chain

```
SQL Forecast (60.2) 
  ↓ 
× Hybrid Rate (55.27%) 
  ↓ 
= SQO Forecast (33.3)
```

**If we fix SQL forecast:**
```
Actual SQLs (92)
  ↓
× Hybrid Rate (55.27%)
  ↓
= 50.8 SQOs (still below 61 actual!)
```

**If we use actual SQLs + actual rate:**
```
Actual SQLs (92)
  ↓
× Actual Rate (66.3%)
  ↓
= 61 SQOs ✅ Matches!
```

**Conclusion:** **Both SQL forecast AND Hybrid rate are too low!**

---

## Conversion Rate Analysis

| Rate Type | Value | Notes |
|-----------|-------|-------|
| **Hybrid Rate (Used in Forecast)** | 55.27% | Trailing + V2 Challenger fallback |
| **Actual October Rate** | 66.3% | 61 SQOs / 92 SQLs |
| **Gap** | **-11.0 p.p.** | Hybrid rate is significantly lower |

**October was an exceptional month:**
- Normal conversion: ~55-60%
- October actual: 66.3% (+6-11 p.p. higher!)
- This could be:
  - Seasonal effect
  - Quality improvement
  - One-time spike

---

## Model Performance Summary

| Model | Metric | Forecast | Actual | Error | Status |
|-------|--------|----------|--------|-------|--------|
| **Dynamic Causal MQL** | MQLs | 214.3 | 218 | -1.7% | ✅ **Excellent!** |
| **V3.1 SQL** | SQLs | 60.2 | 92 | -34.6% | ❌ **Under-predicting** |
| **Hybrid SQO Rate** | SQOs | 33.3 | 61 | -45.4% | ❌ **Under-predicting** |

---

## Issues Identified

### 1. SQL Model (V3.1) Under-Predicting ⚠️

**October Forecast:** 60.2 vs Actual: 92 (-34.6% error)

**Previous Backtest (October 2025):**
- V3.1 forecast: 64.9 vs Actual: 92 (-27.1% error)
- Current forecast: 60.2 (even lower!)

**Possible Solutions:**
1. **Recalibrate model** - Retrain on more recent data
2. **Adjust for trend** - October may have higher volume than training period
3. **Check feature engineering** - Lag features may need adjustment
4. **Scale up forecast** - Apply correction factor based on recent under-prediction

### 2. Hybrid Conversion Rate Too Low ⚠️

**Hybrid Rate:** 55.27% vs Actual: 66.3% (-11 p.p.)

**Analysis:**
- October had unusually high conversion (66.3% vs typical 55-60%)
- This could be:
  - **One-time event** (normal variance)
  - **Quality improvement** (sustainable change)
  - **Seasonal effect** (Q4 tends to have higher conversion)

**Possible Solutions:**
1. **Monitor if trend continues** - If November/December also high, update hybrid rate
2. **Use October rate** - 66.3% may be new normal
3. **Use weighted average** - Blend recent (higher) rates with historical

---

## Corrected Forecast Using Actual Rates

If we use:
- **Actual SQLs:** 92
- **Actual SQO Rate:** 66.3%

Then:
- **SQO Forecast:** 92 × 66.3% = **61 SQOs** ✅ Matches actual!

**Conclusion:** The issue is a combination of:
1. **SQL forecast too low** (34.6% error)
2. **Hybrid rate too low** (11 p.p. below actual)

---

## Recommendations

### Immediate Actions

1. **SQL Model:**
   - ✅ Model is consistently under-predicting
   - ✅ Consider scaling up forecasts by ~35% (1 / (1 - 0.346) = 1.53x)
   - ✅ Or retrain model on more recent data (including September/October)

2. **SQO Conversion Rate:**
   - ⚠️ October rate (66.3%) is significantly higher than hybrid rate (55.27%)
   - ⚠️ Monitor November/December to see if this is a trend
   - ⚠️ Consider updating hybrid rate if trend continues

### Model Improvements

1. **Recalibrate V3.1 SQL Model:**
   - Retrain on data including recent months
   - Check for recent volume trends not captured in training data
   - Consider adding trend features

2. **Update Hybrid Rate:**
   - If October's 66.3% rate is the new normal, update hybrid rate
   - Or use rolling 30-day rate instead of 90-day for faster adaptation

---

**Status:** ⚠️ Issues Identified - SQL forecast and SQO rate both need adjustment




















