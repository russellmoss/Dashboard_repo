# Quarterly Forecast Chart - Quick Start Guide

## What You Can Now Do

The view `vw_sgm_capacity_coverage_with_forecast` now includes two key fields for Looker Studio charts:

1. **`total_expected_current_quarter_margin_aum_millions`**
   - **Formula**: Actual Joined This Quarter + Forecast from Pipeline
   - **Shows**: Complete expected margin AUM for current quarter

2. **`total_expected_next_quarter_margin_aum_millions`**
   - **Formula**: Forecast from Pipeline
   - **Shows**: Expected margin AUM for next quarter

## Quick Chart Setup

### Step 1: Add Data Source
1. Looker Studio → Add Data Source → BigQuery
2. Select: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_coverage_with_forecast`

### Step 2: Create Bar Chart
1. Add Chart → Bar Chart
2. **Dimension**: `sgm_name`
3. **Metrics**:
   - `total_expected_current_quarter_margin_aum_millions` (rename to "Current Quarter")
   - `total_expected_next_quarter_margin_aum_millions` (rename to "Next Quarter")
4. **Reference Line**: `quarterly_target_margin_aum_millions` (Target: $36.75M)

### Step 3: Add Filter
- Filter: `IsActive = TRUE` (to show only active SGMs)

## What the Metrics Mean

### Current Quarter Total Expected
```
$15M (already joined) + $20M (forecast from pipeline) = $35M total expected
```

This shows:
- ✅ What has **already happened** this quarter (actuals)
- ✅ What we **expect to happen** from existing pipeline (forecast)
- ✅ **Total expected** for the full quarter

### Next Quarter Total Expected
```
$30M (forecast from pipeline) = $30M total expected
```

This shows:
- ✅ What we **expect to happen** from existing pipeline (forecast)
- ✅ **Total expected** for next quarter

## Example Chart Output

```
SGM Name          | Current Quarter | Next Quarter | Target
------------------|-----------------|--------------|--------
John Doe          | $38.5M         | $32.0M      | $36.75M
Jane Smith        | $25.2M         | $28.5M      | $36.75M
Bob Johnson       | $42.1M         | $35.8M      | $36.75M
```

## Key Fields Reference

| Field | Description |
|-------|-------------|
| `total_expected_current_quarter_margin_aum_millions` | **Use this** - Total expected for current quarter |
| `total_expected_next_quarter_margin_aum_millions` | **Use this** - Total expected for next quarter |
| `current_quarter_actual_joined_aum_millions` | Actual joined (for breakdown) |
| `expected_to_join_this_quarter_margin_aum_millions` | Forecast from pipeline (for breakdown) |
| `quarterly_target_margin_aum_millions` | Target: $36.75M |

## Next Steps

1. ✅ Deploy the updated view to BigQuery
2. ✅ Create the bar chart in Looker Studio
3. ✅ Add filters and styling
4. ✅ Share with your team!

For detailed chart configurations, see: `Looker_Studio_Quarterly_Forecast_Chart_Guide.md`

