# Forecast Risk Analysis Report

**Date**: Generated from Production Forecast Data  
**Analysis Period**: Next 90 days (Current Date to +90 days)  
**Data Source**: `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`

---

## Query 1: Forecast Volume by Model Type

**Business Question**: "How much of our total forecasted volume comes from the reliable (but few) ARIMA models versus the simple (but many) heuristic averages? I want to know where our forecast 'risk' is."

### Results

| Model Type | Forecasted MQLs | Forecasted SQLs | Forecasted SQOs | % of Total SQO Forecast |
|------------|----------------|-----------------|-----------------|------------------------|
| **Heuristic Model (20 Segments)** | 524.32 | 128.73 | 67.82 | **60.2%** |
| **ARIMA Model (4 Segments)** | 238.80 | 75.03 | 44.83 | **39.8%** |

### Key Insights

- **60.2%** of forecasted SQOs come from Heuristic models (20 segments)
- **39.8%** of forecasted SQOs come from ARIMA models (4 segments)
- The majority of forecast risk is in the Heuristic models, which cover more segments but use simpler averaging methods

---

## Query 2: Forecast Confidence & Uncertainty

**Business Question**: "Where is our forecast most and least confident? Show me the segments with the widest and narrowest 95% confidence intervals so I know where we have the most uncertainty."

### Top 10 Most Uncertain Segments

| Channel Grouping | Original Source | Total SQOs (Forecast) | Lower Bound (95%) | Upper Bound (95%) | Absolute Uncertainty Range | Relative Uncertainty % |
|------------------|-----------------|----------------------|-------------------|-------------------|---------------------------|------------------------|
| Marketing | Re-Engagement | 9.19 | 6.43 | 11.95 | 5.51 | **60.0%** |
| Marketing | Ashby | 1.53 | 1.07 | 1.99 | 0.92 | **60.0%** |
| Marketing | LinkedIn (Content) | 1.53 | 1.07 | 1.99 | 0.92 | **60.0%** |
| Ecosystem | Advisor Referral | 5.00 | 3.50 | 6.50 | 3.00 | **60.0%** |
| Ecosystem | Recruitment Firm | 24.58 | 17.21 | 31.96 | 14.75 | **60.0%** |
| Marketing | Event | 3.41 | 2.39 | 4.44 | 2.05 | **60.0%** |
| Outbound | Provided Lead List | 20.25 | 14.17 | 26.32 | 12.15 | **60.0%** |
| Outbound | LinkedIn (Self Sourced) | 47.15 | 33.00 | 61.29 | 28.29 | **60.0%** |

**Summary**: All segments show approximately 60% relative uncertainty in their 95% confidence intervals, meaning the upper bound is about 60% higher than the forecast and the lower bound is about 40% lower. This suggests consistent uncertainty modeling across segments, with the largest absolute uncertainty ranges occurring in high-volume segments like Outbound > LinkedIn (Self Sourced) at 28.29 SQOs.

---

## Query 3: Quarterly Forecast Scenarios (Bull vs. Bear Case)

**Business Question**: "I see the 123 SQO forecast. What is the 'optimistic' (bull case) versus 'pessimistic' (bear case) number for the full quarter based on the model's 95% confidence?"

### Quarterly Forecast Summary

| Scenario | SQO Count | Description |
|----------|-----------|-------------|
| **Actuals to Date** | 53 | Completed SQOs so far this quarter |
| **Forecast Point Estimate** | 76.26 | Most likely remaining SQOs |
| **Most Likely Quarter Total** | 129.26 | Actuals + Forecast (point estimate) |
| **Bear Case (Lower 95% Bound)** | 106.38 | Actuals + Forecast (lower bound) |
| **Bull Case (Upper 95% Bound)** | 152.14 | Actuals + Forecast (upper bound) |

### Forecast Range Details

| Metric | Value |
|--------|-------|
| Forecast Lower Bound (remaining days) | 53.38 |
| Forecast Point Estimate (remaining days) | 76.26 |
| Forecast Upper Bound (remaining days) | 99.14 |

### Key Insights

- **Most Likely Scenario**: 129 SQOs for the quarter
- **Bear Case (95% lower bound)**: 106 SQOs for the quarter
- **Bull Case (95% upper bound)**: 152 SQOs for the quarter
- **Range**: 46 SQOs difference between bear and bull cases (±23 SQOs from the point estimate)

---

## Query 4: Conversion Rate Drivers

**Business Question**: "Which segments have the best and worst SQL-to-SQO conversion rates? I want to know which segments are most efficient at closing."

### SQL-to-SQO Conversion Rates (Last 60 Days)

