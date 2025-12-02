# Stage Velocity Analysis Results

## Overview

This document contains the results of analyzing historical data to determine median cycle times and conversion rates from each sales stage to "Joined" status.

## Analysis Date

Analysis performed using BigQuery MCP tool on the `savvy-gtm-analytics.SavvyGTMData.Opportunity` table.

## Key Findings

### Stage-to-Join Metrics

| Stage | Total Entered | Total Joined | Conversion Rate | Median Days to Join | P25 Days | P75 Days | Avg Days to Join |
|-------|---------------|--------------|-----------------|---------------------|----------|----------|------------------|
| **Signed** | 90 | 78 | **86.67%** | **16 days** | 7 days | 35 days | 24.62 days |
| **Negotiating** | 184 | 64 | **34.78%** | **37 days** | 14 days | 74 days | 47.45 days |
| **Sales Process** | 503 | 67 | **13.32%** | **69 days** | 32 days | 97 days | 79.46 days |
| **Discovery** | 48 | 4 | **8.33%** | **62 days** | 25 days | 74 days | 112.75 days |

### Current Pipeline Status

| Stage | Open Deals | Has Stage Entry Date | Avg SQO Age (Days) |
|-------|------------|----------------------|-------------------|
| **Qualifying** | 2 | 0 | 400.5 |
| **Discovery** | 28 | 10 | 47.8 |
| **Sales Process** | 61 | 60 | 63.3 |
| **Negotiating** | 27 | 27 | 112.6 |
| **Signed** | 8 | 8 | 75.5 |

## Insights

### 1. Signed Stage (Highest Conversion)
- **86.67% conversion rate** - Very high likelihood of joining
- **16 days median** from stage entry to join
- **8 open deals** currently in this stage
- **Recommendation**: Use 16 days from stage entry date (or current date if no entry date)

### 2. Negotiating Stage (Moderate Conversion)
- **34.78% conversion rate** - Moderate likelihood of joining
- **37 days median** from stage entry to join
- **27 open deals** currently in this stage
- **Recommendation**: Use 37 days from stage entry date (or current date if no entry date)

### 3. Sales Process Stage (Lower Conversion)
- **13.32% conversion rate** - Lower likelihood of joining
- **69 days median** from stage entry to join
- **61 open deals** currently in this stage (largest pipeline segment)
- **Recommendation**: Use 69 days from stage entry date

### 4. Discovery Stage (Lowest Conversion)
- **8.33% conversion rate** - Low likelihood of joining
- **62 days median** from stage entry to join
- **28 open deals** currently in this stage
- **Note**: Small sample size (only 4 deals with both dates)
- **Recommendation**: Use 62 days from stage entry date, but be cautious due to low conversion rate

## Implementation in Forecast View

The forecast view (`vw_sgm_capacity_coverage_with_forecast`) now uses:

1. **Stage Entry Date + Median Time** (preferred):
   - If a deal has entered a stage and we have the stage entry date, use: `Stage Entry Date + Median Days`
   - This is more accurate because it accounts for how long the deal has already been in the stage

2. **Current Date + Median Time** (fallback for Signed/Negotiating):
   - If a deal is in Signed or Negotiating but we don't have the stage entry date, use: `Current Date + Median Days`
   - This assumes the deal just entered the stage

3. **SQO Date + 70 Days** (default):
   - For deals in earlier stages or without stage entry dates, use: `SQO Date + 70 days`
   - This uses the overall median cycle time from SQO to Join

## Forecast Accuracy Considerations

### High Confidence Stages
- **Signed**: High conversion rate (86.67%) and short cycle time (16 days) = High forecast accuracy
- **Negotiating**: Moderate conversion rate (34.78%) and reasonable cycle time (37 days) = Moderate forecast accuracy

### Lower Confidence Stages
- **Sales Process**: Lower conversion rate (13.32%) and longer cycle time (69 days) = Lower forecast accuracy
- **Discovery**: Very low conversion rate (8.33%) and variable cycle time (62 days) = Lower forecast accuracy

### Recommendations

1. **Weight forecasts by stage**: Deals in Signed/Negotiating should have higher weight in forecasts
2. **Monitor conversion rates**: Track actual vs. forecasted conversions to refine the model
3. **Consider deal age**: Older deals in a stage may have different probabilities than newer deals
4. **Use stage probabilities**: The forecast already multiplies by stage probability, which helps account for conversion rates

## Data Quality Notes

- **Discovery stage**: Only 4 deals have both stage entry date and join date (small sample)
- **Sales Process stage**: 60 out of 61 open deals have stage entry dates (good data quality)
- **Negotiating stage**: All 27 open deals have stage entry dates (excellent data quality)
- **Signed stage**: All 8 open deals have stage entry dates (excellent data quality)

## Next Steps

1. ✅ **Implemented**: Updated forecast view with actual median times
2. **Monitor**: Track forecast accuracy over time
3. **Refine**: Consider SGM-specific cycle times if data allows
4. **Validate**: Compare forecasted vs. actual joined margin AUM quarterly

