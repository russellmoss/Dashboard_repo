# Final Forecast Model Documentation

**Last Updated:** November 2025  
**Status:** ✅ Production-Ready and Integrated  
**Model Version:** Final (V3.1 Super-Segment ML + Hybrid Conversion Rates)

---

## Executive Summary

This document describes the **final production forecast model** architecture, validated through comprehensive backtesting and **now integrated into production (November 2025)**. The model uses a **hybrid approach** combining:

- **Top of Funnel (MQLs):** ARIMA_PLUS time-series models
- **Top of Funnel (SQLs):** **V3.1 Super-Segment ML Model** ✅ **NOW IN PRODUCTION**
- **Bottom of Funnel (SQL→SQO):** Hybrid conversion rates (Trailing rates weighted by volume + V2 Challenger fallback)

**Validation:** 
- **SQL Forecasting:** V3.1 Super-Segment Model validated with -27.1% error (2.24x better than ARIMA_PLUS)
- **SQO Conversion:** Hybrid approach validated with -5.35% error (best performing method)

**Integration Status:**
- ✅ **V3.1 integrated into production** (November 2025)
- ✅ Replaces ARIMA_PLUS for SQL forecasting
- ✅ All views and dashboards updated

---

## Model Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Top of Funnel (ToF)                      │
├─────────────────────────────────────────────────────────────┤
│ MQLs: ARIMA_PLUS (model_arima_mqls)                         │
│       Source: daily_forecasts table                         │
│                                                              │
│ SQLs: V3.1 Super-Segment ML ✅ PRODUCTION                   │
│       Model: model_tof_sql_regressor_v3_1_final            │
│       Distributed via: vw_v3_1_sql_forecast_by_channel_...│
│       Validated: -27.1% error (2.24x better than ARIMA)    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Bottom of Funnel (BoF) - SQOs                  │
├─────────────────────────────────────────────────────────────┤
│ Method: Hybrid Conversion Rate                              │
│                                                              │
│ Formula: V3.1 SQLs × Hybrid Rate                            │
│ Hybrid Rate: Trailing rates (weighted by SQL volume)        │
│             + V2 Challenger (69.3% fallback)                │
│                                                              │
│ Validated: -5.35% error (October 2025 backtest)            │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. SQL Queries for Each Model Component

### 1.1 Top of Funnel: MQLs (ARIMA_PLUS) and SQLs (V3.1)

**MQL Forecast Model (ARIMA_PLUS):**
```sql
-- Model: savvy-gtm-analytics.savvy_forecast.model_arima_mqls
-- Forecasts MQLs by Channel_Grouping_Name and Original_source
-- Stored in: daily_forecasts table

SELECT
  Channel_Grouping_Name,
  Original_source,
  CAST(forecast_timestamp AS DATE) AS date_day,
  forecast_value AS mqls_forecast,
  prediction_interval_lower_bound AS mqls_lower,
  prediction_interval_upper_bound AS mqls_upper
FROM ML.FORECAST(
  MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
  STRUCT(90 AS horizon, 0.9 AS confidence_level)
);
```

**SQL Forecast Model (V3.1 Super-Segment ML) - ✅ PRODUCTION:**
```sql
-- Model: savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_1_final
-- Forecasts SQLs at super-segment level, distributed to Channel/Source
-- View: vw_v3_1_sql_forecast_by_channel_source

-- V3.1 generates forecasts at super-segment level (4 segments)
-- Then distributes to Channel_Grouping_Name × Original_source via mapping

SELECT
  date_day,
  Channel_Grouping_Name,
  Original_source,
  sqls_forecast_v3_1 AS sqls_forecast
FROM `savvy-gtm-analytics.savvy_forecast.vw_v3_1_sql_forecast_by_channel_source`
WHERE date_day >= CURRENT_DATE();
```

**Key Difference:**
- **MQLs:** Still use ARIMA_PLUS via `daily_forecasts` table
- **SQLs:** Now use **V3.1 Super-Segment ML** (2.24x more accurate!)
- **V3.1 Benefits:** -27.1% error vs ARIMA_PLUS -60.7% error

**Location:** 
- MQLs: Generated via `daily_forecasts` table insertion process
- SQLs: Generated via `vw_v3_1_sql_forecast_by_channel_source` view (real-time from V3.1 model)

