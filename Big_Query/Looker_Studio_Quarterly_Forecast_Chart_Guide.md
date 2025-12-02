# Looker Studio Quarterly Forecast Chart Guide

## Overview

This guide shows you how to create charts in Looker Studio that display:
1. **Total Expected Margin AUM for Current Quarter** - Actual joined + Forecast from pipeline
2. **Total Expected Margin AUM for Next Quarter** - Forecast from pipeline

## Available Fields

### Primary Metrics (Use These for Charts)

| Field Name | Description | Use Case |
|------------|-------------|----------|
| `total_expected_current_quarter_margin_aum_millions` | **Actual joined this quarter + Forecast from pipeline** | Main metric for current quarter forecast |
| `total_expected_next_quarter_margin_aum_millions` | **Forecast from pipeline for next quarter** | Main metric for next quarter forecast |

### Supporting Metrics (For Context)

| Field Name | Description |
|------------|-------------|
| `current_quarter_actual_joined_aum_millions` | What has already joined this quarter (actuals) |
| `expected_to_join_this_quarter_margin_aum_millions` | What we forecast will join from pipeline (rest of quarter) |
| `expected_to_join_next_quarter_margin_aum_millions` | What we forecast will join from pipeline (next quarter) |
| `quarterly_target_margin_aum_millions` | Target: $36.75M per quarter |

## Chart Examples

### 1. Bar Chart: Current Quarter vs Next Quarter Forecast by SGM

**Chart Type**: Column Chart (Bar Chart)

**Configuration**:
- **Dimension**: `sgm_name`
- **Metric 1**: `total_expected_current_quarter_margin_aum_millions` (Series 1)
- **Metric 2**: `total_expected_next_quarter_margin_aum_millions` (Series 2)
- **Reference Line**: `quarterly_target_margin_aum_millions` (Target: $36.75M)

**Styling**:
- Series 1 (Current Quarter): Blue
- Series 2 (Next Quarter): Orange
- Reference Line: Red dashed line at $36.75M

**Use Case**: See which SGMs are forecasted to hit target this quarter vs next quarter

---

### 2. Combo Chart: Current Quarter Actuals + Forecast

**Chart Type**: Combo Chart (Column + Line)