| Channel Grouping | Original Source | SQL-to-SQO Conversion Rate | Opportunities in Last 60 Days | Backoff Level |
|------------------|-----------------|---------------------------|------------------------------|---------------|
| **Ecosystem** | **Recruitment Firm** | **74.1%** | 17 | GLOBAL |
| **Marketing** | **Advisor Waitlist** | **71.4%** | 18 | SOURCE_60D |
| **Outbound** | **LinkedIn (Self Sourced)** | **52.5%** | 49 | SOURCE_30D |
| **Outbound** | **Provided Lead List** | **48.4%** | 21 | SOURCE_30D |
| **Marketing** | **Event** | **37.9%** | 19 | SOURCE_60D |

### Key Insights

- **Highest Conversion**: Ecosystem > Recruitment Firm at **74.1%** (17 opportunities)
- **Strong Performance**: Marketing > Advisor Waitlist at **71.4%** (18 opportunities)
- **Largest Volume**: Outbound > LinkedIn (Self Sourced) with 49 opportunities and **52.5%** conversion
- **Lowest Conversion**: Marketing > Event at **37.9%** (19 opportunities)

---

## Query 5: ARIMA Trend Analysis (The 'Why')

**Business Question**: "For our most important segments, what trend did the ARIMA model actually find? Is it forecasting growth, decline, or just seasonal wiggles?"

### ARIMA Model Analysis for Key Segments

| Channel Grouping | Original Source | Detected Trend | Detected Seasonality | Non-Seasonal P | Non-Seasonal D | Non-Seasonal Q | Has Holiday Effect | Has Spikes/Dips |
|------------------|-----------------|----------------|---------------------|----------------|----------------|----------------|-------------------|-----------------|
| **Ecosystem** | **Recruitment Firm** | Flat Trend | No Strong Seasonality | 1 | 0 | 2 | No | Yes |
| **Marketing** | **Advisor Waitlist** | Flat Trend | No Strong Seasonality | 0 | 0 | 0 | No | Yes |
| **Outbound** | **LinkedIn (Self Sourced)** | Flat Trend | Seasonality Detected | 2 | 0 | 2 | No | No |
| **Outbound** | **Provided Lead List** | Flat Trend | Seasonality Detected | 3 | 0 | 2 | No | Yes |

### Key Insights

- **Trend Detection**: All four segments show **flat trends** (no strong upward or downward drift), suggesting stable baseline forecasts across all key segments
- **Seasonality**: 
  - **Seasonality Detected**: Outbound > LinkedIn (Self Sourced) and Outbound > Provided Lead List both show seasonal patterns
  - **No Seasonality**: Ecosystem > Recruitment Firm and Marketing > Advisor Waitlist show no strong seasonal patterns
- **Model Parameters**: 
  - Recruitment Firm uses ARIMA(1,0,2) - autoregressive model with 1 lag and 2 moving average terms
  - Advisor Waitlist uses ARIMA(0,0,0) - simplest model (white noise or constant level)
  - LinkedIn (Self Sourced) uses ARIMA(2,0,2) - moderate complexity with 2 autoregressive lags
  - Provided Lead List uses ARIMA(3,0,2) - most complex structure with 3 autoregressive lags
- **Anomalies**: Three of four segments have detected **spikes and dips** (Recruitment Firm, Advisor Waitlist, Provided Lead List), indicating the models account for irregular events
- **Holiday Effects**: No segments show significant holiday effects in the current models

### Interpretation

The ARIMA models for all key segments are forecasting **stable, steady-state performance** rather than growth or decline. The flat trend across all segments suggests that recent historical patterns will continue, with models primarily capturing:
- Short-term fluctuations (via AR/MA terms)
- Seasonal patterns (weekly/monthly) for Outbound segments
- Irregular events (spikes/dips) for most segments

This indicates a **conservative forecasting approach** that assumes continuation of current performance levels rather than predicting growth or decline trends.

---

## Summary & Recommendations

### Forecast Risk Distribution
- **60.2%** of SQO forecast relies on Heuristic models (higher risk, broader coverage)
- **39.8%** of SQO forecast relies on ARIMA models (lower risk, focused coverage)

### Uncertainty
- All segments show approximately **60% relative uncertainty** in their confidence intervals
- Highest absolute uncertainty in high-volume segments (Outbound > LinkedIn: ±28.29 SQOs)

### Quarterly Scenarios
- **Most Likely**: 129 SQOs
- **Range**: 106 (bear) to 152 (bull) SQOs
- **Planning Recommendation**: Use the range (106-152) for risk-adjusted planning

### Conversion Efficiency
- Focus on high-conversion segments: **Recruitment Firm (74.1%)** and **Advisor Waitlist (71.4%)**
- Monitor low-conversion segments: **Event (37.9%)** for improvement opportunities

### ARIMA Model Behavior
- Models forecast **stable performance** (flat trends) for key segments
- Some seasonality detected in Provided Lead List segment
- Both models account for irregular events (spikes/dips)

---

*Report generated from production forecast data. All forecasts are based on 90-day forward-looking period from current date.*
