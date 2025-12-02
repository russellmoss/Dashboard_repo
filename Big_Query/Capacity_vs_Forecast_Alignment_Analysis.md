# Capacity vs Forecast Alignment Analysis

## Overview

This document explains the relationship between:
1. **Capacity Estimate** (`sgm_capacity_expected_joined_aum_millions_estimate`) - from `vw_sgm_capacity_coverage`
2. **Quarterly Forecasts** (`expected_to_join_this_quarter_margin_aum_millions`, `expected_to_join_next_quarter_margin_aum_millions`) - from `vw_sgm_capacity_coverage_with_forecast`

## Key Metrics Comparison

### Capacity Estimate (Total Pipeline)
```
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_active_weighted_margin_aum_estimate × 
  effective_sqo_to_joined_conversion_rate
```

**What it represents:**
- **Total expected joined AUM from ALL active pipeline**
- **No time component** - doesn't specify when deals will close
- **All deals** that are active (non-stale, ≤120 days old)

### Quarterly Forecasts (Time-Split Pipeline)
```
expected_to_join_this_quarter_margin_aum_millions = 
  (Pipeline deals projected THIS quarter) × conversion_rate

expected_to_join_next_quarter_margin_aum_millions = 
  (Pipeline deals projected NEXT quarter) × conversion_rate
```

**What they represent:**
- **Expected joined AUM split by WHEN deals will close**
- **This Quarter**: Deals projected to close in current quarter
- **Next Quarter**: Deals projected to close in next quarter
- **Beyond Next Quarter**: Not explicitly tracked (but included in total capacity)

## Relationship

### Mathematical Relationship
```
Total Capacity = This Quarter Forecast + Next Quarter Forecast + Beyond Next Quarter
```

**In practice:**
- `sgm_capacity_expected_joined_aum_millions_estimate` = **Total capacity** (all deals)
- `expected_to_join_this_quarter_margin_aum_millions` = **This quarter portion**
- `expected_to_join_next_quarter_margin_aum_millions` = **Next quarter portion**
- **Difference** = Deals projected beyond next quarter (not explicitly tracked)

### Alignment Check

The views **ARE aligned** because:

1. **Same base data**: Both use `current_pipeline_active_weighted_margin_aum_estimate`
2. **Same conversion rate**: Both use `effective_sqo_to_joined_conversion_rate`
3. **Same filtering**: Both exclude stale deals (>120 days)
4. **Same weighting**: Both use stage probabilities

**The only difference:**
- Capacity estimate: **No time split** (all deals together)
- Quarterly forecasts: **Time split** (deals grouped by projected close date)

## Use Cases

### When to Use Capacity Estimate
- **Overall capacity planning**: "Does this SGM have enough pipeline?"
- **Coverage ratio**: "Are they at/above/below target capacity?"
- **Long-term planning**: "What's their total expected capacity?"

### When to Use Quarterly Forecasts
- **Short-term planning**: "What do we expect this quarter vs next quarter?"
- **Quarterly targets**: "Will they hit their $36.75M target this quarter?"
- **Pipeline timing**: "When will deals close?"

## Total Expected Current Quarter

The `total_expected_current_quarter_margin_aum_millions` field is **different** from capacity:

```
Total Expected Current Quarter = 
  Actual Joined This Quarter (already happened) + 
  Forecast from Pipeline (rest of quarter)
```

**This is NOT the same as capacity because:**
- Capacity = **Only pipeline** (future deals)
- Total Expected = **Actuals + Pipeline** (complete quarter picture)

## Example

**SGM Example:**
- **Total Capacity**: $50M (all active pipeline)
- **This Quarter Forecast**: $20M (from pipeline)
- **Next Quarter Forecast**: $25M (from pipeline)
- **Beyond Next Quarter**: $5M (difference, not explicitly tracked)
- **Actual Joined This Quarter**: $15M (already happened)
- **Total Expected Current Quarter**: $35M ($15M actuals + $20M forecast)

## Alignment Verification

To verify alignment, run:
```sql
SELECT 
  sgm_name,
  sgm_capacity_expected_joined_aum_millions_estimate AS total_capacity,
  expected_to_join_this_quarter_margin_aum_millions + 
  expected_to_join_next_quarter_margin_aum_millions AS sum_quarterly_forecasts,
  sgm_capacity_expected_joined_aum_millions_estimate - 
  (expected_to_join_this_quarter_margin_aum_millions + 
   expected_to_join_next_quarter_margin_aum_millions) AS beyond_next_quarter
FROM vw_sgm_capacity_coverage_with_forecast
```

**Expected result:**
- `sum_quarterly_forecasts` ≤ `total_capacity` (because some deals may be beyond next quarter)
- `beyond_next_quarter` = deals projected to close more than 2 quarters out

## Conclusion

✅ **The views ARE aligned** - they use the same underlying data and calculations
✅ **Capacity estimate** = Total expected from all pipeline (no time component)
✅ **Quarterly forecasts** = Same pipeline split by when deals will close
✅ **Total expected current quarter** = Actuals + Forecast (complete quarter picture)

The difference is **purpose**:
- **Capacity**: Overall pipeline sufficiency
- **Forecasts**: Timing of when deals will close

