# SGM Capacity & Coverage Dashboard - Structure Guide

## Recommended Dashboard Layout

### Page 1: Executive Overview (High-Level)

This is your main landing page - designed for 30-second executive reviews.

```
┌─────────────────────────────────────────────────────────────────┐
│  FIRM-WIDE SUMMARY (Top Row - 4 Scorecards)                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Total   │ │Sufficient │ │ At Risk  │ │Under-Cap  │        │
│  │ SGMs    │ │ Capacity  │ │          │ │           │        │
│  │   12    │ │    5      │ │    4     │ │    3      │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FIRM-WIDE COVERAGE GAUGE (Center - Large)                      │
│                                                                  │
│              ┌─────────────────────┐                           │
│              │                     │                           │
│              │    Coverage: 0.92   │                           │
│              │    (At Risk)        │                           │
│              │                     │                           │
│              └─────────────────────┘                           │
│                                                                  │
│  Target: $3.67M per SGM | Current Capacity: $3.38M avg        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────┬──────────────────────────┐
│  CAPACITY vs TARGET (Bar Chart)     │  COVERAGE DISTRIBUTION   │
│  ┌──────────────────────────────┐   │  ┌──────────────────┐   │
│  │ SGM 1  ████████░░ 0.95       │   │  │ Sufficient: 42%  │   │
│  │ SGM 2  ██████████ 1.10       │   │  │ At Risk: 33%     │   │
│  │ SGM 3  ██████░░░░ 0.75       │   │  │ Under-Cap: 25%   │   │
│  │ ...                          │   │  └──────────────────┘   │
│  └──────────────────────────────┘   │                          │
│  [Gold = Target | Blue = Capacity]   │  [Pie/Donut Chart]       │
└──────────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  SGM CAPACITY TABLE (Sortable, Filterable)                      │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │ SGM Name │Capacity  │ Coverage │  Status  │   Gap    │      │
│  │          │(Estimate)│  Ratio   │          │          │      │
│  ├──────────┼──────────┼──────────┼──────────┼──────────┤      │
│  │ SGM A    │ $3.85M   │  1.05    │ Sufficient│  +$0.18M │      │
│  │ SGM B    │ $3.45M   │  0.94    │ At Risk  │  -$0.22M │      │
│  │ SGM C    │ $2.80M   │  0.76    │Under-Cap │  -$0.87M │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
│                                                                  │
│  [Click any row to drill down to SGM details]                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Component Specifications

### Section 1: Firm-Wide Summary Scorecards

**Purpose**: Instant understanding of overall health

**4 Scorecards** (equal width, horizontal row):

1. **Total Active SGMs**
   - Metric: `COUNT_DISTINCT(sgm_name)`
   - Format: Number
   - Color: Neutral (Blue/Gray)

2. **SGMs with Sufficient Capacity**
   - Metric: `COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate >= 1.0 THEN sgm_name END)`
   - Format: Number
   - Color: Green (#34A853)
   - Subtitle: "On Track"

3. **SGMs At Risk**
   - Metric: `COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate >= 0.85 AND coverage_ratio_estimate < 1.0 THEN sgm_name END)`
   - Format: Number
   - Color: Yellow/Amber (#FBBC04)
   - Subtitle: "Needs Attention"

4. **SGMs Under-Capacity**
   - Metric: `COUNT_DISTINCT(CASE WHEN coverage_ratio_estimate < 0.85 THEN sgm_name END)`
   - Format: Number
   - Color: Red (#EA4335)
   - Subtitle: "Critical"

**Optional 5th Card**: Average Coverage Ratio
- Metric: `AVG(coverage_ratio_estimate)`
- Format: Percentage (1 decimal)
- Color: Based on value (Green/Yellow/Red)

---

### Section 2: Firm-Wide Coverage Gauge

**Purpose**: Single visual indicator of overall capacity health

**Type**: Large Gauge Chart (centered, prominent)

**Configuration**:
- **Metric**: `AVG(coverage_ratio_estimate)` across all SGMs
- **Min**: 0
- **Max**: 1.5
- **Thresholds**:
  - Red: 0 - 0.85 (Under-Capacity)
  - Yellow: 0.85 - 1.0 (At Risk)
  - Green: 1.0 - 1.5 (Sufficient)

**Additional Text Below Gauge**:
- "Target: $3.67M per SGM"
- "Average Capacity: $X.XXM"
- "Total Expected: $XX.XXM | Total Target: $XX.XXM"

---

### Section 3: Capacity vs Target Bar Chart

**Purpose**: Visual comparison of each SGM's capacity against target

**Type**: Horizontal Grouped Bar Chart

**Configuration**:
- **Dimension**: `sgm_name`
- **Metrics**:
  - `quarterly_target_margin_aum_millions` (Gold bar, fixed at $3.67M)
  - `sgm_capacity_expected_joined_aum_millions_estimate` (Blue bar, variable)
- **Sort**: By `coverage_ratio_estimate` (ascending - lowest first)
- **Color by**: `coverage_status` (Green/Yellow/Red)

**Chart Title**: "SGM Capacity vs Target ($3.67M)"

**Optional**: Add a third bar for Actual (includes stale) in gray for comparison

---

### Section 4: Coverage Distribution

**Purpose**: Quick view of how SGMs are distributed across status categories

**Type**: Pie Chart or Donut Chart

**Configuration**:
- **Dimension**: `coverage_status`
- **Metric**: `COUNT_DISTINCT(sgm_name)`
- **Colors**:
  - Sufficient: Green (#34A853)
  - At Risk: Yellow (#FBBC04)
  - Under-Capacity: Red (#EA4335)

**Alternative**: Use a horizontal bar chart showing counts for each status

---

### Section 5: SGM Capacity Table

**Purpose**: Detailed, sortable, filterable view of all SGMs

**Type**: Table with conditional formatting

**Columns** (in order of importance):

1. **SGM Name** (`sgm_name`)
   - Format: Text
   - Make clickable for drill-down

2. **Coverage Status** (`coverage_status`)
   - Format: Text
   - Color code: Green/Yellow/Red

3. **Coverage Ratio (Estimate)** (`coverage_ratio_estimate`)
   - Format: Percentage (1 decimal, e.g., "94.5%")
   - Conditional formatting:
     - Green if >= 1.0
     - Yellow if >= 0.85 and < 1.0
     - Red if < 0.85

4. **Capacity (Estimate)** (`sgm_capacity_expected_joined_aum_millions_estimate`)
   - Format: Currency (Millions, 2 decimals, e.g., "$3.45M")
   - Sortable

5. **Target** (`quarterly_target_margin_aum_millions`)
   - Format: Currency (Millions, 2 decimals, "$3.67M")
   - Fixed value

6. **Gap** (`capacity_gap_millions_estimate`)
   - Format: Currency (Millions, 2 decimals)
   - Color: Red if negative, Green if positive
   - Sortable

7. **Active SQOs** (`non_stale_sqo_count`)
   - Format: Number
   - Tooltip: "Non-stale SQOs in pipeline"

8. **Stale SQOs** (`stale_sqo_count`)
   - Format: Number
   - Color: Red if > 0
   - Tooltip: "SQOs older than 120 days"

**Optional Additional Columns**:
- **Coverage Ratio (Actual)** - for comparison
- **Current Quarter Actual** - for performance tracking
- **Conversion Rate** - for context

**Default Sort**: By `coverage_ratio_estimate` (ascending - lowest first)

**Filters**:
- SGM Name (multi-select dropdown)
- Coverage Status (checkbox)
- Date range (if you add historical tracking)

**Row Actions**: Click row to drill down to SGM detail page

---

## Page 2: SGM Detail (Drill-Down)

**Purpose**: Deep dive into individual SGM performance

**Trigger**: Click on SGM name from main table

**Layout**:

```
┌─────────────────────────────────────────────────────────────────┐
│  SGM: [Name] - Capacity & Coverage Detail                       │
│  [Back to Overview Button]                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  KEY METRICS (4 Scorecards)                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │ Capacity │ │ Coverage │ │  Active  │ │  Stale   │        │
│  │ $3.45M   │ │   0.94   │ │   12 SQOs│ │  3 SQOs  │        │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────┬──────────────────────────┐
│  ACTUAL vs ESTIMATE COMPARISON       │  QUARTERLY PROGRESS      │
│  ┌──────────────────────────────┐   │  ┌──────────────────┐   │
│  │ Estimate: $3.45M (94%)       │   │  │ Target: $3.67M    │   │
│  │ Actual:   $4.20M (114%)      │   │  │ Actual: $1.20M    │   │
│  │                              │   │  │ Progress: 33%    │   │
│  │ [Difference: +$0.75M]        │   │  │                  │   │
│  └──────────────────────────────┘   │  └──────────────────┘   │
│  [Bar comparison chart]              │  [Progress bar/gauge]   │
└──────────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  PIPELINE BREAKDOWN                                              │
│  - Active Weighted Pipeline: $X.XXM                             │
│  - Total Weighted Pipeline: $X.XXM                              │
│  - Stale Pipeline: $X.XXM (XX% of total)                       │
│  - Conversion Rate: XX%                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Page 3: Actual vs Estimate Comparison (Optional)

