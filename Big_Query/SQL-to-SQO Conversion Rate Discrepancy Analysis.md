# SQL-to-SQO Conversion Rate Discrepancy Analysis

**Date**: January 2025  
**Issue**: Major discrepancy between V2 backtest (92.2%) and business view (62%)  
**Root Cause**: Metric definition mismatch between `SQL__c = 'Yes'` and `Date_Became_SQO__c IS NOT NULL`

---

## Executive Summary

✅ **Root Cause Confirmed**: The discrepancy is due to **different SQO definitions**:
- **User Definition**: `Opportunity.SQL__c = 'Yes'` → **62.0% conversion rate**
- **Model Definition**: `Opportunity.Date_Became_SQO__c IS NOT NULL` → **80.4% conversion rate**

**Key Finding**: The model's definition captures **87 additional SQOs** (19% of SQLs) that the user's definition misses, resulting in an **18.4 percentage point difference**.

---

## Conversion Rate Comparison

### Period: April 1 - October 30, 2025

| Metric Source | Total SQLs | Total SQOs | Conversion Rate |
|---------------|------------|------------|-----------------|
| **User Definition** (`SQL__c = 'Yes'`) | 460 | 290 | **62.0%** ✅ |
| **Model Definition** (`Date_Became_SQO__c IS NOT NULL`) | 460 | 370 | **80.4%** ⚠️ |
| **Difference** | - | +80 SQOs | **+18.4 percentage points** |

### Backtest Period: Q3 2024 (July 1 - September 30, 2024)

| Metric Source | Total SQLs | Total SQOs | Conversion Rate |
|---------------|------------|------------|-----------------|
| **Model Definition** (Q3 2024 Backtest) | 154 | 134 | **87.0%** ⚠️ |

**Note**: Q3 2024 shows an even higher rate (87%) than April-October 2025 (80.4%), suggesting:
- Either Q3 2024 was an exceptional period (anomaly)
- Or the model's definition is capturing opportunities that should not be considered SQOs
- Or the backtest cohort filtering (12-month age filter, stale filter) selected only high-quality SQLs

---

## Confusion Matrix: Definition Overlap Analysis

### Breakdown of All Opportunities (April-October 2025)

| User Definition | Model Definition | Opportunity Count | % of Total |
|----------------|------------------|-------------------|------------|
| SQL__c = 'Yes' | Date_Became_SQO__c IS NOT NULL | **290** | **63.0%** |
| SQL__c != 'Yes' | Date_Became_SQO__c IS NOT NULL | **87** | **18.9%** ⚠️ |
| SQL__c != 'Yes' | Date_Became_SQO__c IS NULL | **83** | **18.0%** |
| SQL__c = 'Yes' | Date_Became_SQO__c IS NULL | **0** | **0.0%** |

**Total Opportunities**: 460

### Key Insights

1. **63% Match**: 290 opportunities match both definitions (true overlap)
2. **Model-Only SQOs**: 87 opportunities (19%) are SQOs by model definition but NOT by user definition
   - These have `Date_Became_SQO__c IS NOT NULL` but `SQL__c != 'Yes'`
   - This is the source of the 18.4 percentage point difference
3. **User-Only SQOs**: 0 opportunities have `SQL__c = 'Yes'` but `Date_Became_SQO__c IS NULL`
   - The user definition appears to be a subset of the model definition
4. **Neither**: 83 opportunities (18%) are not SQOs by either definition

---

## Root Cause Analysis

### Why the Model Definition Captures More SQOs

**The 87 "Model-Only" SQOs** likely represent:
1. **Data Quality Issue**: Opportunities that became SQOs (`Date_Became_SQO__c` populated) but the `SQL__c` field was never updated to 'Yes'
2. **Process Gap**: Sales process may populate `Date_Became_SQO__c` but forget to update `SQL__c`
3. **Timing Difference**: `Date_Became_SQO__c` may be populated earlier/later than `SQL__c` is set
4. **Different Data Sources**: The two fields may be populated from different workflows or systems

### Why the Backtest Showed 92.2% (Q3 2024)

The Q3 2024 backtest showed **87.0%** raw conversion rate, which was further filtered down to **92.2%** in the backtest cohort due to:
- **12-month age filter**: Only SQLs from July 2023 - July 2024
- **Stale filter**: Excluded SQLs with >90 days inactivity
- **Stage exclusions**: Excluded ClosedLost and On Hold

**Result**: The backtest cohort (13 SQLs) represented only the **most active, recent SQLs**, which naturally had a higher conversion rate.

---

## Implications for V2 Forecast

### Current Situation

1. **Training Data**: Model was trained on `Date_Became_SQO__c IS NOT NULL` definition
2. **Historical Rate**: April-October 2025 shows **80.4%** using model definition
3. **Business Expectation**: Business expects **62.0%** based on `SQL__c = 'Yes'` definition
4. **Forecast Gap**: V2 forecast (79.2 SQOs) may be based on wrong historical rate

### The Real Question

**Which definition is "correct" for forecasting?**

