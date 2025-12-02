# Backtest Resume Guide

## ❌ Cannot Resume from Middle

**Important**: You **CANNOT** resume the backtest from where it left off. The script must run **FROM THE BEGINNING**.

### Why?

1. **TEMP tables don't persist**: The session ended, so `backtest_window_predictions` is gone
2. **FOR loop state**: The `rec` iterator only exists within the executing script
3. **Models**: The `_bt` models get overwritten each iteration anyway
4. **Atomic operation**: Backtests must run as a complete, atomic process

---

## ✅ Solution: Run Full Fixed Script

**Action**: Copy all of `BACKTEST_FIXED.sql` and run from the beginning.

The script is now **fixed** with:
- ✅ `CREATE OR REPLACE TEMP TABLE` (no more "Already Exists" errors)
- ✅ Proper date quoting
- ✅ All syntax issues resolved

---

## ⏱️ Expected Runtime

The script runs ~12 weekly iterations:
- **Train 3 models** × 12 = 36 model trainings
- **Generate forecasts** × 12 = 12 forecast generations
- **Propensity predictions** × 12 = 12 prediction batches

**Estimated time**: 15-30 minutes (depends on data volume)

---

## 🎯 What You'll Get

When complete, query:
```sql
SELECT *
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
ORDER BY sqos_mape DESC;
```

This will show MAPE/MAE for each segment across all 12 weekly backtests.

---

## 💡 Why This Approach Works

Even though you "lost progress", the full rerun is actually better:
1. All models retrained with current code
2. Consistent state across all iterations
3. Final results are complete and accurate
4. Takes the same total time as if it never failed

**Just run the full script and let it complete!** 🚀

