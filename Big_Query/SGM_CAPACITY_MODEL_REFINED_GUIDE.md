  # SGM Capacity Model - Refined Implementation Guide

## Overview
This guide explains the **refined** SGM Capacity Model that includes quarterly Margin AUM targets ($36,750,000 per SGM) and pipeline sufficiency analysis.

## Key Features

### 1. Quarterly Target
- **Target**: $36,750,000 Margin AUM per SGM per quarter
- Hardcoded in the view as `quarterly_target_margin_aum`

### 2. Historical Metrics (Last 12 Months)
The model calculates per-SGM averages from the last 12 months:
- **Average Margin AUM per SQO**: Total Margin AUM of SQOs / Count of SQOs
- **Average Margin AUM per Joined**: Total Margin AUM of Joined / Count of Joined
- **SQO → Joined Conversion Rate**: Count of Joined / Count of SQOs
- **Fallback**: If an SGM doesn't have enough history, uses overall averages across all SGMs

### 3. Required Calculations
Based on historical averages, the model calculates:
- **Required SQOs per Quarter**: `Target Margin AUM / Avg Margin AUM per SQO`
- **Required Joined per Quarter**: `Target Margin AUM / Avg Margin AUM per Joined`
- **Required SQOs with Conversion Rate**: Accounts for SQO → Joined conversion rate
  - Formula: `(Required Joined) / SQO_to_Joined_Conversion_Rate`

### 4. Current Pipeline Status
Tracks current opportunities in pipeline (not closed, not joined):
- **Current Pipeline SQO Count**: Number of SQOs currently in pipeline
- **Current Pipeline SQO Margin AUM**: Total Margin AUM of SQOs in pipeline (unweighted, actual values only)
- **Current Pipeline SQO Margin AUM Estimate**: Total estimated Margin AUM including fallback calculations for opportunities without Margin_AUM__c
  - Uses actual `Margin_AUM__c` when available
  - Falls back to `Underwritten_AUM__c / 3.125` when Margin_AUM__c is missing
  - Falls back to `Amount / 3.22` when both Margin_AUM__c and Underwritten_AUM__c are missing
  - See "Estimated Margin AUM Metrics" section below for detailed explanation
- **Current Pipeline SQO Weighted Margin AUM**: Probability-weighted Margin AUM of SQOs in pipeline (actual values only)
  - Formula: `SUM(Margin_AUM * probability_to_join)` for each SQO in pipeline
  - Uses stage-specific probabilities from `vw_stage_to_joined_probability` lookup view
  - Provides a more realistic estimate of expected Margin AUM based on historical conversion rates
- **Current Pipeline SQO Weighted Margin AUM Estimate**: Probability-weighted estimated Margin AUM including fallback calculations
  - Formula: `SUM(estimated_margin_aum * probability_to_join)` for each SQO in pipeline
  - Includes opportunities without Margin_AUM__c using the same fallback logic as the unweighted estimate
- **Current Pipeline SQO Stale Margin AUM**: Total Margin AUM of pipeline SQOs older than 120 days from Date_Became_SQO__c (actual values only)
  - Identifies at-risk opportunities that have been in pipeline for over 120 days
  - Helps assess pipeline health and identify opportunities that may need cleanup or re-engagement
  - Formula: `SUM(Margin_AUM__c)` for SQOs where `sqo_age_days > 120` and Margin_AUM__c is populated
  - **Limitation**: May significantly undercount stale pipeline value since many stale SQOs don't have Margin_AUM__c populated
- **Current Pipeline SQO Stale Margin AUM Estimate**: ⭐ **Recommended** Total estimated Margin AUM of stale SQOs including fallback calculations
  - Uses the same three-tier fallback logic as other estimate metrics:
    1. Actual `Margin_AUM__c` if available and > 0
    2. `Underwritten_AUM__c / 3.125` if Margin_AUM__c is missing
    3. `Amount / 3.22` if both Margin_AUM__c and Underwritten_AUM__c are missing
  - Formula: `SUM(estimated_margin_aum)` for SQOs where `sqo_age_days > 120`
  - **Why it matters**: Provides a complete picture of stale pipeline value, including opportunities without Margin_AUM__c
  - **Use case**: Calculate "Stale % of Pipeline" to identify SGMs with unhealthy pipeline composition
  - **Example**: If an SGM has $10M in total pipeline estimate but $4M in stale pipeline estimate, that's 40% stale - a red flag for pipeline health
- **Current Pipeline Opp Count**: All opportunities in pipeline
- **Current Pipeline Margin AUM**: Total Margin AUM of all opportunities in pipeline

### 4a. Estimated Margin AUM Metrics: Why We Created Them

**The Problem**: Analysis of open SQOs revealed that only **15.45%** have a non-zero `Margin_AUM__c` value. The remaining **84.55%** of open SQOs have `Margin_AUM__c = 0` or NULL, which means the original pipeline metrics (`current_pipeline_sqo_margin_aum`, `current_pipeline_sqo_weighted_margin_aum`, etc.) were significantly undercounting pipeline value.

**The Solution**: We analyzed historical relationships between `Margin_AUM__c`, `Underwritten_AUM__c`, and `Amount` across all historical opportunities to create reliable estimates.

