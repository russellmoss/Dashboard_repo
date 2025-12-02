# SGM Capacity Model Views: Logic Review & Documentation

## V1 vs V2 Model Summary

| Aspect | V1 Model | V2 Model |
|--------|----------|----------|
| **Valuation** | Static divisors (3.125, 3.22) | Dynamic divisors (3.30, 3.80) calculated from recent joined deals |
| **Stale Logic** | Static 120-day threshold for all deals | Deal-size dependent thresholds (<$5M: 90d, $5M-$15M: 120d, $15M-$30M: 180d, ≥$30M: 240d) |
| **Forecasting** | Conversion rate multiplication (double-counting risk) | Stage probabilities only (no double-counting) |
| **Enterprise** | Included in firm-wide averages (inflated metrics) | Excluded from firm-wide averages (≥$30M threshold) |

## Overview

This document provides a comprehensive review of the logic behind four key SQL views that power the SGM (Strategic Growth Manager) Capacity & Coverage Dashboard:

1. **`vw_sgm_capacity_model_refined`** - Core capacity model with pipeline analysis
2. **`vw_sgm_capacity_coverage`** - Executive-ready capacity and coverage metrics
3. **`vw_sgm_capacity_coverage_with_forecast`** - Enhanced view with quarterly forecasts
4. **`vw_sgm_open_sqos_detail`** - Detailed view of all open SQOs by SGM

These views implement the **V2 Capacity Model**, which uses data-driven thresholds and deal-size dependent logic to provide accurate capacity planning and forecasting.

---

## Table of Contents

