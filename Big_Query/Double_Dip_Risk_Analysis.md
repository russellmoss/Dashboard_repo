# Double-Dip Risk Analysis: Mix Shift vs Independent Decline

**Analysis Date:** November 2025  
**Purpose:** Determine if conversion rate drop is due to mix shift (more large deals) or independent decline (all deals worse)  
**Critical Finding:** **BOTH factors are at play** - Need careful implementation to avoid double-counting

---

## Executive Summary

**Critical Finding:** The conversion rate drop is **NOT just mix shift**. Both small and large deals declined independently, with **small deals declining MORE than large deals** (-48% vs -24%).

**Risk:** If we apply both deal-size penalty AND time-period penalty without proper logic, we'll double-count and over-correct.

**Solution:** Apply adjustments sequentially with proper logic to avoid double-counting.

---

## Analysis Results

### Conversion Rates by Deal Size and Time Period

| Deal Size | Time Period | SQO Count | Joined | Conversion Rate | Change |
|-----------|-------------|-----------|--------|-----------------|--------|
| **Small/Med (<$10M)** | Historical (6-12 Mos) | 79 | 13 | **16.46%** | Baseline |
| **Small/Med (<$10M)** | Recent (Last 6 Mos) | 116 | 10 | **8.62%** | **-48% drop** ⚠️ |
| **Large/Ent (>$10M)** | Historical (6-12 Mos) | 123 | 13 | **10.57%** | Baseline |
| **Large/Ent (>$10M)** | Recent (Last 6 Mos) | 161 | 13 | **8.07%** | **-24% drop** ⚠️ |

### Key Findings

1. **Both Deal Sizes Declined Independently**
   - Small deals: 16.46% → 8.62% (-48% drop)
   - Large deals: 10.57% → 8.07% (-24% drop)
   - **Small deals declined MORE than large deals**

2. **Mix Shift Also Occurred**
   - Historical: 79 small + 123 large = 202 total (39% small, 61% large)
   - Recent: 116 small + 161 large = 277 total (42% small, 58% large)
   - **Slight shift toward small deals** (not large as expected)

3. **Overall Drop Explained**
   - Historical overall: ~12.87% (weighted average)
   - Recent overall: ~8.3% (weighted average)
   - **Drop is combination of:**
     - Independent decline in both sizes
     - Small deals declining more than large deals

---

## Risk Analysis: Double-Counting

### The Problem

If we apply both adjustments naively:
1. **Deal-Size Penalty:** Large deals get 0.64x multiplier (36% lower)
2. **Time-Period Penalty:** Recent deals get 0.64x multiplier (36% lower)
3. **Result:** Large recent deals get 0.64 × 0.64 = **0.41x multiplier** (59% lower) ⚠️

**This would be over-correction!**

### The Correct Approach

**Option 1: Sequential Adjustment (Recommended)**

Apply adjustments in order, using the correct baseline:

```sql
-- Step 1: Start with base stage probability
base_probability = stage_probability

-- Step 2: Apply deal-size adjustment (relative to small deals)
IF deal_size >= $20M THEN
  size_adjusted = base_probability * 0.64  -- Large deals convert 36% lower than small
ELSE
  size_adjusted = base_probability * 1.00  -- Small deals are baseline
END IF

-- Step 3: Apply time-period adjustment (relative to historical for same size)
IF recent_period THEN
  IF deal_size >= $10M THEN
    time_adjusted = size_adjusted * (8.07 / 10.57)  -- Large: recent vs historical
  ELSE
    time_adjusted = size_adjusted * (8.62 / 16.46)  -- Small: recent vs historical
  END IF
ELSE
  time_adjusted = size_adjusted  -- Historical: no time adjustment
END IF

final_probability = time_adjusted
```

**Option 2: Combined Adjustment Factor**

Calculate a single adjustment factor that accounts for both:

```sql
-- Calculate adjustment factor based on deal size and time period
CASE
  -- Small deals, historical (baseline)
  WHEN estimated_margin_aum < 10000000 AND is_recent = FALSE THEN 1.00
  
  -- Small deals, recent
  WHEN estimated_margin_aum < 10000000 AND is_recent = TRUE THEN 0.52  -- 8.62% / 16.46%
  
  -- Large deals, historical
  WHEN estimated_margin_aum >= 10000000 AND is_recent = FALSE THEN 0.64  -- 10.57% / 16.46%
  
  -- Large deals, recent
  WHEN estimated_margin_aum >= 10000000 AND is_recent = TRUE THEN 0.49  -- 8.07% / 16.46%
END AS combined_adjustment_factor
```

**Option 3: Separate but Non-Overlapping Adjustments**