#### Historical Ratio Analysis

Based on analysis of **114 historical opportunities** that had all three fields populated:

**Underwritten_AUM__c to Margin_AUM__c Relationship:**
- **Median Ratio**: 3.125 (Underwritten_AUM__c is typically 3.125x larger than Margin_AUM__c)
- **Average Ratio**: 3.21
- **Standard Deviation**: 0.77
- **Coefficient of Variation**: 0.24 (low volatility - reliable estimate)
- **Range**: 1.25x to 6.38x
- **25th Percentile**: 2.86x
- **75th Percentile**: 3.41x

**Amount to Margin_AUM__c Relationship:**
- **Median Ratio**: 3.22 (Amount is typically 3.22x larger than Margin_AUM__c)
- **Average Ratio**: 3.40 (excluding extreme outliers)
- **Standard Deviation**: 1.14 (moderate volatility)
- **Coefficient of Variation**: 0.34 (moderate volatility - less reliable than Underwritten_AUM__c)
- **Range**: 0.54x to 8.33x (excluding extreme outliers)
- **25th Percentile**: 2.86x
- **75th Percentile**: 4.00x

**Key Insights:**
1. **Underwritten_AUM__c is more reliable**: Lower volatility (CV = 0.24) makes it a better proxy than Amount (CV = 0.34)
2. **Both ratios are consistent**: Median ratios of 3.125 and 3.22 are very close, suggesting a stable relationship
3. **Estimation accuracy**: Using these ratios, we can estimate Margin_AUM__c within approximately ±25-35% accuracy (based on the interquartile range)

#### Fallback Logic

The estimated metrics use a three-tier fallback approach:

1. **Primary**: Use actual `Margin_AUM__c` if available and > 0
2. **First Fallback**: If `Margin_AUM__c` is NULL or 0, estimate from `Underwritten_AUM__c / 3.125`
3. **Second Fallback**: If both are NULL or 0, estimate from `Amount / 3.22`

This ensures we capture the full pipeline value, including opportunities that haven't yet had their Margin_AUM__c calculated or entered.

#### Why This Matters

Without these estimates, the capacity model was missing **74.8%** of open SQOs from pipeline calculations because they lacked `Margin_AUM__c` values. However, **100%** of those SQOs have either `Underwritten_AUM__c` or `Amount` populated, meaning we can provide a reasonable estimate of their potential Margin AUM.

**Example Impact:**
- **Before**: An SGM with 10 open SQOs, but only 2 have Margin_AUM__c = $5M total → Pipeline shows $5M
- **After**: Same SGM, but 8 additional SQOs have Underwritten_AUM__c totaling $25M → Estimated pipeline shows $5M + ($25M / 3.125) = $13M

This provides a much more accurate picture of pipeline capacity and helps identify SGMs who may appear to have sufficient pipeline when they actually don't (or vice versa).

#### Understanding Estimate Accuracy

**For Underwritten_AUM__c estimates:**
- **Typical accuracy**: ±15-20% (based on 25th-75th percentile range of 2.86x to 3.41x)
- **Best case**: Within 5% if the opportunity follows the median ratio
- **Worst case**: Could be off by ±50% for outliers (1.25x to 6.38x range)

**For Amount estimates:**
- **Typical accuracy**: ±20-30% (based on 25th-75th percentile range of 2.86x to 4.00x)
- **Best case**: Within 10% if the opportunity follows the median ratio
- **Worst case**: Could be off by ±60% for outliers (0.54x to 8.33x range)

**Recommendation**: Use the estimate metrics as directional indicators rather than precise values. They provide a more complete picture of pipeline capacity, but actual Margin_AUM__c values should always be preferred when available.

### 5. Current Quarter Actuals
Tracks what's happened this quarter:
- **Current Quarter SQO Count**: SQOs that became SQO this quarter
- **Current Quarter SQO Margin AUM**: Margin AUM of SQOs this quarter
- **Current Quarter Joined Count**: Advisors who joined this quarter
- **Current Quarter Joined Margin AUM**: Margin AUM of Joined this quarter

### 6. Gap Analysis
Shows the difference between required and current:
- **SQO Gap Count**: `Required SQOs - Current Pipeline SQOs`
- **Margin AUM Gap**: `Target Margin AUM - Current Pipeline SQO Margin AUM`
- **Joined Gap Count**: `Required Joined - Current Quarter Joined`
- **Joined Margin AUM Gap**: `Target Margin AUM - Current Quarter Joined Margin AUM`

### 7. Pipeline Sufficiency Indicators
Three key indicators:
- **Has Sufficient SQOs in Pipeline**: Yes/No/Unknown
  - Compares current pipeline SQO count to required SQOs
- **Has Sufficient Margin AUM in Pipeline**: Yes/No
  - Compares current pipeline SQO Margin AUM to target
- **Quarterly Target Status**: On Track / Behind / No Activity
  - Based on current quarter Joined Margin AUM vs target

### 8. Percentage of Target
- **Pipeline Margin AUM % of Target**: `(Current Pipeline SQO Margin AUM / Target) * 100`
- **Current Quarter Joined % of Target**: `(Current Quarter Joined Margin AUM / Target) * 100`