**Purpose**: Understand the impact of stale deals and data quality

**Layout**:

```
┌─────────────────────────────────────────────────────────────────┐
│  ACTUAL vs ESTIMATE ANALYSIS                                     │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────┬──────────────────────────┐
│  CAPACITY COMPARISON (Bar Chart)     │  COVERAGE COMPARISON     │
│  [Grouped bars: Estimate vs Actual]   │  [Grouped bars]          │
└──────────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  DIFFERENCE ANALYSIS TABLE                                       │
│  Shows: Estimate - Actual for each SGM                          │
│  Highlights: Large differences (potential stale deal issues)     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Design Principles

### 1. **Hierarchy of Information**
- Most important (firm-wide health) at the top
- Individual SGM details below
- Drill-downs for specifics

### 2. **Color Coding Consistency**
- Green: Sufficient/On Track (≥1.0)
- Yellow: At Risk (0.85-1.0)
- Red: Under-Capacity (<0.85)

### 3. **Progressive Disclosure**
- Overview page: High-level summary
- Detail page: Individual SGM deep dive
- Optional: Actual vs Estimate analysis

### 4. **Actionable Insights**
- Sort by coverage ratio (lowest first) to prioritize attention
- Highlight gaps clearly
- Show stale SQO counts to identify cleanup needs

### 5. **Comparison Context**
- Always show target ($3.67M) for reference
- Compare estimate vs actual to identify data quality issues
- Show current quarter actuals for performance tracking

---

## Recommended Filters (Top of Dashboard)

1. **SGM Name** - Multi-select dropdown
2. **Coverage Status** - Checkbox (Sufficient/At Risk/Under-Capacity)
3. **Date** - Date range picker (if tracking historical trends)

---

## Mobile/Responsive Considerations

For mobile views:
- Stack scorecards vertically (2x2 grid)
- Simplify table to 3-4 key columns
- Use single metric per chart
- Hide less critical details

---

## Quick Start Checklist

- [ ] Create Page 1: Executive Overview
- [ ] Add 4 scorecards (Total, Sufficient, At Risk, Under-Capacity)
- [ ] Add firm-wide coverage gauge
- [ ] Add capacity vs target bar chart
- [ ] Add coverage distribution chart
- [ ] Add SGM capacity table with conditional formatting
- [ ] Set default sort to coverage ratio (ascending)
- [ ] Add filters (SGM Name, Coverage Status)
- [ ] Enable cross-filtering between charts
- [ ] Create Page 2: SGM Detail (drill-down)
- [ ] Test with sample data
- [ ] Set refresh schedule (recommended: every 4 hours)

---

## Example Dashboard Title & Subtitle

**Title**: "SGM Capacity & Coverage Dashboard"

**Subtitle**: "Quarterly Target: $3.67M Margin AUM per SGM | Last Updated: [as_of_date]"

**Key Insight Box** (optional, top right):
- "Firm-Wide Coverage: XX%"
- "SGMs At Risk: X"
- "Total Capacity Gap: $X.XXM"

