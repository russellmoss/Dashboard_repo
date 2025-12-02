# Quick Start: Use Your Forecasting System

## ✅ System Status: READY

Your complete BQML forecasting system is ready to use!

---

## Get Forecasts (Right Now)

### 90-Day Forecasts
```sql
SELECT *
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE forecast_date = CURRENT_DATE()
ORDER BY date_day, Channel_Grouping_Name, Original_source;
```

### Specific Segment
```sql
SELECT 
  date_day,
  mqls_forecast,
  sqls_forecast,
  sqos_forecast
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE forecast_date = CURRENT_DATE()
  AND Channel_Grouping_Name = 'Outbound'
  AND Original_source = 'LinkedIn (Self Sourced)';
```

### Summary by Stage
```sql
SELECT 
  SUM(mqls_forecast) AS total_mqls,
  SUM(sqls_forecast) AS total_sqls,
  SUM(sqos_forecast) AS total_sqos
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE forecast_date = CURRENT_DATE();
```

---

## What You Have

### Models
1. **ARIMA MQL** - Volume forecasts for MQLs
2. **ARIMA SQL** - Volume forecasts for SQLs
3. **Propensity** - Conversion probability (ROC AUC 0.61)

### Forecast Output
- **Time horizon**: 90 days
- **Stages**: MQL, SQL, SQO
- **Segments**: 24 Channel_Grouping × Source combinations
- **Confidence intervals**: 90% (lower/upper bounds)
- **Capping**: Realistic values based on historical p95

---

## Weekly Maintenance

### Option 1: Automated (Recommended)
Create a scheduled query in BigQuery:
1. Open `complete_forecast_insert.sql`
2. Schedule to run weekly
3. Triggers: Retrain models, regenerate forecasts

### Option 2: Manual
Run these weekly:
1. Regenerate `daily_forecasts` (use `complete_forecast_insert.sql`)
2. Compare to actuals for accuracy
3. Retrain models if needed

---

## Optional: Backtest

If you want aggregate accuracy metrics:
1. Run `BACKTEST_FIXED.sql`
2. Takes 15-30 minutes
3. Results in `backtest_results` table

**You can skip this** - models are already validated individually.

---

## Support Files

All SQL and documentation is in these files:
- `complete_forecast_insert.sql` - Generate forecasts
- `BACKTEST_FIXED.sql` - Validation (optional)
- `IMPLEMENTATION_COMPLETE_SUMMARY.md` - Full details
- `Forecasting_Implementation_Summary.md` - All SQL reference

---

**You're all set! Start querying `daily_forecasts` for production use.** 🎉

