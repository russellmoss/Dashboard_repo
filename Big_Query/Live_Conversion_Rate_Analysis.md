# Live Conversion Rate Analysis

**Issue Identified:** We are currently using a **static conversion rate (69.3%)** from a Q3 2024 backtest, rather than live actual conversion rates.

---

## Current Implementation

### What We're Using:
- **V2 Static Rate:** 69.3% (from Q3 2024 backtest: 9.01 predicted SQOs / 13 cohort SQLs)
- **Location:** Hardcoded in `vw_production_forecast_updated.sql`
- **Update Frequency:** Never - it's a constant value

### Problems with Static Rate:
1. ❌ **Doesn't reflect current performance** - Rate is from months ago
2. ❌ **Can't adapt to changing conversion patterns** - Business conditions change
3. ❌ **May over-predict SQOs** - Recent actual rates are lower (50-56%)

---

## Live Actual Conversion Rates

| Period | Total SQLs | Converted SQOs | **Live Rate** | vs Static (69.3%) |
|--------|------------|----------------|---------------|-------------------|
| **Last 30 Days** | 40 | 20 | **50.0%** | ⚠️ **-19.3 p.p. lower** |
| **Last 30-60 Days** | 72 | 40 | **55.6%** | ⚠️ **-13.7 p.p. lower** |
| **Last 60-90 Days** | 46 | 32 | **69.6%** | ✅ Close to static |

### Analysis:
- **Recent trend:** Conversion rates have dropped from ~69% to ~50-56%
- **Last 90 days average:** ~58% (blended across periods)
- **V1 trailing_rates average:** 54.9% (segment-specific, updated daily)

---

## Impact on Q4 2025 Forecast

**Q4 SQL Forecast:** 179.9 SQLs (from V3.1 model)

| Method | Conversion Rate | **Forecasted SQOs** | Difference |
|--------|----------------|---------------------|------------|
| **Current: Static V2 Rate** | 69.3% | **124.7 SQOs** | Baseline |
| **Live Rate (30-day)** | 50.0% | **90.0 SQOs** | -34.7 SQOs (-28%) |
| **Live Rate (60-day)** | 55.6% | **100.0 SQOs** | -24.7 SQOs (-20%) |
| **V1 trailing_rates** | 54.9% | **98.8 SQOs** | -25.9 SQOs (-21%) |

**Finding:** Using static 69.3% rate may be **over-predicting SQOs by ~20-28%** based on recent actual performance.

---

## Recommendations

### Option 1: Use Live Rolling Rate (Recommended)
- Calculate a **90-day rolling average** of actual SQL→SQO conversion
- Update weekly/monthly or recalculate in the view dynamically
- Automatically adapts to current business conditions

### Option 2: Use V1 trailing_rates_features
- Already calculates segment-specific rates from recent data
- Updated daily in production
- More granular (segment-level) than single global rate
- Currently shows 54.9% average (vs our 69.3% static)

### Option 3: Hybrid Approach
- Use V2 model's **individual SQL predictions** (not just average rate)
- Apply ML predictions on actual SQL cohort
- More accurate but requires running predictions on each SQL

---

## Next Steps

1. **Update `vw_production_forecast_updated.sql`** to use:
   - Live 90-day rolling rate, OR
   - V1 trailing_rates_features (already in production), OR
   - V2 ML model predictions on actual SQLs

2. **Re-run Q4 forecast** with updated conversion method

3. **Compare forecasts** to see impact of using live vs static rates