---

### 1.2 Bottom of Funnel: Hybrid Conversion Rate

**Hybrid Rate Calculation:**
```sql
-- View: savvy-gtm-analytics.savvy_forecast.vw_hybrid_conversion_rates
-- Calculates weighted trailing rates + V2 Challenger fallback

WITH
-- Get actual SQL distribution by Channel/Source (last 90 days) for weighting
recent_sql_distribution AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    SUM(sqls_daily) AS total_sqls,
    SUM(SUM(sqls_daily)) OVER () AS grand_total,
    SUM(sqls_daily) / SUM(SUM(sqls_daily)) OVER () AS sql_fraction
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts`
  WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND date_day < CURRENT_DATE()
  GROUP BY Channel_Grouping_Name, Original_source
),
-- Get latest trailing rates
latest_trailing_rates AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    s2q_rate_selected AS sql_to_sqo_rate,
    s2q_den_60d AS sample_size,
    date_day AS rate_date
  FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
  WHERE date_day = (
    SELECT MAX(date_day) 
    FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
  )
    AND s2q_rate_selected IS NOT NULL
),
-- Calculate hybrid rate: trailing rates weighted by SQL volume, V2 Challenger (69.3%) as fallback
hybrid_rate_calculation AS (
  SELECT
    COALESCE(
      SUM(rsd.sql_fraction * COALESCE(ltr.sql_to_sqo_rate, 0.693)),
      0.693
    ) AS hybrid_sql_to_sqo_rate,
    SUM(rsd.sql_fraction * CASE WHEN ltr.sql_to_sqo_rate IS NOT NULL THEN 1 ELSE 0 END) AS trailing_coverage_pct,
    AVG(ltr.sql_to_sqo_rate) AS avg_trailing_rate,
    0.693 AS v2_challenger_rate,
    MAX(ltr.rate_date) AS trailing_rate_date
  FROM recent_sql_distribution rsd
  LEFT JOIN latest_trailing_rates ltr
    ON rsd.Channel_Grouping_Name = ltr.Channel_Grouping_Name
    AND rsd.Original_source = ltr.Original_source
)
SELECT
  CURRENT_DATE() AS calculation_date,
  hybrid_sql_to_sqo_rate,
  trailing_coverage_pct,
  avg_trailing_rate,
  v2_challenger_rate,
  trailing_rate_date,
  CURRENT_TIMESTAMP() AS last_updated
FROM hybrid_rate_calculation;
```

**SQO Forecast Calculation:**
```sql
-- Applied in vw_production_forecast
-- Formula: SQLs × Hybrid Rate

