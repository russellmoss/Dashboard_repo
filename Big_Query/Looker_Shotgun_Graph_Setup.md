# Looker Shotgun-Style Graph Setup Guide

**View:** `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker` ✅ **Created and Ready**

**Status:** ✅ View is live and ready to use in Looker

---

## View Overview

This view is optimized for creating shotgun-style confidence interval graphs in Looker. It includes:
- ✅ Forecast values by Original Source, Channel, and Date
- ✅ 50% confidence intervals (upper and lower)
- ✅ Actuals and predictions for comparison
- ✅ Time period filters (ACTUAL, TODAY, FORECAST)
- ✅ Confidence interval width for visualization

---

## Looker Visualization Setup

### Step 1: Create a New Look

1. Go to **Explore** → Select `vw_forecast_for_looker`
2. Add filters:
   - `Original_source` (or filter to specific sources)
   - `Channel_Grouping_Name` (optional)
   - `date_day` (date range)
   - `time_period_type` (optional: show ACTUAL + FORECAST)

### Step 2: Create Shotgun-Style Graph

#### Option A: Using Looker's Band/Area Chart

1. **X-Axis:** `date_day` (Date dimension)
2. **Y-Axis (Primary):** 
   - `sqls_value` (or `mqls_value`, `sqos_value`)
   - Measure type: **Sum** or **Average**
3. **Y-Axis (Confidence Bands):**
   - `sqls_forecast_lower_50` (Lower bound)
   - `sqls_forecast_upper_50` (Upper bound)
   - Measure type: **Sum** or **Average**

4. **Visualization Type:** 
   - **Line Chart** with **Band/Confidence Interval**
   - OR **Area Chart** with stacked bands

5. **Series:**
   - Line 1: `sqls_actual` (Actuals - solid line)
   - Line 2: `sqls_forecast` (Forecast - dashed line)
   - Band: Between `sqls_forecast_lower_50` and `sqls_forecast_upper_50`

#### Option B: Using Custom Visualization (Recommended)

**Visualization Type:** **Line Chart with Error Bars** or **Line Chart with Confidence Bands**

**Configuration:**
- **X-Axis:** `date_day`
- **Y-Axis:** `sqls_value`
- **Series 1:** `sqls_actual` (label: "Actual SQLs")
  - Color: Blue
  - Line style: Solid
- **Series 2:** `sqls_forecast` (label: "Forecast SQLs")
  - Color: Orange
  - Line style: Dashed
- **Confidence Band:** 
   - Lower: `sqls_forecast_lower_50`
   - Upper: `sqls_forecast_upper_50`
   - Fill color: Light orange (semi-transparent)
   - Style: Area/shaded band
   - **For 95% CI:** Use `sqls_forecast_lower_95` and `sqls_forecast_upper_95` instead

---

## Example Looker Query Structure

```lookml
explore: vw_forecast_for_looker {
  # Add dimensions and measures as needed
}

dimension: date_day {
  type: date
  sql: ${TABLE}.date_day ;;
}

dimension: original_source {
  type: string
  sql: ${TABLE}.Original_source ;;
}

dimension: channel_grouping_name {
  type: string
  sql: ${TABLE}.Channel_Grouping_Name ;;
}

dimension: time_period_type {
  type: string
  sql: ${TABLE}.time_period_type ;;
}

measure: sqls_actual {
  type: sum
  sql: ${TABLE}.sqls_actual ;;
  value_format_name: decimal_1
}

measure: sqls_forecast {
  type: sum
  sql: ${TABLE}.sqls_forecast ;;
  value_format_name: decimal_1
}

measure: sqls_forecast_lower_50 {
  type: sum
  sql: ${TABLE}.sqls_forecast_lower_50 ;;
  value_format_name: decimal_1
}

measure: sqls_forecast_upper_50 {
  type: sum
  sql: ${TABLE}.sqls_forecast_upper_50 ;;
  value_format_name: decimal_1
}
```

---

## Shotgun Graph Characteristics

### What Makes a "Shotgun" Graph:
1. ✅ **Confidence intervals widen over time** - Already built in (CI width increases with forecast horizon)
2. ✅ **Actuals line** - Shows historical performance
3. ✅ **Forecast line** - Shows predicted future
4. ✅ **Confidence band (50% or 95%)** - Shaded area showing uncertainty

**Available Confidence Intervals:**
- **50% CI:** `*_forecast_lower_50`, `*_forecast_upper_50` (primary visualization)
- **95% CI:** `*_forecast_lower_95`, `*_forecast_upper_95` (conservative bounds)
- **CI Width:** `*_ci_width_50`, `*_ci_width_95` (shows widening over time)

### Why Intervals Widen:
- The `sqls_ci_width_50` measure shows the width of the confidence interval
- Forecasts further in the future have wider intervals (greater uncertainty)
- Looker will automatically show this widening as you extend the date range

---

## Quick Start Examples

### Example 1: SQL Forecast by Source (Last 30 days + Next 60 days)

**Filters:**
- `date_day`: Last 30 days through Next 60 days
- `Original_source`: [Select specific sources]
- `time_period_type`: ACTUAL + FORECAST

**Visualization:**
- X: `date_day`
- Y: `sqls_value` (combined actuals + forecast)
- Series: `sqls_actual` and `sqls_forecast`
- Band: `sqls_forecast_lower_50` to `sqls_forecast_upper_50`

### Example 2: SQO Forecast Across All Channels

**Filters:**
- `date_day`: Next 90 days
- `Channel_Grouping_Name`: [All or specific]

**Visualization:**
- X: `date_day`
- Y: `sqos_value`
- Series: `sqos_forecast`
- Band: `sqos_forecast_lower_50` to `sqos_forecast_upper_50`
- Group by: `Original_source` (multiple lines)

---

## View Fields Reference

### Key Dimensions:
- `Channel_Grouping_Name` - Filter by channel
- `Original_source` - Filter by source
- `date_day` - Date dimension
- `time_period_type` - ACTUAL, TODAY, or FORECAST
- `days_from_today` - For dynamic filtering

### Key Measures (per Stage):
- `*_actual` - Historical actual values
- `*_forecast` - Predicted values
- `*_forecast_lower_50` - 50% CI lower bound
- `*_forecast_upper_50` - 50% CI upper bound
- `*_value` - Combined (actual if available, else forecast)
- `*_ci_width_50` - Confidence interval width

### Available Stages:
- `mqls_*` - MQL metrics
- `sqls_*` - SQL metrics
- `sqos_*` - SQO metrics

---

## Tips for Looker Visualization

1. **Use Date Range Filters:**
   - Show last 30-60 days of actuals
   - Extend forecast 60-90 days into future
   - This shows the "shotgun" widening effect

2. **Color Coding:**
   - Actuals: Blue or Green (solid line)
   - Forecast: Orange or Red (dashed line)
   - Confidence Band: Light shade matching forecast color

3. **Multiple Series:**
   - Show actuals and forecast on same graph
   - Use different line styles (solid vs dashed)
   - Confidence band as semi-transparent fill

4. **Grouping:**
   - Group by `Original_source` for multi-line comparison
   - Group by `Channel_Grouping_Name` for channel-level view
   - Use Looker's "Compare" feature for period-over-period

---

## Expected Graph Appearance

```
      Forecast Line (dashed)
    /     Upper CI (50%)
   /    /    
  /   /     
 /  /       
/ /          Lower CI (50%)
/            Actuals Line (solid)
|            
|            
|            
+------------+------------+------------+
Past         Today        Future
```

The confidence interval will naturally widen as you move further into the future, creating the "shotgun" effect.

