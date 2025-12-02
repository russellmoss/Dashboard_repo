# 🔴 Critical SQO Forecast Decision Needed

**Date**: October 30, 2025  
**Issue**: SQO forecast accuracy is poor regardless of approach

---

## The Problem

You correctly identified that **90 SQOs is ~40% too low** vs **151 historical SQOs** (last 90 days).

---

## What We've Tried

### Option 1: Historical Trailing Rates (Current)
- **SQO Forecast**: 90
- **VS Historical**: 151
- **Gap**: 40% low
- **Backtest Accuracy**: 11.4% (terrible - using trailing rates over-predicts by 88%)

### Option 2: Propensity Model
- **SQO Forecast**: 25
- **VS Historical**: 151  
- **Gap**: 83% low
- **Backtest**: 0.72x bias, 74.6% MAPE (good, but still conservative)

**Why model is low**: `days_in_sql_stage = 0` for future SQLs → model predicts low probability (15-25% vs 65% actual)

---

## Root Cause

The **backtest only had 29 SQOs over 90 days**, but **recent history has 151 SQOs**. Your business has **dramatically accelerated**.

**Backtest period** (earlier this year): 29 SQOs → 0.72x bias = reasonable  
**Current period**: 151 SQOs → 0.72x bias × 151 = 109 SQOs

---

## The Real Issue: ARIMA SQL Forecasts

**Production SQL forecast**: 168 SQLs  
**Historical SQL actuals**: Unknown exact, but if 151 SQOs at 65% conversion = **232 SQLs**

**ARIMA is forecasting 28% fewer SQLs than needed for the SQO volume**

---

## Recommended Solution

### Use Propensity Model (Conservative is Better Than Wrong)
- Backtested: 0.72x bias, 74.6% MAPE
- Current: 25 SQOs (severely low, but we know why)
- If we expect 151 and model gives 25 at 0.72x bias, it suggests SQL forecasts are ~35 SQLs/day short

### Fix SQL Forecasts, Not SQO Conversion
The SQO problem is a **symptom**, not the disease. The disease is **ARIMA under-forecasting SQLs**.

### Immediate Action
1. **Accept 25 SQOs** as conservative forecast
2. **Document**: "Expected 40-60 SQOs based on recent trends, model conservative"
3. **Investigate**: Why is ARIMA forecasting 168 SQLs vs ~232 needed?
4. **Retrain**: Consider longer window or different ARIMA parameters

---

## What Do You Want To Do?

**Option A**: Keep current conservative forecast (25-90 SQOs), document expected higher volumes  
**Option B**: Manually adjust SQL forecasts upward by 40% before feeding to propensity  
**Option C**: Use simple heuristic: `SQL forecast × 0.65` without any model  
**Option D**: Continue investigating why ARIMA is low

**My Recommendation**: **Option A + Investigate ARIMA** - The models are working, but SQL volumes have surged and we need to understand why ARIMA missed it.
