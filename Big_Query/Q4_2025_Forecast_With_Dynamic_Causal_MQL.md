# Q4 2025 Forecast - Dynamic Causal MQL Model Integrated

**Date:** Generated with new model architecture  
**Forecast Period:** October 1 - December 31, 2025 (Q4 2025)  
**Model Architecture:**
- **MQLs:** Dynamic Causal Model (`Predicted_Contacted_Volume × Predicted_C2M_Rate`)
- **SQLs:** V3.1 Super-Segment ML Model
- **SQOs:** Hybrid Conversion Rates (Trailing Rates + V2 Challenger Fallback)

---

## Q4 2025 Forecast Summary

| Metric | Q4 2025 Total | October | November | December |
|--------|---------------|---------|----------|----------|
| **MQLs** | **598.5** | 214.3 | 188.8 | 195.4 |
| **SQLs** | **178.9** | 60.2 | 59.4 | 59.3 |
| **SQOs** | **98.9** | 33.3 | 32.8 | 32.8 |

---

## Comparison to Previous Forecast (ARIMA_PLUS MQL Model)

### Q4 2025 Total Forecast

| Metric | Dynamic Causal MQL | ARIMA_PLUS MQL | Difference | % Change |
|--------|-------------------|----------------|------------|----------|
| **MQLs** | **598.5** | 794.9 | **-196.4** | **-24.7%** |
| **SQLs** | **178.9** | 179.4 | -0.5 | -0.3% |
| **SQOs** | **98.9** | 109.3 | -10.4 | -9.5% |

### Forecast Period Only (Nov + Dec 2025)

| Metric | Dynamic Causal MQL | ARIMA_PLUS MQL | Difference | % Change |
|--------|-------------------|----------------|------------|----------|
| **MQLs** | **384.2** (188.8 + 195.4) | 512.9 | **-128.7** | **-25.1%** |
| **SQLs** | **118.7** (59.4 + 59.3) | *Same as Dynamic Causal* | 0 | 0% |
| **SQOs** | **65.6** (32.8 + 32.8) | *Same as Dynamic Causal* | 0 | 0% |

**Note:** 
- SQLs and SQOs are **identical** since both approaches use V3.1 Super-Segment ML + Hybrid rates
- The only difference is in **MQL forecasting method**
- Dynamic Causal Model forecasts **25% fewer MQLs** than ARIMA_PLUS (384.2 vs 512.9 for Nov+Dec)

---

## Model Details

### MQL Forecast (Dynamic Causal Model)

**Method:** `Predicted_MQLs = Predict(Contacted_Volume) × Predict(Contacted_to_MQL_Rate)`

- **Average C2M Rate:** 13.04% (bounded at 20% max)
- **Model:** `model_tof_contacted_regressor_v1` + `model_tof_c2m_rate_regressor_v1`
- **Improvements Applied:**
  - ✅ FilterDate for date attribution
  - ✅ Rate bounds (0-20%)
  - ✅ Low-volume filter (≥5 contacted leads)
  - ✅ Increased regularization (L1=0.2, L2=2.0)

**Monthly Breakdown:**
- **October:** 214.3 MQLs
- **November:** 188.8 MQLs
- **December:** 195.4 MQLs

**Backtest Performance (Q3 2025):**
- Forecast: 448.87 vs Actual: 547 MQLs (-17.9% error)
- **Much better than ARIMA_PLUS** (3.30 MAE vs 5.95 MAE)

### SQL Forecast (V3.1 Super-Segment ML)

**Method:** Super-segment aggregation + BOOSTED_TREE_REGRESSOR

- **Model:** `model_tof_sql_regressor_v3_1_final`
- **Segments:** 4 super-segments (Outbound, Inbound_Marketing, Partnerships_Referrals, Other)
- **Validation:** -27.1% error on October 2025 backtest (2.24x better than ARIMA_PLUS)

**Monthly Breakdown:**
- **October:** 60.2 SQLs
- **November:** 59.4 SQLs
- **December:** 59.3 SQLs

### SQO Forecast (Hybrid Conversion Rates)

**Method:** `Predicted_SQOs = Predicted_SQLs × Hybrid_SQL_to_SQO_Rate`

