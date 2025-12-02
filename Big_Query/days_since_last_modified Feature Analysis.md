# `days_since_last_modified` Feature Signal Analysis

**Feature**: `days_since_last_modified`  
**Attribution**: 70.8% (Top feature, #1)  
**Calculation**: `DATE_DIFF(bs.sql_date, DATE(bs.LastModifiedDate), DAY)`  
- Where `sql_date` = Lead conversion date (`Lead.ConvertedDate`)
- Where `LastModifiedDate` = Opportunity last modified date

---

## Distribution Analysis: SQOs vs Non-SQOs

| Metric | Non-SQOs (label=0) | SQOs (label=1) | Difference | Signal Strength |
|--------|-------------------|----------------|------------|-----------------|
| **Count** | 185 | 1,857 | - | - |
| **Mean** | **-12.5 days** | **-333.6 days** | **-321.1 days** | 🔴 **VERY STRONG** |
| **Median** | **-7 days** | **-314 days** | **-307 days** | 🔴 **VERY STRONG** |
| **StdDev** | 20.1 days | 244.9 days | - | Higher variance in SQOs |
| **Min** | -106 days | -813 days | - | - |
| **P25** | -13 days | -528 days | -515 days | - |
| **P50 (Median)** | -7 days | -314 days | -307 days | - |
| **P75** | 0 days | -101 days | -101 days | - |
| **Max** | 0 days | 0 days | - | - |

---

## Key Findings

### 🔴 **CRITICAL DISCOVERY: Negative Values Dominance**

**All values are negative or zero (0)**:
- **Non-SQOs**: Mean = -12.5 days, Median = -7 days
- **SQOs**: Mean = -333.6 days, Median = -314 days

**Interpretation**:
- **Negative values** indicate that `LastModifiedDate` is **AFTER** the `sql_date` (Lead conversion date)
- This means: Opportunities were modified **AFTER** the Lead was converted
- **SQOs show much more negative values** (-333 days mean) vs Non-SQOs (-12.5 days mean)

### 📊 **Signal Analysis**

**What This Means**:
1. **SQOs**: Opportunities that became SQOs were last modified an average of **333 days AFTER** Lead conversion
   - This suggests SQOs come from opportunities that were **already active** and continued to be modified/worked after the Lead converted
   - These are likely **existing opportunities** that received converted leads

2. **Non-SQOs**: Opportunities that didn't become SQOs were last modified only **12.5 days after** Lead conversion on average
   - This suggests non-SQOs are **newer opportunities** from recent Lead conversions that didn't progress

**The Signal**: 
- **Opportunities with more recent modifications AFTER Lead conversion → More likely to become SQOs**
- **OR**: **Opportunities that were modified much earlier (before conversion) but converted later → More likely to become SQOs**

### ⚠️ **Data Quality Concern**

**All Max Values Are 0**:
- Both SQOs and non-SQOs have `max_days = 0`
- This suggests no opportunities have `LastModifiedDate` **before** `sql_date` (which would give positive values)
- **Possible Explanation**: All opportunities in training data have `LastModifiedDate >= sql_date`, meaning they were all modified on or after Lead conversion

### 📈 **Bucket Analysis**

**All records fall in "0 or Negative" bucket**:
- **Total**: 2,042 records (100%)
- **SQOs**: 1,857 (100% of SQOs)
- **Conversion Rate**: 90.9% (matches overall distribution)
- **Mean days**: -304.5 days

**Distribution**:
- **Non-SQOs**: 50 have 0 days, 135 have negative days (73% negative)
- **SQOs**: 3 have 0 days, 1,854 have negative days (99.8% negative)

---

## Why This Feature Has 70.8% Attribution

**The model learned a critical pattern**:
- **SQOs**: Almost always have large negative values (median: -314 days)
- **Non-SQOs**: Tend to have smaller negative values or zero (median: -7 days)

**This is a very clean separation**:
- The feature cleanly separates SQOs from non-SQOs based on how far in the past the last modification was relative to Lead conversion
- **SQOs**: "Old" opportunities (modified 314+ days after conversion) → High conversion
- **Non-SQOs**: "Recent" opportunities (modified <13 days after conversion) → Low conversion

---

## Validation of Calculation

**Calculation Verification**:
```sql
DATE_DIFF(bs.sql_date, DATE(bs.LastModifiedDate), DAY)
```

**Where**:
- `sql_date` = `DATE(l.ConvertedDate)` (Lead conversion date)
- `LastModifiedDate` = Opportunity last modified timestamp

**Expected Behavior**:
- If `LastModifiedDate` > `sql_date` → Negative value (modified after Lead conversion)
- If `LastModifiedDate` < `sql_date` → Positive value (modified before Lead conversion)

**Actual Behavior**:
- All values are negative or zero → All opportunities were modified on or after Lead conversion date
- This aligns with business logic: Opportunities are typically created/modified when Leads convert

---

## Business Interpretation

### Hypothesis: "Opportunity Age Signal"

The feature may be capturing **opportunity maturity** rather than "days since last modification":

1. **SQOs**: Opportunities that became SQOs tend to be from **older Lead conversions** where the Opportunity continued to be worked on for 300+ days after conversion
   - These represent opportunities that stayed in pipeline and eventually converted
   - The large negative values suggest these opportunities existed for a long time and were actively worked

2. **Non-SQOs**: Opportunities that didn't convert were **recently created** (12.5 days on average) and haven't progressed
   - These are newer opportunities that haven't had time to mature or convert
   - Smaller negative values suggest these are fresh opportunities

### Alternative Hypothesis: "Data Leakage Risk"

⚠️ **CRITICAL CONCERN**: If `LastModifiedDate` includes modifications that happen **AFTER** the SQL date, this could be capturing future information:
- If an Opportunity was modified AFTER becoming an SQO, those modifications wouldn't be knowable at prediction time
- This would be a form of **data leakage**

**Validation Needed**: 
- Verify that `LastModifiedDate` used in calculation is truly "last modified date as of SQL date", not current LastModifiedDate
- Check if the training data correctly filters to only use modifications that occurred on or before `sql_date`

---

## Recommendations

### ✅ **If Calculation is Correct (Point-in-Time)**:

The feature is valid and provides strong predictive signal:
- ✅ **Keep the feature** - it captures opportunity maturity/activity patterns
- ✅ **Proceed to backtesting** - signal is valid

### ⚠️ **If Calculation Has Data Leakage**:

The feature may be using future information:
- ❌ **Remove or recalculate** - must ensure `LastModifiedDate` is as of SQL date only
- ⚠️ **Recalculate training data** - filter OpportunityFieldHistory to only include modifications ≤ `sql_date`

---

## Next Steps

1. **Verify Point-in-Time Calculation**: Confirm that `LastModifiedDate` in training data represents last modification **as of SQL date**, not current date
2. **If Valid**: Proceed to Phase 3 (Backtesting) - feature signal is strong and legitimate
3. **If Data Leakage Found**: Recalculate training table with correct point-in-time filtering

---

## 🔴 **CRITICAL FINDING: Potential Data Leakage**

### Calculation Review

**Current Calculation** (line 502 in training query):
```sql
DATE_DIFF(bs.sql_date, DATE(bs.LastModifiedDate), DAY) as days_since_last_modified
```

**Where**:
- `bs.sql_date` = `DATE(l.ConvertedDate)` (Lead conversion date)
- `bs.LastModifiedDate` = `o.LastModifiedDate` from Opportunity table (line 339)

**Issue**: `o.LastModifiedDate` is the **current** LastModifiedDate from the Opportunity table, not the LastModifiedDate **as of SQL date**. This means:

- ✅ **For Historical SQLs**: If the Opportunity was last modified in 2023 and sql_date is 2024, we get negative values (valid - modification was before Lead conversion)
- ⚠️ **For Recent SQLs**: If the Opportunity was modified TODAY (after Lead conversion), we're using FUTURE information that wouldn't be knowable at prediction time

### Data Leakage Assessment

**Evidence**:
- All values are negative, indicating `LastModifiedDate` is always AFTER `sql_date`
- SQOs show mean -333 days (Opportunity modified 333 days AFTER Lead conversion)
- Non-SQOs show mean -12.5 days (Opportunity modified 12.5 days AFTER Lead conversion)

**Interpretation**:
- **SQOs**: Opportunities that converted had many post-conversion modifications (333 days after Lead conversion) - this could be modifications that happened AFTER the SQL became an SQO
- **Non-SQOs**: Opportunities that didn't convert had fewer post-conversion modifications (12.5 days after)

**Risk Level**: 🔴 **HIGH** - If modifications that happened AFTER Lead conversion (or AFTER becoming SQO) are being used, this is data leakage.

### Correct Calculation Needed

**Should Be**: LastModifiedDate **as of SQL date**, filtered from OpportunityFieldHistory:
```sql
-- Pseudo-code for correct calculation
WITH last_modified_as_of_sql AS (
  SELECT 
    OpportunityId,
    MAX(CreatedDate) as last_modified_date_as_of_sql
  FROM OpportunityFieldHistory
  WHERE CreatedDate <= sql_date
  GROUP BY OpportunityId
)
-- Then calculate:
DATE_DIFF(bs.sql_date, DATE(lm.last_modified_date_as_of_sql), DAY) as days_since_last_modified
```

---

**Status**: 🔴 **DATA LEAKAGE RISK CONFIRMED** - Feature calculation uses current LastModifiedDate, not point-in-time. Must recalculate using OpportunityFieldHistory filtered to ≤ sql_date before proceeding to backtesting.
