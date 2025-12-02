# SGM Capacity & Coverage Dashboard - Step-by-Step Build Guide

## Overview

This guide will help you build a comprehensive SGM Capacity & Coverage dashboard with:
- **High-Level Summaries** at the top (executive-ready)
- **Detailed Tables** at the bottom (for drill-down analysis)
- **New Coverage Metrics** integrated with existing capacity metrics

---

## Step 1: Connect Data Sources

### 1.1 Primary Data Source: Capacity & Coverage View

1. In Looker Studio, click **Create** → **Data Source**
2. Select **BigQuery** connector
3. Choose **savvy-gtm-analytics** project
4. Select **savvy_analytics** dataset
5. Select **vw_sgm_capacity_coverage** table
6. Click **Connect**
7. Name it: "SGM Capacity & Coverage"

**Key Fields Available**:
- `sgm_capacity_expected_joined_aum_millions_estimate` - Capacity (Estimate)
- `sgm_capacity_expected_joined_aum_millions_actual_includes_stale` - Capacity (Actual)
- `coverage_ratio_estimate` - Coverage Ratio (Estimate - recommended)
- `coverage_ratio_actual_includes_stale` - Coverage Ratio (Actual)
- `coverage_status` - Status (Sufficient/At Risk/Under-Capacity)
- `quarterly_target_margin_aum_millions` - Target ($3.67M)

### 1.2 Secondary Data Source: Detailed Capacity View

1. Add another data source: **vw_sgm_capacity_model_refined**
2. Name it: "SGM Capacity Details"

**This provides**:
- All the detailed metrics for summary tables
- Historical metrics
- Gap analysis
- Pipeline breakdowns

### 1.3 Detail Data Source: Open SQOs

1. Add data source: **vw_sgm_open_sqos_detail** (if exists)
2. Name it: "SGM Open SQOs Detail"

**This provides**:
- Row-level opportunity details
- Salesforce links
- Days open calculations

---

## Step 2: Create the Dashboard

1. Click **Create** → **Report**
2. Select the "SGM Capacity & Coverage" data source
3. Name it: "SGM Capacity & Coverage Dashboard"

---

## Step 3: Build High-Level Summary Section (Top of Page)

### 3.1 Create Firm-Wide Scorecards (4 Cards)

**Card 1: Total Active SGMs**

1. Click **Add a chart** → **Scorecard**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Field: `sgm_name`
   - Aggregation: `COUNT_DISTINCT`