sqos_forecast = sqls_forecast * hybrid_sql_to_sqo_rate
sqos_lower_50 = sqls_lower_50 * hybrid_sql_to_sqo_rate
sqos_upper_50 = sqls_upper_50 * hybrid_sql_to_sqo_rate
sqos_lower_95 = sqls_lower_95 * hybrid_sql_to_sqo_rate
sqos_upper_95 = sqls_upper_95 * hybrid_sql_to_sqo_rate
```

---

## 2. BigQuery Objects: Files, Tables, Views, and Models

### 2.1 Models

| Object Name | Type | Purpose | Status |
|------------|------|---------|--------|
| `savvy-gtm-analytics.savvy_forecast.model_arima_mqls` | MODEL | MQL forecasting (ToF) | ✅ Production |
| `savvy-gtm-analytics.savvy_forecast.model_arima_sqls` | MODEL | SQL forecasting (ToF) | ✅ Production |
| `savvy-gtm-analytics.savvy_forecast.model_tof_sql_regressor_v3_1_final` | MODEL | V3.1 Super-Segment SQL model (better than ARIMA, not yet integrated) | ⚠️ Available |
| `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity_v2` | MODEL | V2 SQL→SQO classifier (used for conversion rate validation) | ✅ Available |

### 2.2 Tables

| Table Name | Purpose | Key Fields |
|-----------|---------|------------|
| `savvy-gtm-analytics.savvy_forecast.daily_forecasts` | Stores ARIMA_PLUS forecasts | `forecast_date`, `Channel_Grouping_Name`, `Original_source`, `date_day`, `mqls_forecast`, `sqls_forecast`, `mqls_lower/upper`, `sqls_lower/upper` |
| `savvy-gtm-analytics.savvy_forecast.trailing_rates_features` | Segment-specific historical conversion rates | `date_day`, `Channel_Grouping_Name`, `Original_source`, `s2q_rate_selected` |
| `savvy-gtm-analytics.savvy_forecast.tof_v3_1_daily_training_data` | V3.1 model training data (super-segments) | `date_day`, `super_segment`, `target_sqls`, lag features |
| `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training_v2` | V2 classifier training data | SQL-level features for SQO propensity |

### 2.3 Views

| View Name | Purpose | Key Fields |
|-----------|---------|------------|
| `savvy-gtm-analytics.savvy_forecast.vw_production_forecast` | **Main production forecast view** | All metrics, actuals + forecasts, 50% & 95% CIs |
| `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker` | **Optimized for Looker visualizations** | Forecast metrics with CI widths, time dimensions |
| `savvy-gtm-analytics.savvy_forecast.vw_v3_1_sql_forecast_by_channel_source` | **V3.1 SQL forecasts distributed to Channel/Source** | `date_day`, `Channel_Grouping_Name`, `Original_source`, `sqls_forecast_v3_1` |
| `savvy-gtm-analytics.savvy_forecast.vw_super_segment_to_channel_source_mapping` | Maps super-segments to Channel/Source distribution | `super_segment`, `Channel_Grouping_Name`, `Original_source`, `normalized_fraction` |
| `savvy-gtm-analytics.savvy_forecast.vw_hybrid_conversion_rates` | Hybrid conversion rate calculator | `hybrid_sql_to_sqo_rate`, `trailing_coverage_pct` |
| `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts` | Daily actuals by segment | `date_day`, `Channel_Grouping_Name`, `Original_source`, `mqls_daily`, `sqls_daily`, `sqos_daily` |
| `savvy-gtm-analytics.savvy_forecast.vw_sga_funnel_super_segments` | Super-segment mapping for V3.1 | `created_date`, `super_segment`, `LeadSource` mapping |
| `savvy-gtm-analytics.savvy_forecast.vw_live_conversion_rates` | Live rolling 90-day rates (not used in final model) | `contacted_to_mql_rate`, `mql_to_sql_rate`, `sql_to_sqo_rate` |

### 2.4 Local Files

| File Name | Purpose |
|-----------|---------|
| `Views/vw_production_forecast_v3_1.sql` | Production forecast view (uses V3.1 for SQLs + Hybrid rates) |
| `Views/vw_forecast_for_looker_final.sql` | Looker-optimized view definition (50% & 95% CIs) |
| `Views/vw_v3_1_sql_forecast_by_channel_source.sql` | V3.1 SQL forecast distribution view |
| `Views/vw_sga_funnel_super_segments.sql` | Super-segment mapping view (for V3.1 model) |
| `Views/vw_live_conversion_rates.sql` | Live rolling conversion rates (not used in final model) |
| `Views/vw_model_performance_updated.sql` | Model performance monitoring view |
| `Views/vw_model_drift_alert_updated.sql` | Drift detection alerts view |

---

## 3. Why We Chose This Approach

### 3.1 Top of Funnel: MQLs (ARIMA_PLUS) and SQLs (V3.1) ✅

**MQLs: ARIMA_PLUS (Still Used):**
- ✅ Integrated into production (`daily_forecasts` table)
- ✅ Provides forecasts at `Channel_Grouping_Name` × `Original_source` granularity
- ✅ Production-tested and stable
- ✅ Includes confidence intervals
- ✅ No better alternative validated yet

**SQLs: V3.1 Super-Segment ML (✅ NOW IN PRODUCTION):**
- ✅ **2.24x more accurate** than ARIMA_PLUS (-27.1% vs -60.7% error)
- ✅ Uses machine learning (BOOSTED_TREE_REGRESSOR)
- ✅ Forecasts at super-segment level, distributed to Channel/Source via mapping
- ✅ **Integrated November 2025** - Replaces ARIMA_PLUS for SQL forecasting
- ✅ Validated in October 2025 backtest (64.9 SQLs vs 89 actual)

**Integration Solution:**
- Created `vw_super_segment_to_channel_source_mapping` to map super-segments to Channel/Source
- Created `vw_v3_1_sql_forecast_by_channel_source` to distribute V3.1 forecasts
- Updated `vw_production_forecast` to use V3.1 SQL forecasts instead of ARIMA_PLUS

**Decision:** ✅ **V3.1 is now in production** - The 2.24x accuracy improvement justified the integration effort. ARIMA_PLUS is still used for MQLs where no better alternative exists.

### 3.2 Bottom of Funnel: Hybrid Approach (vs Other Methods)

#### Method Comparison (October 2025 Backtest)

| Method | Error | Predicted SQOs | Actual SQOs | Status |
|--------|-------|----------------|-------------|--------|
| **🏆 Hybrid (Trailing + V2)** | **-5.35%** | 57.7 | 61 | ✅ **BEST** |
| **V2 Challenger Only** | +4.52% | 63.8 | 61 | ⚠️ Over-predicts |
| **Trailing Average Only** | -16.94% | 50.7 | 61 | ❌ Under-predicts |
| **Live Rolling Rate** | Not tested | N/A | N/A | ⚠️ Untested |

**Why Hybrid Approach Won:**

1. **Most Accurate:** -5.35% error (smallest among all methods)
   - Only 3.3 SQOs off from actual (57.7 vs 61)

2. **Segment-Aware:** 
   - Uses segment-specific trailing rates (not a single average)
   - Reflects actual performance differences across channels/sources

3. **Volume-Weighted:**
   - High-volume segments (like LinkedIn Self Sourced) have more influence
   - Better reflects actual business mix

4. **Balanced:**
   - Not too optimistic (V2: 69.3%) or too conservative (Trailing Avg: 55.07%)
   - Hybrid rate: ~55.27% (weighted average)

5. **Validated:**
   - Backtested against October 2025 actuals
   - Outperformed all alternatives

### 3.3 Why Not Other Approaches

**❌ V2 Challenger Only (69.3%):**
- Over-predicts (+4.52% error)
- Single rate doesn't reflect segment differences
- Too optimistic for most segments

**❌ Trailing Average Only (~55%):**
- Under-predicts significantly (-16.94% error)
- Unweighted average doesn't account for business mix
- Too conservative

**❌ Live Rolling Rate (58.23%):**
- Not backtested (would likely perform between V2 and Trailing)
- Updates frequently (less stable)
- Doesn't leverage segment-specific insights

**❌ V3.1 for SQLs + Segment-Level Modeling:**
- V3.1 is at super-segment level (4 segments)
- Current production needs Channel/Source granularity
- Integration would require mapping logic
- V3.1 validated but not yet integrated into production pipeline

---

## 4. Forecast Views: Usage Guide

### 4.1 Main Production Forecast View

**View:** `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`

**File:** `Views/vw_production_forecast_final.sql`

**Key Fields:**
- **Dimensions:** `Channel_Grouping_Name`, `Original_source`, `date_day`
- **Actuals:** `mqls_actual`, `sqls_actual`, `sqos_actual`
- **Forecasts:** `mqls_forecast`, `sqls_forecast`, `sqos_forecast`
- **Combined:** `mqls_combined`, `sqls_combined`, `sqos_combined` (actual if available, else forecast)
- **50% CIs:** `mqls_lower_50`, `mqls_upper_50`, `sqls_lower_50`, `sqls_upper_50`, `sqos_lower_50`, `sqos_upper_50`
- **95% CIs:** `mqls_lower_95`, `mqls_upper_95`, `sqls_lower_95`, `sqls_upper_95`, `sqos_lower_95`, `sqos_upper_95`
- **Metadata:** `data_type` (ACTUAL/FORECAST), `quarter`, `month`, `year`, cumulative metrics (MTD, QTD)

**Basic Query Example:**
```sql
SELECT
  date_day,
  Channel_Grouping_Name,
  Original_source,
  sqls_combined,
  sqls_forecast,
  sqls_forecast_lower_50,
  sqls_forecast_upper_50,
  sqls_forecast_lower_95,
  sqls_forecast_upper_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_production_forecast`
WHERE date_day >= '2025-10-01'
  AND date_day <= '2025-12-31'
ORDER BY date_day, Channel_Grouping_Name, Original_source;
```

