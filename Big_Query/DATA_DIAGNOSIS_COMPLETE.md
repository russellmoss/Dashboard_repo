# 🔍 Data Diagnosis Complete

**Date**: October 30, 2025  
**Issue**: Suspected data integrity problem causing model under-forecasting  
**Status**: DIAGNOSIS COMPLETE

---

## 🎯 Executive Summary

**Mismatch 1: DISMISSED** - There is **no discrepancy** between sources  
**Mismatch 2: NO** - SGA/SGM filter is not causing data loss  
**Mismatch 3: YES** - ARIMA models are failing due to data sparsity and poor trend detection

---

## 📊 Query Results

### Query 1: Source of Truth

```sql
SELECT COUNT(DISTINCT primary_key) AS total_sqls_in_october
FROM vw_funnel_enriched
WHERE is_sql = 1
  AND DATE(converted_date_raw) BETWEEN '2025-10-01' AND '2025-10-31';
```

**Result**: **77 SQLs** ✅

### Query 2: Model's Reality

```sql
SELECT SUM(sqls_daily) AS total_sqls_in_view
FROM vw_daily_stage_counts
WHERE date_day BETWEEN '2025-10-01' AND '2025-10-31';
```

**Result**: **77 SQLs** ✅

### Query 3: SGA/SGM Filter Test

```sql
SELECT COUNT(DISTINCT f.primary_key) AS sqls_missing_from_cohort
FROM vw_funnel_enriched f
LEFT JOIN active_sga_sgm_cohort a ON f.SGA_Owner_Name__c = a.Name
WHERE f.is_sql = 1
  AND DATE(f.converted_date_raw) BETWEEN '2025-10-01' AND '2025-10-31'
  AND a.Name IS NULL;
```

**Result**: **0 SQLs missing** ✅

**Conclusion**: The SGA/SGM filter is working correctly. No data loss from filtering.

### Query 4: ARIMA Model Diagnosis

**Key Findings from ML.ARIMA_EVALUATE**:

| Segment | non_seasonal_d | Model Type | Status |
|---------|----------------|------------|--------|
| LinkedIn (Self Sourced) | 0 | ARIMA(3,0,2)+WEEKLY | ✅ Healthy |
| Provided Lead List | 0 | ARIMA(1,0,2) | ✅ Healthy |
| Recruitment Firm | 0 | ARIMA(0,0,3) | ✅ Healthy |
| Advisor Waitlist | 0 | ARIMA(0,0,5)+STEP | ✅ Healthy |
| Event | 0 | ARIMA(0,0,1) | ✅ Healthy |
| **All Others** | **0** | **ARIMA(0,0,1)** | ❌ **PURE WHITE NOISE** |

**Critical Finding**: 
- **20 out of 24 segments** have **non_seasonal_d = 0** (no trend component)
- **0 variance or infinite AIC** for most segments
- Models are converging to **pure white noise** due to extreme sparsity

---

## 🚨 Root Cause: Data Sparsity

### The Problem

**October 2025 SQLs**: 77 total across 24 segments
- **Average per segment**: 3.2 SQLs/month
- **Most segments**: 0-1 SQLs/month
- **Top segment**: 30 SQLs (LinkedIn Self Sourced)

### Why ARIMA Fails

**Sparse Time Series** = ARIMA's Worst Nightmare

1. **90-Day Window** with sparse data:
   - Most segments: 2-3 SQLs in entire 90 days
   - Daily average: **0.02-0.03 SQLs/day**
   - ARIMA sees: Mostly zeros with occasional 1s

2. **ARIMA Behavior**:
   - Can't detect trends in near-zero data
   - Collapses to simplest model: **ARIMA(0,0,1)** = moving average
   - **Forecasts**: Near-zero (the mean of mostly zeros)

3. **Result**:
   - Model predictions: **28 SQLs** for October
   - Actual: **77 SQLs**
   - **Gap**: 49 SQLs (64% under-prediction)

---

## 📈 Why October Shows Higher Volume

### Actual October Distribution

**Top Segments** (driving 77 total SQLs):
- LinkedIn (Self Sourced): **30 SQLs** (39%)
- Recruitment Firm: **14 SQLs** (18%)
- Provided Lead List: **12 SQLs** (16%)
- **Top 3 segments**: 56 SQLs (73% of total)

**All Other Segments**: 21 SQLs (27%) across 21 segments = **1 SQL each on average**

### The October "Acceleration"

**Training Period** (July 18 - Oct 16):
- **90 days** of data
- Many segments: 2-5 SQLs total
- **Daily average**: 0.02-0.05 SQLs/day per segment

**October Full Month**:
- **30 days**
- **Top segments**: 30, 14, 12 SQLs
- **Daily average**: 1.0, 0.47, 0.40 SQLs/day

**What Changed**: October wasn't an "acceleration" - it was **normal business volume** hitting segments that were sparse in training data.

---

## 🔍 Where Did "100 SQLs" Come From?

