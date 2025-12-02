# File Cleanup Plan

**Date**: October 30, 2025  
**Purpose**: Remove obsolete and duplicate files, keep only production-ready documentation

---

## ✅ KEEP - Production Files

### Core Documentation
- ✅ `ARIMA_PLUS_Implementation.md` - **MASTER GUIDE** (source of truth)
- ✅ `SYSTEM_COMPLETE.md` - High-level system status
- ✅ `RETRAIN_PROCEDURE_SCHEDULE.md` - Retraining execution instructions
- ✅ `RETRAIN_SCRIPT_DOCUMENTATION_COMPLETE.md` - Retrain script documentation

### Production SQL Scripts
- ✅ `RETRAIN_SCRIPT.sql` - **Complete retraining script** (385 lines)
- ✅ `HYBRID_FORECAST_FIXED.sql` - Production hybrid forecast
- ✅ `BACKTEST_REACTIVE_180DAY.sql` - Reactive backtest validation
- ✅ `regenerate_forecast_simple.sql` - Simplified forecast regeneration

### Supporting Documentation (Still Relevant)
- ✅ `MONITORING_VIEWS_CREATED.md` - Monitoring views summary
- ✅ `PRODUCTION_VIEW_CREATED.md` - Production view documentation
- ✅ `LOOKER_STUDIO_USAGE_GUIDE.md` - Looker Studio integration
- ✅ `MODEL_ACCURACY_ASSESSMENT.md` - Accuracy analysis
- ✅ `Q4_SQO_FORECAST_AND_CONFIDENCE_UPDATED.md` - Q4 forecast with CI
- ✅ `FINAL_DIAGNOSIS.md` - ARIMA failure analysis
- ✅ `DATA_DIAGNOSIS_COMPLETE.md` - Data mismatch investigation
- ✅ `REACTIVE_BACKTEST_ANALYSIS.md` - Remediation analysis
- ✅ `MODEL_CONFIDENCE_REPORT.md` - Confidence assessment
- ✅ `BACKTEST_COMPLETE_SUMMARY.md` - Backtest detailed analysis
- ✅ `README.md` - Project overview

### Directories
- ✅ `Views/` - Production views (13 files)
- ✅ `documentation/` - Supporting docs

---

## ⚠️ KEEP AS REFERENCE - Legacy/Historical

- ⚠️ `RETRAIN_PROCEDURE.sql` - Legacy stored procedure attempt (kept for reference)
- ⚠️ `backtest_validation.sql` - Backtest validation queries

---

## 🗑️ DELETE - Obsolete/Duplicate

### Backtest Development Files (Resolved Issues)
- ❌ `BACKTEST_FIXED.sql` - Replaced by BACKTEST_REACTIVE_180DAY.sql
- ❌ `BACKTEST_ERROR_FIXED.md` - Development notes
- ❌ `BACKTEST_FINAL_FIX.md` - Development notes
- ❌ `BACKTEST_FINAL_QUOTE_FIX.md` - Development notes
- ❌ `BACKTEST_NEXT_STEPS.md` - Development notes
- ❌ `BACKTEST_QUICK_CHECK.sql` - Development queries
- ❌ `BACKTEST_QUICK_REFERENCE.md` - Development notes
- ❌ `BACKTEST_RESUME_GUIDE.md` - Development guide
- ❌ `BACKTEST_SIMPLE_FIX.md` - Development notes
- ❌ `BACKTEST_TEMP_TABLE_FIX.md` - Development notes
- ❌ `BACKTEST_VALIDATION_GUIDE.md` - Replaced by ARIMA_PLUS_Implementation.md
- ❌ `REACTIVE_BACKTEST_FIX_APPLIED.md` - Development notes
- ❌ `REACTIVE_BACKTEST_FIXED_FINAL.md` - Development notes
- ❌ `REACTIVE_BACKTEST_SUCCESS.md` - Development notes
- ❌ `REACTIVE_MODEL_BACKTEST_GUIDE.md` - Replaced by master doc

### Trail Rates Fix Files (Resolved Issues)
- ❌ `trailing_rates_FINAL_FIX.sql` - Development SQL
- ❌ `trailing_rates_fixed_correct_dates.sql` - Development SQL
- ❌ `trailing_rates_fixed.sql` - Development SQL
- ❌ `trailing_rates_PROD_FIXED.sql` - Development SQL
- ❌ `rebuild_trailing_rates_correct.sql` - Development SQL
- ❌ `vw_heuristic_forecast_FIXED.sql` - Replaced by vw_heuristic_forecast view

### Forecast Development Files (Replaced by HYBRID_FORECAST_FIXED.sql)
- ❌ `complete_forecast_insert_hybrid.sql` - Development SQL
- ❌ `complete_forecast_insert.sql` - Development SQL