4. **Label**: "Total Active SGMs"
5. **Format**: Number (0 decimals)
6. **Style**: 
   - Background: Light gray (#F5F5F5)
   - Text: Dark gray (#333333)

**Card 2: SGMs with Sufficient Capacity**

1. Click **Add a chart** → **Scorecard**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Create calculated field:
   ```
   COUNT_DISTINCT(CASE 
     WHEN coverage_ratio_estimate >= 1.0 
     THEN sgm_name 
     ELSE NULL 
   END)
   ```
   - Name it: "SGMs Sufficient"
4. **Label**: "Sufficient Capacity"
5. **Subtitle**: "On Track"
6. **Format**: Number (0 decimals)
7. **Style**:
   - Background: Green (#34A853)
   - Text: White

**Card 3: SGMs At Risk**

1. Click **Add a chart** → **Scorecard**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Create calculated field:
   ```
   COUNT_DISTINCT(CASE 
     WHEN coverage_ratio_estimate >= 0.85 
       AND coverage_ratio_estimate < 1.0 
     THEN sgm_name 
     ELSE NULL 
   END)
   ```
   - Name it: "SGMs At Risk"
4. **Label**: "At Risk"
5. **Subtitle**: "Needs Attention"
6. **Format**: Number (0 decimals)
7. **Style**:
   - Background: Yellow/Amber (#FBBC04)
   - Text: Dark gray (#333333)

**Card 4: SGMs Under-Capacity**

1. Click **Add a chart** → **Scorecard**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Create calculated field:
   ```
   COUNT_DISTINCT(CASE 
     WHEN coverage_ratio_estimate < 0.85 
     THEN sgm_name 
     ELSE NULL 
   END)
   ```
   - Name it: "SGMs Under-Capacity"
4. **Label**: "Under-Capacity"
5. **Subtitle**: "Critical"
6. **Format**: Number (0 decimals)
7. **Style**:
   - Background: Red (#EA4335)
   - Text: White

**Card 5: Firm-Wide SGM Capacity (Margin AUM)**

This scorecard shows the total expected joined Margin AUM from all SGMs' active pipelines.

**Formula**: Active SQOs × Join Probability × Avg Margin AUM per Joined

1. Click **Add a chart** → **Scorecard**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Field: `sgm_capacity_expected_joined_aum_millions_estimate`
   - Aggregation: `SUM`
4. **Label**: "Total SGM Capacity"
5. **Subtitle**: "Expected Joined AUM"
6. **Format**: Currency (Millions, 2 decimals, e.g., "$45.20M")
7. **Style**:
   - Background: Blue (#4285F4)
   - Text: White
8. **Tooltip**: 
   ```
   Formula: Active SQOs × Join Probability × Avg Margin AUM per Joined
   
   This represents the total expected joined Margin AUM from all SGMs' 
   active (non-stale) pipelines, accounting for stage probabilities 
   and historical conversion rates.
   
   Calculation Components:
   • Active SQOs: Count of non-stale SQOs in pipeline
   • Join Probability: Historical SQO→Joined conversion rate
   • Avg Margin AUM per Joined: Historical average per joined advisor
   ```

**Show Capacity Breakdown (Optional - Below Scorecard)**

To display the calculation components visually:

1. Click **Add a chart** → **Scorecard** (create 3 small scorecards in a row)

**Scorecard A: Active SQOs**
- **Metric**: `SUM(non_stale_sqo_count)`
- **Label**: "Active SQOs"
- **Format**: Number (0 decimals)
- **Subtitle**: "In Pipeline"

**Scorecard B: Join Probability**
- **Metric**: `AVG(sqo_to_joined_conversion_rate) * 100`
- **Label**: "Join Probability"
- **Format**: Percentage (1 decimal)
- **Subtitle**: "SQO→Joined Rate"

**Scorecard C: Avg Margin AUM per Joined**
- **Metric**: `AVG(avg_margin_aum_per_joined_millions)`
- **Label**: "Avg Margin AUM"
- **Format**: Currency (Millions, 2 decimals)
- **Subtitle**: "Per Joined Advisor"

**Or use a Text component** to show the formula:

1. Click **Add a chart** → **Text**
2. Content:
   ```
   Capacity Calculation:
   [SUM(non_stale_sqo_count)] Active SQOs
   × [AVG(sqo_to_joined_conversion_rate) * 100]% Join Probability
   × $[AVG(avg_margin_aum_per_joined_millions)]M Avg Margin AUM per Joined
   = $[SUM(sgm_capacity_expected_joined_aum_millions_estimate)]M Total Capacity
   ```
3. Position: Below the capacity scorecard

**Layout**: Arrange all 5 cards in a horizontal row at the top (or 4 cards + capacity card below)

---

### 3.2 Create Firm-Wide Coverage Gauge

1. Click **Add a chart** → **Gauge**
2. **Data Source**: SGM Capacity & Coverage
3. **Metric**: 
   - Field: `coverage_ratio_estimate`
   - Aggregation: `AVG`
4. **Label**: "Firm-Wide Coverage Ratio"
5. **Min Value**: 0
6. **Max Value**: 1.5
7. **Thresholds**:
   - **Red**: 0 - 0.85 (Under-Capacity)
   - **Yellow**: 0.85 - 1.0 (At Risk)
   - **Green**: 1.0 - 1.5 (Sufficient)
8. **Format**: Percentage (1 decimal)
9. **Size**: Large (centered below scorecards)

**Add Text Below Gauge**:
1. Click **Add a chart** → **Text**
2. Content:
   ```
   Target: $3.67M per SGM
   Average Capacity: $[AVG(sgm_capacity_expected_joined_aum_millions_estimate)]M
   ```
3. Position: Below gauge

---

### 3.3 Create Capacity vs Target Bar Chart

1. Click **Add a chart** → **Bar Chart** → **Grouped Bar Chart**
2. **Data Source**: SGM Capacity & Coverage
3. **Dimension**: `sgm_name`
4. **Metrics**:
   - **Metric 1**: `quarterly_target_margin_aum_millions`
     - Label: "Target"
     - Color: Gold (#FFD700)
   - **Metric 2**: `sgm_capacity_expected_joined_aum_millions_estimate`
     - Label: "Capacity (Estimate)"
     - Color: Blue (#4285F4)
   - **Metric 3** (Optional): `sgm_capacity_expected_joined_aum_millions_actual_includes_stale`
     - Label: "Capacity (Actual)"
     - Color: Light gray (#CCCCCC)
5. **Sort**: 
   - Sort by: `coverage_ratio_estimate`
   - Order: Ascending (lowest first)
6. **Chart Style**: Horizontal bars
7. **Title**: "SGM Capacity vs Target ($3.67M)"
8. **Color by Dimension**: `coverage_status` (optional - colors bars by status)

**Position**: Left side, below gauge

---

### 3.4 Create Coverage Distribution Chart

1. Click **Add a chart** → **Pie Chart** (or Donut Chart)
2. **Data Source**: SGM Capacity & Coverage
3. **Dimension**: `coverage_status`
4. **Metric**: 
   - Field: `sgm_name`
   - Aggregation: `COUNT_DISTINCT`
5. **Colors**:
   - Sufficient: Green (#34A853)
   - At Risk: Yellow (#FBBC04)
   - Under-Capacity: Red (#EA4335)
6. **Title**: "Coverage Distribution"
7. **Show**: Percentages and counts

**Position**: Right side, next to bar chart

---

## Step 4: Create Coverage Summary Table (New High-Level Table)

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity & Coverage
3. **Dimensions**:
   - `sgm_name` (Column 1)
   - `coverage_status` (Column 2)
4. **Metrics**:
   - `coverage_ratio_estimate` (Column 3)
   - `sgm_capacity_expected_joined_aum_millions_estimate` (Column 4)
   - `quarterly_target_margin_aum_millions` (Column 5)
   - `capacity_gap_millions_estimate` (Column 6)
   - `non_stale_sqo_count` (Column 7)
   - `stale_sqo_count` (Column 8)

**Formatting**:
- **Coverage Ratio**: Percentage (1 decimal)
- **Capacity & Target**: Currency (Millions, 2 decimals)
- **Gap**: Currency (Millions, 2 decimals)
- **SQO Counts**: Number (0 decimals)

**Conditional Formatting**:
- **Coverage Ratio Column**:
  - Green if >= 1.0
  - Yellow if >= 0.85 and < 1.0
  - Red if < 0.85
- **Gap Column**:
  - Green if positive
  - Red if negative

**Sorting**: 
- Default: `coverage_ratio_estimate` (Ascending - lowest first)

**Title**: "SGM Coverage Summary"

**Position**: Below bar chart and pie chart

---

## Step 5: Add Existing Detailed Tables (Bottom Section)

### 5.1 SGM Capacity Bar Chart (Existing - Keep)

**Data Source**: SGM Capacity Details (vw_sgm_capacity_model_refined)

**Bars** (per SGM):
- Target (Blue): `quarterly_target_margin_aum` (now $3.67M)
- Current Pipeline Margin AUM (Orange): `current_pipeline_sqo_margin_aum`
- Current Pipeline Weighted Margin AUM (Orange - Lighter): `current_pipeline_sqo_weighted_margin_aum`
- Current Pipeline Weighted AUM Estimate (Green): `current_pipeline_sqo_weighted_margin_aum_estimate`
- Current Quarter Joined Margin AUM (Teal): `current_quarter_joined_margin_aum`

**Title**: "SGM Capacity - Detailed Pipeline Breakdown"

**Position**: Below Coverage Summary Table

---

### 5.2 SGM Capacity Summary - Margin AUM Table

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity Details
3. **Dimensions**: `sgm_name`
4. **Metrics**:
   - `current_pipeline_sqo_margin_aum` (Pipeline Unweighted Actual)
   - `current_pipeline_sqo_weighted_margin_aum` (Pipeline Weighted Actual)
   - `current_pipeline_sqo_weighted_margin_aum_estimate` (Pipeline Weighted Estimate)
   - `current_quarter_joined_margin_aum` (Current Quarter Joined Actuals)

**Format**: Currency (Millions, 2 decimals)

**Title**: "SGM Capacity Summary - Margin AUM"

---

### 5.3 SGM Capacity Summary - Potentially Stale Pipeline Table

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity Details
3. **Dimensions**: `sgm_name`
4. **Metrics**:
   - `current_pipeline_sqo_stale_margin_aum` (Stale Pipeline Actual)
   - `current_pipeline_sqo_stale_margin_aum_estimate` (Stale Pipeline Estimate)
   - Create calculated field for Stale %:
     ```
     SAFE_DIVIDE(
       current_pipeline_sqo_stale_margin_aum_estimate,
       current_pipeline_sqo_margin_aum_estimate
     ) * 100
     ```
   - Name: "Stale Percentage of Estimated Pipeline"

**Format**: 
- AUM: Currency (Millions, 2 decimals)
- Percentage: Percentage (1 decimal)

**Conditional Formatting**:
- Stale %: Red if > 30%

**Title**: "SGM Capacity Summary - Potentially Stale Pipeline"

---

### 5.4 SGM Capacity Summary - SQOs Table

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity Details
3. **Dimensions**: `sgm_name`
4. **Metrics**:
   - `required_sqos_per_quarter` (Required Number of SQOs)
   - `current_pipeline_sqo_count` (Current Pipeline SQOs)
   - `avg_margin_aum_per_sqo` (Average Margin AUM per SQO)
   - `sqo_gap_count` (Gap)
   - `pipeline_margin_aum_pct_of_target` (Percentage of Target)

**Format**:
- Counts: Number (0 decimals)
- AUM: Currency (Millions, 2 decimals)
- Percentage: Percentage (1 decimal)

**Title**: "SGM Capacity Summary - SQOs"

---

### 5.5 Gap Analysis Table

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity Details
3. **Dimensions**: `sgm_name`
4. **Metrics**:
   - `required_sqos_per_quarter` (Required SQOs per Quarter)
   - `current_pipeline_sqo_count` (Current Pipeline SQOs)
   - `sqo_gap_count` (SQO Gap)
   - `required_joined_per_quarter` (Required Joined per Quarter)
   - `current_quarter_joined_count` (Current Quarter Joined)
   - `joined_gap_count` (Joined Gap)

**Format**: Number (0 decimals)

**Title**: "Gap Analysis - SQOs and Joined"

---

### 5.6 Historical Metrics Table

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Capacity Details
3. **Dimensions**: `sgm_name`
4. **Metrics**:
   - `avg_margin_aum_per_sqo` (Average Margin AUM per SQO)
   - `avg_margin_aum_per_joined` (Average Margin AUM per Joined)
   - `sqo_to_joined_conversion_rate` (SQO to Joined Conversion Rate)
   - `historical_sqo_count_12m` (Number of SQOs - Last 12 Mo)
   - `historical_joined_count_12m` (Number of Joined - Last 12 Mo)

**Format**:
- AUM: Currency (Millions, 2 decimals)
- Rate: Percentage (1 decimal)
- Counts: Number (0 decimals)

**Title**: "Historical Metrics (Last 12 Months)"

---

## Step 6: Add Detail Tables (Row-Level Opportunities)

### 6.1 Detail Table - Active Deals

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Open SQOs Detail
3. **Filter**: 
   - Create filter: `days_open_since_sqo <= 120`
   - Or use: `is_stale = 0` (if available)
4. **Dimensions**:
   - `sgm_name`
   - `sqo_date` (SQO Date)
   - `advisor_url` (Advisor - URL link to Salesforce)
   - `stage_name` (Stage Name)
5. **Metrics**:
   - `margin_aum_actual` (Margin AUM - Actual)
   - `margin_aum_estimate` (Margin AUM - Est)
   - `days_open` (Days Open)

**Sort**: `days_open` (Descending - oldest first)

**Title**: "Detail Table - Active Deals (≤120 days)"

---

### 6.2 Detail Table - Potentially Stale Deals

1. Click **Add a chart** → **Table**
2. **Data Source**: SGM Open SQOs Detail
3. **Filter**: 
   - Create filter: `days_open_since_sqo > 120`
   - Or use: `is_stale = 1` (if available)
4. **Same columns as Active Deals table**

**Sort**: `days_open` (Descending - oldest first)

**Title**: "Detail Table - Potentially Stale Deals (>120 days)"

**Style**: Use red text or background to highlight urgency

---

## Step 7: Add Filters and Controls

### 7.1 SGM Filter

1. Click **Add a control** → **Filter control** → **Dropdown list**
2. **Data Source**: SGM Capacity & Coverage
3. **Control field**: `sgm_name`
4. **Allow multiple selections**: Yes
5. **Default selection**: All
6. **Position**: Top of page, left side

### 7.2 Coverage Status Filter

1. Click **Add a control** → **Filter control** → **Checkbox**
2. **Data Source**: SGM Capacity & Coverage
3. **Control field**: `coverage_status`
4. **Allow multiple selections**: Yes
5. **Position**: Top of page, next to SGM filter

### 7.3 Date Filter (Optional - for historical tracking)

1. Click **Add a control** → **Filter control** → **Date range**
2. **Data Source**: SGM Capacity & Coverage
3. **Control field**: `as_of_date`
4. **Position**: Top of page, right side

---

## Step 8: Enable Cross-Filtering

1. Select any chart
2. In the **Style** tab, find **Interactions**
3. Enable **Cross-filtering**
4. Repeat for all charts

**This allows**: Clicking on an SGM in one chart filters all other charts

---

## Step 9: Add Page Title and Description

1. Click **Add a chart** → **Text**
2. **Title**: "SGM Capacity & Coverage Dashboard"
3. **Subtitle**: 
   ```
   Quarterly Target: $3.67M Margin AUM per SGM
   Last Updated: [as_of_date]
   ```
4. **Position**: Top of page, above filters

---

## Step 10: Formatting and Styling

### 10.1 Color Scheme

**Consistent Colors**:
- **Target**: Gold (#FFD700)
- **Capacity (Estimate)**: Blue (#4285F4)
- **Capacity (Actual)**: Light gray (#CCCCCC)
- **Sufficient**: Green (#34A853)
- **At Risk**: Yellow (#FBBC04)
- **Under-Capacity**: Red (#EA4335)
- **Current Quarter Actuals**: Teal (#00BCD4)

### 10.2 Layout

**Recommended Layout**:
```
┌─────────────────────────────────────────────────────────┐
│  PAGE TITLE & DESCRIPTION                               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FILTERS: [SGM] [Coverage Status] [Date]              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FIRM-WIDE SCORECARDS (4 cards in a row)               │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FIRM-WIDE COVERAGE GAUGE (Large, centered)            │
└─────────────────────────────────────────────────────────┘

┌──────────────────────────┬──────────────────────────────┐
│  CAPACITY VS TARGET      │  COVERAGE DISTRIBUTION       │
│  (Bar Chart)             │  (Pie Chart)                │
└──────────────────────────┴──────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  SGM COVERAGE SUMMARY TABLE (New - High Level)         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  SGM CAPACITY BAR CHART (Detailed Pipeline)            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  SGM CAPACITY SUMMARY TABLES (3 tables)                │
│  - Margin AUM                                          │
│  - Potentially Stale Pipeline                          │
│  - SQOs                                                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  GAP ANALYSIS TABLE                                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  HISTORICAL METRICS TABLE                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  DETAIL TABLES                                          │
│  - Active Deals (≤120 days)                            │
│  - Potentially Stale Deals (>120 days)                 │
└─────────────────────────────────────────────────────────┘
```

---

## Step 11: Create Calculated Fields (Optional but Recommended)

### 11.1 Coverage Percentage

**Name**: `Coverage Percentage (Estimate)`
**Formula**: 
```
coverage_ratio_estimate * 100
```

### 11.2 Capacity Gap Percentage

**Name**: `Capacity Gap Percentage`
**Formula**:
```
(capacity_gap_millions_estimate / quarterly_target_margin_aum_millions) * 100
```

### 11.3 Stale Pipeline Percentage

**Name**: `Stale Pipeline %`
**Formula**:
```
SAFE_DIVIDE(stale_sqo_count, active_sqo_count) * 100
```

### 11.4 Difference: Estimate vs Actual

**Name**: `Capacity Difference (Estimate - Actual)`
**Formula**:
```
sgm_capacity_expected_joined_aum_millions_estimate - 
sgm_capacity_expected_joined_aum_millions_actual_includes_stale
```

### 11.5 SGM Capacity Breakdown (For Scorecard Display)

**Name**: `SGM Capacity Formula Components`
**Formula** (for display purposes):
```
"Active SQOs: " + CAST(non_stale_sqo_count AS STRING) + 
" × Join Prob: " + CAST(ROUND(sqo_to_joined_conversion_rate * 100, 1) AS STRING) + "%" +
" × Avg Margin AUM: $" + CAST(ROUND(avg_margin_aum_per_joined_millions, 2) AS STRING) + "M"
```

**Or create separate calculated fields**:

**Name**: `Active SQO Count (for Capacity)`
**Formula**:
```
non_stale_sqo_count
```

**Name**: `Join Probability %`
**Formula**:
```
sqo_to_joined_conversion_rate * 100
```

**Name**: `Avg Margin AUM per Joined (M)`
**Formula**:
```
avg_margin_aum_per_joined_millions
```

**Name**: `Capacity Calculation Verification`
**Formula** (simplified version - should approximate capacity):
```
non_stale_sqo_count * sqo_to_joined_conversion_rate * avg_margin_aum_per_joined_millions
```

**Note**: The actual capacity calculation uses weighted pipeline value (which accounts for stage probabilities and individual deal sizes), then multiplies by conversion rate. The simplified formula above (count × rate × average) is an approximation. For exact capacity, use `sgm_capacity_expected_joined_aum_millions_estimate`.

---

## Step 12: Set Refresh Schedule

1. Click **File** → **Report settings**
2. **Data freshness**: 
   - Recommended: **Every 4 hours** (or daily for executive dashboards)
3. **Cache**: Enable for faster loading

---

## Step 13: Test and Validate

### 13.1 Test Filters

- Select individual SGMs
- Select multiple SGMs
- Filter by coverage status
- Verify all charts update correctly

### 13.2 Validate Numbers

- Check that Coverage Summary table matches Capacity tables
- Verify Coverage Ratio calculations (should be Capacity / 3.67)
- Confirm stale counts match detail tables

### 13.3 Test Drill-Down

- Click on SGM name in table
- Verify detail tables filter correctly
- Check Salesforce links work

---

## Step 14: Add Tooltips and Help Text

### 14.1 Add Tooltips to Key Metrics

1. Select a scorecard or chart
2. In **Style** tab, add **Tooltip**
3. Add explanatory text:

**Example Tooltips**:
- **Coverage Ratio**: "Expected joined AUM capacity divided by target ($3.67M). 1.0 = on target."
- **Capacity (Estimate)**: "Active weighted pipeline value × conversion rate. Excludes stale deals."
- **Capacity (Actual)**: "Total weighted pipeline value × conversion rate. Includes stale deals."

### 14.2 Add Help Text Section

1. Click **Add a chart** → **Text**
2. Add explanation:
   ```
   Key Metrics:
   - Coverage Ratio: Capacity ÷ Target ($3.67M). ≥1.0 = Sufficient, 0.85-1.0 = At Risk, <0.85 = Under-Capacity
   - Capacity (Estimate): Most realistic forecast using active (non-stale) deals
   - Capacity (Actual): Includes stale deals - use to identify pipeline hygiene issues
   ```
3. Position: Top of page, below title

---

## Quick Reference: Key Field Mappings

### High-Level Summary (New)
- **Coverage Ratio**: `coverage_ratio_estimate` (recommended)
- **Capacity**: `sgm_capacity_expected_joined_aum_millions_estimate` (recommended)
  - **Formula**: Active SQOs × Join Probability × Avg Margin AUM per Joined
  - **Components**:
    - Active SQOs: `non_stale_sqo_count`
    - Join Probability: `sqo_to_joined_conversion_rate`
    - Avg Margin AUM per Joined: `avg_margin_aum_per_joined_millions`
- **Status**: `coverage_status` (Sufficient/At Risk/Under-Capacity)
- **Target**: `quarterly_target_margin_aum_millions` ($3.67M)

### Detailed Metrics (Existing)
- **Pipeline Weighted Estimate**: `current_pipeline_sqo_weighted_margin_aum_estimate`
- **Pipeline Weighted Actual**: `current_pipeline_sqo_weighted_margin_aum`
- **Stale Pipeline**: `current_pipeline_sqo_stale_margin_aum_estimate`
- **Required SQOs**: `required_sqos_per_quarter`
- **SQO Gap**: `sqo_gap_count`

---

## Troubleshooting

**Issue**: Coverage ratio showing as NULL
- **Solution**: Check that `sqo_to_joined_conversion_rate` is not NULL

**Issue**: Numbers don't match between tables
- **Solution**: Verify you're using the same data source and filters

**Issue**: Charts not updating with filters
- **Solution**: Enable cross-filtering in chart settings

**Issue**: Target shows as $36.75M instead of $3.67M
- **Solution**: Make sure you're using `vw_sgm_capacity_coverage` view (updated target)

---

## Next Steps

1. **Share dashboard** with stakeholders
2. **Set up alerts** for SGMs dropping below 0.85 coverage
3. **Create email reports** for weekly capacity reviews
4. **Add time-series charts** to track coverage trends over time

---

## Summary

You now have a comprehensive dashboard with:
✅ **High-level summaries** at the top (executive-ready)
✅ **Coverage metrics** integrated with capacity metrics
✅ **Detailed tables** at the bottom (for drill-down)
✅ **Row-level details** for individual opportunities
✅ **Filters and cross-filtering** for interactive analysis

The dashboard answers:
- **"Do we have enough pipeline?"** (Coverage Ratio)
- **"Who needs attention?"** (Sorted by coverage, lowest first)
- **"Why are they at risk?"** (Gap analysis, stale pipeline %)
- **"What specific deals need work?"** (Detail tables)