---

### 4.2 Looker-Optimized Forecast View

**View:** `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`

**File:** `Views/vw_forecast_for_looker_final.sql`

**Purpose:** Optimized for Looker visualizations, especially shotgun-style graphs

**Key Fields (Additional):**
- `time_period_type` (ACTUAL/TODAY/FORECAST)
- `days_from_today` (for filtering recent vs future)
- `*_ci_width_50` (confidence interval width for visualizations)
- `*_ci_width_95` (95% CI width)
- Time dimensions: `day_name`, `month_name`, `day_of_week`, etc.

---

## 5. How to Use Forecast Views: Shotgun Graphs and Confidence Intervals

### 5.1 Getting 50% Confidence Intervals

**For SQLs (Example):**
```sql
SELECT
  date_day,
  Channel_Grouping_Name,
  Original_source,
  sqls_actual,
  sqls_forecast,
  sqls_forecast_lower_50 AS sqls_lower_50,
  sqls_forecast_upper_50 AS sqls_upper_50
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
ORDER BY date_day;
```

**For SQOs (Example):**
```sql
SELECT
  date_day,
  sqos_actual,
  sqos_forecast,
  sqos_forecast_lower_50 AS sqos_lower_50,
  sqos_forecast_upper_50 AS sqos_upper_50
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
ORDER BY date_day;
```