**Configuration**:
- **Dimension**: `sgm_name`
- **Column 1**: `current_quarter_actual_joined_aum_millions` (What's already joined)
- **Column 2**: `expected_to_join_this_quarter_margin_aum_millions` (Forecast from pipeline)
- **Line**: `total_expected_current_quarter_margin_aum_millions` (Total expected)
- **Reference Line**: `quarterly_target_margin_aum_millions` (Target)

**Use Case**: See breakdown of current quarter: actuals vs forecast, plus total expected

---

### 3. Scorecard: Total Expected by Quarter

**Chart Type**: Scorecard (Multiple Scorecards)

**Scorecard 1 - Current Quarter**:
- **Metric**: `total_expected_current_quarter_margin_aum_millions`
- **Comparison**: `quarterly_target_margin_aum_millions`
- **Label**: "Expected Current Quarter"

**Scorecard 2 - Next Quarter**:
- **Metric**: `total_expected_next_quarter_margin_aum_millions`
- **Comparison**: `quarterly_target_margin_aum_millions`
- **Label**: "Expected Next Quarter"

**Use Case**: Quick overview of total expected margin AUM for both quarters

---

### 4. Table: Detailed Quarterly Forecast by SGM

**Chart Type**: Table

**Columns**:
1. `sgm_name`
2. `current_quarter_actual_joined_aum_millions` (Actual Joined)
3. `expected_to_join_this_quarter_margin_aum_millions` (Forecast from Pipeline)
4. `total_expected_current_quarter_margin_aum_millions` (Total Expected)
5. `total_expected_next_quarter_margin_aum_millions` (Next Quarter Forecast)
6. `quarterly_target_margin_aum_millions` (Target)
7. **Calculated Field**: `SAFE_DIVIDE(total_expected_current_quarter_margin_aum_millions, quarterly_target_margin_aum_millions)` (Coverage %)

**Conditional Formatting**:
- Green: Coverage % >= 100%
- Yellow: Coverage % >= 85%
- Red: Coverage % < 85%

**Use Case**: Detailed view of each SGM's forecast with breakdown

---

### 5. Time Series: Forecast Trend Over Time

**Chart Type**: Time Series Chart

**Configuration**:
- **Dimension**: `as_of_date` (Date dimension)
- **Metric 1**: `total_expected_current_quarter_margin_aum_millions` (Series 1)
- **Metric 2**: `total_expected_next_quarter_margin_aum_millions` (Series 2)
- **Reference Line**: `quarterly_target_margin_aum_millions`

**Use Case**: Track how forecasts change over time as deals progress

---

## Step-by-Step: Creating the Main Forecast Chart

### Step 1: Add Data Source
1. In Looker Studio, click **Add a data source**
2. Select **BigQuery**
3. Choose your project: `savvy-gtm-analytics`
4. Select dataset: `savvy_analytics`
5. Select view: `vw_sgm_capacity_coverage_with_forecast`

### Step 2: Create Bar Chart
1. Click **Add a chart** → **Bar chart**
2. Drag chart to your dashboard

### Step 3: Configure Chart
1. **Data Source**: Select your data source
2. **Dimension**: 
   - Add `sgm_name`
3. **Metrics**:
   - Add `total_expected_current_quarter_margin_aum_millions` (rename to "Current Quarter")
   - Add `total_expected_next_quarter_margin_aum_millions` (rename to "Next Quarter")
4. **Reference Line**:
   - Add `quarterly_target_margin_aum_millions` (rename to "Target")

### Step 4: Style the Chart
1. **Chart Style**:
   - Series 1 (Current Quarter): Blue (#4285F4)
   - Series 2 (Next Quarter): Orange (#FF9800)
   - Reference Line: Red dashed line (#EA4335)
2. **Axis**:
   - Y-axis label: "Margin AUM (Millions)"
   - Format: Number → Currency → Millions

### Step 5: Add Filters (Optional)
1. Add filter for `IsActive = TRUE` (to show only active SGMs)
2. Add filter for `sgm_name` (if you want to focus on specific SGMs)

## Calculated Fields (Optional)

### Current Quarter Coverage Ratio
```
SAFE_DIVIDE(
  total_expected_current_quarter_margin_aum_millions,
  quarterly_target_margin_aum_millions
)
```

### Next Quarter Coverage Ratio
```
SAFE_DIVIDE(
  total_expected_next_quarter_margin_aum_millions,
  quarterly_target_margin_aum_millions
)
```

### Gap to Target (Current Quarter)
```
quarterly_target_margin_aum_millions - total_expected_current_quarter_margin_aum_millions
```

### Gap to Target (Next Quarter)
```
quarterly_target_margin_aum_millions - total_expected_next_quarter_margin_aum_millions
```

## Best Practices

1. **Always show target**: Include the $36.75M target as a reference line for context
2. **Use color coding**: 
   - Green for on/above target
   - Yellow for at risk (85-100%)
   - Red for under-capacity (<85%)
3. **Show breakdown**: Use combo charts to show actuals vs forecast separately
4. **Filter active SGMs**: Always filter `IsActive = TRUE` unless you specifically want to see inactive SGMs
5. **Update frequency**: The view updates daily, so forecasts will change as deals progress

## Understanding the Metrics

### Current Quarter Total Expected
```
Total Expected = Actual Joined + Forecast from Pipeline
```

**Example**:
- Actual Joined: $15M (already happened this quarter)
- Forecast from Pipeline: $20M (expected to join rest of quarter)
- **Total Expected: $35M**

### Next Quarter Total Expected
```
Total Expected = Forecast from Pipeline Only
```

**Example**:
- Forecast from Pipeline: $30M (expected to join next quarter)
- **Total Expected: $30M**

## Troubleshooting

### Issue: Values seem too high/low
- **Check**: Are you using the correct fields? Make sure you're using `total_expected_*` fields, not just `expected_to_join_*`
- **Check**: Is `IsActive = TRUE` filter applied?

### Issue: Forecast doesn't match expectations
- **Remember**: Forecast uses stage probabilities and conversion rates, so it's an estimate
- **Check**: Run the validation queries to see forecast accuracy
- **Note**: Forecast accuracy is ~81% for quarter predictions

### Issue: Missing SGMs
- **Check**: Filter `IsActive = TRUE` is applied
- **Check**: Some SGMs may not have any pipeline, so they won't appear in forecast

## Next Steps

1. Create the main bar chart showing current vs next quarter
2. Add a table for detailed breakdown
3. Create scorecards for quick overview
4. Add filters for SGM selection
5. Set up automatic refresh (daily recommended)

## Questions?

Refer to:
- `Quarterly_Forecast_Guide.md` - Detailed forecast methodology
- `Stage_Velocity_Analysis_Results.md` - Stage-specific cycle times
- `Validation_Queries/README.md` - Forecast accuracy validation

