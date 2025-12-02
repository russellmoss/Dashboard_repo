# SGA/SGM Filter Analysis & Recommendations

**Date**: October 30, 2025  
**Issue**: Should we refine the active SGA/SGM filter to account for role-specific conversion rates?

---

## 🔍 Current Status

**What we're already doing RIGHT** ✅:
1. Filter for **active** SGA/SGM only: `WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE`
2. Apply this filter in `trailing_rates_features`, `vw_sga_funnel_team_agg`, and all views
3. Handle "Savvy Marketing" reassignment in some views (reassign to opportunity owner)

**Current Active Team**:
- **14 SGAs**: 13 individuals + "Savvy Marketing" (should be excluded)
- **10 SGMs**: All active individuals
- **Total**: 24 active team members

---

## ⚠️ Issues Found

### 1. "Savvy Marketing" Not Explicitly Excluded

**Problem**: "Savvy Marketing" appears in the active SGA list, but should be excluded per your guidance.

**Current Filter**:
```sql
WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE
```

**Should Be**:
```sql
WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) 
  AND IsActive = TRUE
  AND Name NOT IN ('Savvy Marketing', 'Savvy Operations')
```

**Impact**: Low - We already handle "Savvy Marketing" via opportunity owner reassignment in many views.

### 2. Role Separation Not Required

**Question**: Should we separate SGA vs SGM for conversion rate calculations?

**Answer**: **NO** ✅

**Why**:
1. Conversion rates are already **segment-specific** (channel + source)
2. SGA/SGM distinction is **not a meaningful predictor** at the aggregate level
3. Segments already capture performance variations
4. Most SQL → SQO transitions are **already handled by SGMs** (168 SQOs vs 9 SGA SQOs)
5. Mixing both roles in models provides **more training data** and **better generalization**

**Evidence**:
- SGM SQL→SQO conversion: **58.7%** (168 SQOs / 286 SQLs)
- SGA SQL→SQO conversion: **81.8%** (9 SQOs / 11 SQLs) - but **only 11 SQLs**, too small
- Overall SQL→SQO conversion: **60%** (matches our forecast)

**Conclusion**: Keep using **combined** active SGA/SGM filter.

---

## ✅ Recommended Actions

### Action 1: Add Explicit Exclusion for "Savvy Marketing" and "Savvy Operations"

**Where**: Update `Active_SGA_SGM_Users` CTE in:
- `vw_sga_funnel_team_agg.sql`
- `vw_sga_funnel.sql`
- Any other views that filter users
- `trailing_rates_features` table definition

**Change**:
```sql
-- BEFORE
WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE

-- AFTER
WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) 
  AND IsActive = TRUE
  AND Name NOT IN ('Savvy Marketing', 'Savvy Operations')
```

**Priority**: **Medium** - Data quality improvement, but low impact due to existing reassignment logic

### Action 2: Document the Filter Logic

Add a comment explaining why we use both SGA and SGM:
```sql
-- Active SGA/SGM Users (excluding Savvy Marketing and Savvy Operations)
-- SGAs handle: Contacted → MQL → SQL
-- SGMs handle: SQL → SQO → Joined
-- Both included for training data volume and segment-specific rates capture performance
```

**Priority**: **Low** - Documentation improvement

---

## 🎯 Bottom Line

**Current Status**: ✅ **Mostly correct**

**Needed Changes**:
1. Add explicit exclusion for "Savvy Marketing" and "Savvy Operations" (medium priority)
2. Keep using **combined** SGA/SGM filter (no change needed)

**Why Combined Filter is Better**:
- More training data for models
- Segment-specific rates already capture performance differences
- Role distinction doesn't meaningfully improve forecast accuracy
- Current approach is working (60% conversion rate validated)

---

## 📋 Implementation Checklist

- [ ] Update `vw_sga_funnel_team_agg.sql` to exclude "Savvy Marketing"
- [ ] Update `vw_sga_funnel.sql` to exclude "Savvy Marketing"
- [ ] Update `trailing_rates_features` table creation to exclude "Savvy Marketing"
- [ ] Verify other views use correct filter
- [ ] Test that "Savvy Marketing" records are properly reassigned
- [ ] Validate conversion rates remain stable after exclusion