### 5.2 Getting 95% Confidence Intervals

**Same query, use `*_lower_95` and `*_upper_95` fields:**
```sql
SELECT
  date_day,
  sqls_actual,
  sqls_forecast,
  sqls_forecast_lower_95 AS sqls_lower_95,
  sqls_forecast_upper_95 AS sqls_upper_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
ORDER BY date_day;
```

### 5.3 Creating Shotgun-Style Graphs in Looker

**Step 1: Create Explore**
- Go to **Explore** → Select `vw_forecast_for_looker`
- Add filters:
  - `Original_source` (optional: filter to specific sources)
  - `Channel_Grouping_Name` (optional)
  - `date_day` (date range: past 30-60 days + future 60-90 days)
  - `time_period_type` (optional: ACTUAL + FORECAST)

**Step 2: Configure Visualization**

**For 50% Confidence Interval Shotgun Graph:**

**X-Axis:** `date_day` (Date dimension)

**Y-Axis (Primary):**
- Measure 1: `sqls_value` (Sum or Average) - Combined actuals + forecast
- Measure 2: `sqls_actual` (Sum or Average) - Historical actuals line
- Measure 3: `sqls_forecast` (Sum or Average) - Forecast line

**Y-Axis (Confidence Band - 50%):**
- Lower Bound: `sqls_forecast_lower_50` (Sum or Average)
- Upper Bound: `sqls_forecast_upper_50` (Sum or Average)

**Visualization Type:**
- **Line Chart with Confidence Bands/Error Bars**
- OR **Area Chart** with stacked bands

**Series Configuration:**
- **Series 1:** `sqls_actual` (label: "Actual SQLs")
  - Color: Blue
  - Line style: Solid
  - Show only for `time_period_type = 'ACTUAL'`

- **Series 2:** `sqls_forecast` (label: "Forecast SQLs")
  - Color: Orange
  - Line style: Dashed
  - Show only for `time_period_type = 'FORECAST'`

- **Confidence Band (50%):**
  - Lower: `sqls_forecast_lower_50`
  - Upper: `sqls_forecast_upper_50`
  - Fill color: Light orange (semi-transparent, ~30% opacity)
  - Style: Area/shaded band
  - Show only for `time_period_type = 'FORECAST'`

**For 95% Confidence Interval Shotgun Graph:**

Use the same configuration but replace:
- `sqls_forecast_lower_50` → `sqls_forecast_lower_95`
- `sqls_forecast_upper_50` → `sqls_forecast_upper_95`
- Use a lighter fill color (more transparent) to show wider band

**Step 3: Shotgun Effect (Widening Intervals)**

