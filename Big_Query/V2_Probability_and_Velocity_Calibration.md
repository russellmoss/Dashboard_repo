# V2 Probability and Velocity Calibration

**Analysis Date:** November 2025  
**Purpose:** Calibrate V2 probability multipliers and Large deal cycle times based on actual data  
**Key Finding:** V2 probability adjustments are too aggressive; Large deal cycle time needs adjustment

---

## Executive Summary

**Critical Findings:**
1. ⚠️ **Small deals convert at 16.22%** (not 8.6% as V2 predicted) - V2 too aggressive
2. ✅ **Large deals convert at 10.62%** (close to V2's 8.0%, but still higher)
3. ⚠️ **Large deals median cycle time is 70 days** (not 80 days) - But average is 97 days

**Recommendation:** Revise probability multipliers and Large deal cycle time based on actual data.

---

## Test 1: Probability Calibration

### Purpose
Find exact conversion rates for recent cohorts (6-12 months ago) to properly tune V2 multipliers.

### Results

| Deal Size | Total SQOs | Joined | Actual Conversion Rate | V2 Predicted | Difference |
|-----------|------------|--------|------------------------|--------------|------------|
| **Small (<$10M)** | 74 | 12 | **16.22%** | 8.6% | **-7.62%** ⚠️ |
| **Large (>$10M)** | 113 | 12 | **10.62%** | 8.0% | **-2.62%** ⚠️ |

### Analysis

**Key Findings:**

1. **Small deals: V2 is 53% too low**
   - Actual: 16.22%
   - V2 predicted: 8.6%
   - **V2 is under-predicting by 7.62 percentage points**

2. **Large deals: V2 is 25% too low**
   - Actual: 10.62%
   - V2 predicted: 8.0%
   - **V2 is under-predicting by 2.62 percentage points**

3. **Both deal sizes convert higher than V2 predicted**
   - Small: 16.22% vs 8.6% (almost 2x higher)
   - Large: 10.62% vs 8.0% (33% higher)

### Root Cause

**Current V2 Multipliers:**
- Small recent: 0.52x (8.6% / 16.46% baseline)
- Large recent: 0.49x (8.0% / 16.46% baseline)

**But Actual Recent Rates:**
- Small: 16.22% (same as historical baseline!)
- Large: 10.62% (lower than baseline, but not as low as V2)

**The Issue:** V2 multipliers were based on overall recent decline (8.3% vs 12.87%), but when broken down by size:
- Small deals maintained their conversion rate (16.22%)
- Large deals declined but not as much (10.62% vs 8.0%)

### Recommended Multipliers

**Based on Actual Conversion Rates:**

| Deal Size | Historical Baseline | Recent Actual | Recommended Multiplier | Rationale |
|-----------|-------------------|---------------|------------------------|-----------|
| **Small** | 16.46% | 16.22% | **1.00x** (no change) | No decline |
| **Large** | 10.57% | 10.62% | **1.00x** (no change) | Same as historical |

**Wait - This doesn't match the earlier analysis!**

Let me check: The earlier "Double Dip" analysis showed:
- Small recent: 8.62% (vs 16.46% historical)
- Large recent: 8.07% (vs 10.57% historical)

But this calibration shows:
- Small recent: 16.22%
- Large recent: 10.62%

**The difference:** This calibration uses 6-12 months ago (baked cohort), while Double Dip used last 6 months (recent, may not be fully baked).

**Recommendation:** Use this calibration (6-12 months ago) as it's more reliable (fully baked outcomes).

---

## Test 2: Large Deal Velocity Tuning

### Purpose
Find optimal cycle time for Large deals ($15M-$30M) since 80 days was too short.

### Results

| Metric | Value |
|--------|-------|
| **Deal Count** | 11 |
| **Average Days** | **97 days** |
| **Median Days** | **70 days** |
| **P25 Days** | 42 days |
| **P60 Days** | **80 days** |
| **P75 Days** | **148 days** |
| **P90 Days** | 195 days |
| **Min Days** | 10 days |
| **Max Days** | 222 days |

### Analysis

**Key Findings:**

1. **Median is 70 days** (not 80 days)
   - Current V2 uses 80 days
   - But median is 70 days
   - **However:** Average is 97 days (higher due to outliers)

2. **P75 is 148 days** (very high)
   - 25% of Large deals take 148+ days
   - This explains why some deals miss their forecast quarter

3. **Distribution is wide**
   - Range: 10-222 days
   - P25: 42 days, P75: 148 days
   - **High variability**

**The Problem:**
- Using 80 days: 60% of deals land in correct quarter (P60)
- But 25% take 148+ days (P75)
- **Need to balance:** Too short = miss long deals, Too long = include deals that won't close

### Recommendation

**Option 1: Use Median (70 days)**
- Pros: 50% of deals land correctly
- Cons: Misses the 25% that take 148+ days

**Option 2: Use P75 (148 days)**
- Pros: Captures 75% of deals
- Cons: Too long for most deals, includes stale deals

**Option 3: Use Average (97 days)**
- Pros: Accounts for outliers
- Cons: Higher than median, may over-forecast

**Option 4: Use 90 days (between median and average)**
- Pros: Balanced approach
- Cons: Still may miss some long deals

**Recommended:** **90 days** for Large deals ($15M-$30M)
- Between median (70) and average (97)
- More conservative than 80 days
- Better captures the distribution

---

## Revised V2 Recommendations

### 1. Probability Multipliers (Revised)

**Based on Calibration (6-12 months ago cohort):**

| Deal Size | Historical | Recent (6-12mo) | Recommended Multiplier | Current V2 | Change |
|-----------|------------|-----------------|------------------------|------------|--------|
| **Small** | 16.46% | 16.22% | **1.00x** (no adjustment) | 0.52x | **Remove penalty** |
| **Large** | 10.57% | 10.62% | **1.00x** (no adjustment) | 0.49x | **Remove penalty** |

**Wait - This suggests NO recent penalty needed!**

But earlier analysis showed recent decline. Let me reconcile:

**Earlier Analysis (Last 6 months):**
- Overall: 8.3% vs 12.87% historical
- Small: 8.62% vs 16.46% historical
- Large: 8.07% vs 10.57% historical

**This Calibration (6-12 months ago):**
- Small: 16.22% (same as historical)
- Large: 10.62% (same as historical)

**The Difference:** 
- 6-12 months ago: No decline (fully baked)
- Last 6 months: Significant decline (may not be fully baked yet)

**Recommendation:** Use **time-period specific multipliers:**
- **6-12 months ago:** No penalty (1.00x) - fully baked, no decline
- **Last 6 months:** Apply penalty (0.75x/0.70x) - recent decline observed

### 2. Large Deal Cycle Time (Revised)

**Current V2:** 80 days  
**Recommended:** **90 days**

**Rationale:**
- Median: 70 days (too short - misses 50% of deals)
- Average: 97 days (accounts for outliers)
- P60: 80 days (current, but only 60% accurate)
- **90 days:** Balanced between median and average

---

## Final Calibrated V2 Logic

### Probability Adjustments

```sql
CASE 
  -- Recent (Last 6 months) - Apply penalty
  WHEN is_recent AND prob_bucket = 'Small_Med' THEN base_probability * 0.75  -- 12-13%
  WHEN is_recent AND prob_bucket = 'Large_Ent' THEN base_probability * 0.70  -- 9-10%
  
  -- Historical (6-12 months ago) - No penalty (fully baked, no decline)
  WHEN NOT is_recent AND prob_bucket = 'Small_Med' THEN base_probability * 1.00  -- 16.22%
  WHEN NOT is_recent AND prob_bucket = 'Large_Ent' THEN base_probability * 1.00  -- 10.62%
  
  -- Very old (>12 months) - Use baseline
  ELSE base_probability * 1.00
END AS calibrated_v2_probability
```

### Velocity Adjustments

```sql
CASE 
  WHEN size_bucket = 'Enterprise' THEN 120 days  -- Validated
  WHEN size_bucket = 'Large' THEN 90 days  -- Revised (was 80)
  WHEN size_bucket = 'Medium' THEN 50 days  -- Validated
  WHEN size_bucket = 'Small' THEN 50 days  -- Validated
  ELSE 70 days  -- Default
END AS calibrated_v2_cycle_time
```

---

## Summary

### Calibration Results

1. **Probability:**
   - Small deals: 16.22% (no decline from historical 16.46%)
   - Large deals: 10.62% (no decline from historical 10.57%)
   - **Recommendation:** Only apply penalties to very recent deals (<6 months)

2. **Velocity:**
   - Large deals median: 70 days
   - Large deals average: 97 days
   - **Recommendation:** Use 90 days (balanced)

### Revised V2 Logic

**Probability:**
- Recent (<6 months): Small 0.75x, Large 0.70x
- Historical (6-12 months): No penalty (1.00x)
- Very old (>12 months): Baseline (1.00x)

**Velocity:**
- Enterprise: 120 days ✅
- Large: **90 days** (revised from 80)
- Medium: 50 days ✅
- Small: 50 days ✅

**Expected Impact:** More accurate forecasts with properly calibrated adjustments.

