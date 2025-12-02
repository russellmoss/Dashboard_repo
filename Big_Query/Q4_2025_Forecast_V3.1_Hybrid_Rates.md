# Q4 2025 Forecast: V3.1 + Hybrid Conversion Rates (Trailing + V2)

**Forecast Date:** Generated on execution  
**Forecast Period:** October 1 - December 31, 2025 (92 days)  
**Model Architecture:**
- **Top of Funnel (MQLs):** ARIMA_PLUS (`model_arima_mqls`)
- **Top of Funnel (SQLs):** V3.1 Super-Segment Model (`model_tof_sql_regressor_v3_1_final`)
- **Bottom of Funnel (SQL→SQO):** **Hybrid Approach** - Trailing rates (segment-specific) weighted by SQL volume, with V2 Challenger (69.3%) as fallback

---

## Executive Summary

This forecast uses a **hybrid conversion rate approach** that combines:
- **Trailing rates** (segment-specific historical rates) where available, weighted by actual SQL volume
- **V2 Challenger rate** (69.3%) as fallback for segments without trailing rates
- More accurate to reality by reflecting actual segment performance patterns

---

## Q4 2025 Total Forecast

| Metric | Forecast | Method |
|--------|----------|--------|
| **MQLs** | **794.9** | ARIMA_PLUS (282 actual + 512.9 forecast) |
| **SQLs** | **179.6** | V3.1 Super-Segment ML |
| **SQOs** | **99.3** | SQLs × 55.27% (Hybrid Rate) |

**Conversion Method:** Hybrid (Trailing Rates weighted by volume + V2 Challenger fallback)  
**Hybrid Conversion Rate:** **55.27%** (weighted average of trailing rates, 100% coverage)

---

## Monthly Breakdown

| Month | MQLs | SQLs | SQOs | Conversion Rate |
|-------|------|------|------|-----------------|
| **October 2025** | 282.0 | 61.0 | 33.7 | 55.27% |
| **November 2025** | 236.9 | 58.1 | 32.1 | 55.27% |
| **December 2025** | 276.0 | 60.4 | 33.4 | 55.27% |
| **Q4 Total** | **794.9** | **179.6** | **99.3** | **55.27%** |

---

## Hybrid Conversion Rate Details

**Approach:**
- Uses trailing rates for segments where historical data exists (weighted by SQL volume)
- Falls back to V2 Challenger rate (69.3%) for segments without trailing rates
- More accurate than pure V2 Challenger as it reflects actual segment performance

**Rate Components:**
- Average Trailing Rate: 54.93% (unweighted average across segments)
- V2 Challenger Rate: 69.3% (fallback rate)
- **Hybrid Rate: 55.27%** (trailing rates weighted by SQL volume, 100% coverage)

**Coverage:** 100% of SQLs have trailing rates available (no V2 fallback needed)

---

## Comparison: Hybrid vs V2 Challenger Only

| Conversion Method | SQLs | SQOs | Conversion Rate | Difference |
|-------------------|------|------|-----------------|------------|
| **Hybrid (Trailing + V2)** | 179.6 | **99.3** | **55.27%** | Baseline |
| **V2 Challenger Only** | 179.6 | 124.4 | 69.3% | **+25.1 SQOs** |

**Key Insight:**
- Hybrid rate (55.27%) is **closer to trailing rate average** (54.93%) than V2 Challenger (69.3%)
- Hybrid approach results in **25.1 fewer SQOs** (99.3 vs 124.4)
- More conservative and **more accurate to historical reality** by using segment-specific rates

---

## Key Insights

### Forecast Totals
- **MQLs:** 794.9 total (282 actual + 512.9 forecast)
- **SQLs:** 179.6 total (all forecasted by V3.1)
- **SQOs:** 99.3 total (using hybrid conversion rate)

### Conversion Analysis
- **Hybrid Rate (55.27%):** Weighted average of segment-specific trailing rates
- **More accurate than V2 Challenger:** Reflects actual segment performance patterns
- **100% coverage:** All SQLs mapped to segments with trailing rates
- **Conservative forecast:** Lower than V2 Challenger, closer to historical averages

### Monthly Trends
- **October:** Highest SQLs (61.0) and SQOs (33.7) - includes actuals
- **November:** Lowest SQLs (58.1) and SQOs (32.1) - fully forecasted
- **December:** Similar to October (60.4 SQLs, 33.4 SQOs) - fully forecasted

---

## Recommendation

**✅ Use Hybrid Approach** - More accurate to reality:
- Uses segment-specific historical rates (trailing rates)
- Weighted by actual SQL volume distribution
- Results in more conservative (realistic) SQO forecast (99.3 vs 124.4)
- Better reflects actual business performance patterns

---

**Report Status:** ✅ Complete - Q4 2025 Forecast Generated with Hybrid Rates

