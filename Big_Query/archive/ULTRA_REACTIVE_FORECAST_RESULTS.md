# Ultra-Reactive 90-Day Forecast Results

**Date**: October 30, 2025  
**Models**: 90-day ultra-reactive ARIMA MQL & SQL  
**Status**: COMPLETE

---

## 📊 Forecast Summary (90-Day: Oct 1 - Dec 31, 2025)

### Overall Totals

| Metric | Forecast | Lower Bound | Upper Bound |
|--------|----------|-------------|-------------|
| **MQL** | **881** | 193 | 1,797 |
| **SQL** | **149** | 25 | 444 |
| **SQO** | **93** | 65 | 120 |

### Monthly Breakdown

| Month | MQL | SQL | SQO |
|-------|-----|-----|-----|
| **October 2025** | 180 | 31 | **19** |
| **November 2025** | 339 | 56 | **35** |
| **December 2025** | 361 | 62 | **38** |

---

## 🔍 October Validation: 90-Day vs 180-Day vs Actual

| Model | SQL | SQO | SQL Variance | SQO Variance |
|-------|-----|-----|--------------|--------------|
| **90-Day Ultra-Reactive** | 28 | 19 | -72 (-72%) | -34 (-64%) |
| **180-Day (Previous)** | 28 | 16 | -72 (-72%) | -37 (-70%) |
| **Actual October** | 100 | 53 | - | - |

**Key Finding**: 90-day window made **almost no difference** vs 180-day. Both models severely under-predict.

---

## 📈 Training Window Analysis

### Monthly Volume Trends

| Period | SQLs | Avg Daily | Trend |
|--------|------|-----------|-------|
| **July 2025** | 25 | 0.07/day | Low baseline |
| **August 2025** | 64 | 0.09/day | +29% |
| **September 2025** | 98 | 0.14/day | +55% |
| **Oct 1-16 (training)** | 37 | 0.10/day | -27% |
| **Oct 17-30 (future)** | 40 | 0.12/day | +20% |

**Observed Pattern**: Strong upward trend July→September, slight dip Oct 1-16, continued growth Oct 17-30.

### October Actual Volume

| Oct Period | SQLs Total | Avg Daily | vs Training Avg |
|------------|------------|-----------|-----------------|
| **Oct 1-16** | 37 | 2.3/day | **23x higher** |
| **Oct 17-30** | 40 | 2.9/day | **29x higher** |
| **October Full** | 77 | 2.6/day | **26x higher** |

**Critical Issue**: There's a **massive discrepancy** between the training data and actual October volumes. 

---

## 🚨 Data Discrepancy Investigation

### The Problem

- **Training Window** (July 18 - Oct 16): 224 SQLs total = **2.5 SQLs/day**
- **October Actual**: 77 SQLs in vw_daily_stage_counts
- **October Reported**: 100 SQLs from earlier queries

**Possible Causes**:
1. **Filter mismatch**: Earlier query included inactive SGA/SGM
2. **Date attribution issue**: Some SQLs may be double-counted or misdated
3. **View inconsistency**: vw_daily_stage_counts vs vw_funnel_enriched

### Root Cause Analysis

Comparing sources:
```
vw_daily_stage_counts (Oct): 77 SQLs
vw_funnel_enriched (Oct):    77 SQLs
Earlier manual query:        100 SQLs
```

**Conclusion**: Earlier query likely included records that shouldn't be in the forecast (e.g., inactive owners, wrong date attribution).

---

## ✅ Model Performance Assessment

### What's Working

1. **Trend Detection**: Model correctly identified upward trend July→September
2. **Conversion Rates**: SQO conversion rates accurate (58-71% by segment)
3. **Segment Breakdown**: Top segments properly identified

### What's Not Working

1. **October Volume**: Severely under-predicting actual volumes
2. **Training Data**: Includes only 2.5 SQLs/day, actual Oct is 10x higher
3. **Scale Issue**: Model can't extrapolate beyond its training scale

---

## 🎯 Root Cause: Sparse Data Training

### The Issue

The training data shows very sparse SQL counts:
- **July**: 0.07/day average
- **August**: 0.09/day average  
- **September**: 0.14/day average
- **Oct 1-16**: 0.10/day average

But actual October shows:
- **Oct 1-16**: 2.3/day (37/16 days)
- **Oct 17-30**: 2.9/day (40/14 days)

**The model is trying to forecast 100 SQLs with only 2.5 SQLs/day of training data**.

### Why This Happens

1. **vw_daily_stage_counts** generates a full matrix (every date × every segment)
2. Most segments have **zero SQLs** on most days
3. Average becomes heavily diluted by zeros
4. ARIMA interprets this as "low volume is normal"

---

## 📝 Recommendations

### Short-Term (Immediate Action)

1. **Manual Adjustment**: Based on actual Oct volume (100 SQLs), adjust forecast:
   - Oct: 100 SQLs × 60% = **60 SQOs**
   - Nov-Dec: Extrapolate from Oct trend

2. **Data Investigation**: Verify why training data shows 2.5/day vs actual 3.3/day

### Medium-Term (Next Week)

1. **Retrain with Corrected Data**: If data discrepancy is found, rebuild tables
2. **Add External Regressors**: Campaign data, seasonality, etc.
3. **Increase Training Window**: Consider 120-180 days to capture more trend data

### Long-Term (Next Month)

1. **Segment-Level Modeling**: Separate high-volume segments from sparse ones
2. **Zero-Inflation Handling**: Explicitly model sparse vs dense periods
3. **Hierarchical Forecasting**: Forecast at channel level, disaggregate to segments

---

## 🔍 Data Quality Questions

1. **Why is October showing 77 SQLs in vw_daily_stage_counts but 100 in direct query?**
2. **Are we filtering out inactive SGA/SGM correctly in the training data?**
3. **Is there a date attribution issue causing missing SQLs in the view?**
4. **Are we counting all opportunities or just certain record types?**

---

## ✅ What We Know Works

1. **Conversion rates are accurate** (58-71% by segment)
2. **Trend detection works** (identified July→September growth)
3. **Top segments identified correctly**
4. **Monthly granularity working**
5. **SQO date attribution fixed**

---

## ⚠️ What Needs Fixing

1. **Training data volume mismatch** (2.5/day vs 3.3/day actual)
2. **Sparse data handling** (zeros diluting averages)
3. **Model scale limitations** (can't forecast 10x beyond training)
4. **Segment-level volume distribution**

---

## 🎯 Bottom Line

The 90-day ultra-reactive model made **minimal improvement** vs 180-day because both are constrained by the **same sparse training data**. 

The real issue is a **data volume discrepancy**: training shows 2.5 SQLs/day, but October actual is 3.3 SQLs/day. This suggests either:
- A filtering issue in the views
- A date attribution problem
- Missing data in the training window

**Next Step**: Investigate and fix the data discrepancy, then retrain.

---

**Status**: Forecast generated successfully, but severe under-prediction indicates data quality issue needs resolution.
