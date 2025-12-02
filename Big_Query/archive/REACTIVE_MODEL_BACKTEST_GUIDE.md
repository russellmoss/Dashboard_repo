# Reactive Model Backtest Execution Guide

**Status**: ✅ Models retrained with 180-day windows (Prompts 1-2 complete)  
**Next**: Run reactive backtest script (Prompt 3)

---

## What's Been Done

### ✅ Prompt 1: ARIMA Models Retrained
- `model_arima_mqls` - Now using 180-day training window
- `model_arima_sqls` - Now using 180-day training window
- Training window: Last 194 days, holding out last 14 days

### ✅ Prompt 2: Propensity Model Retrained  
- `model_sql_sqo_propensity` - Now using 180-day training window
- Training data: Last 180 days only

**Impact**: Models will be more reactive to recent performance, should reduce over-forecasting

---

## ⏭️ Prompt 3: Run Reactive Backtest

**File**: `BACKTEST_REACTIVE_180DAY.sql`

**Instructions**:
1. Open BigQuery Console
2. Copy **ALL** of `BACKTEST_REACTIVE_180DAY.sql`
3. Paste and run
4. **Wait** 15-30 minutes for completion

**Expected changes** from previous backtest:
- Models trained at each step using **only 180 days** of history
- Should see **lower bias** (forecast/actual closer to 1.0)
- MAPE may still be high but **less over-forecasting**

---

## What to Look For

The new backtest will overwrite `backtest_results` table with results from reactive models.

**Comparison**:
- **Old backtest**: Used full history, over-forecasted 2-65x
- **New backtest**: Uses 180-day window, should forecast closer to actuals

---

## After Backtest Completes

Run validation queries from `MOdel remediation plan v2.md` Prompt 4 to:
1. Check overall bias (should be closer to 1.0)
2. Compare to old results
3. Identify trusted segments

---

**Ready to run**: Copy `BACKTEST_REACTIVE_180DAY.sql` into BigQuery Console and execute.

**Estimated time**: 15-30 minutes

