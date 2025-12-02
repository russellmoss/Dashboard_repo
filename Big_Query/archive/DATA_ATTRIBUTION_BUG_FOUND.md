# 🚨 Critical Data Attribution Bug Found

**Date**: October 30, 2025  
**Issue**: SQO counts are incorrectly attributed to wrong dates  
**Impact**: **HIGH** - Affects conversion rate calculations and forecast accuracy

---

## 🔍 The Problem

**You reported**: 53 SQOs in October 2025  
**Model is seeing**: 28 SQOs in October 2025  
**Gap**: 25 SQOs missing (47% undercount!)

---

## 🎯 Root Cause Analysis

### What We're Doing Wrong

The `trailing_rates_features` table (used for conversion rate calculations) groups SQOs by `FilterDate` instead of `Date_Became_SQO__c`:

```sql
-- CURRENT (WRONG) - from ARIMA_PLUS_Implementation.md line 798-801
FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
WHERE DATE(FilterDate) >= '2023-05-01'  -- ❌ WRONG DATE!
GROUP BY 1, 2, 3  -- Groups by FilterDate
```

**The Bug**: `FilterDate` is a fallback chain that uses:
1. Lead FilterDate (from contacting stage)
2. Opportunity Created Date
3. Date_Became_SQO__c (fallback 3rd)
4. Advisor Join Date

For SQOs, `FilterDate` often falls back to the lead's contacted date or opportunity created date, **NOT the SQO date**.

### What Should Happen

According to `vw_actual_vs_forecast_by_source.sql`:
```sql
-- SQO data (use Date_Became_SQO__c as the date)
SELECT
  DATE(Date_Became_SQO__c) AS date_day,  -- ✅ CORRECT
  COUNT(CASE WHEN is_sqo = 1 THEN 1 END) AS sqo_actual
FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
WHERE Date_Became_SQO__c IS NOT NULL
GROUP BY 1, 2, 3
```

**Correct Logic**: Use `Date_Became_SQO__c` as the attribution date for SQOs.

---

## 📊 Evidence

### October 2025 SQO Counts by Date Field

| Date Field Used | Count | Status |
|----------------|-------|--------|
| `Date_Became_SQO__c` | **53** | ✅ Correct (your data) |
| `FilterDate` | **28** | ❌ Wrong (model sees this) |
| Gap | **-25** | ❌ 47% undercount |

---

## 🔧 The Fix Needed

### Option 1: Fix `trailing_rates_features` Table (Recommended)

Modify the `trailing_rates_features` calculation to use proper stage-specific dates:

```sql
-- FIXED daily_progressions CTE
daily_progressions AS (
  SELECT
    -- Use FilterDate for contacted/mql/sql (early stages)
    DATE(FilterDate) AS date_day,  -- ✅ Correct for early stages
    Channel_Grouping_Name,
    Original_source,
    
    -- Denominators
    COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN primary_key END) AS contacted_denom,
    COUNT(DISTINCT CASE WHEN is_mql = 1 THEN primary_key END) AS mql_denom,
    COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END) AS sql_denom,
    
    -- FIXED: Use Date_Became_SQO__c for SQO attribution
    DATE(Date_Became_SQO__c) AS sqo_date_day,  -- ✅ NEW: Separate date for SQOs
    
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END) AS sqo_denom,
    
    -- Numerators
    COUNT(DISTINCT CASE WHEN is_contacted = 1 AND is_mql = 1 THEN primary_key END) AS contacted_to_mql,
    COUNT(DISTINCT CASE WHEN is_mql = 1 AND is_sql = 1 THEN primary_key END) AS mql_to_sql,
    COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 THEN Full_Opportunity_ID__c END) AS sql_to_sqo,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_joined = 1 THEN Full_Opportunity_ID__c END) AS sqo_to_joined
    
  FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
  INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
  WHERE DATE(FilterDate) >= '2023-05-01'
    OR Date_Became_SQO__c IS NOT NULL  -- Include SQOs with any date
  GROUP BY 1, 2, 3, 4  -- Now groups by both FilterDate AND sqo_date_day
)
```

**Then**, the SQL→SQO conversion rate calculation needs to join on the correct date:

```sql
-- FIXED: Calculate rates using SQO-specific dates
date_calculations AS (
  SELECT 
    DATE(FilterDate) AS date_day,  -- Date dimension for daily tracking
    ...
    -- SUM SQL→SQO progressions by SQO date
    SUM(CASE WHEN DATE_DIFF(CURRENT_DATE(), sqo_date_day, DAY) <= 60 THEN sql_to_sqo END) AS s2q_num_60d,
    SUM(CASE WHEN DATE_DIFF(CURRENT_DATE(), sqo_date_day, DAY) <= 60 THEN sql_denom END) AS s2q_den_60d,
    ...
)
```

### Option 2: Switch to `vw_funnel_lead_to_joined_v2`

**Better approach**: Use the already-correct `vw_funnel_lead_to_joined_v2` instead of `vw_funnel_enriched`:

```sql
-- Use the working view
FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` f
WHERE DATE(Date_Became_SQO__c) >= '2023-05-01'  -- ✅ Correct
```

This view already has proper date fields separated (`filter_date`, `mql_date`, `sql_date`, `sqo_date`, `joined_date`).

---

## 🎯 Impact Assessment

### Current (Broken) State
- **October SQOs**: 28 (actual: 53) - 47% undercount
- **Conversion rates**: Calculated on wrong dates
- **Forecast accuracy**: Severely compromised

### After Fix
- **October SQOs**: 53 (correct)
- **Conversion rates**: Accurate stage-specific dates
- **Forecast accuracy**: Should improve significantly

---

## ✅ Recommendation

**IMMEDIATE ACTION REQUIRED**:
1. **Rebuild `trailing_rates_features`** using stage-specific dates
2. **Use `Date_Became_SQO__c`** for SQO attribution (not FilterDate)
3. **Regenerate conversion rates** from corrected data
4. **Retrain models** with corrected rates
5. **Regenerate production forecast**

This is a **critical data quality issue** that affects the entire forecasting system.