1. [Core Concepts & Methodology](#core-concepts--methodology)
2. [View-by-View Logic Review](#view-by-view-logic-review)
3. [Dashboard Components Logic](#dashboard-components-logic)
4. [Data-Driven Decisions & Thresholds](#data-driven-decisions--thresholds)
5. [Calculation Formulas](#calculation-formulas)

---

## Core Concepts & Methodology

### V2 Capacity Model Philosophy

The V2 model addresses key limitations identified in earlier versions:

1. **Dynamic Valuation**: Uses calculated divisors from recent joined deals (3.30 for Underwritten_AUM, 3.80 for Amount) instead of static estimates
2. **Deal-Size Dependent Logic**: Recognizes that larger deals take longer and have different characteristics
3. **Probability-Based Forecasting**: Uses stage probabilities rather than simple conversion rates to avoid double-counting
4. **Active vs. Total Pipeline**: Distinguishes between active (non-stale) and total pipeline to provide realistic capacity estimates

### Capacity vs. Forecast

**Capacity** is a measure of inventory sufficiency (do we have enough pipeline?), whereas **Forecast** is a measure of timing (will it close this quarter?).

- **Capacity**: Answers "Do we have enough pipeline value to theoretically hit our target?" It's a forward-looking measure of pipeline sufficiency, regardless of when deals will close.
- **Forecast**: Answers "What do we expect to close this quarter?" It's a timing-specific prediction that considers deal velocity, stage progression, and quarterly boundaries.

**Key Distinction**: An SGM can have sufficient **Capacity** (enough pipeline value) but a weak **Forecast** for the current quarter (deals won't close in time). Conversely, an SGM can have strong current quarter **Forecast** but insufficient **Capacity** for future quarters (pipeline will run dry).

### Momentum Validation

**The Finding**: Analysis of 766 opportunities revealed that deals under 180 days win at a higher rate (16.0%) than survivors >180 days (10.5%). This data-driven insight fundamentally changes our modeling approach.

**The Pivot**: Consequently, we have removed the "New Deal Discount". The model now prioritizes fresh momentum. We apply full stage weighting to fresh deals (0-180 days) and apply a conservative "Momentum Decay" factor (0.80x) to older active deals to reflect the statistical drop in win rate as time passes.

**Key Implications**:
- **Fresh deals are more valuable**: Deals that close quickly (≤180 days) demonstrate stronger buyer intent and higher conversion rates
- **Time is the enemy**: Deals that linger beyond 180 days show declining win rates, justifying the momentum decay factor
- **Data-driven confidence**: The model now reflects actual historical performance rather than conservative assumptions

### Capacity Calculation Flow

[insert mermaid diagram here]

**Flow Explanation**:
1. **Is SQO?**: Only opportunities marked as SQO (SQL__c = 'yes') are considered
2. **Is Active?**: Deals must pass deal-size dependent stale thresholds to be included
   - **If NO**: Deal is excluded from capacity (goes to "Excluded from Capacity")
   - **If YES**: Proceeds to step 3
3. **Apply Valuation**: Use actual Margin_AUM or estimate using dynamic divisors
4. **Apply Stage Probability**: Multiply by probability of stage converting to "Joined"
5. **Apply Momentum Decay**: Older active deals (>180 days but still active) get 0.80x decay factor
   - **Important**: Only deals that passed step 2 (Is Active?) can reach this step
   - **Practical Impact**: Momentum decay primarily affects Enterprise deals (≥$30M) that are 180-240 days old, because:
     - Small deals (<$5M) >90 days: Already excluded (stale)
     - Medium deals ($5M-$15M) >120 days: Already excluded (stale)
     - Large deals ($15M-$30M) >180 days: Already excluded (stale)
     - Enterprise deals (≥$30M) 180-240 days: Still active, so get momentum decay
6. **Final Capacity**: Sum of all weighted values for active deals (fresh deals get full value)

### Key Metrics Definitions

#### Capacity (SGM Capacity)
**Capacity** is the forward-looking forecast of expected quarterly joined Margin AUM an SGM's active pipeline can produce.

- **Formula**: `Capacity = Active Weighted Pipeline Value`
- **Logic**: Uses active, non-stale SQOs weighted by stage probability (no additional conversion rate multiplication needed - stage probabilities already account for conversion)
- **Purpose**: Answers "Do we have enough pipeline to hit future quarterly targets?"

**Note on Weighting**: We calculate capacity using Stage Probability. We do *not* multiply this by the SQO→Joined conversion rate again, as the stage probability inherently contains the likelihood of reaching 'Joined' status. Multiplying by the conversion rate would be double-counting the conversion probability.

#### Coverage Ratio
**Coverage Ratio** measures whether an SGM's Capacity is sufficient to hit their quarterly target.

- **Formula**: `Coverage Ratio = Capacity / Target`
- **Target**: $36.75M Margin AUM per SGM per quarter
- **Interpretation**:
  - ≥ 1.0: Sufficient capacity
  - 0.85-0.99: At Risk
  - < 0.85: Under-Capacity

#### Active vs. Stale Pipeline
**Active Pipeline** includes only non-stale deals using dynamic thresholds:
- Small deals (<$5M): Active if ≤90 days old
- Medium deals ($5M-$15M): Active if ≤120 days old
- Large deals ($15M-$30M): Active if ≤180 days old
- Enterprise deals (≥$30M): Active if ≤240 days old

**Stale Pipeline** includes deals that exceed these thresholds and are less likely to close.

**Interaction with Momentum Decay**:
The momentum decay factor (0.80x for deals >180 days) only applies to deals that are still considered "active" (i.e., they passed the stale threshold check). This creates an important distinction:

- **Small deals (<$5M) >90 days**: Already excluded as stale, never reach momentum decay step
- **Medium deals ($5M-$15M) >120 days**: Already excluded as stale, never reach momentum decay step  
- **Large deals ($15M-$30M) >180 days**: Already excluded as stale, never reach momentum decay step
- **Enterprise deals (≥$30M) 180-240 days**: Still active (within 240-day threshold), so they receive momentum decay (0.80x)

**Practical Impact**: Momentum decay primarily (or exclusively) affects Enterprise deals that are between 180-240 days old, because all other deal sizes would already be excluded as stale by the time they reach 180 days. This is intentional - Enterprise deals have longer sales cycles, so they get a longer active window, but still receive conservative weighting as they age.

---

## View-by-View Logic Review

### 1. `vw_sgm_capacity_model_refined.sql`

#### Purpose
This is the foundational view that calculates all core capacity metrics, pipeline analysis, and required calculations for each SGM.

#### Key CTEs and Logic

##### Dynamic_Valuation_Params
Calculates dynamic divisors for estimating Margin_AUM when it's missing:
```sql
COALESCE(AVG(SAFE_DIVIDE(Underwritten_AUM__c, Margin_AUM__c)), 3.30) AS dyn_und_div
COALESCE(AVG(SAFE_DIVIDE(Amount, Margin_AUM__c)), 3.80) AS dyn_amt_div
```
- **Source**: Recent joined deals (last 12 months) where Margin_AUM__c > 0
- **Rationale**: Uses actual historical ratios rather than static estimates, improving accuracy when Margin_AUM is missing

##### Opp_Base
Base opportunity data with key calculations:

**Estimated Margin AUM** (V2 Dynamic Fallback Logic):
```sql
CASE
  WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 
    THEN o.Margin_AUM__c / 1000000
  WHEN o.Underwritten_AUM__c IS NOT NULL AND o.Underwritten_AUM__c > 0 
    THEN (o.Underwritten_AUM__c / vp.dyn_und_div) / 1000000
  WHEN o.Amount IS NOT NULL AND o.Amount > 0 
    THEN (o.Amount / vp.dyn_amt_div) / 1000000
  ELSE 0
END AS estimated_margin_aum
```
- **Priority**: Actual Margin_AUM > Estimated from Underwritten_AUM > Estimated from Amount
- **Result**: Always in millions for consistency

**Stage Probability**:
- Joins to `vw_stage_to_joined_probability` to get probability of each stage converting to "Joined"
- Used for weighted pipeline calculations

**SQO Age in Days**:
```sql
CASE 
  WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL
  THEN DATE_DIFF(c.current_date, DATE(o.Date_Became_SQO__c), DAY)
  ELSE NULL
END AS sqo_age_days
```
- Used for stale deal identification and momentum decay calculations

##### SGM_Historical_Metrics
Calculates SGM-specific historical averages (last 12 months):
- `avg_margin_aum_per_sqo`: Average Margin AUM per SQO
- `avg_margin_aum_per_joined`: Average Margin AUM per Joined deal
- `sqo_to_joined_conversion_rate`: Historical conversion rate

**Important**: These are used for reference and context, NOT for capacity calculations (which use stage probabilities).

##### Firm_Wide_Averages_Excluding_Enterprise
Calculates firm-wide averages **excluding enterprise deals (≥$30M)**:
- **Rationale**: Enterprise deals (like Bre McDaniel's) are fundamentally different in size and would inflate averages
- **Threshold**: $30M cleanly separates enterprise-focused SGMs from standard SGMs
- **Used for**: Required SQOs and Required Joined calculations

##### SGM_Current_Pipeline
Aggregates current pipeline metrics per SGM:

**Active Weighted Pipeline (V2 Logic)**:
```sql
SUM(CASE 
  WHEN o.is_sqo = 1 
  AND o.is_in_pipeline = 1
  AND (
    -- Dynamic stale logic based on deal size
    (o.estimated_margin_aum < 5 AND (o.sqo_age_days IS NULL OR o.sqo_age_days <= 90))
    OR (o.estimated_margin_aum >= 5 AND o.estimated_margin_aum < 15 AND (o.sqo_age_days IS NULL OR o.sqo_age_days <= 120))
    OR (o.estimated_margin_aum >= 15 AND o.estimated_margin_aum < 30 AND (o.sqo_age_days IS NULL OR o.sqo_age_days <= 180))
    OR (o.estimated_margin_aum >= 30 AND (o.sqo_age_days IS NULL OR o.sqo_age_days <= 240))
  )
  THEN o.estimated_margin_aum * o.stage_probability * 
    CASE 
      -- Momentum Decay: Older active deals (>180 days but still active) get 0.80x decay
      -- Fresh deals (0-180 days) get full value (1.0x) - data shows higher win rate
      WHEN o.sqo_age_days IS NOT NULL AND o.sqo_age_days > 180 THEN 0.80
      ELSE 1.0
    END
  ELSE 0 
END) AS current_pipeline_active_weighted_margin_aum_estimate
```

**Key Components**:
1. **Dynamic Stale Logic**: Deal-size dependent age thresholds (deals exceeding these are excluded entirely)
2. **Stage Probability**: Multiplies by probability to join (already accounts for conversion)
3. **Momentum Decay**: Older active deals (>180 days but still active) get 0.80x decay factor; fresh deals (0-180 days) get full value (1.0x)
   - **Critical Note**: Momentum decay only applies to deals that have already passed the "Is Active?" check. Since most deal sizes become stale before 180 days, momentum decay primarily affects Enterprise deals (≥$30M) that are 180-240 days old (still within their 240-day active threshold).

**Stale Metrics**:
- Calculates stale pipeline value and count using the same dynamic thresholds
- Used for pipeline hygiene analysis

**Current Quarter Actuals**:
- Counts and sums Margin AUM for deals that joined in the current quarter
- Used to compare actual performance vs. target

##### Required Calculations
**Required Joined Per Quarter**:
```sql
CEILING(36.75 / fw.firm_wide_avg_margin_aum_per_joined)
```
- Uses firm-wide average (excluding enterprise) to calculate how many joined advisors needed
- CEILING ensures we get whole numbers (can't convert 0.45 people)

**Required SQOs Per Quarter**:
```sql
CEILING(
  CEILING(36.75 / fw.firm_wide_avg_margin_aum_per_joined)
  / fw.firm_wide_sqo_to_joined_conversion_rate_365d
)
```
- First calculates required joined (whole number)
- Then calculates SQOs needed to achieve that (accounting for conversion rate)
- Uses firm-wide conversion rate from `vw_conversion_rates` (trailing 365 days)

#### Key Output Fields

- `quarterly_target_margin_aum`: $36.75M (constant)
- `current_pipeline_active_weighted_margin_aum_estimate`: Active weighted pipeline (most realistic for capacity)
- `current_pipeline_sqo_weighted_margin_aum`: Total weighted pipeline (includes stale)
- `required_sqos_per_quarter`: How many SQOs needed to hit target
- `current_quarter_joined_margin_aum`: Actual joined Margin AUM this quarter
- `sqo_gap_count`: Required SQOs - Current Pipeline SQOs

---

### 2. `vw_sgm_capacity_coverage.sql`

#### Purpose
Simplified, executive-ready view for Looker Studio that provides capacity and coverage metrics without the detailed pipeline breakdown.

#### Key Logic

##### Firm_Wide_Conversion_Rate
Calculates firm-wide average SQO→Joined conversion rate for fallback when SGM doesn't have enough history.

##### SGM_Data CTE
Joins `vw_sgm_capacity_model_refined` with User table to get:
- SGM created date (for "On Ramp" logic)
- Effective conversion rate (uses firm-wide for "On Ramp" SGMs)

**On Ramp Logic**:
```sql
CASE
  WHEN DATE_DIFF(CURRENT_DATE(), DATE(u.CreatedDate), DAY) <= 90 THEN 1
  ELSE 0
END AS is_on_ramp
```
- SGMs created within 90 days are considered "On Ramp"
- Their capacity is not calculated (they're still ramping)

##### Capacity Calculation
**Estimate Version** (Primary):
```sql
COALESCE(
  current_pipeline_active_weighted_margin_aum_estimate,
  0
) AS sgm_capacity_expected_joined_aum_millions_estimate
```
- Uses active weighted pipeline directly
- **No additional conversion rate multiplication** - stage probabilities already account for conversion
- This is the most realistic capacity metric

**Actual Version** (Includes Stale):
```sql
COALESCE(
  current_pipeline_sqo_weighted_margin_aum,
  0
) AS sgm_capacity_expected_joined_aum_millions_actual_includes_stale
```
- Includes stale deals, so it's higher than the estimate version
- Used for comparison but not primary capacity planning

##### Coverage Ratio
```sql
SAFE_DIVIDE(
  COALESCE(current_pipeline_active_weighted_margin_aum_estimate, 0),
  36.75
) AS coverage_ratio_estimate
```
- Capacity / Target
- 1.0 = Perfectly staffed
- >1.0 = Sufficient capacity
- <1.0 = Under-capacity

##### Coverage Status
```sql
CASE
  WHEN is_on_ramp = 1 THEN 'On Ramp'
  WHEN SAFE_DIVIDE(...) >= 1.0 THEN 'Sufficient'
  WHEN SAFE_DIVIDE(...) >= 0.85 THEN 'At Risk'
  ELSE 'Under-Capacity'
END AS coverage_status
```
- Checks "On Ramp" first
- Then evaluates coverage ratio against thresholds

#### Key Output Fields

- `sgm_capacity_expected_joined_aum_millions_estimate`: Primary capacity metric
- `coverage_ratio_estimate`: Coverage ratio (capacity/target)
- `coverage_status`: Categorical status (On Ramp/Sufficient/At Risk/Under-Capacity)
- `capacity_gap_millions_estimate`: Target - Capacity
- `non_stale_sqo_count`: Active SQOs (calculated as total - stale)
- `stale_sqo_count`: Stale SQOs

---

### 3. `vw_sgm_capacity_coverage_with_forecast.sql`

#### Purpose
Enhanced capacity coverage view that adds quarterly forecasts using deal-size dependent velocity and stage probabilities.

#### Key Logic

##### Dynamic_Valuation_Params
Same as `vw_sgm_capacity_model_refined` - calculates dynamic divisors.

##### Opp_With_Forecast CTE
Calculates projected join dates and quarterly assignments for each opportunity:

**Projected Join Date** (V2 Deal-Size Dependent Cycle Times):
```sql
CASE
  WHEN (deal_size) >= 30000000 THEN
    -- Enterprise (>$30M)
    CASE
      WHEN o.Stage_Entered_Signed__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 38 DAY)
      WHEN o.Stage_Entered_Negotiating__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 49 DAY)
      WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 94 DAY)
      ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 120 DAY)
    END
  WHEN (deal_size) >= 15000000 THEN
    -- Large ($15M-$30M)
    CASE
      WHEN o.Stage_Entered_Signed__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 18 DAY)
      WHEN o.Stage_Entered_Negotiating__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 37 DAY)
      WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 66 DAY)
      ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 90 DAY)
    END
  ELSE
    -- Standard (<$15M)
    CASE
      WHEN o.Stage_Entered_Signed__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 10 DAY)
      WHEN o.Stage_Entered_Negotiating__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 18 DAY)
      WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL 
        THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 49 DAY)
      ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 50 DAY)
    END
END AS projected_join_date
```

**Cycle Time Logic**:
- Uses most recent stage entered date if available
- Falls back to SQO date with default cycle time
- Deal-size dependent: Enterprise (120d), Large (90d), Standard (50d)

**Forecast Quarter Assignment**:
- Compares projected join date to current quarter end and next quarter end
- Assigns: 'Current Quarter', 'Next Quarter', or 'Beyond Next Quarter'

##### SGM_Quarterly_Forecast CTE
Aggregates forecast values by quarter per SGM:

**Current Quarter Forecast**:
```sql
SUM(CASE 
  WHEN o.is_in_pipeline = 1
    AND o.forecast_quarter = 'Current Quarter'
    AND (active deal conditions)
  THEN o.estimated_margin_aum * o.stage_probability * 
    CASE 
      -- Momentum Decay: Older active deals (>180 days but still active) get 0.80x decay
      -- Fresh deals (0-180 days) get full value (1.0x) - data shows higher win rate
      WHEN o.sqo_age_days IS NOT NULL AND o.sqo_age_days > 180 THEN 0.80
      ELSE 1.0
    END
  ELSE 0
END) AS current_quarter_forecast_weighted_margin_aum_estimate
```

**Next Quarter Forecast**:
- Same logic but for `forecast_quarter = 'Next Quarter'`

#### Key Output Fields

- `expected_to_join_this_quarter_margin_aum_millions`: Pipeline forecast for rest of current quarter
- `expected_to_join_next_quarter_margin_aum_millions`: Pipeline forecast for next quarter
- `total_expected_current_quarter_margin_aum_millions`: Current actuals + forecast for rest of quarter
- `total_expected_next_quarter_margin_aum_millions`: Forecast for next quarter

---

### 4. `vw_sgm_open_sqos_detail.sql`

#### Purpose
Detailed view of all open SQOs by SGM for verification and drill-down analysis.

#### Key Logic

**Estimated Margin AUM**:
- Uses V2 dynamic fallback logic matching the main capacity model
- Uses dynamic divisors (3.30 for Underwritten_AUM, 3.80 for Amount) calculated from recent joined deals
- Priority: Actual Margin_AUM > Estimated from Underwritten_AUM > Estimated from Amount

**Days Open Since SQO**:
```sql
DATE_DIFF(c.current_date, DATE(o.Date_Became_SQO__c), DAY)
```

**Is Stale** (V2 Logic - Deal-Size Dependent):
- Uses dynamic deal-size dependent thresholds matching V2 standards:
  - Small deals (<$5M): Stale if >90 days
  - Medium deals ($5M-$15M): Stale if >120 days
  - Large deals ($15M-$30M): Stale if >180 days
  - Enterprise deals (≥$30M): Stale if >240 days
- This view now fully matches V2 logic for consistency across all capacity views

**Velocity-Based Forecasting Fields** (V2 Logic - Deal-Size + Stage Dependent):
- `velocity_projected_close_date`: Uses deal-size and stage dependent cycle times:
  - **Enterprise (>$30M)**: Signed=38d, Negotiating=49d, Sales Process=94d, Default=120d
  - **Large ($15M-$30M)**: Signed=18d, Negotiating=37d, Sales Process=66d, Default=90d
  - **Standard (<$15M)**: Signed=10d, Negotiating=18d, Sales Process=49d, Default=50d
- `forecast_bucket`: Categorizes deals into buckets based on V2 velocity logic and status

#### Key Output Fields

- All opportunity details (name, stage, AUM values)
- `estimated_margin_aum`: Estimated Margin AUM (millions)
- `days_open_since_sqo`: Age of SQO
- `is_stale`: Stale flag (Yes/No)
- `forecast_bucket`: Velocity-based forecast category

---

## Dashboard Components Logic

### 1. Chart: SGM Capacity vs Target

**Data Source**: `vw_sgm_capacity_coverage`

**Fields Used**:
- X-Axis: SGM Name
- Y-Axis: Margin AUM (Millions)
- Series 1: `quarterly_target_margin_aum_millions` (constant $36.75M)
- Series 2: `sgm_capacity_expected_joined_aum_millions_estimate`

**Logic**:
- **Target Line**: Constant $36.75M for all SGMs (horizontal reference line)
- **Capacity Bars**: Active weighted pipeline value (estimate version)
- **Interpretation**: 
  - Bars above the line = Sufficient capacity
  - Bars below the line = Under-capacity
  - Gap between bar and line = Capacity gap

**Why This Metric**:
- Uses `sgm_capacity_expected_joined_aum_millions_estimate` (active weighted pipeline) because it's the most realistic forecast
- Excludes stale deals to provide accurate capacity assessment
- Stage probabilities already account for conversion, so no additional conversion rate needed

---

### 2. Table: SGM Coverage Status

**Data Source**: `vw_sgm_capacity_coverage`

**Fields**:
- `sgm_name`
- `coverage_status`
- `coverage_ratio_estimate`
- `sgm_capacity_expected_joined_aum_millions_estimate`
- `capacity_gap_millions_estimate`
- `non_stale_sqo_count` (calculated as `active_sqo_count - stale_sqo_count`)
- `stale_sqo_count`

**Logic**:

**Coverage Status**:
- **On Ramp**: SGM created within 90 days (capacity not calculated)
- **Sufficient**: Coverage ratio ≥ 1.0
- **At Risk**: Coverage ratio 0.85-0.99
- **Under-Capacity**: Coverage ratio < 0.85

**Coverage Ratio**:
- Formula: `Capacity / Target`
- Uses active weighted pipeline (estimate) divided by $36.75M
- Represents percentage of target capacity

**Capacity Gap**:
- Formula: `Target - Capacity`
- Negative gap = Over-capacity (good)
- Positive gap = Under-capacity (needs attention)

**SQO Counts**:
- `non_stale_sqo_count`: Active SQOs (within dynamic age thresholds)
- `stale_sqo_count`: Stale SQOs (exceeded age thresholds)
- Used to assess pipeline hygiene

---

### 3. Chart: Current Quarter Joined Margin AUM

**Data Source**: `vw_sgm_capacity_model_refined`

**Fields**:
- X-Axis: SGM Name
- Y-Axis: Margin AUM (Millions)
- Series 1: `quarterly_target_margin_aum` (constant $36.75M)
- Series 2: `current_quarter_joined_margin_aum`

**Logic**:
- **Target Line**: Constant $36.75M (horizontal reference)
- **Actual Bars**: Sum of Margin AUM for deals that joined in current quarter
- **Interpretation**:
  - Bars above line = Exceeded target this quarter
  - Bars below line = Behind target this quarter
  - Gap = How much more needed to hit target

**Why This Metric**:
- Shows actual performance (what has closed) vs. target
- Different from capacity (which is forward-looking)
- Used to assess current quarter performance and commission eligibility

---

### 4. Table: Quarterly Forecast

**Data Source**: `vw_sgm_capacity_coverage_with_forecast`

**Fields**:
- `sgm_name`
- `current_quarter_actual_joined_aum_millions`
- `expected_to_join_this_quarter_margin_aum_millions`
- `total_expected_current_quarter_margin_aum_millions`
- `total_expected_next_quarter_margin_aum_millions`

**Logic**:

**Current Quarter Actuals**:
- What has already closed this quarter (factual)
- Source: `current_quarter_joined_margin_aum` from base model

**Expected to Join This Quarter**:
- Pipeline forecast for rest of current quarter
- Uses deal-size dependent velocity and stage probabilities
- Only includes active (non-stale) deals

**Total Expected Current Quarter**:
- Formula: `Current Actuals + Expected from Pipeline`
- Complete picture: What's happened + What we expect
- Used to assess end-of-quarter forecast

**Total Expected Next Quarter**:
- Pipeline forecast for next quarter
- Leading indicator of future capacity
- Used to assess next quarter readiness

**Forecast Methodology**:
1. Calculates projected join date using deal-size dependent cycle times
2. Assigns deals to quarters based on projected date
3. Applies stage probability and momentum decay (0.80x for older active deals >180 days)
4. Sums weighted values by quarter

---

### 5. Table: SGM Capacity Summary - Margin AUM

**Data Source**: `vw_sgm_capacity_model_refined`

**Fields**:
- `sgm_name`
- `current_pipeline_sqo_margin_aum` (actual, unweighted)
- `current_pipeline_sqo_weighted_margin_aum` (actual, weighted)
- `current_pipeline_sqo_weighted_margin_aum_estimate` (estimate, weighted)
- `current_quarter_joined_margin_aum`

**Logic**:

**Unweighted Pipeline (Actual)**:
- Sum of actual Margin_AUM__c values for all SQOs in pipeline
- No probability weighting
- Includes stale deals
- Represents "raw" pipeline value

**Weighted Pipeline (Actual)**:
- Sum of actual Margin_AUM__c × stage_probability
- Accounts for conversion probability
- Includes stale deals
- More realistic than unweighted

**Weighted Pipeline (Estimate)**:
- Sum of estimated_margin_aum × stage_probability
- Uses estimates when Margin_AUM is missing
- Includes stale deals
- Most complete picture (handles missing data)

**Current Quarter Joined**:
- Actual Margin AUM that joined this quarter
- Used for comparison with pipeline

**Why Multiple Versions**:
- **Actual**: Most accurate when data is complete
- **Estimate**: Most complete when Margin_AUM is missing
- **Weighted**: Most realistic (accounts for conversion probability)
- **Unweighted**: Shows raw pipeline value

---

### 6. Table: SGM Capacity Summary - Potentially Stale Pipeline

**Data Source**: `vw_sgm_capacity_model_refined`

**Fields**:
- `sgm_name`
- `current_pipeline_sqo_stale_margin_aum` (actual)
- `current_pipeline_sqo_stale_margin_aum_estimate` (estimate)
- Stale % of pipeline (calculated: `stale_estimate / total_estimate * 100`)

**Logic**:

**Stale Pipeline (Actual)**:
- Sum of actual Margin_AUM__c for stale SQOs
- Uses dynamic deal-size dependent thresholds:
  - <$5M: >90 days
  - $5M-$15M: >120 days
  - $15M-$30M: >180 days
  - ≥$30M: >240 days

**Stale Pipeline (Estimate)**:
- Sum of estimated_margin_aum for stale SQOs
- More complete (handles missing Margin_AUM)

**Stale % of Pipeline**:
- Formula: `Stale Estimate / Total Pipeline Estimate * 100`
- Interpretation:
  - <10%: Healthy pipeline
  - 10-20%: Some cleanup needed
  - 20-30%: Significant cleanup needed
  - >30%: Major red flag (pipeline bloat)

**Why This Matters**:
- High stale % indicates pipeline hygiene issues
- Stale deals are less likely to close
- Enterprise SGMs (like Bre McDaniel) may have higher stale % due to longer cycles (acceptable if deals are progressing)

---

### 7. Table: SGM Capacity Summary - SQOs

**Data Source**: `vw_sgm_capacity_model_refined`

**Fields**:
- `sgm_name`
- `required_sqos_per_quarter`
- `current_pipeline_sqo_count`
- `avg_margin_aum_per_sqo`
- `avg_margin_aum_per_joined`
- `sqo_to_joined_conversion_rate`
- `sqo_gap_count`

**Logic**:

**Required SQOs Per Quarter**:
- Formula: `CEILING(CEILING(36.75 / avg_margin_aum_per_joined) / conversion_rate)`
- Uses firm-wide averages (excluding enterprise deals ≥$30M)
- Base case: ~40 SQOs per quarter
- Range: 24-56 SQOs (due to volatility in underlying data)

**Double Ceiling Logic**: We apply a "Double Ceiling" logic. First, we calculate that we need a *whole number* of human advisors to join (e.g., CEILING(3.4) = 4). Then, based on that whole number, we calculate the SQOs required. This ensures we never plan for fractional human outcomes. You can't convert 0.45 people - you need whole advisors, so we ensure our calculations reflect that reality.

**Current Pipeline SQOs**:
- Count of all open SQOs in pipeline
- Includes stale SQOs
- Used to assess pipeline quantity

**Average Margin AUM Per SQO**:
- Historical average (last 12 months)
- SGM-specific if available, otherwise firm-wide
- Used for context and comparison

**Average Margin AUM Per Joined**:
- Historical average (last 12 months)
- SGM-specific if available, otherwise firm-wide
- Used for required calculations

**SQO to Joined Conversion Rate**:
- Historical rate (last 12 months)
- SGM-specific if available, otherwise firm-wide
- Used for required calculations

**SQO Gap Count**:
- Formula: `Required SQOs - Current Pipeline SQOs`
- Positive gap = Need more SQOs
- Negative gap = Have sufficient SQOs
- Used to assess pipeline sufficiency

**Volatility Context**:
- Required SQOs has ±16 SQO range due to:
  - Margin AUM volatility (48.8% coefficient of variation)
  - Conversion rate uncertainty (7.26%-12.83% CI)
- Interpretation thresholds:
  - ≥40 SQOs: On Target
  - 32-39 SQOs: Close to Target
  - 24-31 SQOs: Within Range
  - <24 SQOs: Significant/Critical Gap

---

## Data-Driven Decisions & Thresholds

### Deal-Size Dependent Stale Thresholds

**Decision**: Use dynamic thresholds based on deal size rather than a single 120-day cutoff.

**Rationale** (from data analysis):
- 25.26% of joined AUM comes from deals that took >120 days
- Larger deals naturally take longer to close
- Average cycle time is 77 days, but enterprise deals often take 120+ days

**Thresholds**:
- **Small Deals (<$5M)**: 90 days
- **Medium Deals ($5M-$15M)**: 120 days
- **Large Deals ($15M-$30M)**: 180 days
- **Enterprise Deals (≥$30M)**: 240 days

**Impact**: Prevents excluding healthy large deals from active pipeline while still flagging truly stale deals.

---

### Enterprise Deal Exclusion ($30M Threshold)

**Decision**: Exclude deals ≥$30M from firm-wide averages for required calculations.

**Rationale** (from data analysis):
- Bre McDaniel (Enterprise SGM): 8 of 19 deals (42.1%) are ≥$30M, avg $49.81M
- All Other SGMs: 0 deals ≥$30M (max $21.15M)
- Including enterprise increases average by 63% ($11.35M → $18.51M)
- Increases volatility by 88% (48.8% → 91.5% coefficient of variation)
- $30M cleanly separates enterprise-focused SGM from standard SGMs

**Impact**: Provides realistic required metrics for standard SGMs without inflation from enterprise deals.

---

### Dynamic Valuation Divisors

**Decision**: Use calculated divisors from recent joined deals instead of static estimates.

**Previous Values**:
- Underwritten_AUM: 3.125 (static)
- Amount: 3.22 (static)

**V2 Values** (calculated from last 12 months):
- Underwritten_AUM: 3.30 (dynamic)
- Amount: 3.80 (dynamic)

**Rationale**:
- Static values were underestimating by 16-23% when Margin_AUM was missing
- Dynamic values reflect actual current ratios
- Recalculated periodically to stay current

**Impact**: More accurate capacity estimates when Margin_AUM is missing.

---

### Momentum-Based Probability Weighting

**Decision**: Prioritize fresh momentum based on data validation showing higher win rates for deals <180 days.

**Weighting Factors**:
- Fresh deals (0-180 days): 1.0x (full value) - data shows 16.0% win rate
- Older active deals (>180 days but still active): 0.80x (momentum decay) - data shows 10.5% win rate
- Stale deals (exceed threshold): 0.0x (excluded)

**Rationale**:
- Data analysis of 766 opportunities revealed deals <180 days win at 16.0% vs. 10.5% for >180 days
- Fresh deals demonstrate stronger buyer intent and faster decision-making
- Momentum decay factor reflects statistical reality: win rates decline as deals age
- Model now reflects actual historical performance rather than conservative assumptions

**Impact**: More accurate forecasts that reward fresh momentum while conservatively adjusting for aging deals.

---

### Stage Probability vs. Conversion Rate

**Decision**: Use stage probabilities only, not additional SQO→Joined conversion rate multiplication.

**Rationale**:
- Stage probabilities already account for conversion to "Joined"
- Multiplying by conversion rate would be double-counting
- Weighted pipeline = `Margin_AUM × Stage_Probability` (no additional conversion rate)

**Impact**: More accurate capacity calculations without double-counting.

---

### Required SQOs Calculation Methodology

**Decision**: Use firm-wide averages (excluding enterprise) with volatility context.

**Formula**:
1. `Required Joined = CEILING(36.75 / avg_margin_aum_per_joined)`
2. `Required SQOs = CEILING(Required Joined / conversion_rate)`

**Volatility Range**:
- Base Case: 40 SQOs (using $11.35M avg, 10.04% conversion)
- Range: 24-56 SQOs (±16 SQOs)
- Due to:
  - Margin AUM volatility (48.8% CV, range $3.75M-$23.09M)
  - Conversion rate uncertainty (7.26%-12.83% CI)

**Interpretation Thresholds** (calculated dynamically):
- **Within Range**: ≥24 SQOs (lower bound of CI)
- **Close to Target**: ≥32 SQOs (midpoint)
- **On Target**: ≥40 SQOs (base case)
- **Exceeding Target**: >40 SQOs

**Impact**: Provides realistic guidance while acknowledging uncertainty in underlying data.

---

## Calculation Formulas

### Capacity (Primary Metric)

```
Capacity = Active Weighted Pipeline Value
         = Σ(estimated_margin_aum × stage_probability × momentum_factor)
         WHERE deal is active (non-stale based on dynamic thresholds)
```

**Components**:
- `estimated_margin_aum`: Actual Margin_AUM or estimated using dynamic divisors
- `stage_probability`: Probability of stage converting to "Joined" (from `vw_stage_to_joined_probability`)
- `momentum_factor`: 1.0x for fresh deals (0-180 days), 0.80x for older active deals (>180 days but still active)
- Active condition: Deal age ≤ threshold (deal-size dependent)

**Note**: Fresh deals (0-180 days) receive full weighting (1.0x) as data shows they have a higher win rate (16.0%) compared to older deals (10.5%). Older active deals that haven't yet hit the stale threshold receive a momentum decay factor (0.80x) to reflect declining win rates over time.

---

### Coverage Ratio

```
Coverage Ratio = Capacity / Target
               = sgm_capacity_expected_joined_aum_millions_estimate / 36.75
```

**Interpretation**:
- ≥ 1.0: Sufficient
- 0.85-0.99: At Risk
- < 0.85: Under-Capacity

---

### Capacity Gap

```
Capacity Gap = Target - Capacity
             = 36.75 - sgm_capacity_expected_joined_aum_millions_estimate
```

**Interpretation**:
- Negative: Over-capacity (good)
- Positive: Under-capacity (needs attention)

---

### Required Joined Per Quarter

```
Required Joined = CEILING(36.75 / firm_wide_avg_margin_aum_per_joined)
```

**Where**:
- `firm_wide_avg_margin_aum_per_joined`: Average from last 12 months, excluding enterprise deals (≥$30M)
- CEILING ensures whole number (can't convert 0.45 people)

---

### Required SQOs Per Quarter

```
Required SQOs = CEILING(Required Joined / firm_wide_sqo_to_joined_conversion_rate)
```

**Where**:
- `firm_wide_sqo_to_joined_conversion_rate`: Trailing 365 days from `vw_conversion_rates`
- CEILING ensures whole number

**Double Ceiling Logic**: We apply a "Double Ceiling" approach:
1. First CEILING: `Required Joined = CEILING(36.75 / avg_margin_aum_per_joined)` - ensures we calculate whole number of advisors needed
2. Second CEILING: `Required SQOs = CEILING(Required Joined / conversion_rate)` - ensures we calculate whole number of SQOs needed

This ensures we never plan for fractional human outcomes (you can't convert 0.45 people).

**Volatility Range**: ±16 SQOs (24-56 SQOs) due to uncertainty in underlying data.

---

### SQO Gap

```
SQO Gap = Required SQOs - Current Pipeline SQOs
```

**Interpretation**:
- Positive: Need more SQOs
- Negative: Have sufficient SQOs

---

### Stale % of Pipeline

```
Stale % = (Stale Pipeline Estimate / Total Pipeline Estimate) × 100
```

**Where**:
- Stale Pipeline: Deals exceeding dynamic age thresholds
- Total Pipeline: All SQOs in pipeline

**Interpretation**:
- <10%: Healthy
- 10-20%: Some cleanup needed
- 20-30%: Significant cleanup needed
- >30%: Major red flag

---

### Projected Join Date (Forecast)

```
IF deal_size >= $30M THEN
  IF Stage_Entered_Signed THEN SQO_Date + 38 days
  ELSE IF Stage_Entered_Negotiating THEN SQO_Date + 49 days
  ELSE IF Stage_Entered_Sales_Process THEN SQO_Date + 94 days
  ELSE SQO_Date + 120 days
ELSE IF deal_size >= $15M THEN
  IF Stage_Entered_Signed THEN SQO_Date + 18 days
  ELSE IF Stage_Entered_Negotiating THEN SQO_Date + 37 days
  ELSE IF Stage_Entered_Sales_Process THEN SQO_Date + 66 days
  ELSE SQO_Date + 90 days
ELSE
  IF Stage_Entered_Signed THEN SQO_Date + 10 days
  ELSE IF Stage_Entered_Negotiating THEN SQO_Date + 18 days
  ELSE IF Stage_Entered_Sales_Process THEN SQO_Date + 49 days
  ELSE SQO_Date + 50 days
```

**Where**:
- Uses most recent stage entered date if available
- Falls back to SQO date with default cycle time
- Deal-size dependent cycle times

---

### Quarterly Forecast

```
Current Quarter Forecast = Σ(estimated_margin_aum × stage_probability × momentum_factor)
                          WHERE forecast_quarter = 'Current Quarter'
                          AND deal is active (non-stale)

Next Quarter Forecast = Σ(estimated_margin_aum × stage_probability × momentum_factor)
                        WHERE forecast_quarter = 'Next Quarter'
                        AND deal is active (non-stale)

Total Expected Current Quarter = Current Actuals + Current Quarter Forecast
Total Expected Next Quarter = Next Quarter Forecast
```

**Where**:
- Forecast quarter assigned based on projected join date
- Only includes active (non-stale) deals
- Applies stage probability and momentum decay (0.80x for older active deals >180 days, 1.0x for fresh deals 0-180 days)

---

## Key Takeaways

1. **Capacity is forward-looking**: It represents expected pipeline value over time, not what will close in the current quarter.

2. **Active vs. Total Pipeline**: Active pipeline (non-stale) is used for capacity calculations; total pipeline includes stale deals for comparison.

3. **Stage Probabilities Only**: No additional conversion rate multiplication - stage probabilities already account for conversion.

4. **Deal-Size Dependent Logic**: Larger deals have longer cycle times and higher stale thresholds, reflecting their complexity.

5. **Enterprise Exclusion**: Enterprise deals (≥$30M) are excluded from firm-wide averages to prevent inflation of required metrics.

6. **Volatility Acknowledgment**: Required SQOs have a ±16 SQO range due to uncertainty in underlying data - use as guidance, not precise target.

7. **Momentum-Based Weighting**: Fresh deals (0-180 days) get full value (1.0x) based on data showing 16.0% win rate; older active deals (>180 days) get momentum decay (0.80x) reflecting 10.5% win rate.

8. **Dynamic Valuation**: Uses calculated divisors from recent joined deals instead of static estimates for better accuracy.

---

## References

- `generate_capacity_summary.py`: Python script that generates LLM-powered capacity reports using these views
- `capacity_summary_report_*.md`: Example reports showing how these views are used in practice
- `vw_stage_to_joined_probability`: View that provides stage probabilities used in capacity calculations
- `vw_conversion_rates`: View that provides firm-wide conversion rates for required calculations

---

*Document Version: 1.0*  
*Last Updated: 2025-01-XX*  
*Author: Capacity Model Team*

