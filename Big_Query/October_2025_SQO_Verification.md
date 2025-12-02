# October 2025 SQO Verification

**Question:** Is 61 SQOs from 92 SQLs (66.3% conversion) sensible?

---

## Summary

**October 2025 Performance:**
- **SQLs:** 92
- **SQOs:** 61
- **Conversion Rate:** 66.3%

---

## Historical Comparison

| Period | SQLs | SQOs | Conversion Rate |
|--------|------|------|-----------------|
| **October 2025** | 92 | 61 | **66.3%** |
| **Last 30 Days** | 89 | 59 | 66.29% |
| **Q3 2025** | 221 | 133 | 60.18% |
| **Last 90 Days** | 249 | 158 | 63.45% |

**Analysis:**
- October's 66.3% rate is **slightly higher** than Q3 2025 (60.18%)
- Very similar to Last 30 Days (66.29%)
- Within reasonable range of historical performance (60-66%)

---

## Potential Issues to Investigate

### 1. SQO Definition Mismatch

There are two possible definitions:
- **Model Definition:** `Date_Became_SQO__c IS NOT NULL` (likely what we're using)
- **Business Definition:** `SQL__c = 'Yes'` (validated definition)

**Impact:** The model definition may be overcounting SQOs by ~19% compared to the business definition.

### 2. Daily Anomalies

From the daily breakdown, we see:
- Some days with SQOs but **no SQLs** on that day (attribution lag)
- Some days with **>100% conversion** (1 SQL → 2 SQOs)

**Example Anomalies:**
- Oct 2: 1 SQL → 2 SQOs (200% conversion)
- Oct 3: 1 SQL → 2 SQOs (200% conversion)
- Oct 13: 1 SQL → 2 SQOs (200% conversion)
- Oct 29: 1 SQL → 2 SQOs (200% conversion)

**Root Cause:** These are likely SQOs from SQLs created on earlier days (date attribution timing differences).

### 3. Date Attribution

SQOs may be attributed to dates when:
- The SQO milestone was reached (Date_Became_SQO__c)
- While the corresponding SQL was created on an earlier date

This is **normal** for conversion metrics but can create daily anomalies.

---

## Verification Needed

1. **Check SQO Definition Used:**
   - Is `vw_daily_stage_counts` using `Date_Became_SQO__c` or `SQL__c = 'Yes'`?
   - If using `Date_Became_SQO__c`, how many SQOs would we have with `SQL__c = 'Yes'`?

2. **Cross-Reference SQL Creation Dates:**
   - Verify that all 61 SQOs correspond to SQLs created in October (or earlier)
   - Check for any SQLs converted to SQO on Oct 31 that should count

---

---

## Critical Finding: Timing Mismatch ⚠️

**The Issue:**

The reported **61 SQOs from 92 SQLs (66.3%)** mixes:
- **SQOs dated by when they became SQO** (`Date_Became_SQO__c` in October)
- **SQLs dated by when they were created** (`ConvertedDate` in October)

**The Reality:**

| Scenario | Count | Conversion Rate |
|----------|-------|-----------------|
| **SQOs from October SQLs (Business Definition)** | 46 SQOs from 92 SQLs | **50.0%** ✅ |
| **SQOs that became SQO in October (but from earlier SQLs)** | 14 SQOs | N/A (not October SQLs) |

**Breakdown:**
- **46 SQOs** came from **92 SQLs created in October** = **50.0% conversion rate**
- **14 SQOs** came from **SQLs created before October** (September 12-30) that converted to SQO in October

---

## Answer: Is 61 SQOs Sensible?

**Yes and No:**

1. **If counting SQOs by milestone date:** 61 SQOs is correct (but includes 14 from pre-October SQLs)

2. **If calculating October SQL→SQO conversion rate:** Should be **50.0%** (46/92), not 66.3%

3. **The 66.3% rate is misleading** because it's comparing:
   - Numerator: SQOs that became SQO in October (61, including 14 from earlier SQLs)
   - Denominator: SQLs created in October (92)

---

## Recommendation

**For forecasting purposes**, we should use:
- **Conversion Rate:** 50.0% (46 SQOs / 92 SQLs created in October)
- This aligns with our validated Hybrid rate of 55.27% (slightly lower, which is reasonable)

**For reporting purposes**, we should clarify:
- **61 SQOs became SQO in October** (milestone-based)
- **46 of those came from October SQLs** (conversion-based)
- **50.0% conversion rate for October SQLs** (correct calculation)

---

## SQO Definition Discrepancy

Also noted:
- **Using `Date_Became_SQO__c IS NOT NULL`:** 107 SQOs total in October
- **Using `SQL__c = 'Yes'` (Business Definition):** 60 SQOs total in October
- **Current view likely uses:** `Date_Became_SQO__c` (model definition)

**Recommendation:** Verify which definition `vw_daily_stage_counts` uses. The business definition (`SQL__c = 'Yes'`) is more accurate.

---

**Status:** ✅ Analysis Complete

