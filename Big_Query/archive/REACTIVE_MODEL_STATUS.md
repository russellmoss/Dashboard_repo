# Reactive Model Remediation Status

**Date**: October 29, 2025  
**Objective**: Fix over-forecasting by shortening training windows to 180 days

---

## ✅ Completed

### Prompt 1: ARIMA Models Retrained ✅
**Status**: Successfully retrained both models

**Changes**:
- Training window: 2024-01-01 → **Last 194 days** (holding out last 14)
- Models: `model_arima_mqls`, `model_arima_sqls`
- Impact: Models now focus on recent 6 months, forget older irrelevant data

**SQL executed**:
- MQL ARIMA: `WHERE date_day BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 194 DAY) AND DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)`
- SQL ARIMA: Same window

---

### Prompt 2: Propensity Model Retrained ✅
**Status**: Successfully retrained propensity model

**Changes**:
- Training data: Full history → **Last 180 days only**
- Model: `model_sql_sqo_propensity`
- Impact: Conversion probabilities based on recent team performance

**SQL executed**:
- `WHERE label IS NOT NULL AND sql_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)`

---

## ⏳ In Progress

### Prompt 3: Full Backtest
**Status**: **READY TO RUN** - Waiting for manual execution

**File**: `BACKTEST_REACTIVE_180DAY.sql`

**Action required**:
1. Copy script to BigQuery Console
2. Run complete script
3. Wait 15-30 minutes for completion

**Expected improvements**:
- Less over-forecasting bias
- Forecast/actual ratio closer to 1.0
- MAPE may still be high but bias should improve

---

## 📋 Pending

### Prompt 4: Validation
**Status**: Waiting for Prompt 3 completion

**Will check**:
1. Overall bias (WAPE and bias ratios)
2. Comparison to old backtest
3. Segment-level performance
4. Identify trusted segments

---

## 🎯 Success Criteria

**Bias improvements** (Target vs Previous):
- **Old**: MQL bias ~2-65x over-forecast
- **Target**: MQL bias closer to 1.0-1.5x
- **Old**: SQO bias ~high over-forecast
- **Target**: SQO bias closer to 1.0-2.0x

**Note**: MAPE will likely remain high due to sparsity, but **bias reduction** is the key success metric.

---

## 📊 Models Ready

**Production models** (trained with 180-day windows):
1. ✅ `model_arima_mqls`
2. ✅ `model_arima_sqls`
3. ✅ `model_sql_sqo_propensity`

**Waiting for**: Validation via reactive backtest

---

**Next step**: Run `BACKTEST_REACTIVE_180DAY.sql` in BigQuery Console