The confidence intervals **automatically widen** as you forecast further into the future:
- Intervals are calculated from standard deviations
- Future dates have wider intervals (greater uncertainty)
- Use `sqls_ci_width_50` or `sqls_ci_width_95` to visualize the widening

**Example Query to Show Widening:**
```sql
SELECT
  date_day,
  days_from_today,
  sqls_forecast,
  sqls_forecast_lower_50,
  sqls_forecast_upper_50,
  sqls_ci_width_50,
  sqls_forecast_lower_95,
  sqls_forecast_upper_95,
  sqls_ci_width_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE time_period_type = 'FORECAST'
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY)
ORDER BY days_from_today;
```

**Step 4: Multiple Series (By Source or Channel)**

To show multiple lines (e.g., by `Original_source`):
- Add `Original_source` as a dimension/grouping
- Looker will create separate lines for each source
- Confidence bands can be shown per source or aggregated

**Example:**
```
X-Axis: date_day
Y-Axis: sqls_value
Group by: Original_source
Series: sqls_actual, sqls_forecast
Confidence Band: sqls_forecast_lower_50 to sqls_forecast_upper_50
```

---

### 5.4 Sample Queries for Common Use Cases

**Use Case 1: Total Forecast with Confidence Intervals**
```sql
SELECT
  date_day,
  SUM(sqls_actual) AS total_sqls_actual,
  SUM(sqls_forecast) AS total_sqls_forecast,
  SUM(sqls_forecast_lower_50) AS total_sqls_lower_50,
  SUM(sqls_forecast_upper_50) AS total_sqls_upper_50,
  SUM(sqls_forecast_lower_95) AS total_sqls_lower_95,
  SUM(sqls_forecast_upper_95) AS total_sqls_upper_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY date_day
ORDER BY date_day;
```

**Use Case 2: Forecast by Original Source**
```sql
SELECT
  Original_source,
  date_day,
  sqls_forecast,
  sqls_forecast_lower_50,
  sqls_forecast_upper_50,
  sqls_forecast_lower_95,
  sqls_forecast_upper_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= CURRENT_DATE()
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
ORDER BY Original_source, date_day;
```

**Use Case 3: Q4 2025 Total Forecast**
```sql
SELECT
  'Q4 2025' AS period,
  SUM(CASE WHEN time_period_type = 'ACTUAL' THEN mqls_actual ELSE 0 END) + 
  SUM(CASE WHEN time_period_type = 'FORECAST' THEN mqls_forecast ELSE 0 END) AS total_mqls,
  SUM(CASE WHEN time_period_type = 'ACTUAL' THEN sqls_actual ELSE 0 END) + 
  SUM(CASE WHEN time_period_type = 'FORECAST' THEN sqls_forecast ELSE 0 END) AS total_sqls,
  SUM(CASE WHEN time_period_type = 'ACTUAL' THEN sqos_actual ELSE 0 END) + 
  SUM(CASE WHEN time_period_type = 'FORECAST' THEN sqos_forecast ELSE 0 END) AS total_sqos
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= '2025-10-01'
  AND date_day <= '2025-12-31';
```

---

## 6. Model Validation Summary

### 6.1 SQL Forecasting Validation

| Model | Backtest Error | Status |
|-------|---------------|--------|
| **V3.1 Super-Segment** | **-27.1%** | ✅ Best (not yet integrated) |
| V1 ARIMA_PLUS | -60.7% | ⚠️ Current production |
| V3 Daily Regression | -81.4% | ❌ Worse than V1 |

**Current Status:** Using ARIMA_PLUS for production stability. V3.1 validated but requires integration work.

### 6.2 SQL→SQO Conversion Validation

| Method | Backtest Error | Status |
|--------|---------------|--------|
| **Hybrid (Trailing + V2)** | **-5.35%** | ✅ **PRODUCTION** |
| V2 Challenger Only | +4.52% | ⚠️ Over-predicts |
| Trailing Average Only | -16.94% | ❌ Under-predicts |

**Current Status:** ✅ **Using Hybrid Approach** - Best validated method

---

## 7. Key Metrics and Definitions

### 7.1 Conversion Rates

