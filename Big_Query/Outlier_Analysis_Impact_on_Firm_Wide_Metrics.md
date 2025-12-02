# Outlier Analysis: Impact of Bre McDaniel's Enterprise Deals on Firm-Wide Metrics

**Analysis Date:** November 2025  
**Key Question:** Should we exclude outlier SGMs (like Bre McDaniel with enterprise deals) when calculating firm-wide averages?

---

## Executive Summary

**Finding:** Bre McDaniel has 3 outlier deals ($78M, $58.9M, $56.4M) that are significantly larger than typical deals. However, **removing outliers from firm-wide averages makes forecasts WORSE, not better**.

**Key Insight:** The problem isn't outliers in the average calculation - it's that **using any single average for all deals is fundamentally flawed**. Deal-level estimates remain the optimal approach.

---

## Outlier Analysis

### Bre McDaniel's Outlier Deals

| Deal | Margin_AUM | Outlier Type |
|------|------------|--------------|
| Deal 1 | $78.00M | Top 5% Outlier |
| Deal 2 | $58.92M | Top 5% Outlier |
| Deal 3 | $56.40M | 2-Sigma Outlier |

**All 3 outlier deals belong to Bre McDaniel** - confirming she handles enterprise-level deals that are fundamentally different from typical deals.

### Firm-Wide Averages (Different Methods)

| Method | Average Margin_AUM | Deals Included |
|--------|-------------------|---------------|
| **All Deals** | $18.51M | 43 deals (includes outliers) |
| **No 2-Sigma Outliers** | $15.06M | 40 deals (excludes 3 outliers) |
| **No Top 5%** | $16.07M | 41 deals (excludes 2 largest) |

**Impact of Removing Outliers:**
- Average decreases from $18.51M to $15.06M (19% lower)
- This creates a **more conservative** average

---

## Backtest Results: Outlier-Adjusted Averages

### Comparison of All Approaches

| Approach | Accuracy | Error % | MAE | RMSE | Bias |
|----------|----------|---------|-----|------|------|
| **Current (Deal-Level)** | **89.01%** ✅ | -10.99% | $4.68M | $6.83M | -$4.68M |
| **Firm-Wide (All Deals)** | 53.95% | -31.26% | $21.51M | $35.87M | -$13.33M |
| **Firm-Wide (No Top 5%)** | 50.30% ⚠️ | -41.51% | $22.34M | $39.15M | -$17.70M |
| **Firm-Wide (No 2-Sigma)** | 49.13% ⚠️ | -43.84% | $22.71M | $39.94M | -$18.69M |

### Key Finding: Removing Outliers Makes It WORSE

**Counterintuitive Result:**
- Removing outliers **decreases** accuracy from 53.95% to 49.13%
- Error increases from -31.26% to -43.84%
- MAE increases from $21.51M to $22.71M

**Why This Happens:**
1. Removing Bre's large deals lowers the average ($18.51M → $15.06M)
2. This lower average is then applied to **all deals**, including Bre's large ones
3. Result: Even **more severe under-forecasting** for Bre's deals
4. The lower average doesn't help other SGMs either (they still have deal variation)

---

## Root Cause Analysis

### The Real Problem

**Using a single average for all deals is fundamentally flawed**, regardless of how that average is calculated:

1. **Deal Variation is Inherent**
   - Deals range from $3.75M to $78M (20x variation)
   - Even within a single SGM, deals vary widely
   - Bre McDaniel: $4.68M to $78M (16.7x variation)

2. **Outlier Removal Doesn't Help**
   - Lower average ($15.06M) still doesn't represent individual deals
   - Small deals ($4M) are over-forecasted
   - Large deals ($78M) are severely under-forecasted
   - Net result: Worse accuracy

3. **Deal-Level Estimates Are Essential**
   - Each deal has unique characteristics (Margin_AUM, Underwritten_AUM, Amount)
   - Using deal-specific data captures this variation
   - Result: 89% accuracy vs 50% with any average

---

## Recommendations

### 1. Keep Deal-Level Estimates for Forecasts ✅

