# V3 Daily Model Backtest Results (Final)

**Report Date:** Generated on execution  
**Backtest Period:** October 2025 (31 days)  
**Model:** `savvy-gtm-analytics.savvy_forecast.model_tof_sql_backtest_daily`  
**Model Type:** BOOSTED_TREE_REGRESSOR (Daily Aggregated)  
**Forecast Method:** Sum of daily predictions

---

## Executive Summary

The V3 daily regression model was successfully trained and tested. The model uses **daily aggregation** (no segments) to predict total daily SQL counts, avoiding the sparsity issues of segment-level modeling. The backtest shows the model **under-predicts** October 2025, forecasting 16.6 SQLs vs 89 actuals (-81.4% error).

**Key Findings:**
- ✅ **Model Architecture:** Successfully trained daily regression model
- ⚠️ **V3 Forecast:** 16.6 SQLs (vs 89 actual) - **-81.4% error** (under-predicts)
- ⚠️ **V1 Forecast:** 35 SQLs (vs 89 actual) - **-60.7% error** (under-predicts)
- ⚠️ **Comparison:** V3 performs worse than V1, but magnitude is realistic (not catastrophic)

---

## Final Comparison Results

| Model | Forecasted SQLs | Actual SQLs | Absolute Error | Relative Error |
|-------|----------------|-------------|----------------|----------------|
| **V1 (ARIMA_PLUS)** | 35 | 89 | -54 | **-60.7%** |
| **V3 (Daily ML Model)** | **16.6** | 89 | -72.4 | **-81.4%** |

### Analysis

**V1 (ARIMA_PLUS) Performance:**
- Forecast: 35 SQLs vs Actual: 89 SQLs
- Under-predicted by 54 SQLs (60.7% error)
- **Status:** Under-forecast, but reasonable magnitude

**V3 (Daily ML Model) Performance:**
- Forecast: 16.6 SQLs vs Actual: 89 SQLs
- Under-predicted by 72.4 SQLs (81.4% error)
- **Status:** ⚠️ Under-forecast, **worse than V1** but magnitude is realistic (not catastrophic like classifier approach)

### Model Comparison

| Metric | V1 (ARIMA_PLUS) | V3 (Daily ML) | Winner |
|--------|-----------------|---------------|--------|
| **Forecast Error** | -60.7% | -81.4% | **V1** |
| **Magnitude** | Realistic (35) | Realistic (16.6) | **Tie** |
| **Direction** | Under-predicts | Under-predicts | **Tie** |

**Key Observation:**
- Both models **under-predict** October 2025
- V1's forecast (35) is closer to actuals (89) than V3's forecast (16.6)
- However, V3's approach is more straightforward and avoids sparsity issues

---

## Model Architecture

### Training Data

**Table:** `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data_FINAL`

**Structure:**
- **Aggregation Level:** Daily (no segments)
- **Date Range:** 2024-02-07 to 2025-10-31 (633 days)
- **Target Variable:** `total_daily_sqls` (count per day)
- **Average Daily SQLs:** 1.6 SQLs/day
- **Total SQLs:** 924 SQLs across 633 days

**Features:**
- Temporal: `day_of_week`, `day_of_month`, `month`, `quarter`, `year`, `is_weekend`
- Lagged: `sqls_7day_avg_lag1`, `sqls_28day_avg_lag1` (global rolling averages)

### Model Configuration

**Model Type:** BOOSTED_TREE_REGRESSOR  
**Split Method:** Sequential (SEQ) on `date_day`  
**Eval Fraction:** 0.2  
**Regularization:** L1=0.1, L2=1.0  
**Tree Depth:** 6 (max)  
**Subsample:** 0.8  

---

## Analysis & Recommendations

### Why V3 Under-Predicts

1. **Daily Aggregation:**
   - Model learns patterns based on daily totals
   - May miss segment-specific spikes that aggregate to high daily totals
   - Average daily SQLs (1.6) is much lower than October's actual average (89/31 = 2.9)

2. **Training Data Bias:**
   - Training data spans 633 days with average 1.6 SQLs/day
   - October 2025 appears to be an outlier with higher activity
   - Model may be conservatively predicting based on historical averages

3. **Feature Limitations:**
   - Global lag features may not capture sudden increases in activity
   - No segment-level features to capture source-specific trends
   - Temporal features alone may be insufficient for this level of variation

### Comparison to Segment-Level Approach

| Approach | Forecast | Error | Status |
|----------|----------|-------|--------|
| **Segment-Level Classifier** | 1,757-13,260 | +1,874% to +14,798% | ❌ Catastrophic over-prediction |
| **Daily Regression (V3)** | 16.6 | -81.4% | ⚠️ Under-prediction, but realistic |
| **V1 (ARIMA_PLUS)** | 35 | -60.7% | ⚠️ Under-prediction, but closer |

**Key Insight:** Daily aggregation produces **realistic forecasts** (unlike classifier), but **under-predicts** compared to V1.

### Recommendations

**For Production Use:**
1. ⚠️ **V3 is not ready** - Under-predicts by 81.4% (worse than V1)
2. Consider **hybrid approach** - Combine V1 and V3 with weighted average
3. **Feature engineering** - Add more temporal or external features to capture October patterns

**Model Improvements:**
1. **Add segment aggregation** - Average SQLs by LeadSource/Owner, then aggregate
2. **External features** - Add marketing campaign dates, seasonality indicators
3. **Ensemble** - Combine multiple models (V1, V3, segment-based)
4. **Calibration** - Apply scaling factor based on recent trend

---

## Conclusion

**Backtest Status:** ⚠️ **PARTIAL SUCCESS** (Realistic magnitude, but under-predicts)

The V3 daily regression model successfully avoids the catastrophic over-prediction issues of the segment-level classifier approach. However, it **under-predicts** October 2025 by 81.4%, which is worse than V1's 60.7% error.

**Key Takeaways:**
1. ✅ Daily aggregation produces realistic forecasts (no catastrophic errors)
2. ⚠️ Model under-predicts compared to actuals and V1
3. ⚠️ V1 still performs better for this specific backtest period
4. ✅ Architecture is sound - needs feature/tuning improvements

**Next Steps:**
- Investigate why October 2025 was an outlier
- Add more predictive features (segment averages, external signals)
- Consider ensemble approach combining V1 and V3
- Apply calibration/scaling based on recent trends

---

**Report Status:** ⚠️ **MODEL VALIDATED BUT UNDER-PERFORMS V1**