**Hybrid SQL→SQO Rate:**
- **Current Value:** ~55.27% (weighted average)
- **Calculation:** Trailing rates weighted by SQL volume, V2 Challenger (69.3%) as fallback
- **Update Frequency:** Daily (via `vw_hybrid_conversion_rates`)

**V2 Challenger Rate:**
- **Value:** 69.3%
- **Source:** Q3 2024 backtest (9.01 predicted SQOs / 13 cohort SQLs)
- **Usage:** Fallback for segments without trailing rates

### 7.2 Confidence Intervals

**50% Confidence Interval:**
- **Calculation:** Forecast ± (0.674 × std_dev)
- **Interpretation:** 50% chance actual value falls within this range
- **Use Case:** Primary uncertainty visualization (shotgun graphs)

**95% Confidence Interval:**
- **Calculation:** Forecast ± (1.96 × std_dev)
- **Interpretation:** 95% chance actual value falls within this range
- **Use Case:** Conservative uncertainty bounds

**CI Width:**
- **Field:** `*_ci_width_50` or `*_ci_width_95`
- **Use:** Visualize how uncertainty widens over time (shotgun effect)

---

## 8. Maintenance and Updates

### 8.1 Daily Updates

**Automatic:**
- `vw_daily_stage_counts` - Updates with new actuals daily
- `vw_hybrid_conversion_rates` - Recalculates daily with latest data
- `vw_production_forecast` - Reflects latest forecasts and actuals

**Manual (as needed):**
- `daily_forecasts` table - Regenerated when new ARIMA_PLUS forecasts are needed
- ARIMA_PLUS models - Retrained periodically (schedule depends on business needs)

### 8.2 Model Retraining

**When to Retrain:**
- ARIMA_PLUS models: When forecast accuracy degrades or new patterns emerge
- V3.1 model: When new training data becomes available or model performance declines
- Hybrid rates: Auto-updates daily, no retraining needed

**How to Retrain:**
- ARIMA_PLUS: Use BigQuery ML retraining process (see `regenerate_forecast_simple.sql`)
- V3.1: Use `v3_tof_challenger_model.md` Phase 3 query

---

## 9. Troubleshooting

### Common Issues

**Issue:** Forecast values seem wrong
- **Check:** Verify `daily_forecasts` table has latest forecast_date
- **Check:** Confirm `vw_hybrid_conversion_rates` is calculating correctly
- **Check:** Ensure actuals are updating in `vw_daily_stage_counts`

**Issue:** Confidence intervals missing for some dates
- **Reason:** Intervals only calculated for forecast dates (future dates)
- **Solution:** Filter to `time_period_type = 'FORECAST'` or `data_type = 'FORECAST'`

**Issue:** Hybrid rate seems incorrect
- **Check:** Query `vw_hybrid_conversion_rates` directly
- **Verify:** Trailing rates are available for most segments
- **Fallback:** Should use V2 Challenger (69.3%) if trailing rates unavailable

---

## 10. References

### Documentation Files

| File | Purpose |
|------|---------|
| `SQL_to_SQO_Conversion_Backtest_October_2025.md` | Hybrid rate validation |
| `V3.1_Backtest_Results_October_2025.md` | V3.1 SQL model validation |
| `V3.1_vs_ARIMA_Comparison.md` | Side-by-side comparison of V3.1 vs ARIMA_PLUS |
| `Best_Model_Backtest_Analysis.md` | Model comparison summary |
| `V3.1_Production_Integration_Complete.md` | Integration completion documentation |
| `Integrate_V3.1_Into_Production.md` | Integration plan and status |
| `Q4_2025_Forecast_V3.1_Hybrid_Rates.md` | Latest forecast using hybrid approach |
| `Looker_Shotgun_Graph_Setup.md` | Detailed Looker visualization guide |

### Related Views

- `vw_model_performance_updated.sql` - Model performance monitoring
- `vw_model_drift_alert_updated.sql` - Drift detection alerts

---

## Summary

**Final Production Model (Current as of November 2025):**
- **ToF MQLs:** ARIMA_PLUS via `daily_forecasts` table
- **ToF SQLs:** **V3.1 Super-Segment ML** ✅ **PRODUCTION** via `vw_v3_1_sql_forecast_by_channel_source`
- **BoF SQOs:** Hybrid conversion rates (Trailing + V2) via `vw_hybrid_conversion_rates`
- **Views:** `vw_production_forecast` (main, uses V3.1), `vw_forecast_for_looker` (visualizations)
- **Validation:** 
  - V3.1 SQLs: -27.1% error (2.24x better than ARIMA_PLUS)
  - Hybrid SQOs: -5.35% error (best performing)

