# Forecast Data Flow

Yes, `vw_actual_vs_forecast_by_source.sql` still gets its forecast data from `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`, but it goes through an intermediate view.

## Data Flow Chain

```
┌─────────────────────────────────────────────────────────────┐
│ Source Table: q4_2025_forecast                             │
│ savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast         │
│ (Monthly forecast data by channel, source, stage)          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Intermediate View: vw_daily_forecast                       │
│ savvy-gtm-analytics.savvy_analytics.vw_daily_forecast     │
│ (Converts monthly forecasts to daily rates)                │
│                                                             │
│ - Divides monthly totals by days in month                  │
│ - Creates daily forecast rows for Q4 2025                   │
│ - Line 33: FROM q4_2025_forecast                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Final View: vw_actual_vs_forecast_by_source               │
│ savvy-gtm-analytics.savvy_analytics.vw_actual_vs_forecast │
│ (Combines actuals + forecasts with fallback)               │
│                                                             │
│ - Line 98: FROM vw_daily_forecast                          │
│ - Joins actuals to forecasts                               │
│ - Uses actuals as forecast fallback when forecast is NULL  │
└─────────────────────────────────────────────────────────────┘
```

## What Changed vs. What Stayed the Same

### ✅ What Stayed the Same
- Forecast data still comes from `q4_2025_forecast` table
- `vw_daily_forecast` still only has Q4 2025 data (Oct-Dec)
- The monthly-to-daily conversion logic is unchanged

### 🔧 What Changed
- **Before**: `vw_actual_vs_forecast_by_source` filtered out non-Q4 actuals at the source
- **After**: `vw_actual_vs_forecast_by_source` keeps ALL actuals regardless of date
- **New**: When forecast is NULL (any date outside Q4), actuals are used as the forecast

## The Elegant Fallback Pattern

```sql
-- In vw_actual_vs_forecast_by_source.sql line 115-118
COALESCE(forecast.sql_forecast, a.sql_actual) AS sql_forecast
```

This means:
- **Q4 2025 dates**: Use real forecast from `q4_2025_forecast` → `vw_daily_forecast` → view
- **Other dates**: No forecast available, so use actuals as fallback

## Why This Works

`vw_daily_forecast` is still hardcoded to Q4 2025 (line 10: `GENERATE_DATE_ARRAY('2025-10-01', '2025-12-31')`), but that's fine because:
1. It provides the real Q4 forecasts
2. `vw_actual_vs_forecast_by_source` uses a LEFT JOIN, so missing forecasts become NULL
3. The COALESCE fallback handles NULLs gracefully

The fix was in `vw_actual_vs_forecast_by_source`, not in changing the forecast source!