## View Structure

### Supporting View: `vw_stage_to_joined_probability`

This lookup view provides stage-specific probabilities that an opportunity will eventually reach 'Joined' status.

**Purpose**: Calculate forward-looking probability-to-join based on an opportunity's current StageName.

**Structure**:
- `StageName`: The sales stage (e.g., 'Qualifying', 'Discovery', 'Sales Process', 'Negotiating', 'Signed')
- `probability_to_join`: Decimal value (0.0 to 1.0) representing the probability

**Calculation Logic**:
- For each stage, calculates: `(Count of Opps that reached this Stage AND became Joined) / (Count of Opps that ever reached this Stage)`
- Uses historical data from all opportunities to determine conversion probabilities
- Stages included: Qualifying, Discovery, Sales Process, Negotiating, Signed

**Example Probabilities**:
- An opportunity in 'Discovery' might have a 10% chance of eventually reaching 'Joined'
- An opportunity in 'Negotiating' might have a 70% chance of eventually reaching 'Joined'
- An opportunity in 'Signed' might have a 95% chance of eventually reaching 'Joined'

### Verification View: `vw_sgm_open_sqos_detail`

This view provides detailed information about each open SQO for verification and drill-down purposes.

**Purpose**: Allows you to see all open SQOs by SGM with detailed information to verify the aggregated metrics in the main capacity model.

**Key Fields**:

| Field | Description |
|-------|-------------|
| `sgm_name` | SGM name |
| `sgm_user_id` | SGM User ID |
| `opportunity_name` | Opportunity Name |
| `Full_Opportunity_ID__c` | Full Opportunity ID |
| `StageName` | Current stage |
| `Date_Became_SQO__c` | Date became SQO |
| `Margin_AUM__c` | Margin AUM (actual value) |
| `Underwritten_AUM__c` | Underwritten AUM |
| `Amount` | Amount |
| `estimated_margin_aum` | ⭐ **Recommended** Estimated Margin AUM using fallback logic (same as main capacity model) |
| `days_open_since_sqo` | Days open since becoming SQO (calculated) |
| `is_stale` | Yes/No if older than 120 days |
| `pipeline_status` | In Pipeline / Not In Pipeline |

**Usage**: 
- Use this view to verify the aggregated metrics in `vw_sgm_capacity_model_refined`
- Filter by SGM to see all their open SQOs
- Sort by `days_open_since_sqo` to identify stale opportunities
- Use `estimated_margin_aum` in Looker Studio for more complete pipeline value analysis (includes opportunities without Margin_AUM__c)
- Use in Looker Studio to create a detailed table that can be filtered/drilled down from the summary view
- **Why `estimated_margin_aum` is included**: Since only 15.45% of open SQOs have Margin_AUM__c populated, the estimated field provides a more complete picture of each opportunity's potential value. This allows you to see the full pipeline value at the detail level, matching the aggregate estimate metrics in the main capacity model.

### Primary View: `vw_sgm_capacity_model_refined`

This view provides one row per SGM with all capacity planning metrics.

**Dependencies**:
- Uses `vw_stage_to_joined_probability` to get stage-specific probabilities for weighted calculations

**Key Fields**:

| Field | Description |
|-------|-------------|
| `sgm_name` | SGM name |
| `sgm_user_id` | SGM User ID |
| `Is_SGM__c` | Boolean flag indicating if user is an SGM (for filtering) |
| `IsActive` | Boolean flag indicating if user is active (for filtering) |
| `quarterly_target_margin_aum` | Target: $36,750,000 |
| `avg_margin_aum_per_sqo` | Historical average (last 12 months) |
| `avg_margin_aum_per_joined` | Historical average (last 12 months) |
| `sqo_to_joined_conversion_rate` | Historical conversion rate |
| `required_sqos_per_quarter` | Calculated requirement |
| `required_joined_per_quarter` | Calculated requirement |
| `required_sqos_with_conversion_rate` | Required SQOs accounting for conversion |
| `current_pipeline_sqo_count` | Current SQOs in pipeline |
| `current_pipeline_sqo_margin_aum` | Current pipeline Margin AUM (unweighted, actual values only) |
| `current_pipeline_sqo_margin_aum_estimate` | Current pipeline Margin AUM estimate (includes fallback calculations) |
| `current_pipeline_sqo_weighted_margin_aum` | Probability-weighted pipeline Margin AUM (actual values only) |
| `current_pipeline_sqo_weighted_margin_aum_estimate` | Probability-weighted pipeline Margin AUM estimate (includes fallback calculations) |
| `current_pipeline_sqo_stale_margin_aum` | Total Margin AUM of pipeline SQOs older than 120 days from Date_Became_SQO__c (actual values only) |
| `current_pipeline_sqo_stale_margin_aum_estimate` | Total estimated Margin AUM of stale pipeline SQOs (includes fallback calculations) |
| `sqo_gap_count` | Gap: Required - Current |
| `margin_aum_gap` | Gap: Target - Current |
| `has_sufficient_sqos_in_pipeline` | Yes/No/Unknown |
| `has_sufficient_margin_aum_in_pipeline` | Yes/No |
| `quarterly_target_status` | On Track/Behind/No Activity |
| `pipeline_margin_aum_pct_of_target` | % of target in pipeline |