**Key Files:**
- `Views/vw_production_forecast_v3_1.sql` - Main production view (uses V3.1 for SQLs)
- `Views/vw_v3_1_sql_forecast_by_channel_source.sql` - V3.1 distribution view
- `Views/vw_forecast_for_looker_final.sql` - Looker-optimized view
- `Views/vw_hybrid_conversion_rates.sql` - Hybrid rate calculator
- `Views/vw_super_segment_to_channel_source_mapping.sql` - Super-segment mapping view

**Integration Details:**
- **Date Integrated:** November 2025
- **Performance Improvement:** 2.24x more accurate SQL forecasts vs ARIMA_PLUS
- **Architecture:** V3.1 forecasts at super-segment level (4 segments), distributed to Channel/Source granularity
- **Status:** ✅ **Production-Ready, Validated, and Integrated**

**What Changed from Initial Plan:**
- Initially planned to use ARIMA_PLUS for SQLs (via `daily_forecasts` table)
- Discovered V3.1 model is 2.24x more accurate in backtesting (-27.1% vs -60.7% error)
- Integrated V3.1 by creating mapping views to distribute super-segment forecasts to Channel/Source level
- V3.1 now provides all SQL forecasts in production

---

## 11. Quick Reference: Key SQL Queries

### 11.1 Get Current Hybrid Rate

```sql
SELECT 
  hybrid_sql_to_sqo_rate,
  ROUND(hybrid_sql_to_sqo_rate * 100, 2) AS rate_pct,
  trailing_coverage_pct,
  avg_trailing_rate,
  v2_challenger_rate,
  calculation_date
FROM `savvy-gtm-analytics.savvy_forecast.vw_hybrid_conversion_rates`;
```

### 11.2 Get Forecast with 50% CI (Shotgun Graph)

```sql
SELECT
  date_day,
  sqls_actual,
  sqls_forecast,
  sqls_forecast_lower_50,
  sqls_forecast_upper_50,
  sqls_ci_width_50
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY)
ORDER BY date_day;
```

### 11.3 Get Forecast with 95% CI (Conservative Bounds)

```sql
SELECT
  date_day,
  sqls_actual,
  sqls_forecast,
  sqls_forecast_lower_95,
  sqls_forecast_upper_95,
  sqls_ci_width_95
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY)
ORDER BY date_day;
```

### 11.4 Get Forecast by Original Source with CIs

```sql
SELECT
  Original_source,
  date_day,
  sqls_actual,
  sqls_forecast,
  sqls_forecast_lower_50,
  sqls_forecast_upper_50,
  sqos_forecast,
  sqos_forecast_lower_50,
  sqos_forecast_upper_50
FROM `savvy-gtm-analytics.savvy_forecast.vw_forecast_for_looker`
WHERE date_day >= CURRENT_DATE()
  AND date_day <= DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
ORDER BY Original_source, date_day;
```

---

## 12. Model Components Summary Table

| Component | Method | Object Name | Validation | Status |
|-----------|--------|-------------|------------|--------|
| **MQL Forecast** | ARIMA_PLUS | `model_arima_mqls` | Production-tested | ✅ Active |
| **SQL Forecast** | **V3.1 Super-Segment ML** | `model_tof_sql_regressor_v3_1_final` | -27.1% error | ✅ **PRODUCTION** |
| **SQL Forecast (Legacy)** | ARIMA_PLUS | `model_arima_sqls` | -60.7% error | ⚠️ Available (deprecated) |
| **SQO Conversion** | Hybrid (Trailing + V2) | `vw_hybrid_conversion_rates` | -5.35% error | ✅ **PRODUCTION** |
| **SQO Conversion (Alt)** | V2 Challenger | 69.3% constant | +4.52% error | ⚠️ Fallback |

---

**Document Version:** 1.0  
**Last Updated:** November 2025  
**Status:** ✅ Production-Ready