### Multiple Summary Files (Consolidated)
- ❌ `ARIMA_INVESTIGATION.md` - Historical investigation
- ❌ `ARIMA_PLAN_UPDATE_SUMMARY.md` - Replaced by master doc
- ❌ `CONFIDENCE_SUMMARY.md` - Replaced by MODEL_CONFIDENCE_REPORT.md
- ❌ `Conversion_Rate_Calculation_Logic.md` - Integrated into master doc
- ❌ `CONVERSION_RATE_FIX.md` - Development notes
- ❌ `DATA_ATTRIBUTION_BUG_FOUND.md` - Development notes
- ❌ `DATA_ATTRIBUTION_FIX_COMPLETE.md` - Development notes
- ❌ `FINAL_CONFIRMATION.md` - Development notes
- ❌ `FINAL_FORECAST_SUMMARY.md` - Replaced by SYSTEM_COMPLETE.md
- ❌ `FINAL_IMPLEMENTATION_SUMMARY.md` - Replaced by SYSTEM_COMPLETE.md
- ❌ `FINAL_RECOMMENDATION.md` - Historical decision
- ❌ `FINAL_SQO_DECISION.md` - Historical decision
- ❌ `FINAL_SUMMARY.md` - Replaced by SYSTEM_COMPLETE.md
- ❌ `FORECAST_FIXED_SUMMARY.md` - Development notes
- ❌ `FORECAST_PIPELINE_ISSUE.md` - Development notes
- ❌ `FORECAST_REGENERATED_FINAL.md` - Development notes
- ❌ `FORECAST_STATUS_SUMMARY.md` - Development notes
- ❌ `Forecasting_Implementation_Summary.md` - Replaced by master doc
- ❌ `HYBRID_FORECAST_COMPLETE.md` - Replaced by SYSTEM_COMPLETE.md
- ❌ `IMPLEMENTATION_COMPLETE_SUMMARY.md` - Replaced by SYSTEM_COMPLETE.md
- ❌ `MCP_Setup_Guide.md` - Project setup guide (historical)
- ❌ `MOdel remediation plan v2.md` - Integrated into master doc
- ❌ `PRODUCTION_FORECAST_LAUNCHED.md` - Development notes
- ❌ `PROPENSITY_MODEL_FIX_SUMMARY.md` - Integrated into master doc
- ❌ `Q4_SQO_FORECAST_AND_CONFIDENCE.md` - Replaced by UPDATED version
- ❌ `QUICK_START.md` - Project setup (historical)
- ❌ `REACTIVE_MODEL_STATUS.md` - Replaced by master doc
- ❌ `SGA_SGM_FILTER_ANALYSIS.md` - Integrated into master doc
- ❌ `SQO_FORECAST_DIAGNOSIS.md` - Development notes
- ❌ `STEP_5_1_COMPLETE_SUMMARY.md` - Development notes
- ❌ `STEP_BY_STEP_EXECUTION_GUIDE.md` - Replaced by master doc
- ❌ `TRAINING_TABLE_FIX_CONFIRMED.md` - Development notes
- ❌ `ULTRA_REACTIVE_FORECAST_RESULTS.md` - Development notes
- ❌ `WHAT_TO_DO_NEXT.md` - Replaced by master doc

### Old Project Plans
- ❌ `BQML_Forecasting_Plan.md` - Original plan (superseded)
- ❌ `README.md` (if exists) - Check if it's just a placeholder

---

## 📊 Summary

**Keep**: ~22 files (production code + essential docs)  
**Delete**: ~55 files (development history + duplicates)

---

## ✅ Recommended Action

**Phase 1**: Archive Development History
- Move all ❌ files to `archive/` directory for backup
- Keep structure for future reference

**Phase 2**: Final Cleanup
- After confirming everything works, delete `archive/` directory
- Or keep it but exclude from repo

---

## 🎯 Final Directory Structure Goal

```
Big_Query/
├── ARIMA_PLUS_Implementation.md (MASTER DOC)
├── SYSTEM_COMPLETE.md
├── RETRAIN_PROCEDURE_SCHEDULE.md
├── RETRAIN_SCRIPT.sql
├── HYBRID_FORECAST_FIXED.sql
├── BACKTEST_REACTIVE_180DAY.sql
├── regenerate_forecast_simple.sql
├── Views/ (production views)
├── documentation/ (supporting docs)
├── archive/ (old files for reference)
└── Supporting documentation (MODEL_ACCURACY, etc.)
```

---

**Ready to execute cleanup?** Review the plan above and confirm which files to delete/archive.