## Looker Studio Dashboard Components

### 1. SGM Capacity Summary Table
**Data Source**: `vw_sgm_capacity_model_refined`

**Dimensions**: `sgm_name`

**Metrics**:
- `quarterly_target_margin_aum` (Target)
- `current_pipeline_sqo_margin_aum` (Current Pipeline - Unweighted, Actual Only)
- `current_pipeline_sqo_margin_aum_estimate` (Current Pipeline - Unweighted, With Estimates) ⭐ **Recommended for capacity assessment**
- `current_pipeline_sqo_weighted_margin_aum` (Current Pipeline - Weighted, Actual Only)
- `current_pipeline_sqo_weighted_margin_aum_estimate` (Current Pipeline - Weighted, With Estimates) ⭐ **Recommended for realistic forecast**
- `current_pipeline_sqo_stale_margin_aum` (Stale Pipeline - Actual Only)
- `current_pipeline_sqo_stale_margin_aum_estimate` (Stale Pipeline - With Estimates)
- `current_quarter_joined_margin_aum` (Current Quarter Actual)
- `required_sqos_per_quarter` (Required SQOs)
- `current_pipeline_sqo_count` (Current Pipeline SQOs)
- `sqo_gap_count` (Gap)
- `pipeline_margin_aum_pct_of_target` (% of Target)

**Note**: The estimate metrics (marked with ⭐) are recommended for capacity assessment because they include opportunities without Margin_AUM__c values, providing a more complete picture of pipeline capacity. The "actual only" metrics exclude these opportunities and may undercount pipeline value.

**Note**: The weighted Margin AUM provides a more realistic estimate by accounting for the probability that opportunities in each stage will convert to Joined, based on historical conversion rates.

**Conditional Formatting for Stale Pipeline**:
- **Recommended**: Use the estimate version for more accurate stale pipeline analysis
- Create a calculated field: `stale_pct_of_pipeline_estimate` = `(current_pipeline_sqo_stale_margin_aum_estimate / current_pipeline_sqo_margin_aum_estimate) * 100`
- Apply color formatting: Red if > 30%, Yellow if 15-30%, Green if < 15%
- This helps quickly identify SGMs with high proportions of stale pipeline that may need cleanup
- **Why use estimate version**: Since only 15.45% of open SQOs have Margin_AUM__c, the actual-only version may miss most stale opportunities, giving a false sense of pipeline health

**Filtering Out Stale Deals (Recommended for Capacity Assessment)**:
- **Recommended**: Use the estimate versions for more accurate active pipeline calculations
- Create calculated fields to show "Active Pipeline" (excluding stale deals):
  - `Active Pipeline Margin AUM Estimate` = `current_pipeline_sqo_margin_aum_estimate - current_pipeline_sqo_stale_margin_aum_estimate`
  - `Active Pipeline Weighted Margin AUM Estimate` = `current_pipeline_sqo_weighted_margin_aum_estimate - (current_pipeline_sqo_stale_margin_aum_estimate * avg_stage_probability)`
    - For `avg_stage_probability`, use approximately 0.5 as a conservative estimate, or calculate the actual weighted average from the detail view
- Use these "Active Pipeline Estimate" metrics when assessing whether SGMs have sufficient pipeline to meet targets
- This prevents over-inflating pipeline numbers with stale, at-risk opportunities
- **Example**: An SGM shows $15M in total pipeline estimate, but $6M is stale. Their active pipeline is only $9M, which may be insufficient for their quarterly target

**Conditional Formatting**:
- `has_sufficient_sqos_in_pipeline`: Green if "Yes", Red if "No", Yellow if "Unknown"
- `quarterly_target_status`: Green if "On Track", Red if "Behind", Gray if "No Activity"
- `pipeline_margin_aum_pct_of_target`: Color scale (Green > 100%, Yellow 50-100%, Red < 50%)

### 2. Pipeline Sufficiency Scorecard
**Data Source**: `vw_sgm_capacity_model_refined`

**Scorecards**:
- **Total SGMs**: COUNT of `sgm_name`
- **SGMs with Sufficient SQOs**: COUNT where `has_sufficient_sqos_in_pipeline = 'Yes'`
- **SGMs On Track**: COUNT where `quarterly_target_status = 'On Track'`
- **Average % of Target**: AVG of `pipeline_margin_aum_pct_of_target`

### 3. Gap Analysis Table
**Data Source**: `vw_sgm_capacity_model_refined`

**Dimensions**: `sgm_name`

**Metrics**:
- `required_sqos_per_quarter`
- `current_pipeline_sqo_count`
- `sqo_gap_count` (show negative gaps in red)
- `required_joined_per_quarter`
- `current_quarter_joined_count`
- `joined_gap_count` (show negative gaps in red)

**Sort**: By `sqo_gap_count` (ascending - biggest gaps first)

### 4. Historical Metrics Table
**Data Source**: `vw_sgm_capacity_model_refined`

