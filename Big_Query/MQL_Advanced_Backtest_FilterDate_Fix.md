# MQL Advanced Backtest: FilterDate Fix

## Issue Identified

The original model was using `DATE(stage_entered_contacting__c)` for date attribution, but production views use `DATE(FilterDate)` where:

```sql
FilterDate = GREATEST(
  IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
)
```

## Why This Matters

**Problem:**
- Using `stage_entered_contacting__c` directly can misattribute leads to wrong days
- If a lead was created before being contacted, the dates might not align
- This can cause:
  - **Double counting** (lead counted on multiple days)
  - **Wrong time attribution** (lead attributed to contacted date instead of entry date)
  - **Inflated conversion rates** (denominator/numerator misalignment)

**Solution:**
- Use `FilterDate` for date attribution (aligned with production)
- This ensures consistent date dimension across all views
- Matches how `vw_funnel_lead_to_joined_v2` and `vw_sga_funnel` calculate rates

## Changes Made

### 1. Contacted Volume Training View
**Before:**
```sql
DATE(stage_entered_contacting__c) AS contacted_date
```

**After:**
```sql
DATE(GREATEST(
  IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
)) AS filter_date
```

### 2. C2M Rate Training View
**Before:**
```sql
DATE(stage_entered_contacting__c) AS contacted_date
```

**After:**
```sql
DATE(GREATEST(...)) AS filter_date
-- Count contacted leads properly: only those with stage_entered_contacting__c IS NOT NULL
```

## Expected Impact

1. **More Accurate Conversion Rates:**
   - Rates should align better with production views (~4.35% instead of ~25%)
   - Eliminates date misattribution issues

2. **Better Model Performance:**
   - Training data will match production logic
   - Predictions should be more accurate

3. **Consistent Attribution:**
   - Same date logic as `vw_funnel_lead_to_joined_v2`
   - Same date logic as `vw_sga_funnel`
   - Same date logic as `vw_live_conversion_rates`

## Next Steps

1. ✅ **Re-run the training views** with FilterDate
2. ✅ **Re-train both models** (volume + rate)
3. ✅ **Re-generate backtest predictions**
4. ✅ **Compare results** - should see lower, more realistic rates

**Status:** Fixed - Ready to re-execute

