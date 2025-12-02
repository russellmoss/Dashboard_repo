# Quarterly Forecast Guide: Expected to Join This Quarter vs Next Quarter

## Overview

This guide explains how to use the new quarterly forecast metrics in Looker Studio to visualize expected joined margin AUM for the current quarter and next quarter.

## New View: `vw_sgm_capacity_coverage_with_forecast`

This enhanced view extends `vw_sgm_capacity_coverage` with quarterly forecast capabilities. It provides two key metrics:

1. **`expected_to_join_this_quarter_margin_aum_millions`** - Forecasted margin AUM expected to join in the current quarter
2. **`expected_to_join_next_quarter_margin_aum_millions`** - Forecasted margin AUM expected to join in the next quarter

## Forecast Methodology

The forecast uses a **physics-based approach** combining:
- **Stage Probabilities**: Historical probability that deals in each stage will eventually join
- **Velocity/Cycle Time**: Stage-specific median cycle times from historical data analysis
- **Stage Entry Dates**: Uses actual stage entry dates when available for more accurate forecasting

### Calculation Logic

1. **Projected Join Date Calculation** (Based on Historical Data Analysis):
   - **Signed Stage**: Stage Entry Date + 16 days (median: 16 days, conversion: 86.67%)
   - **Negotiating Stage**: Stage Entry Date + 37 days (median: 37 days, conversion: 34.78%)
   - **Sales Process Stage**: Stage Entry Date + 69 days (median: 69 days, conversion: 13.32%)
   - **Discovery Stage**: Stage Entry Date + 62 days (median: 62 days, conversion: 8.33%)
   - **Default/Other Stages**: SQO Date + 70 days (overall median cycle time)
   
   **Note**: If stage entry date is not available:
   - For Signed/Negotiating: Uses Current Date + median days
   - For other stages: Uses SQO Date + 70 days

2. **Quarter Assignment**:
   - Deals are assigned to "Current Quarter" or "Next Quarter" based on their projected join date
   - Only includes **active (non-stale) deals** (SQO age ≤ 120 days)

3. **Expected Margin AUM Calculation**:
   ```
   Expected Margin AUM = Weighted Pipeline Value × Conversion Rate
   
   Where:
   - Weighted Pipeline Value = Estimated Margin AUM × Stage Probability
   - Conversion Rate = SGM's historical SQO→Joined rate (or firm-wide for On Ramp SGMs)
   ```

## Key Fields for Looker Studio

### Primary Forecast Metrics

| Field Name | Description | Use Case |
|------------|-------------|----------|
| `expected_to_join_this_quarter_margin_aum_millions` | Forecasted margin AUM expected to join this quarter | Compare to target, track progress |
| `expected_to_join_next_quarter_margin_aum_millions` | Forecasted margin AUM expected to join next quarter | Plan for next quarter, identify gaps |

### Supporting Metrics

| Field Name | Description |
|------------|-------------|
| `current_quarter_actual_joined_aum_millions` | Actual joined margin AUM this quarter (for comparison) |
| `quarterly_target_margin_aum_millions` | Target: $36.75M per quarter |
| `sgm_capacity_expected_joined_aum_millions_estimate` | Total capacity (all quarters combined) |

## Looker Studio Chart Examples

### 1. Quarterly Forecast Comparison Chart

**Chart Type**: Column Chart or Bar Chart

**Dimensions**:
- `sgm_name`

**Metrics**:
- `expected_to_join_this_quarter_margin_aum_millions` (Series 1)
- `expected_to_join_next_quarter_margin_aum_millions` (Series 2)
- `quarterly_target_margin_aum_millions` (Reference Line)

**Use Case**: See which SGMs are forecasted to hit target this quarter vs next quarter

### 2. This Quarter Forecast vs Actual

**Chart Type**: Combo Chart (Column + Line)

**Dimensions**:
- `sgm_name`