**Continue using deal-level Margin_AUM estimates:**
- Use actual `Margin_AUM__c` when available
- Fall back to `Underwritten_AUM__c / 3.125` if missing
- Fall back to `Amount / 3.22` if both missing

**This is already optimal** - 89% accuracy is excellent.

### 2. For Capacity Planning: Use Outlier-Adjusted Averages

**For calculating required joined/SQO counts** (in `vw_sgm_capacity_model_refined`):

**Option A: Exclude Outlier Deals from Average**
```sql
-- Calculate firm-wide average excluding top 5% deals
AVG(CASE 
  WHEN margin_aum <= PERCENTILE_CONT(margin_aum, 0.95) OVER ()
  THEN margin_aum 
  ELSE NULL 
END)
```

**Option B: Use Median Instead of Mean**
```sql
-- Median is less affected by outliers
PERCENTILE_CONT(margin_aum, 0.5) OVER ()
```

**Option C: Use Trimmed Mean (Exclude Top/Bottom 5%)**
```sql
-- More robust to outliers
AVG(CASE 
  WHEN margin_aum BETWEEN 
    PERCENTILE_CONT(margin_aum, 0.05) OVER () AND
    PERCENTILE_CONT(margin_aum, 0.95) OVER ()
  THEN margin_aum 
  ELSE NULL 
END)
```

**Recommendation:** Use **Option C (Trimmed Mean)** for capacity planning calculations, as it:
- Reduces impact of outliers
- Still uses most of the data (90% of deals)
- More stable than median for small samples

### 3. Consider SGM Segmentation

**For capacity planning, consider:**
- **Enterprise SGMs** (like Bre McDaniel): Use enterprise-specific averages
- **Standard SGMs**: Use trimmed mean (excluding outliers)
- **On Ramp SGMs**: Use firm-wide (as currently done)

**Implementation:**
```sql
CASE
  WHEN sgm_name IN ('Bre McDaniel', ...) THEN enterprise_avg_margin_aum
  WHEN is_on_ramp = 1 THEN firm_wide_trimmed_avg
  ELSE individual_or_firm_wide_based_on_volatility
END
```

---

## Impact on Current Views

### Views That Use Firm-Wide Averages

1. **`vw_sgm_capacity_model_refined`**
   - Currently uses: `overall_avg_margin_aum_per_joined`
   - **Recommendation:** Use trimmed mean (exclude top/bottom 5%)
   - **Impact:** More accurate required joined/SQO counts

2. **`vw_sgm_capacity_coverage`**
   - Uses deal-level estimates for forecasts ✅ (no change needed)
   - Uses firm-wide for capacity planning (could use trimmed mean)

3. **`vw_sgm_capacity_coverage_with_forecast`**
   - Uses deal-level estimates for forecasts ✅ (no change needed)
   - Uses firm-wide for capacity planning (could use trimmed mean)

### Views That Use Deal-Level Estimates

- **All forecast views** - ✅ **No changes needed**
- These already use deal-level data, which is optimal

---

## Conclusion

### Key Takeaways

1. **Bre McDaniel's enterprise deals ARE outliers** ($78M, $58.9M, $56.4M)
2. **Removing outliers from averages makes forecasts WORSE** (49% vs 54% accuracy)
3. **Deal-level estimates remain optimal** (89% accuracy)
4. **For capacity planning, use trimmed mean** (exclude top/bottom 5%)

### Final Recommendation

✅ **Keep deal-level estimates for forecasts** (no change)  
✅ **Use trimmed mean for capacity planning** (exclude top/bottom 5% of deals)  
✅ **Consider SGM segmentation** (enterprise vs standard) for future enhancement

The outlier issue is real, but the solution is **not** to remove outliers from forecast averages. Instead:
- Use deal-level estimates for forecasts (already done) ✅
- Use trimmed mean for capacity planning calculations (recommended change)

This approach:
- Maintains 89% forecast accuracy
- Provides more stable capacity planning metrics
- Accounts for enterprise deal differences without breaking the model