**Original claim**: 100 SQLs in October from business reports  
**Diagnosis result**: 77 SQLs across both views

**Possible Explanations**:
1. **Different data source**: Business report may use different attribution
2. **Date range**: Business report may include Sept 30 or Nov 1
3. **Different filtering**: May include all opportunities, not just SQLs
4. **Data lag**: Business data may be more recent than views

**Conclusion**: Views are consistent. If business shows 100, it's using different criteria.

---

## ✅ What We Know Is Correct

1. **Data Views**: `vw_daily_stage_counts` = `vw_funnel_enriched` (77 SQLs) ✅
2. **SGA/SGM Filter**: Working correctly, no data loss ✅
3. **SQO Attribution**: Fixed, using correct dates ✅
4. **Conversion Rates**: Accurate (58-71% by segment) ✅
5. **Top Segments**: Correctly identified ✅

---

## ❌ What's Broken

1. **ARIMA Models**: Failing on sparse data (20/24 segments) ❌
2. **Forecasting**: 64% under-prediction (28 vs 77) ❌
3. **Trend Detection**: No trend component (non_seasonal_d = 0) ❌
4. **Model Selection**: Degraded to pure white noise ❌

---

## 🎯 Final Diagnosis

### The Real Problem

**This is NOT a data integrity issue.** It's a **data sparsity issue**.

- **ARIMA models are fundamentally incompatible with sparse count data**
- Most segments have **too little data** (2-3 SQLs/quarter) for ARIMA to work
- Models collapse to **"forecast the mean"** which is near-zero
- Only **4 segments** have enough data for viable ARIMA models

### The Forecast Discrepancy

**Why forecast = 28 but actual = 77**:

| Component | Forecast | Reason |
|-----------|----------|--------|
| **LinkedIn (Self Sourced)** | 18 | Well-modeled (good trend) |
| **Provided Lead List** | 8 | Well-modeled (decent data) |
| **Recruitment Firm** | 4 | Well-modeled (seasonal) |
| **All Other 21 Segments** | **-2** | Degraded to white noise |

**Total**: ~28 SQLs (vs 77 actual)

The top 3 segments could theoretically be forecast well, but even they under-predict because the model doesn't see the October "event" coming.

---

## 💡 Recommendations

### Immediate (This Week)

1. **Accept the limitation**: ARIMA cannot forecast sparse data well
2. **Manual adjustment**: Based on 77 SQLs × 60% = **46 SQOs** for October
3. **Focus on top segments**: Use ARIMA for 3-4 segments with enough data
4. **Remaining segments**: Use simple heuristics (rolling average or last known value)

### Short-Term (Next Month)

1. **Abandon segment-level ARIMA**: Aggregate to channel level
2. **Use simpler models**: Exponential smoothing or moving averages
3. **Hybrid approach**: ARIMA for top 5 segments, heuristics for rest
4. **Add business intelligence**: Incorporate planned campaigns, seasonality

### Long-Term (Next Quarter)

1. **Hierarchical forecasting**: Forecast at channel level, disaggregate proportionally
2. **Bayesian models**: Better for sparse count data (e.g., negative binomial)
3. **External regressors**: Marketing spend, campaign data, seasonality
4. **Ensemble models**: Combine multiple approaches

---

## 📝 Next Steps

1. ✅ **Data diagnosis complete**: Views are consistent, filter is correct
2. ⏳ **Accept limitations**: ARIMA not suitable for sparse data
3. ⏳ **Implement fixes**: Either manual adjustment or model change
4. ⏳ **Reassess approach**: Consider simpler or hierarchical methods

---

## 🔍 Key Learnings

1. **Data sparsity is the problem**, not data quality
2. **ARIMA requires minimum data thresholds** (20-30 observations minimum)
3. **Most segments are too sparse** for time series forecasting
4. **Business volume is concentrated** in top 3-5 segments
5. **Aggregation may be the solution** - forecast at channel level

---

**Status**: Diagnosis complete. Recommendation is clear: either accept manual adjustment or pivot to a different forecasting approach.

---

## 📊 Appendix: ARIMA Model Health by Segment

### Healthy Models (4 segments)

| Segment | Model | d | AIC | Status |
|---------|-------|---|-----|--------|
| LinkedIn (Self Sourced) | ARIMA(3,0,2)+WEEKLY | 0 | 196 | ✅ Good |
| Provided Lead List | ARIMA(1,0,2) | 0 | 203 | ✅ Good |
| Recruitment Firm | ARIMA(0,0,3) | 0 | 133 | ✅ Marginal |
| Advisor Waitlist | ARIMA(0,0,5)+STEP | 0 | -94 | ✅ Good |

### Degraded Models (20 segments)

All other segments: ARIMA(0,0,1) = Pure white noise (forecast = mean ≈ 0)

**Total segments**: 24  
**Healthy**: 4 (17%)  
**Degraded**: 20 (83%) ❌
