# Firm-Wide vs Individual Metrics: Backtest Impact Analysis

**Analysis Date:** November 2025  
**Purpose:** Compare forecast accuracy using different Margin_AUM estimation approaches  
**Key Question:** How would using firm-wide metrics (or hybrid approach) impact backtest accuracy?

---

## Executive Summary

**Critical Finding:** Using **deal-level Margin_AUM estimates** (current approach) is **significantly more accurate** than using firm-wide averages. The current approach achieves **89% accuracy** vs **54% accuracy** with firm-wide averages.

### Key Insight

The question about "firm-wide vs individual metrics" is **NOT about individual deal forecasts**. Instead, it's about:
1. **Historical averages for capacity planning** (e.g., avg Margin_AUM per SGM)
2. **Conversion rates** (SQO to Joined)

For **individual deal forecasts**, we should **always use deal-level estimates** when available (Margin_AUM, Underwritten_AUM, or Amount).

---

## Backtest Results Comparison

### Approach 1: Current (Deal-Level Margin_AUM Estimates)

| Metric | Value | Assessment |
|--------|-------|------------|
| **Total Forecasted** | $607.07M | |
| **Total Actual** | $682.02M | |
| **Total Error** | -$74.95M | Under-forecasting |
| **Percentage Error** | -10.99% | ✅ **Good** (slight conservative bias) |
| **Mean Absolute Error** | $4.68M | ✅ **Low** |
| **RMSE** | $6.83M | ✅ **Low** |
| **Bias** | -$4.68M | Slight under-forecast |
| **Accuracy** | **89.01%** | ✅ **Excellent** |

**How it works:**
- Uses actual `Margin_AUM__c` when available
- Falls back to `Underwritten_AUM__c / 3.125` if Margin_AUM missing
- Falls back to `Amount / 3.22` if both missing
- Multiplies by `stage_probability` (firm-wide, from `vw_stage_to_joined_probability`)

### Approach 2: Firm-Wide Average Margin_AUM

| Metric | Value | Assessment |
|--------|-------|------------|
| **Total Forecasted** | $468.80M | |
| **Total Actual** | $682.02M | |
| **Total Error** | -$213.22M | **Severe under-forecasting** |
| **Percentage Error** | -31.26% | ⚠️ **Poor** (too conservative) |
| **Mean Absolute Error** | $21.51M | ⚠️ **High** (4.6x worse) |
| **RMSE** | $35.87M | ⚠️ **Very High** (5.3x worse) |
| **Bias** | -$13.33M | Significant under-forecast |
| **Accuracy** | **53.95%** | ⚠️ **Poor** (35% worse than current) |

**How it works:**
- Uses firm-wide average Margin_AUM ($12.49M) for ALL deals
- Ignores actual deal-level data
- Multiplies by `stage_probability` (same as current)

---

## Analysis

### Why Deal-Level Estimates Are Better

1. **Deal-Specific Data is More Accurate**
   - Each deal has unique Margin_AUM, Underwritten_AUM, or Amount
   - Firm-wide average ($12.49M) doesn't capture deal variation
   - Some deals are $4M, others are $78M - average doesn't represent either

2. **Current Approach Already Uses Firm-Wide Where Appropriate**
   - Stage probabilities are firm-wide (from `vw_stage_to_joined_probability`)
   - Only Margin_AUM estimation uses deal-level data
   - This is the optimal combination

3. **Firm-Wide Average Creates Systematic Bias**
   - Under-forecasts large deals (e.g., $78M deal forecasted as $12.49M)
   - Over-forecasts small deals (e.g., $4M deal forecasted as $12.49M)
   - Net result: Significant under-forecasting (-31% error)

### Impact on Capacity Planning

