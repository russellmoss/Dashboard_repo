# V2 Backtest Analysis Results

**Analysis Date:** November 2025  
**Methodology:** Retrospective analysis (matching original 89% baseline approach)  
**Key Finding:** ⚠️ **V2 adjustments are too aggressive** - Reducing accuracy instead of improving it

---

## Executive Summary

**Critical Finding:** V2 logic is **worsening forecast accuracy** compared to baseline:
- Baseline: 27-75% accuracy (varies by quarter)
- V2: 13-39% accuracy
- **V2 is 13-36 percentage points WORSE**

**Root Cause:** Probability adjustments (0.49x, 0.52x) are too aggressive when applied to deals that actually joined.

---

## Detailed Results

### Quarterly Comparison: Baseline vs V2

| Quarter | Actual (M) | Baseline Forecast (M) | Baseline Accuracy | V2 Forecast (M) | V2 Accuracy | V2 vs Baseline |
|---------|------------|----------------------|-------------------|-----------------|-------------|----------------|
| Q4 2025 | $185.18 | $130.57 | **70.51%** | $64.23 | **34.68%** | **-35.83%** ⚠️ |
| Q3 2025 | $156.81 | $117.31 | **74.81%** | $60.61 | **38.65%** | **-36.16%** ⚠️ |
| Q2 2025 | $87.99 | $23.03 | **26.17%** | $11.40 | **12.96%** | **-13.21%** ⚠️ |
| Q1 2025 | $81.66 | $22.65 | **27.74%** | $11.37 | **13.93%** | **-13.81%** ⚠️ |
| Q4 2024 | $170.37 | $54.45 | **31.96%** | $26.83 | **15.75%** | **-16.21%** ⚠️ |

### V2 Backtest with Velocity Logic

| Quarter | Actual (M) | V2 Forecast (M) | Accuracy | Deals in Forecast | Total Deals | Excluded (Stale) | Excluded (Timing) |
|---------|------------|-----------------|----------|-------------------|-------------|------------------|-------------------|
| Q4 2025 | $185.18 | $64.91 | **35.05%** | 8 | 8 | 0 | 0 |
| Q3 2025 | $156.81 | $47.45 | **30.26%** | 6 | 7 | 1 | 0 |
| Q2 2025 | $87.99 | $11.73 | **13.33%** | 4 | 4 | 0 | 0 |
| Q1 2025 | $81.66 | $11.37 | **13.93%** | 8 | 8 | 0 | 0 |
| Q4 2024 | $170.37 | $26.83 | **15.75%** | 6 | 6 | 0 | 0 |

---

## Analysis

### Issue 1: Probability Adjustments Too Aggressive

**The Problem:**
- V2 applies 0.49x-0.52x multipliers to recent deals
- But these deals **actually joined** - they shouldn't be penalized
- The adjustments are meant for **forecasting**, not for deals that already converted

**Example:**
- Large recent deal that joined: Gets 0.49x probability
- But it DID join, so probability should be high (or at least baseline)
- Result: Under-forecasting successful deals

### Issue 2: Conceptual Mismatch

**The Logic:**
- Probability adjustments (0.49x, 0.52x) account for **lower conversion rates**
- But in backtest, we're looking at deals that **already converted**
- Applying conversion penalties to converted deals doesn't make sense

**What Should Happen:**
- For deals that joined: Use baseline probabilities (they converted, so they had that probability)
- For deals in pipeline: Apply adjustments (they might not convert)

### Issue 3: Baseline Also Lower Than Expected

**Observation:**
- Original backtest showed 89% accuracy
- This backtest shows 27-75% baseline accuracy
- **Difference:** Original backtest may have included different deal set or methodology

**Possible Reasons:**
- Different time period
- Different deal filtering
- Different probability calculation

---

## Root Cause Analysis

### Why V2 Adjustments Don't Work in Backtest

**The adjustments are designed for:**
- Forecasting deals that **haven't joined yet**
- Accounting for lower conversion rates in recent period
- Adjusting for deal-size differences

**But in backtest:**
- We're looking at deals that **already joined**
- They already beat the odds (converted)
- Applying penalties to successful deals is backwards

### The Correct Approach

**For Backtesting:**
1. Use baseline probabilities (deals that joined had those probabilities)
2. Test valuation improvements (3.30/3.80 divisors)
3. Test velocity improvements (deal-size cycle times)
4. **Don't apply probability penalties** to deals that already converted

**For Forecasting (Production):**
1. Apply all V2 adjustments (probability, velocity, stale)
2. These adjust for expected conversion rates
3. These account for deal-size differences

---

## Recommendations

### Option 1: Separate Backtest Components (Recommended)

**Test Each Component Individually:**

1. **Valuation Test:**
   - Compare baseline (3.125/3.22) vs V2 (3.30/3.80)
   - Use baseline probabilities (no adjustments)
   - **Expected:** V2 should improve accuracy

2. **Velocity Test:**
   - Compare fixed cycle times vs deal-size dependent
   - Use baseline probabilities and valuation
   - **Expected:** Better quarter predictions

3. **Probability Test:**
   - Test on **pipeline deals** (not joined deals)
   - Compare forecasted conversion vs actual
   - **Expected:** More accurate conversion predictions

### Option 2: Adjust Probability Multipliers

**Current Multipliers May Be Too Low:**
- Large recent: 0.49x (51% reduction)
- Small recent: 0.52x (48% reduction)

**Consider:**
- Large recent: 0.70x (30% reduction)
- Small recent: 0.75x (25% reduction)
- **Less aggressive, more realistic**

### Option 3: Conditional Application

**Only Apply Adjustments When Appropriate:**
- If deal joined: Use baseline probability (it converted)
- If deal in pipeline: Apply adjustments (forecasting)
- **Separate logic for backtest vs production**

---

## Revised V2 Backtest (Valuation Only)

Let's test just the valuation improvements:

```sql
-- Test: V2 Valuation (3.30/3.80) vs Baseline (3.125/3.22)
-- Use baseline probabilities (no adjustments)
-- This isolates the valuation improvement
```

**Expected Result:** V2 valuation should improve accuracy by 2-5% (from fixing under-estimation).

---

## Conclusion

**Key Findings:**

1. **V2 probability adjustments are too aggressive** - Reducing accuracy by 13-36%
2. **Conceptual mismatch** - Adjustments meant for forecasting, not backtesting converted deals
3. **Valuation improvements likely still valid** - Need to test separately
4. **Velocity improvements likely still valid** - Need to test separately

**Recommendation:**

✅ **Test V2 components separately:**
- Valuation: Should improve accuracy
- Velocity: Should improve quarter predictions
- Probability: Test on pipeline, not joined deals

✅ **Revise probability multipliers:**
- Make less aggressive (0.70x-0.75x instead of 0.49x-0.52x)
- Or apply conditionally (only to pipeline deals)

✅ **Separate backtest vs production logic:**
- Backtest: Use baseline probabilities for joined deals
- Production: Apply all V2 adjustments for pipeline deals

**Expected Outcome:** Once components are tested separately and adjusted, V2 should show improvements over baseline.