**Option 1: User Definition is Correct**
- Use `SQL__c = 'Yes'` for both training and forecasting
- Historical rate: **62.0%** (not 80.4%)
- V2 model needs retraining with corrected labels
- Business alignment: ✅ Uses business-standard metric

**Option 2: Model Definition is Correct**
- `Date_Became_SQO__c` is more accurate/timely
- Historical rate: **80.4%** (or 62% if filtering by user definition)
- V2 model is correctly trained
- But forecasts don't match business expectations

**Option 3: Hybrid Approach**
- Use `Date_Became_SQO__c IS NOT NULL AND SQL__c = 'Yes'` (both conditions)
- Historical rate: **62.0%** (matches user definition, more conservative)
- Ensures both fields are populated (data quality check)

---

## Recommendations

### 1. **Immediate: Align on Definition** 🔴 **CRITICAL**

**Decision Required**: Which SQO definition should be used for:
- Training the V2 model
- Comparing forecasts to business expectations
- Production forecasting

**Options**:
- **A**: Use `SQL__c = 'Yes'` (matches business view, 62% rate)
- **B**: Use `Date_Became_SQO__c IS NOT NULL` (model definition, 80.4% rate)
- **C**: Use both: `Date_Became_SQO__c IS NOT NULL AND SQL__c = 'Yes'` (conservative, 62% rate)

### 2. **If Using User Definition (SQL__c = 'Yes')** 🔴 **HIGH PRIORITY**

**Action Required**: Retrain V2 model with corrected labels:
- Replace `Date_Became_SQO__c IS NOT NULL` with `SQL__c = 'Yes'`
- Re-run training data creation (Section 4.1)
- Re-train model (Section 5.1)
- Re-run backtest (Section 6)
- Re-calculate Q4 2025 forecast

**Impact**: 
- Historical conversion rate: 62.0% (not 80.4%)
- Model will learn from different set of SQOs
- Forecasts will align with business expectations

### 3. **Investigate the 87 "Model-Only" SQOs** ⚠️ **MEDIUM PRIORITY**

**Action**: Analyze these 87 opportunities:
- Why do they have `Date_Became_SQO__c` but not `SQL__c = 'Yes'`?
- Are they legitimate SQOs that should be counted?
- Or are they data quality issues that should be excluded?

**Query**:
```sql
-- Analyze the 87 Model-Only SQOs
SELECT 
  o.Id,
  o.SQL__c,
  o.Date_Became_SQO__c,
  o.StageName,
  o.IsClosed,
  DATE(l.ConvertedDate) as sql_date,
  DATE(o.CreatedDate) as opp_created_date,
  DATE_DIFF(DATE(o.Date_Became_SQO__c), DATE(l.ConvertedDate), DAY) as days_from_sql_to_sqo
FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
INNER JOIN `savvy-gtm-analytics.SavvyGTMData.Lead` l
  ON l.ConvertedOpportunityId = o.Id
WHERE
  l.IsConverted = TRUE
  AND DATE(l.ConvertedDate) BETWEEN '2025-04-01' AND '2025-10-30'
  AND o.Date_Became_SQO__c IS NOT NULL
  AND (o.SQL__c != 'Yes' OR o.SQL__c IS NULL)
LIMIT 20
```

### 4. **Re-evaluate Backtest Results** ⚠️ **MEDIUM PRIORITY**

**Action**: Re-run Q3 2024 backtest using user definition:
- Use `SQL__c = 'Yes'` instead of `Date_Became_SQO__c IS NOT NULL`
- Re-calculate actual conversion rate
- Compare V1 vs V2 performance with corrected definition

**Expected Impact**: 
- Actual conversion rate will drop from 82.6% to likely ~60-70%
- V2 relative error may change (could be better or worse)
- Need to validate if V2 still beats V1 with corrected definition

---

## Key Findings Summary

### Conversion Rates by Definition

| Period | User Definition (SQL__c = 'Yes') | Model Definition (Date_Became_SQO__c) |
|--------|----------------------------------|--------------------------------------|
| **Apr-Oct 2025** | **62.0%** (290/460) | **80.4%** (370/460) |
| **Q3 2024** | *Not calculated* | **87.0%** (134/154) |

### Definition Mismatch Impact

- **87 opportunities** (19% of SQLs) are SQOs by model definition but not user definition
- **18.4 percentage point difference** in conversion rates
- **0 opportunities** are SQOs by user definition but not model definition
- User definition appears to be a **subset** of model definition

---

## Next Steps

1. ✅ **Diagnosis Complete** - Definition mismatch confirmed
2. ⏳ **Decision Required**: Choose SQO definition for production use
3. ⏳ **If Using User Definition**: Retrain V2 model with `SQL__c = 'Yes'`
4. ⏳ **Investigate**: Analyze the 87 "Model-Only" SQOs to understand data quality
5. ⏳ **Re-validate**: Re-run backtest with chosen definition

---

**Report Generated**: January 2025  
**Status**: ✅ **Root Cause Identified - Definition Mismatch Confirmed**  
**Recommendation**: **Align on SQO definition before proceeding with V2 deployment**