**Important Distinction:**
- **Deal-Level Forecasts** (what we're backtesting): Use deal-specific data ✅
- **Capacity Planning Metrics** (what the analysis was about): Use historical averages for SGMs

The firm-wide vs individual question applies to:
- `avg_margin_aum_per_joined` (for calculating required joined count)
- `sqo_to_joined_conversion_rate` (for calculating required SQO count)

**NOT** to individual deal forecasts.

---

## Recommendations

### 1. Keep Current Deal-Level Estimation ✅

**Continue using:**
- Deal-level Margin_AUM estimates (Margin_AUM → Underwritten_AUM → Amount)
- Firm-wide stage probabilities (from `vw_stage_to_joined_probability`)

**This is already optimal** - 89% accuracy is excellent.

### 2. Use Firm-Wide Metrics for Capacity Planning

**For capacity planning calculations** (in `vw_sgm_capacity_model_refined`):
- Use firm-wide `avg_margin_aum_per_joined` for most SGMs (due to volatility)
- Use firm-wide `sqo_to_joined_conversion_rate` for most SGMs (due to volatility)
- Consider hybrid approach for SGMs with low volatility (e.g., GinaRose Galli for Margin_AUM only)

**This does NOT affect individual deal forecasts** - those should always use deal-level data.

### 3. Hybrid Approach Impact

The hybrid approach (individual Margin_AUM for low-volatility SGMs, firm-wide for others) would:
- **NOT change deal-level forecasts** (we still use deal-specific data)
- **ONLY change capacity planning metrics** (required joined count, required SQO count)

**Impact on backtest:** **None** - because backtest uses deal-level estimates, not SGM averages.

---

## Outlier Analysis: Bre McDaniel's Enterprise Deals

### Finding: Bre McDaniel Has 3 Outlier Deals

All 3 outlier deals (>$52M) belong to Bre McDaniel:
- $78.00M (Top 5% outlier)
- $58.92M (Top 5% outlier)  
- $56.40M (2-Sigma outlier)

**Question:** Should we exclude these outliers when calculating firm-wide averages?

### Answer: Removing Outliers Makes It WORSE

| Approach | Accuracy | Error % |
|----------|----------|---------|
| Firm-Wide (All Deals) | 53.95% | -31.26% |
| Firm-Wide (No Top 5%) | 50.30% | -41.51% ⚠️ **Worse** |
| Firm-Wide (No 2-Sigma) | 49.13% | -43.84% ⚠️ **Worse** |

**Why:** Removing outliers lowers the average ($18.51M → $15.06M), which then under-forecasts Bre's large deals even more severely.

**Key Insight:** The problem isn't outliers in the average - it's that **using any single average for all deals is fundamentally flawed**. Deal-level estimates remain optimal.

### Recommendation for Capacity Planning

For capacity planning calculations (not forecasts), use **trimmed mean** (exclude top/bottom 5%):
- More stable than mean (less affected by outliers)
- More representative than median (uses 90% of data)
- Better for calculating required joined/SQO counts

---

## Conclusion

### Key Takeaways

1. **Current approach is optimal for forecasts** (89% accuracy)
   - Deal-level Margin_AUM estimates are essential
   - Firm-wide stage probabilities are appropriate

2. **Firm-wide averages should NOT replace deal-level estimates**
   - Would reduce accuracy from 89% to 54%
   - Creates systematic bias (-31% error)
   - Removing outliers makes it worse (49% accuracy)

3. **Bre McDaniel's enterprise deals are outliers, but...**
   - Removing them from averages makes forecasts worse
   - Solution: Use deal-level estimates (already done) ✅
   - For capacity planning: Use trimmed mean (exclude top/bottom 5%)

4. **Firm-wide vs individual question is about capacity planning, not forecasts**
   - Use trimmed mean for calculating required joined/SQO counts
   - Use deal-level estimates for individual deal forecasts

5. **Hybrid approach has minimal impact on backtest**
   - Backtest uses deal-level estimates (not SGM averages)
   - Hybrid approach only affects capacity planning calculations

### Final Recommendation

✅ **Keep current deal-level estimation approach** (no change)  
✅ **Use trimmed mean for capacity planning** (exclude top/bottom 5% of deals)  
✅ **No changes needed to forecast logic** - it's already optimal

The firm-wide vs individual metrics decision should be implemented in `vw_sgm_capacity_model_refined` for capacity planning calculations, but **NOT** in the forecast views (`vw_sgm_capacity_coverage`, `vw_sgm_capacity_coverage_with_forecast`) which correctly use deal-level estimates.

