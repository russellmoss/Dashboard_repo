# 🔍 SQO Forecast Under-Prediction Diagnosis

**Date**: October 30, 2025  
**Issue**: Models forecast only 25 SQOs for 90 days, but actual is ~150 SQOs (last 90 days)

---

## 📊 The Problem

### Current Forecast
- **90-Day SQO Forecast**: 25 SQOs
- **Expected (based on history)**: ~150 SQOs
- **Under-prediction**: 83% too low (25 vs 150)

### Historical Context
- **Last 90 days**: 150 SQOs
- **Last 180 days**: 246 SQOs
- **Recent weekly average**: 10-13 SQOs per week

---

## 🔍 Root Cause Analysis

### Issue 1: Overly Conservative Caps
**Problem**: SQO caps are too low

| Segment | Current Cap | Max Daily | 90-Day Cap Impact |
|---------|-------------|-----------|-------------------|
| Outbound > LinkedIn | 2 | 3 | 180 max |
| Outbound > Provided List | 2 | 3 | 180 max |
| All others | 1 | 2 | 90 max |

**Finding**: Top segments max out at 3 SQOs/day, but we're only forecasting ~0.3/day

### Issue 2: Low Conversion Probabilities
**Problem**: Propensity model predicting ~15-30% conversion, but actual is 60%

- **Model predicts**: 15-30% probability
- **Actual rate**: 60-68% conversion
- **Backtest showed**: 72% bias (conservative)

**Cause**: Using `days_in_sql_stage = 0` for future SQLs may be lowering probability

### Issue 3: Caps Applied to End Result
**Problem**: The forecast logic caps the final SQO count

```sql
LEAST(
  COALESCE(p_in.sqls_forecast, 0) * COALESCE(s_prop.conversion_prob, 0.6),
  p_in.sqo_cap_applied
) AS sqos_forecast
```

**Impact**: Even if SQL forecast × conversion prob = 5 SQOs, it's capped at 2

---

## 🎯 Why This Happened

The **180-day reactive training** fixed the over-forecasting bias (2-65x down to 1.36x), but:
1. **Caps were never updated** - Still using old conservative caps
2. **Propensity probabilities are low** - Likely due to `days_in_sql_stage = 0` in forecasts
3. **Final result is double-capped** - Model already conservative, then capped again

---

## ✅ Solutions

### Option 1: Remove SQO Caps Entirely (Recommended)
Since the model is already conservative (0.72x bias), we shouldn't cap SQOs.

**Change**: Remove `sqo_cap_applied` constraint from forecast calculation

```sql
-- Instead of:
LEAST(
  COALESCE(sqls_forecast, 0) * COALESCE(conversion_prob, 0.6),
  sqo_cap_applied
) AS sqos_forecast

-- Use:
COALESCE(sqls_forecast, 0) * COALESCE(conversion_prob, 0.6) AS sqos_forecast
```

### Option 2: Increase SQO Caps
Raise caps to reflect recent volumes

**Current**: 1-2 SQOs/day  
**Proposed**: 5-8 SQOs/day for high-volume segments

### Option 3: Fix Propensity Model
Retrain with better handling of `days_in_sql_stage = 0` for future predictions

**Current**: 0 days → low probability  
**Needed**: 0 days → should use average historical rate

---

## 💡 Recommended Immediate Fix

**Remove SQO capping entirely** since:
1. Model is already conservative (0.72x backtest bias)
2. Caps were set for sparsity, but volumes have increased
3. Compound effect is creating massive under-forecast

---

## 📋 Next Steps

1. **Immediate**: Regenerate forecasts without SQO caps
2. **Short-term**: Re-evaluate cap strategy based on recent volumes
3. **Long-term**: Consider fixing propensity model for future predictions
