# Q4 2025 Forecast: V3.1 + V2 Challenger

**Forecast Date:** Generated on execution  
**Forecast Period:** October 1 - December 31, 2025 (92 days)  
**Model Architecture:**
- **Top of Funnel (MQLs):** ARIMA_PLUS (`model_arima_mqls`)
- **Top of Funnel (SQLs):** V3.1 Super-Segment Model (`model_tof_sql_regressor_v3_1_final`)
- **Bottom of Funnel (SQL→SQO):** V2 Challenger Model (69.3% conversion rate)

---

## Executive Summary

This forecast combines the **best-performing models** from our backtesting:
- **V3.1 Super-Segment Model** for SQL forecasting (2.24x more accurate than V1)
- **V2 Challenger Model** for SQL→SQO conversion (validated 69.3% rate)
- **ARIMA_PLUS** for MQL forecasting (production-tested)

---

## Q4 2025 Total Forecast

| Metric | Forecast | Method |
|--------|----------|--------|
| **MQLs** | **794.9** | ARIMA_PLUS (282 actual + 512.9 forecast) |
| **SQLs** | **179.6** | V3.1 Super-Segment ML |
| **SQOs** | **124.4** | SQLs × 69.3% (V2 Challenger) |

**SQL→SQO Conversion Rate:** 69.3% (V2 Challenger validated rate)

**Note:** MQLs include actuals through current date (282) plus forecast (512.9)

---

## Monthly Breakdown

| Month | MQLs | SQLs | SQOs |
|-------|------|------|------|
| **October 2025** | 282.0 | 61.0 | 42.3 |
| **November 2025** | 236.9 | 58.1 | 40.3 |
| **December 2025** | 276.0 | 60.4 | 41.9 |
| **Q4 Total** | **794.9** | **179.6** | **124.4** |

---

## Model Details

### Top of Funnel (MQLs)
- **Model:** ARIMA_PLUS (`model_arima_mqls`)
- **Source:** `vw_production_forecast` view
- **Status:** Production-tested, validated

### Top of Funnel (SQLs)
- **Model:** V3.1 Super-Segment ML (`model_tof_sql_regressor_v3_1_final`)
- **Training Data:** `tof_v3_1_daily_training_data`
- **Segments:** 4 super-segments (Outbound, Inbound_Marketing, Partnerships_Referrals, Other)
- **Backtest Performance:** -27.1% error (2.24x better than V1)
- **Status:** ✅ Best performing model based on backtesting

### Bottom of Funnel (SQL→SQO)
- **Model:** V2 Challenger (`model_sql_sqo_propensity_v2`)
- **Conversion Rate:** 69.3% (validated from Q3 2024 backtest)
- **Calculation:** SQLs × 69.3%
- **Status:** Production-ready, validated

---

## Notes

- MQLs include both actuals (through current date) and forecasts (future dates)
- SQLs are 100% forecasted using V3.1 model
- SQOs are calculated by applying V2 Challenger conversion rate to SQL forecast
- All forecasts are for Q4 2025 (Oct 1 - Dec 31, 2025)

---

---

## Key Insights

### Forecast Totals
- **MQLs:** 794.9 total (282 actual + 512.9 forecast)
- **SQLs:** 179.6 total (all forecasted)
- **SQOs:** 124.4 total (calculated from SQLs)

### Monthly Trends
- **October:** Highest SQLs (61.0) - includes actuals through current date
- **November:** Lowest SQLs (58.1) - fully forecasted
- **December:** Similar to October (60.4) - fully forecasted

### Conversion Rates
- **MQL→SQL:** ~22.6% (179.6 SQLs / 794.9 MQLs) - overall funnel
- **SQL→SQO:** 69.3% (124.4 SQOs / 179.6 SQLs) - V2 Challenger rate

### Comparison to Previous Forecasts

| Forecast Method | MQLs | SQLs | SQOs |
|-----------------|------|------|------|
| **V3.1 + V2 Challenger** | **794.9** | **179.6** | **124.4** |
| V1 + V2 Challenger (Live Rates) | 794.9 | ~226.9 | ~139.6 |
| V1 + V2 Challenger (Trailing) | 794.9 | ~226.9 | ~124.7 |

**Key Differences:**
- V3.1 forecasts **47.3 fewer SQLs** than V1 ARIMA_PLUS (179.6 vs 226.9)
- V3.1 + V2 Challenger forecasts **15.2 fewer SQOs** than V1 + Live Rates (124.4 vs 139.6)
- V3.1 + V2 Challenger forecasts **0.3 fewer SQOs** than V1 + Trailing (124.4 vs 124.7)

---

**Report Status:** ✅ Complete - Q4 2025 Forecast Generated

