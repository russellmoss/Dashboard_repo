# Forecast Accuracy Validation Queries

This directory contains SQL queries to validate the accuracy of the quarterly forecast model.

## Queries

### 1. `forecast_accuracy_validation.sql` (Main Summary)
**Purpose**: Provides overall accuracy metrics and breakdowns by stage and SGM.

**Key Metrics**:
- Average and median absolute days error
- Quarter accuracy percentage
- Accuracy within ±7, ±14, and ±30 days
- Breakdown by forecast stage used
- Top 10 SGMs by deal count

**Use Case**: Quick overview of forecast performance across all dimensions.

**Example Output**:
```
=== OVERALL ACCURACY ===
- Total Deals: 97
- Avg Absolute Days Error: 25.3 days
- Quarter Accuracy: 68.0%
- Within 30 Days: 75.3%
```

### 2. `forecast_accuracy_detailed.sql` (Deal-Level Detail)
**Purpose**: Shows individual deal-level forecast accuracy for detailed analysis.

**Key Fields**:
- SGM name
- Opportunity name
- Forecast stage used
- Actual vs forecasted join dates
- Days difference
- Accuracy category (e.g., "Accurate (±7 days)", "Forecast Too Early")
- Quarter accuracy

**Use Case**: 
- Identify patterns and outliers
- Understand which deals had poor forecasts
- Analyze specific SGM or stage performance

**Example Output**:
```
sgm_name | opportunity_name | forecast_stage_used | days_difference | accuracy_category
---------|------------------|---------------------|----------------|-------------------
John Doe | ABC Advisors     | Signed              | -3             | Accurate (±7 days)
```

### 3. `forecast_accuracy_by_time_period.sql` (Trend Analysis)
**Purpose**: Analyzes forecast accuracy trends over time (by month and quarter).

**Key Metrics**:
- Accuracy metrics grouped by actual join month/quarter
- Trends to identify if accuracy is improving or degrading
- Margin AUM totals by period

**Use Case**:
- Track forecast accuracy over time
- Identify if model needs recalibration
- Understand seasonal patterns

**Example Output**:
```
grouping_type | time_period    | total_deals | avg_absolute_days_error | quarter_accuracy_pct
--------------|----------------|-------------|-------------------------|--------------------
By Quarter    | 2024-Q4        | 25          | 22.5                    | 72.0%
By Month      | 2024-12        | 8           | 18.3                    | 75.0%
```

## How to Use

### Step 1: Run Main Validation Query
```sql
-- Run in BigQuery
SELECT * FROM `savvy-gtm-analytics.savvy_analytics.forecast_accuracy_validation`
-- Or run the SQL file directly
```

### Step 2: Review Overall Accuracy
- Check if quarter accuracy is > 70% (good target)
- Check if median absolute days error is < 30 days
- Review stage-specific accuracy to identify which stages need improvement

### Step 3: Analyze Detailed Results
- Run detailed query to see individual deal performance
- Identify patterns (e.g., certain SGMs or stages consistently off)
- Look for systematic biases (e.g., consistently forecasting too early/late)

### Step 4: Review Trends
- Run time period query to see if accuracy is stable over time
- Identify if recent months show degradation
- Check if certain quarters had unusual patterns

## Interpretation Guide

### Good Forecast Accuracy
- **Quarter Accuracy**: > 70%
- **Median Absolute Days Error**: < 30 days
- **Within 30 Days**: > 75% of deals

### Stage-Specific Expectations
- **Signed**: Should have highest accuracy (16-day median, high conversion)
- **Negotiating**: Moderate accuracy (37-day median, moderate conversion)
- **Sales Process**: Lower accuracy expected (69-day median, lower conversion)
- **Discovery**: Lower accuracy expected (62-day median, very low conversion)

### Red Flags
- **Quarter Accuracy < 50%**: Model may need significant recalibration
- **Consistent Bias**: If avg_days_error is consistently positive/negative, adjust median times
- **Stage Degradation**: If a stage's accuracy drops over time, may need to update median times

## Recommendations

1. **Run Monthly**: Validate forecast accuracy monthly to catch degradation early
2. **Update Medians**: If accuracy degrades, recalculate median times from recent data
3. **Stage-Specific Tuning**: Consider SGM-specific or deal-size-specific medians if data allows
4. **Monitor Outliers**: Track deals with >60 day errors to understand root causes

## Next Steps

After running validation:
1. If accuracy is good (>70% quarter accuracy): Continue monitoring
2. If accuracy is moderate (50-70%): Consider minor adjustments to median times
3. If accuracy is poor (<50%): Recalculate median times from recent data and update forecast view

## Notes

- Validation uses deals that have already joined (last 12 months)
- Forecast is calculated using the same logic as the forecast view
- Only includes deals with SQO dates and stage entry dates where applicable
- Margin AUM is estimated using the same fallback logic as the forecast view

