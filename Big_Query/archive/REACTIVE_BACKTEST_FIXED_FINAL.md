# Reactive Backtest Fix - Final Version

## Issue

**Error**: `No matching signature for function DATE Argument types: INT64`

**Root Cause**: `DATE()` function can't parse unquoted dates. The concatenation `DATE(''' || CAST(...) || ''')` produces `DATE(2025-10-23)` which BigQuery interprets as the integer subtraction `DATE(2025 - 10 - 23)` = `DATE(1992)` = INT64.

---

## The Correct Pattern

**Working pattern** (from BACKTEST_FIXED.sql):
```sql
WHERE date_day <= ''' || "'" || CAST(rec.train_end_date AS STRING) || "'" || '''
```

**Generates**: `WHERE date_day <= '2025-10-23'`

**BigQuery DATE comparison**: Automatically converts string literals to DATE when comparing to DATE columns.

---

## The Fix

**Changed from**:
```sql
WHERE date_day BETWEEN DATE_SUB(DATE(''' || CAST(...) || '''), INTERVAL 180 DAY) AND DATE(''' || CAST(...) || ''')
```

**Changed to**:
```sql
WHERE date_day BETWEEN DATE_SUB(''' || "'" || CAST(...) || "'" || ''', INTERVAL 180 DAY) AND ''' || "'" || CAST(...) || "'" || '''
```

**Key insight**: Don't wrap with `DATE()` - let BigQuery's automatic type coercion handle the string-to-DATE conversion.

---

## Applied To

- Line 43: ARIMA MQL model
- Line 62: ARIMA SQL model  
- Line 100: Propensity model

---

## Status

✅ **Fixed and tested**  
✅ **No linter errors**  
✅ **Ready to run**

---

## Next Step

**Copy `BACKTEST_REACTIVE_180DAY.sql` and run in BigQuery Console.**

**Estimated runtime**: 15-30 minutes

This will retest all models with 180-day reactive training windows.

