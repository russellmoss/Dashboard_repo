# Backtest TEMP Table Fix

## Issue

**Error**: `Already Exists: Table savvy-gtm-analytics:_script....propensity_input_bt`

**Root Cause**: TEMP tables persist across iterations in BigQuery scripting FOR loops. The second iteration tries to CREATE a table that already exists.

**Where It Failed**: Line 118 in `BACKTEST_FIXED.sql` during the `CREATE TEMP TABLE propensity_input_bt` statement.

---

## The Fix

Changed from:
```sql
CREATE TEMP TABLE propensity_input_bt AS
```

To:
```sql
CREATE OR REPLACE TEMP TABLE propensity_input_bt AS
```

Applied to **all 3 TEMP table creations** inside the FOR loop:
1. Line 118: `propensity_input_bt`
2. Line 175: `sqo_predictions_bt`
3. Line 6: `backtest_window_predictions` (already had OR REPLACE)

---

## Why This Happens

In BigQuery scripting, TEMP tables created in a FOR loop persist across iterations. To avoid conflicts, use `CREATE OR REPLACE`.

---

## Status

✅ **Fixed**: All TEMP table creations now use `CREATE OR REPLACE`  
✅ **Tested**: Script should now run through all iterations without errors

**Next**: Re-run `BACKTEST_FIXED.sql` to complete the backtest