**Dimensions**: `sgm_name`

**Metrics**:
- `avg_margin_aum_per_sqo` (Average Margin AUM per SQO)
- `avg_margin_aum_per_joined` (Average Margin AUM per Joined)
- `sqo_to_joined_conversion_rate` (Conversion Rate %)
- `historical_sqo_count_12m` (SQOs in last 12 months)
- `historical_joined_count_12m` (Joined in last 12 months)

**Purpose**: Understand each SGM's historical performance to validate the required calculations

### 5. Target vs Actual Chart
**Data Source**: `vw_sgm_capacity_model_refined`

**Chart Type**: Bar Chart (Grouped)

**Dimensions**: `sgm_name`

**Metrics**:
- `quarterly_target_margin_aum` (Target - Blue)
- `current_pipeline_sqo_margin_aum` (Pipeline - Unweighted - Orange)
- `current_pipeline_sqo_weighted_margin_aum` (Pipeline - Weighted - Light Orange)
- `current_quarter_joined_margin_aum` (Actual - Green)

**Purpose**: Visual comparison of target vs pipeline (both weighted and unweighted) vs actual

**Insight**: The weighted pipeline metric shows a more realistic expectation of Margin AUM that will convert, accounting for stage-specific conversion probabilities.

### 6. Open SQOs Detail Table (Verification View)
**Data Source**: `vw_sgm_open_sqos_detail`

**Chart Type**: Table

**Purpose**: Detailed view of all open SQOs for verification and drill-down analysis

**Dimensions**: 
- `sgm_name` (for filtering/grouping)
- `opportunity_name`
- `Full_Opportunity_ID__c`
- `StageName`
- `Date_Became_SQO__c`

**Metrics**:
- `Margin_AUM__c` (actual value)
- `Underwritten_AUM__c`
- `Amount`
- `estimated_margin_aum` ⭐ **Recommended** - Estimated Margin AUM using fallback logic (Underwritten_AUM__c / 3.125 or Amount / 3.22)
- `days_open_since_sqo` (Days Open)
- `is_stale` (Yes/No indicator)

**Additional Fields** (for context):
- `pipeline_status`
- `opp_created_date`
- `advisor_join_date__c`

**Usage**:
- **Verification**: Use this table to verify the aggregated metrics in the main capacity model
- **Drill-down**: Set up cross-filtering so clicking on an SGM in the summary table filters this detail table
- **Stale Analysis**: Sort by `days_open_since_sqo` DESC to see oldest SQOs first
- **Stage Analysis**: Group by `StageName` to see distribution of SQOs across stages
- **Filtering**: Add filters for:
  - `sgm_name` (dropdown)
  - `is_stale` (Yes/No checkbox)
  - `StageName` (dropdown)

**Conditional Formatting**:
- `is_stale`: Red if "Yes", Green if "No"
- `days_open_since_sqo`: Color scale (Red > 120 days, Yellow 60-120 days, Green < 60 days)
- `StageName`: Color by stage (e.g., Signed = Green, Discovery = Yellow, etc.)

**Example Use Cases**:
1. **Verify Aggregated Counts**: Compare `COUNT(*)` in this view (grouped by SGM) with `current_pipeline_sqo_count` from the main view
2. **Identify Stale Opportunities**: Filter where `is_stale = 'Yes'` to see all stale SQOs
3. **Stage Distribution**: Create a pivot table showing SQO count by SGM and StageName
4. **Days Open Analysis**: Calculate average days open per SGM to identify SGMs with slow-moving pipelines

## Key Calculations Explained

### Weighted Pipeline Margin AUM

The weighted pipeline metric provides a probability-adjusted estimate of expected Margin AUM:

```
Weighted Margin AUM = SUM(Margin_AUM * probability_to_join) for each SQO in pipeline
```

**Why Use Weighted Metrics?**
- **Unweighted Margin AUM**: Assumes all opportunities in pipeline will convert (100% probability)
- **Weighted Margin AUM**: Accounts for historical reality - opportunities in earlier stages have lower conversion rates

**Example**:
- Opportunity A: $5M Margin AUM, in 'Discovery' stage (10% probability) → Weighted: $500K
- Opportunity B: $3M Margin AUM, in 'Negotiating' stage (70% probability) → Weighted: $2.1M
- Opportunity C: $2M Margin AUM, in 'Signed' stage (95% probability) → Weighted: $1.9M
- **Total Unweighted**: $10M
- **Total Weighted**: $4.5M (more realistic expectation)

**Use Case**: Compare weighted pipeline Margin AUM to quarterly target to see if you have enough "realistic" pipeline to meet goals.

### Required SQOs Calculation
```
Required SQOs = CEILING(Target Margin AUM / Avg Margin AUM per SQO)
```

**Example**:
- Target: $36,750,000
- Avg Margin AUM per SQO: $2,500,000
- Required SQOs = CEILING(36,750,000 / 2,500,000) = 15 SQOs

### Required SQOs with Conversion Rate
```
Required SQOs = CEILING((Target Margin AUM / Avg Margin AUM per Joined) / SQO_to_Joined_Rate)
```