**Metrics**:
- `expected_to_join_this_quarter_margin_aum_millions` (Column)
- `current_quarter_actual_joined_aum_millions` (Line)
- `quarterly_target_margin_aum_millions` (Reference Line)

**Use Case**: Compare forecast to actuals to validate forecast accuracy

### 3. Quarterly Forecast Trend

**Chart Type**: Time Series Chart

**Dimensions**:
- `as_of_date` (Date dimension)

**Metrics**:
- `expected_to_join_this_quarter_margin_aum_millions` (Series 1)
- `expected_to_join_next_quarter_margin_aum_millions` (Series 2)

**Use Case**: Track how forecasts change over time as deals progress

### 4. Forecast Coverage Ratio

**Chart Type**: Scorecard or Table

**Dimensions**:
- `sgm_name`

**Metrics**:
- `expected_to_join_this_quarter_margin_aum_millions`
- `quarterly_target_margin_aum_millions`
- **Calculated Field**: `SAFE_DIVIDE(expected_to_join_this_quarter_margin_aum_millions, quarterly_target_margin_aum_millions)`

**Use Case**: See which SGMs are forecasted to hit target this quarter

## Important Notes

### Forecast Accuracy

- **Best for**: Deals in "Negotiating" or "Signed" stages (higher probability, shorter cycle time)
- **Less accurate for**: Early-stage deals (Qualifying, Discovery) due to longer cycle times and higher variability
- **Updates daily**: Forecasts recalculate each day as deals progress through stages

### Limitations

1. **Cycle Time Variability**: While median is 70 days, actual cycle times range from 33 days (P25) to 148+ days (P90)
2. **Stage Progression**: Forecast assumes deals progress at historical rates; actual progression may vary
3. **New Deals**: Very new SQOs (just became SQO) may have less accurate forecasts until they progress to later stages

### Best Practices

1. **Compare to Actuals**: Regularly compare forecasts to actual joined margin AUM to validate accuracy
2. **Use with Other Metrics**: Combine with `coverage_status` and `sgm_capacity_expected_joined_aum_millions_estimate` for full picture
3. **Monitor Changes**: Track how forecasts change over time - increasing forecasts indicate healthy pipeline progression
4. **Focus on Active Deals**: Forecasts only include active (non-stale) deals; stale deals (>120 days) are excluded

## Example SQL Query

```sql
SELECT
  sgm_name,
  expected_to_join_this_quarter_margin_aum_millions,
  expected_to_join_next_quarter_margin_aum_millions,
  current_quarter_actual_joined_aum_millions,
  quarterly_target_margin_aum_millions,
  -- Calculate forecast coverage
  SAFE_DIVIDE(
    expected_to_join_this_quarter_margin_aum_millions,
    quarterly_target_margin_aum_millions
  ) AS forecast_coverage_ratio_this_quarter,
  SAFE_DIVIDE(
    expected_to_join_next_quarter_margin_aum_millions,
    quarterly_target_margin_aum_millions
  ) AS forecast_coverage_ratio_next_quarter
FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_coverage_with_forecast`
WHERE IsActive = TRUE
ORDER BY expected_to_join_this_quarter_margin_aum_millions DESC
```

## Deployment

1. **Deploy the view**:
   ```sql
   -- Run Views/vw_sgm_capacity_coverage_with_forecast.sql in BigQuery
   ```

2. **Update Looker Studio Data Source**:
   - Add the new view as a data source or update existing data source
   - Fields will be available immediately

3. **Create Charts**:
   - Use the examples above to create forecast visualizations
   - Add filters for `IsActive = TRUE` to show only active SGMs

## Questions?

For questions about the forecast methodology or implementation, refer to:
- `Pipeline_Forecasting_Feasibility_Study.md` - Detailed analysis of cycle times and forecasting approach
- `Views/vw_sgm_capacity_coverage_with_forecast.sql` - Full SQL implementation with comments