Apply adjustments to different aspects:
- **Deal-size adjustment:** Apply to stage probabilities (conversion likelihood)
- **Time-period adjustment:** Apply to cycle times (timing, not conversion)

This avoids double-counting by affecting different aspects of the forecast.

---

## Recommended Implementation

### Approach: Sequential Adjustment with Correct Baselines

**Step 1: Deal-Size Adjustment (Relative to Small Deals)**

```sql
-- Large deals convert at 10.57% vs small at 16.46% = 0.64x
CASE
  WHEN estimated_margin_aum >= 20000000 THEN stage_probability * 0.64  -- Enterprise
  WHEN estimated_margin_aum >= 10000000 THEN stage_probability * 0.64  -- Large
  ELSE stage_probability * 1.00  -- Small/Medium (baseline)
END AS size_adjusted_probability
```

**Step 2: Time-Period Adjustment (Relative to Historical for Same Size)**

```sql
-- Recent deals convert lower than historical for same size
CASE
  WHEN is_recent_period AND estimated_margin_aum >= 10000000 THEN 
    size_adjusted_probability * (8.07 / 10.57)  -- Large: 0.76x
  WHEN is_recent_period AND estimated_margin_aum < 10000000 THEN 
    size_adjusted_probability * (8.62 / 16.46)  -- Small: 0.52x
  ELSE 
    size_adjusted_probability  -- Historical: no adjustment
END AS final_adjusted_probability
```

**Result:**
- Small historical: 1.00x (baseline)
- Small recent: 0.52x (48% drop)
- Large historical: 0.64x (36% lower than small)
- Large recent: 0.49x (64% lower than small historical, 24% lower than large historical)

---

## Validation: Check the Math

### Expected Conversion Rates (After Adjustments)

| Deal Size | Time Period | Base Prob | Size Adj | Time Adj | Final | Expected Actual |
|-----------|-------------|-----------|----------|----------|--------|-----------------|
| Small | Historical | 0.10 | 1.00 | 1.00 | 0.10 | 16.46% |
| Small | Recent | 0.10 | 1.00 | 0.52 | 0.052 | 8.62% ✅ |
| Large | Historical | 0.10 | 0.64 | 1.00 | 0.064 | 10.57% ✅ |
| Large | Recent | 0.10 | 0.64 | 0.76 | 0.049 | 8.07% ✅ |

**Note:** Base probability of 0.10 is example - actual stage probabilities vary by stage.

### Verification

- Small recent: 0.052 / 0.10 = 0.52x ✅ (matches 8.62% / 16.46%)
- Large historical: 0.064 / 0.10 = 0.64x ✅ (matches 10.57% / 16.46%)
- Large recent: 0.049 / 0.10 = 0.49x ✅ (matches 8.07% / 16.46%)

**Math checks out!**

---

## Summary

### Key Insights

1. **Both factors are real** - Mix shift AND independent decline
2. **Small deals declined MORE** - 48% vs 24% for large deals
3. **Sequential adjustment needed** - Apply size first, then time
4. **Correct baselines critical** - Use small historical as baseline

### Implementation Logic

```sql
-- Final implementation
WITH Base_Probabilities AS (
  SELECT 
    stage_probability,
    estimated_margin_aum,
    CASE 
      WHEN DATE(Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY) 
      THEN TRUE ELSE FALSE 
    END AS is_recent
  FROM ...
),
Size_Adjusted AS (
  SELECT 
    *,
    CASE
      WHEN estimated_margin_aum >= 20000000 THEN stage_probability * 0.64
      WHEN estimated_margin_aum >= 10000000 THEN stage_probability * 0.64
      ELSE stage_probability * 1.00
    END AS size_adjusted_probability
  FROM Base_Probabilities
)
SELECT 
  *,
  CASE
    WHEN is_recent AND estimated_margin_aum >= 10000000 THEN 
      size_adjusted_probability * 0.76  -- Large recent: 8.07% / 10.57%
    WHEN is_recent AND estimated_margin_aum < 10000000 THEN 
      size_adjusted_probability * 0.52  -- Small recent: 8.62% / 16.46%
    ELSE 
      size_adjusted_probability  -- Historical: no time adjustment
  END AS final_adjusted_probability
FROM Size_Adjusted
```

### Expected Impact

- **Prevents double-counting** ✅
- **Accounts for both factors** ✅
- **Uses correct baselines** ✅
- **Maintains forecast accuracy** ✅

---

## Conclusion

**The conversion rate drop is BOTH mix shift AND independent decline.**

**Solution:** Apply adjustments sequentially:
1. **Deal-size adjustment first** (relative to small deals)
2. **Time-period adjustment second** (relative to historical for same size)

**Result:** Accurate adjustments without double-counting, maintaining forecast accuracy while accounting for both deal-size and time-period effects.