**Example**:
- Target: $36,750,000
- Avg Margin AUM per Joined: $3,000,000
- Required Joined = 36,750,000 / 3,000,000 = 12.25 → 13 Joined
- SQO to Joined Rate: 80% (0.8)
- Required SQOs = CEILING(13 / 0.8) = CEILING(16.25) = 17 SQOs

This accounts for the fact that not all SQOs will convert to Joined.

## Implementation Steps

### Step 1: Deploy Supporting View
1. **Deploy `vw_stage_to_joined_probability` first**:
   - Run `Views/vw_stage_to_joined_probability.sql` in BigQuery
   - Verify the view is created: `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability`
   - Test with a sample query:
     ```sql
     SELECT * FROM `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability`
     ```
   - Expected output: One row per stage (Qualifying, Discovery, Sales Process, Negotiating, Signed) with probability values

### Step 2: Deploy Main View
1. Run `vw_sgm_capacity_model_refined.sql` in BigQuery
2. Verify the view is created: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`
3. Test with a sample query:
   ```sql
   SELECT * FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`
   LIMIT 10
   ```
4. Verify the weighted metric is populated:
   ```sql
   SELECT 
     sgm_name,
     current_pipeline_sqo_margin_aum,
     current_pipeline_sqo_weighted_margin_aum,
     CASE 
       WHEN current_pipeline_sqo_margin_aum > 0 
       THEN current_pipeline_sqo_weighted_margin_aum / current_pipeline_sqo_margin_aum 
       ELSE 0 
     END AS weighted_pct_of_unweighted
   FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`
   WHERE current_pipeline_sqo_margin_aum > 0
   ```

### Step 3: Deploy Verification View
1. Run `vw_sgm_open_sqos_detail.sql` in BigQuery
2. Verify the view is created: `savvy-gtm-analytics.savvy_analytics.vw_sgm_open_sqos_detail`
3. Test with a sample query:
   ```sql
   SELECT * FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_open_sqos_detail`
   WHERE sgm_name = 'Your SGM Name'
   ORDER BY days_open_since_sqo DESC
   ```