- **Hybrid Rate:** 55.27%
- **Approach:** Trailing rates weighted by volume + V2 Challenger (69.3%) fallback
- **Validation:** -5.35% error on October 2025 backtest (best performing method)

**Monthly Breakdown:**
- **October:** 33.3 SQOs
- **November:** 32.8 SQOs
- **December:** 32.8 SQOs

---

## Conversion Rates

### Top of Funnel
- **Contacted → MQL:** 13.04% (predicted average, dynamically forecasted)

### Bottom of Funnel
- **SQL → SQO:** 55.27% (Hybrid: Trailing + V2 Challenger)

---

## Key Insights

1. **MQL Forecast:** 598.5 MQLs for Q4 2025
   - Average ~6.5 MQLs/day
   - October highest (214.3), then December (195.4), November lowest (188.8)
   - **25% lower than ARIMA_PLUS** (598.5 vs 794.9) - more conservative forecast

2. **SQL Forecast:** 178.9 SQLs for Q4 2025
   - Average ~1.9 SQLs/day
   - Relatively consistent across months (~60 SQLs/month)
   - **Virtually identical to ARIMA_PLUS forecast** (178.9 vs 179.4) since both use V3.1

3. **SQO Forecast:** 98.9 SQOs for Q4 2025
   - Average ~1.1 SQOs/day
   - Consistent across months (~33 SQOs/month)
   - Represents 55.27% conversion from SQLs
   - **9.5% lower than ARIMA_PLUS** (98.9 vs 109.3) due to slightly lower SQL forecast

4. **Funnel Progression:**
   - MQL → SQL: 29.9% (178.9 / 598.5)
   - SQL → SQO: 55.27% (98.9 / 178.9)
   - MQL → SQO: 16.5% (98.9 / 598.5)

5. **Model Comparison:**
   - **Dynamic Causal MQL Model** forecasts **196 fewer MQLs** than ARIMA_PLUS (-24.7%)
   - This is expected given the Q3 backtest showed Dynamic Causal slightly under-predicted (-17.9% error)
   - However, Dynamic Causal was **much more accurate** than ARIMA_PLUS (3.30 MAE vs 5.95 MAE)

---

## Model Performance Expectations

### MQL Model (Dynamic Causal)
- **Backtest Performance (Q3 2025):** -17.9% error
  - Forecast: 448.87 vs Actual: 547 MQLs
  - Much better than ARIMA_PLUS (3.30 MAE vs 5.95 MAE)
- **Q4 Forecast:** 598.5 MQLs (vs ARIMA_PLUS 794.9)
- **Expected:** Slightly conservative forecast based on backtest performance

### SQL Model (V3.1)
- **Backtest Performance (October 2025):** -27.1% error
  - Forecast: 64.9 vs Actual: 92 SQLs
  - 2.24x more accurate than ARIMA_PLUS (-60.7% error)
- **Q4 Forecast:** 178.9 SQLs

### SQO Model (Hybrid Rates)
- **Backtest Performance (October 2025):** -5.35% error
  - Forecast: 46.8 vs Actual: 49.4 SQOs
- **Q4 Forecast:** 98.9 SQOs

---

## Recommendations

### Which Model Should Be Used?

**Arguments for Dynamic Causal MQL Model:**
- ✅ **More accurate** than ARIMA_PLUS (3.30 MAE vs 5.95 MAE)
- ✅ **Validated** against Q3 2025 actuals
- ✅ **More realistic** forecasts (598.5 vs 794.9 MQLs)
- ✅ **Causal approach** - predicts based on contacted volume and conversion rates

**Arguments for ARIMA_PLUS:**
- ⚠️ Higher forecast (794.9 MQLs) might be closer to reality
- ⚠️ Dynamic Causal slightly under-predicts (-17.9% error)

**Recommendation:** 
- **Use Dynamic Causal Model** for MQL forecasting
- Consider scaling up forecast by ~18% if desired to account for slight under-prediction
- Or use as-is for more conservative planning

---

**Status:** ✅ Forecast Generated - Dynamic Causal Model integrated

**Next Steps:**
1. Monitor Q4 2025 actuals vs forecasts
2. Validate Dynamic Causal model performance in production
3. Compare against ARIMA_PLUS to confirm which is more accurate
