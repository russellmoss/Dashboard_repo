# Deprecated Objects and View Updates for savvy_forecast

**Generated:** Using BigQuery MCP analysis  
**Dataset:** `savvy-gtm-analytics.savvy_forecast`

---

## Objects to DELETE (Deprecated/Failed)

### Deprecated V3 Models (4 models)

| Object Name | Type | Reason | Safe to Delete? |
|-------------|------|--------|-----------------|
| `model_tof_sql_forecast_v3` | MODEL | Failed - Segment sparsity (99.75%) | ✅ YES |
| `model_tof_sql_classifier_v3` | MODEL | Failed - Probability calibration | ✅ YES |
| `model_tof_sql_classifier_v3_calibrated` | MODEL | Failed - Calibration issues | ✅ YES |
| `model_tof_sql_backtest_classifier_calibrated` | MODEL | Failed - Calibration issues | ✅ YES |

### Deprecated V3 Tables (4 tables)

| Object Name | Type | Reason | Safe to Delete? |
|-------------|------|--------|-----------------|
| `tof_v3_daily_training_data` | TABLE | Replaced by `tof_v3_daily_training_data_FINAL` | ✅ YES |
| `tof_v3_backtest_results` | TABLE | Old backtest results (deprecated) | ✅ YES |
| `tof_v3_backtest_results_corrected` | TABLE | Old backtest results (deprecated) | ✅ YES |
| `tof_v3_prediction_analysis` | TABLE | Old prediction analysis | ✅ YES |
| `tof_v3_prediction_analysis_calibrated` | TABLE | Old prediction analysis | ✅ YES |

### Deprecated V1 Models (1 model)

| Object Name | Type | Reason | Safe to Delete? |
|-------------|------|--------|-----------------|
| `model_sql_sqo_propensity` | MODEL | Replaced by `model_sql_sqo_propensity_v2` | ✅ YES |

### Deprecated V1 Tables (1 table)

| Object Name | Type | Reason | Safe to Delete? |
|-------------|------|--------|-----------------|
| `sql_sqo_propensity_training` | TABLE | Replaced by `sql_sqo_propensity_training_v2` | ✅ YES |

---

## Summary: Objects to Delete

**Total Objects to Delete: 10**
- **Models:** 5 (4 V3 failed models + 1 V1 deprecated model)
- **Tables:** 5 (4 V3 deprecated tables + 1 V1 deprecated table)

---

## Views to Update

The following views need to be updated to reference the latest models:

1. **`vw_production_forecast`** - Currently uses `daily_forecasts` table (populated by ARIMA models)
2. **`vw_model_performance`** - Depends on `vw_production_forecast`
3. **`vw_model_drift_alert`** - Depends on `vw_production_forecast` and `backtest_results`

---

## Current View Dependencies

### vw_production_forecast
- **Reads from:** `daily_forecasts` table
- **Current Logic:** Uses ARIMA models via `daily_forecasts` table
- **SQO Conversion:** Uses `trailing_rates_features` (V1 approach)
- **Needs Update:** Should use V2 model (69.3% rate) for SQO conversion

### vw_model_performance
- **Reads from:** `vw_production_forecast`
- **Current Logic:** Calculates MAE for MQLs, SQLs, SQOs
- **Needs Update:** Should reference updated `vw_production_forecast`

### vw_model_drift_alert
- **Reads from:** `backtest_results` and `vw_production_forecast`
- **Current Logic:** Compares recent performance vs baseline
- **Needs Update:** Should reference updated baseline from V2/V3 models

---

## Recommendations

### For View Updates:

1. **vw_production_forecast:** Keep using `daily_forecasts` table but note it should be regenerated with:
   - V3 daily model for SQL forecasting (OR keep ARIMA for now)
   - V2 model (69.3% rate) for SQO conversion (instead of trailing_rates)

2. **vw_model_performance:** Update to reference the correct models in comments/documentation

3. **vw_model_drift_alert:** Update baseline to use V2/V3 backtest results

---

## Cleanup SQL Script

See `cleanup_deprecated_v3_objects.sql` for complete deletion script.

---

## Updated View Definitions

Updated view SQL files have been created in the `Views/` directory:

1. **`vw_production_forecast_updated.sql`** - Updated to use V2 conversion rate (69.3%)
2. **`vw_model_performance_updated.sql`** - Updated to work with new vw_production_forecast
3. **`vw_model_drift_alert_updated.sql`** - Updated baseline to use V2 backtest results

### Key Changes:

**vw_production_forecast:**
- ✅ Now uses V2 validated conversion rate (69.3%) instead of `trailing_rates_features`
- ✅ SQO forecasts recalculated as: `sqls_forecast × 0.693`
- ✅ Maintains same structure for backward compatibility

**vw_model_performance:**
- ✅ Updated to use new column names from updated `vw_production_forecast`
- ✅ Tracks performance of V2 conversion model

**vw_model_drift_alert:**
- ✅ Baseline updated to use V2 model backtest results (0.23 MAE per SQL)
- ✅ Added SQL and SQO drift detection

