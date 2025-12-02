# SGM Capacity & Coverage Dashboard - Looker Studio Guide

## Overview

This guide shows you how to build a high-level, executive-ready Capacity & Coverage dashboard in Looker Studio using the BigQuery views we've created.

## Key Concepts

**SGM Capacity** = Expected Quarterly Joined AUM from their active (non-stale) pipeline
- Formula: `Active Weighted Pipeline Value × SQO→Joined Conversion Rate`
- This represents the realistic expected value from deals that are likely to close

**Coverage Ratio** = Capacity ÷ Target ($3.67M)
- `1.00` = Perfectly staffed (exact target)
- `>1.00` = Sufficient capacity (have enough pipeline)
- `<1.00` = Under-capacity (don't have enough pipeline)
- `<0.85` = Critical under-capacity

## Data Sources

### Primary View: `vw_sgm_capacity_coverage`
**Location**: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_coverage`

This is the simplified view designed specifically for Looker. It includes:
- `sgm_capacity_expected_joined_aum_millions_estimate` - The capacity metric (estimate - recommended)
- `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` - The capacity metric (actual - includes stale)
- `coverage_ratio_estimate` - Coverage ratio (capacity/target, estimate - recommended)
- `coverage_ratio_actual_includes_stale` - Coverage ratio (capacity/target, actual - includes stale)
- `coverage_status` - Status for color coding (Sufficient/At Risk/Under-Capacity)
- Supporting metrics for context

### Supporting Views:
- `vw_sgm_capacity_model_refined` - Full detailed metrics
- `vw_firm_wide_capacity_summary` - Firm-level aggregates

## Looker Studio Dashboard Setup

### Step 1: Connect Data Source

1. In Looker Studio, click **Create** → **Data Source**
2. Select **BigQuery** connector
3. Choose **savvy-gtm-analytics** project
4. Select **savvy_analytics** dataset
5. Select **vw_sgm_capacity_coverage** table
6. Click **Connect**

### Step 2: Configure Fields

#### Dimensions (for grouping/filtering):
- `sgm_name` - SGM Name
- `coverage_status` - Coverage Status (for color coding)
- `as_of_date` - As of Date

#### Metrics (for calculations):
- `sgm_capacity_expected_joined_aum_millions_estimate` - SGM Capacity (Estimate - recommended)
- `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` - SGM Capacity (Actual - includes stale)
- `quarterly_target_margin_aum_millions` - Target ($3.67M)
- `coverage_ratio_estimate` - Coverage Ratio (Estimate - recommended)
- `coverage_ratio_actual_includes_stale` - Coverage Ratio (Actual - includes stale)
- `capacity_gap_millions_estimate` - Gap (Target - Capacity, Estimate)
- `capacity_gap_millions_actual_includes_stale` - Gap (Target - Capacity, Actual)
- `active_sqo_count` - Active SQO Count
- `non_stale_sqo_count` - Non-Stale SQO Count
- `stale_sqo_count` - Stale SQO Count

### Step 3: Create Calculated Fields (Optional)

You can create these in Looker Studio for additional flexibility:

**Coverage Percentage (Estimate)**:
```
coverage_ratio_estimate * 100
```

**Coverage Percentage (Actual)**:
```
coverage_ratio_actual_includes_stale * 100
```

**Difference: Estimate vs Actual**:
```
(coverage_ratio_estimate - coverage_ratio_actual_includes_stale) * 100
```

**Capacity vs Target Difference (Estimate)**:
```
sgm_capacity_expected_joined_aum_millions_estimate - quarterly_target_margin_aum_millions
```

**Capacity vs Target Difference (Actual)**:
```
sgm_capacity_expected_joined_aum_millions_actual_includes_stale - quarterly_target_margin_aum_millions
```

**Stale Pipeline Percentage**:
```
SAFE_DIVIDE(stale_sqo_count, active_sqo_count) * 100
```

## Dashboard Components

### Component 1: Executive Summary Scorecard (Top of Dashboard)

**Type**: Scorecard (4 cards)

**Cards**:
1. **Total SGMs**
   - Metric: COUNT_DISTINCT(sgm_name)
   - Format: Number

2. **SGMs with Sufficient Capacity**
   - Metric: COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate >= 1.0 THEN sgm_name END)
   - Format: Number
   - Color: Green

3. **SGMs At Risk**
   - Metric: COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate >= 0.85 AND coverage_ratio_estimate < 1.0 THEN sgm_name END)
   - Format: Number
   - Color: Yellow

4. **SGMs Under-Capacity**
   - Metric: COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate < 0.85 THEN sgm_name END)
   - Format: Number
   - Color: Red

### Component 2: Capacity vs Target Bar Chart

**Type**: Bar Chart (Grouped)

**Configuration**:
- **Dimension**: `sgm_name`
- **Metrics**:
  - `quarterly_target_margin_aum_millions` (Gold bar, fixed at $3.67M)
  - `sgm_capacity_expected_joined_aum_millions_estimate` (Blue bar, variable - recommended)
  - `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` (Optional: Gray bar for comparison)
- **Sort**: By `coverage_ratio_estimate` (ascending - lowest coverage first)
- **Chart Style**: Horizontal bars

**Color Coding**:
- Use `coverage_status` field for bar colors:
  - Sufficient: Green
  - At Risk: Yellow
  - Under-Capacity: Red

### Component 3: Coverage Ratio Gauge Chart

**Type**: Gauge Chart

**Configuration**:
- **Metric**: `coverage_ratio_estimate` (average across all SGMs - recommended)
- **Min**: 0
- **Max**: 1.5
- **Thresholds**:
  - Red: 0 - 0.85
  - Yellow: 0.85 - 1.0
  - Green: 1.0 - 1.5

### Component 4: SGM Capacity Table

**Type**: Table

**Columns**:
1. **SGM Name** (`sgm_name`)
2. **Capacity (Estimate)** (`sgm_capacity_expected_joined_aum_millions_estimate`) - Format: Currency (Millions)
3. **Capacity (Actual)** (`sgm_capacity_expected_joined_aum_millions_actual_includes_stale`) - Format: Currency (Millions)
4. **Target** (`quarterly_target_margin_aum_millions`) - Format: Currency (Millions)
5. **Coverage Ratio (Estimate)** (`coverage_ratio_estimate`) - Format: Percentage (1 decimal)
6. **Coverage Ratio (Actual)** (`coverage_ratio_actual_includes_stale`) - Format: Percentage (1 decimal)
7. **Status** (`coverage_status`) - Color coded
8. **Gap (Estimate)** (`capacity_gap_millions_estimate`) - Format: Currency (Millions)
7. **Active SQOs** (`non_stale_sqo_count`) - Format: Number
8. **Stale SQOs** (`stale_sqo_count`) - Format: Number

**Conditional Formatting**:
- **Coverage Ratio Column**: 
  - Green if >= 1.0
  - Yellow if >= 0.85 and < 1.0
  - Red if < 0.85

**Sorting**: By `coverage_ratio_estimate` (ascending - lowest first)

### Component 5: Coverage Distribution Chart

**Type**: Pie Chart or Donut Chart

**Configuration**:
- **Dimension**: `coverage_status`
- **Metric**: COUNT_DISTINCT(sgm_name)
- **Colors**: 
  - Sufficient: Green
  - At Risk: Yellow
  - Under-Capacity: Red

### Component 6: Capacity Gap Analysis

**Type**: Bar Chart (Horizontal)

**Configuration**:
- **Dimension**: `sgm_name`
- **Metric**: `capacity_gap_millions_estimate` (recommended) or `capacity_gap_millions_actual_includes_stale`
- **Sort**: Ascending (largest gaps first)
- **Color**: Red for negative gaps, Green for positive

## Advanced: Drill-Down to Details

### Create a Detail Page

1. Add a new page to your dashboard
2. Use the same data source (`vw_sgm_capacity_coverage`)
3. Add filters:
   - `sgm_name` (dropdown filter)
4. Add detailed metrics from `vw_sgm_capacity_model_refined`:
   - Pipeline breakdown by stage
   - Historical conversion rates
   - SQO quality metrics

### Cross-Filtering Setup

Enable cross-filtering so clicking on an SGM in one chart filters all other charts:
1. Select any chart
2. In the **Style** tab, enable **Cross-filtering**
3. Repeat for all charts

## Color Scheme Recommendations

**Coverage Status Colors**:
- **Sufficient** (≥1.0): `#34A853` (Green)
- **At Risk** (0.85-1.0): `#FBBC04` (Yellow/Amber)
- **Under-Capacity** (<0.85): `#EA4335` (Red)

**Metric Colors**:
- Target: `#FFD700` (Gold)
- Capacity: `#4285F4` (Blue)
- Gap (negative): `#EA4335` (Red)
- Gap (positive): `#34A853` (Green)

## Key Metrics to Highlight

### Primary KPI (Top of Dashboard):
```
Firm-Wide Coverage Ratio = Average(coverage_ratio_estimate) across all SGMs
```

### Actual vs Estimate Comparison:
- **Estimate Capacity**: Uses active (non-stale) weighted pipeline with estimates (more realistic)
- **Actual Capacity**: Uses total weighted pipeline with actual values only (includes stale, so appears higher)
- **Key Insight**: If actual is much higher than estimate, you may have stale deals inflating your pipeline

### Secondary KPIs:
- Total Expected Joined AUM (Estimate) = SUM(sgm_capacity_expected_joined_aum_millions_estimate)
- Total Expected Joined AUM (Actual) = SUM(sgm_capacity_expected_joined_aum_millions_actual_includes_stale)
- Total Target AUM = COUNT(sgm_name) × 3.67
- SGMs at Risk = COUNT(CASE WHEN coverage_ratio_estimate < 1.0 THEN 1 END)

## Filtering Options

Add these filters to your dashboard:
1. **SGM Name** - Dropdown (multi-select)
2. **Coverage Status** - Checkbox filter
3. **As of Date** - Date range picker (if you want historical views)

## Refresh Schedule

Set your data source to refresh:
- **Recommended**: Every 4 hours (or daily for executive dashboards)
- BigQuery views update in real-time, so refresh frequency depends on your needs

## Example Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  EXECUTIVE SUMMARY SCORECARDS (4 cards)                │
│  [Total SGMs] [Sufficient] [At Risk] [Under-Capacity]  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FIRM-WIDE COVERAGE GAUGE                               │
│  [Large Gauge Chart showing average coverage ratio]     │
└─────────────────────────────────────────────────────────┘

┌──────────────────────────┬──────────────────────────────┐
│  CAPACITY VS TARGET      │  COVERAGE DISTRIBUTION       │
│  [Grouped Bar Chart]     │  [Pie Chart]                │
└──────────────────────────┴──────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  SGM CAPACITY TABLE                                     │
│  [Detailed table with all SGMs, sortable]               │
└─────────────────────────────────────────────────────────┘
```

## Quick Start Checklist

- [ ] Connect `vw_sgm_capacity_coverage` as data source
- [ ] Create Executive Summary scorecards (4 cards)
- [ ] Create Capacity vs Target bar chart
- [ ] Create Coverage Ratio gauge
- [ ] Create SGM Capacity table with conditional formatting
- [ ] Add filters (SGM Name, Coverage Status)
- [ ] Enable cross-filtering
- [ ] Set up color scheme
- [ ] Configure refresh schedule
- [ ] Test with sample data

## Troubleshooting

**Issue**: Coverage ratio showing as NULL
- **Solution**: Check that `sqo_to_joined_conversion_rate` is not NULL. The view uses COALESCE to handle this, but verify your data.

**Issue**: Capacity seems too low
- **Solution**: Remember that capacity uses `active_weighted_pipeline_value_millions_estimate` (excludes stale deals) and multiplies by conversion rate. This is intentionally conservative. Compare with `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` to see the difference.

**Issue**: Numbers don't match expectations
- **Solution**: Verify you're using the correct fields:
  - Capacity (Estimate) = `sgm_capacity_expected_joined_aum_millions_estimate` (recommended)
  - Capacity (Actual) = `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` (includes stale)
  - Target = `quarterly_target_margin_aum_millions` (3.67)
  - Coverage (Estimate) = `coverage_ratio_estimate` (recommended)
  - Coverage (Actual) = `coverage_ratio_actual_includes_stale` (includes stale)

## Next Steps

Once you have the basic dashboard:
1. Add drill-down pages for individual SGM details
2. Create time-series views showing capacity trends
3. Add alerts for SGMs dropping below 0.85 coverage
4. Integrate with `vw_firm_wide_capacity_summary` for firm-level context