4. Verify the data matches the aggregated view:
   ```sql
   -- Compare counts
   SELECT 
     sgm_name,
     COUNT(*) AS detail_count
   FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_open_sqos_detail`
   GROUP BY sgm_name
   
   -- Should match current_pipeline_sqo_count from vw_sgm_capacity_model_refined
   ```

### Step 4: Add to Looker Studio
1. **Add Data Source**: Connect to `vw_sgm_capacity_model_refined`
2. **Verify Fields**: Check that all fields are available and properly typed
3. **Create Calculated Fields** (if needed):
   - `sqo_gap_negative`: `-sqo_gap_count` (for visualization)
   - `margin_aum_gap_negative`: `-margin_aum_gap` (for visualization)

### Step 5: Build Dashboard Components
1. Create SGM Capacity Summary Table
2. Create Pipeline Sufficiency Scorecard
3. Create Gap Analysis Table
4. Create Historical Metrics Table
5. Create Target vs Actual Chart

### Step 6: Add Filters
- **SGM Filter**: Dropdown to filter by specific SGM (`sgm_name`)
- **Is SGM Filter**: Checkbox or dropdown to filter by `Is_SGM__c` (useful if you want to include/exclude SGMs)
- **Is Active Filter**: Checkbox or dropdown to filter by `IsActive` (useful to show only active SGMs or include inactive ones)
- **Date Filter**: **Not Applicable** - The view is a snapshot that always shows "as of today" using `CURRENT_DATE()`. The `as_of_date` field is included for reference but will always be the current date. To see historical snapshots, you would need to modify the view to accept a date parameter or create a separate historical tracking table.

**Note**: The view currently filters to only active SGMs (`Is_SGM__c = TRUE` and `IsActive = TRUE`), but these fields are included in the output for additional filtering flexibility in Looker Studio.

**Note on Estimated Metrics**: The view now includes both "actual" and "estimate" versions of pipeline metrics. The estimate versions use fallback calculations (Underwritten_AUM__c / 3.125 or Amount / 3.22) when Margin_AUM__c is missing. For capacity planning, use the estimate metrics as they provide a more complete picture. See section "4a. Estimated Margin AUM Metrics" for detailed explanation.

## Understanding the Metrics

### Why Different Metrics May Show Different Results

The dashboard includes several related but distinct metrics that measure different aspects of pipeline health:

1. **"Sufficient SQOs"** (`has_sufficient_sqos_in_pipeline`):
   - Measures: **COUNT** of SQOs in pipeline vs required **COUNT** of SQOs
   - Logic: Does the SGM have enough SQOs (quantity) to meet target?
   - Example: Needs 5 SQOs, has 3 SQOs = "No" (insufficient count)

2. **"Average % of Target"** (`pipeline_margin_aum_pct_of_target`):
   - Measures: **Margin AUM** in pipeline vs target Margin AUM
   - Logic: Does the SGM have enough Margin AUM (value) to meet target?
   - Example: Needs $36.75M, has $50M in pipeline = 136% (sufficient value, even if insufficient count)

3. **"On Track"** (`quarterly_target_status`):
   - Measures: **Current quarter actual** joined Margin AUM vs target
   - Logic: Has the SGM already achieved the target this quarter?
   - Example: Target $36.75M, joined $40M this quarter = "On Track"

**Why These Can Disagree:**
- An SGM might have **high-value SQOs** (e.g., 2 SQOs worth $50M each = $100M = 272% of target)
- But still need **more SQOs** (e.g., needs 5 SQOs, only has 2 = insufficient count)
- And might not be **on track** yet (e.g., no joins this quarter = "Behind")

**Best Practice**: Review all three metrics together to get a complete picture:
- **Sufficient SQOs** = Do they have enough opportunities?
- **% of Target** = Do they have enough value?
- **On Track** = Are they achieving results this quarter?

### Understanding "Average % of Target" Aggregation

When you calculate "Average % of Target" across all SGMs, you're averaging each SGM's individual percentage. This can be mathematically valid but potentially misleading if SGMs have very different pipeline sizes.

**Alternative Calculations in Looker Studio:**

Instead of averaging percentages, consider:

1. **Total Pipeline % of Total Target**:
   ```
   SUM(current_pipeline_sqo_margin_aum) / (SUM(quarterly_target_margin_aum)) * 100
   ```
   This shows: "What % of the total target do we have across all SGMs?"

2. **Median % of Target**:
   - Use MEDIAN aggregation instead of AVG
   - Less affected by outliers (SGMs with very high or very low percentages)

3. **Show Both**:
   - Average % (for overall trend)
   - Median % (for typical SGM performance)
   - This gives you both the aggregate view and the typical individual performance

## Notes

1. **Historical Window**: Metrics use last 12 months. Adjust in the view if needed.

2. **Fallback Logic**: If an SGM doesn't have enough history, the view uses overall averages. This ensures all SGMs get calculations even with limited data.

3. **Pipeline Definition**: "In Pipeline" = opportunities that are:
   - Not closed (`IsClosed = FALSE`)
   - Not joined (`advisor_join_date__c IS NULL`)
   - Not in "Closed Lost" stage
   - Not in "On Hold" stage
   - StageName is NOT NULL
   - **Important**: Pipeline includes ALL open SQOs regardless of when they became SQO (includes stale opportunities older than 120 days)
   - **Stale opportunities are NOT excluded** from pipeline totals by default - they're just flagged separately in `current_pipeline_sqo_stale_margin_aum` for risk identification
   - **To filter out stale deals**: In Looker Studio, you can create a calculated field that subtracts stale Margin AUM from total pipeline Margin AUM to get "Active Pipeline" (non-stale) metrics

4. **Quarter Definition**: Uses calendar quarters (Q1: Jan-Mar, Q2: Apr-Jun, etc.)

5. **Time Periods in the Dashboard**:
   - **Pipeline Metrics** (`current_pipeline_sqo_*`): Shows ALL open SQOs regardless of when they became SQO (no quarter filter). This includes stale opportunities. Excludes "On Hold", "Closed Lost", and NULL StageName.
   - **Current Quarter Metrics** (`current_quarter_*`): Shows only opportunities that became SQO or Joined THIS quarter (for actuals tracking).
   - **Historical Metrics** (`avg_margin_aum_per_*`): Uses last 12 months rolling window for averages and conversion rates.
   - **Stale Metric** (`current_pipeline_sqo_stale_margin_aum`): Identifies SQOs older than **120 days from Date_Became_SQO__c** but does NOT exclude them from pipeline totals by default - they're still counted in `current_pipeline_sqo_margin_aum`. This metric can be used to filter out stale deals in Looker Studio to avoid over-inflating pipeline numbers.
  - **Stale Metric Estimate** (`current_pipeline_sqo_stale_margin_aum_estimate`): ⭐ **Recommended** Same as above but includes fallback estimates for opportunities without Margin_AUM__c. Provides a more complete picture of stale pipeline value. Use this version for pipeline health analysis.

6. **Target Update**: To change the quarterly target, update the value `36750000` in the view.

7. **Conversion Rate**: The view calculates SQO → Joined conversion rate from historical data. This may differ from the conversion rates in `vw_conversion_rates` which uses different date anchors.

8. **Weighted Pipeline Metric**: The `current_pipeline_sqo_weighted_margin_aum` field uses stage-specific probabilities from `vw_stage_to_joined_probability` to provide a more realistic estimate of expected Margin AUM. This accounts for the fact that opportunities in earlier stages (e.g., Discovery) have lower historical conversion rates than those in later stages (e.g., Negotiating, Signed).

9. **Stage Probabilities**: The stage-to-joined probabilities are calculated from all historical opportunities, not just recent ones. This provides a stable baseline for probability calculations. If conversion rates change significantly over time, you may want to recalculate these probabilities using a rolling window.

10. **Staleness Calculation**: 
    - **Threshold**: 120 days from `Date_Became_SQO__c` (not `CreatedDate`)
    - **Rationale**: Based on data analysis showing average SQO-to-Joined cycle is 77 days, with 90th percentile at 148 days. 120 days flags ~17% of deals, catching at-risk opportunities while not over-flagging normal sales cycles.
    - **Why Date_Became_SQO__c**: More accurate than `CreatedDate` because it measures time since the opportunity became a qualified SQO, not time since first creation (which may include pre-qualification time).
    - **Usage in Looker Studio**: Create calculated fields to filter out stale deals:
      - **Recommended**: Use estimate versions for more accurate analysis
      - `Active Pipeline Margin AUM Estimate` = `current_pipeline_sqo_margin_aum_estimate - current_pipeline_sqo_stale_margin_aum_estimate`
      - `Active Pipeline Weighted Margin AUM Estimate` = `current_pipeline_sqo_weighted_margin_aum_estimate - (current_pipeline_sqo_stale_margin_aum_estimate * avg_stage_probability)` (approximate)
      - Use these "Active Pipeline Estimate" metrics when assessing capacity sufficiency to avoid over-inflating pipeline numbers
      - **Alternative (actual-only)**: `Active Pipeline Margin AUM` = `current_pipeline_sqo_margin_aum - current_pipeline_sqo_stale_margin_aum` (may undercount due to missing Margin_AUM__c values)

## Troubleshooting

### Issue: "Unknown" for has_sufficient_sqos_in_pipeline
**Cause**: SGM has no historical data and overall average is also NULL
**Solution**: Check if there's any historical data in the Opportunity table

### Issue: Required SQOs seems too high/low
**Cause**: Historical average Margin AUM per SQO may not be representative
**Solution**: Review `avg_margin_aum_per_sqo` and `historical_sqo_count_12m` to validate the calculation

### Issue: Conversion rate seems off
**Cause**: SQO → Joined conversion rate calculated from last 12 months may differ from actual
**Solution**: Compare with `vw_conversion_rates` view to validate

### Issue: Weighted Margin AUM seems too low
**Cause**: Stage probabilities may be conservative, or pipeline has many opportunities in early stages
**Solution**: 
- Review `vw_stage_to_joined_probability` to see the probabilities for each stage
- Check the distribution of opportunities across stages in the pipeline
- Consider that weighted metrics are intentionally conservative to account for historical conversion rates

### Issue: Weighted Margin AUM equals Unweighted Margin AUM
**Cause**: All opportunities in pipeline are in 'Signed' stage (high probability) or stage probabilities are not being applied
**Solution**: 
- Verify `vw_stage_to_joined_probability` view exists and has data
- Check that opportunities have valid StageName values that match the lookup view
- Review the join logic in `Opp_Base` CTE

### Issue: Weighted Margin AUM looks high, but pipeline feels slow
**Cause**: A significant portion of the weighted forecast is tied to old, at-risk opportunities that are unlikely to close
**Solution**: 
- **Use the estimate version** for more accurate analysis: Check the `current_pipeline_sqo_stale_margin_aum_estimate` field
- Calculate the percentage: `(current_pipeline_sqo_stale_margin_aum_estimate / current_pipeline_sqo_margin_aum_estimate) * 100`
- If stale pipeline represents > 30% of total pipeline Margin AUM estimate, this signals a need for pipeline cleanup
- Review individual opportunities older than 120 days (from `Date_Became_SQO__c`) to determine if they should be:
  - Re-engaged with updated outreach and a clear action plan
  - Moved to "On Hold" or "Closed Lost" if no longer viable
  - Replaced with fresh opportunities to maintain healthy pipeline
- **Action**: Calculate "Active Pipeline" = `current_pipeline_sqo_margin_aum_estimate - current_pipeline_sqo_stale_margin_aum_estimate` to see the real pipeline value

### Issue: Stale Pipeline Estimate seems too high or too low
**Cause**: The estimate uses fallback calculations (Underwritten_AUM__c / 3.125 or Amount / 3.22) which have ±15-30% accuracy
**Solution**: 
- Remember that estimates are directional indicators, not precise values
- If an SGM has many stale SQOs without Margin_AUM__c, the estimate provides a more complete picture than the actual-only metric
- For precision, review individual stale opportunities in the detail view and update Margin_AUM__c values where possible
- The estimate is still valuable for identifying pipeline health issues even if not perfectly accurate

## Next Steps

1. Deploy `vw_stage_to_joined_probability` view
2. Deploy `vw_sgm_capacity_model_refined` view
3. Deploy `vw_sgm_open_sqos_detail` view (verification/drill-down)
4. Build Looker Studio dashboard with both weighted and unweighted metrics
5. Add the Open SQOs Detail Table for verification and drill-down analysis
6. Review with stakeholders - explain the difference between weighted and unweighted pipeline metrics
7. Consider adding a comparison chart showing:
   - Unweighted Pipeline Margin AUM vs Target
   - Weighted Pipeline Margin AUM vs Target
   - This helps visualize the "realistic" vs "optimistic" pipeline scenarios
6. Adjust historical window if needed (currently 12 months for averages, all-time for stage probabilities)
7. Consider adding alerts for SGMs with insufficient weighted pipeline
8. Consider adding trend analysis (how pipeline sufficiency changes over time)
9. Periodically review and update `vw_stage_to_joined_probability` if conversion rates change significantly

