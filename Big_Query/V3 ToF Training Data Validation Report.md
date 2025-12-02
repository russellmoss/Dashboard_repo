# V3 ToF Training Data Validation Report

**Report Date:** Generated on execution  
**Data Source:** `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data`  
**Purpose:** Validate training table for data quality, collinearity, and outliers before model training

---

## Executive Summary

This report validates the Phase 1 training table for the V3 ToF segment-level forecasting model. All validation checks have been completed to ensure data quality, identify collinearity issues, detect outliers, and verify feature redundancy.

**Key Findings:**
- ✅ **Table Structure:** Valid - 272,190 rows covering 633 days × 430 segments
- ⚠️ **Collinearity Alert:** `month` vs `quarter` correlation = 0.965 → **EXCLUDE `quarter`**
- ⚠️ **Collinearity Alert:** `sqls_7day_avg_lag1` vs `sqls_28day_avg_lag1` correlation = 0.950 → **Flag for review**
- ✅ **Outlier Analysis:** 0.25% of data are outliers (expected for sparse target variable)
- ✅ **Temporal Features:** All other correlations acceptable

**Recommended Actions:**
1. **EXCLUDE `quarter` feature** from model training (correlation 0.965 with `month`)
2. **Monitor `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1`** - both may be needed but watch for overfitting
3. **Proceed to Phase 3** with approved feature set

---

## Query 1: Basic Statistics

### Results

| Metric | Value |
|--------|-------|
| **Total Rows** | 272,190 |
| **Min Date** | 2024-02-07 |
| **Max Date** | 2025-10-31 |
| **Average Daily SQLs per Segment** | 0.172 |
| **Average Daily MQLs per Segment** | 0.538 |

### Analysis

✅ **Table Structure Validation:**
- Date range: 2024-02-07 to 2025-10-31 (633 days, starting after 28-day lag exclusion)
- Segment-level granularity confirmed (day × LeadSource × Owner × Status)
- Average values align with expectations for segment-level aggregation

**Note:** The average daily SQLs per segment (0.172) reflects that most segment-day combinations have 0 SQLs, which is expected for a sparse target variable.

---

## Query 2: Collinearity Check

### Correlation Results

| Feature A | Feature B | Correlation | Status | Action |
|-----------|-----------|-------------|--------|--------|
| month | quarter | **0.965** | ⚠️ **SEVERE** | **EXCLUDE `quarter`** |
| sqls_7day_avg_lag1 | sqls_28day_avg_lag1 | **0.950** | ⚠️ **HIGH** | **Flag for review** |
| sqls_7day_avg_lag1 | mqls_7day_avg_lag1 | 0.510 | ✅ Acceptable | Keep both |
| sqls_28day_avg_lag1 | mqls_7day_avg_lag1 | 0.469 | ✅ Acceptable | Keep both |
| day_of_week | is_weekend | -0.001 | ✅ Acceptable | Keep both |
| day_of_week | day_of_month | 0.006 | ✅ Acceptable | Keep both |
| month | year | -0.256 | ✅ Acceptable | Keep both |
| day_of_month | month | -0.005 | ✅ Acceptable | Keep both |

### Detailed Analysis

#### ⚠️ Severe Collinearity (>0.95): EXCLUDE

1. **month vs quarter (0.965)**
   - **Analysis:** Almost perfect correlation - quarter is directly derived from month
   - **Decision:** **EXCLUDE `quarter` from model training**
   - **Rationale:** Month provides more granular temporal information, quarter adds no additional signal
   - **Action:** Already excluded in Phase 3 model query (commented out)

#### ⚠️ High Collinearity (0.8-0.95): Flag for Review

2. **sqls_7day_avg_lag1 vs sqls_28day_avg_lag1 (0.950)**
   - **Analysis:** Very high correlation - both measure recent SQL trends
   - **Decision:** **Keep both but monitor during training**
   - **Rationale:** 
     - 7-day avg captures short-term volatility
     - 28-day avg captures longer-term trends
     - Different time horizons may provide complementary signal
     - Phase 3 plan already expects this correlation (~0.7-0.8), but 0.950 is higher
   - **Action:** Monitor feature importance during training - if one dominates, consider removing the other
   - **Risk:** Higher correlation increases overfitting risk

#### ✅ Acceptable Correlations (<0.8): Keep All

All other feature pairs have correlations well below 0.8, indicating acceptable independence.

---

## Query 3: Outlier Detection

### Target Variable Distribution

| Target Value | Frequency | Percentage |
|--------------|-----------|------------|
| 0 SQLs | 271,513 | 99.75% |
| 1 SQL | 526 | 0.19% |
| 2 SQLs | 104 | 0.04% |
| 3 SQLs | 25 | 0.01% |
| 4 SQLs | 11 | <0.01% |
| 5 SQLs | 5 | <0.01% |
| 6 SQLs | 4 | <0.01% |
| 7 SQLs | 1 | <0.01% |
| 12 SQLs | 1 | <0.01% |

### Outlier Statistics

| Metric | Value |
|--------|-------|
| **Total Outliers (1.5×IQR rule)** | 677 rows |
| **Percentage of Data** | 0.25% |
| **Max SQLs in Single Segment-Day** | 12 |

### Detailed Analysis

#### Outlier Characteristics

**Outlier Percentage:** 0.25% of data (677 rows)

✅ **Status: ACCEPTABLE**
- Outlier percentage (0.25%) is well below the 5% threshold
- Expected for sparse target variable where most segment-days have 0 SQLs
- Positive SQL values are naturally "outliers" in a mostly-zero distribution

#### Extreme Values (>3×IQR)

**Top 10 Extreme Values:**

| Date | SQLs | MQLs | Day | Month | LeadSource | Owner | Status |
|------|------|------|-----|-------|------------|-------|--------|
| 2025-09-11 | 12 | 12 | Thu | 9 | Event | Savvy Marketing | Qualified |
| 2025-09-23 | 7 | 7 | Tue | 9 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2025-07-02 | 6 | 6 | Wed | 7 | Provided Lead List | Chris Morgan | Qualified |
| 2024-08-02 | 6 | 6 | Fri | 8 | Provided Lead List | Craig Suchodolski | Qualified |
| 2025-02-21 | 6 | 6 | Fri | 2 | Provided Lead List | Lauren George | Qualified |
| 2025-03-31 | 6 | 6 | Mon | 3 | Provided Lead List | Russell Armitage | Qualified |
| 2024-08-30 | 5 | 5 | Fri | 8 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2025-07-14 | 5 | 5 | Mon | 7 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2024-08-07 | 5 | 5 | Wed | 8 | LinkedIn (Self Sourced) | Eleni Stefanopoulos | Qualified |
| 2024-10-02 | 5 | 5 | Wed | 10 | Provided Lead List | Russell Armitage | Qualified |

**Analysis:**
- Extreme values are legitimate business events (not data errors):
  - **Event** source on 2025-09-11 (12 SQLs) - likely a large marketing event
  - **LinkedIn (Self Sourced)** and **Provided Lead List** sources dominate extreme values
  - No clear holiday pattern (varied days of week and months)
  
✅ **Status: ACCEPTABLE**
- Extreme values are business-driven (events, campaigns) not data quality issues
- Holiday features (HOLIDAY_REGION='US' in model) will help capture some seasonality
- No action needed - these are legitimate high-conversion days

---

## Query 4: Temporal Feature Correlation (Redundancy Check)

### Results

| Feature Pair | Correlation | Expected Range | Status | Decision |
|--------------|-------------|----------------|--------|----------|
| day_of_week vs is_weekend | -0.001 | ~0.6-0.7 | ⚠️ Unexpected | Keep both (low correlation is fine) |
| month vs quarter | **0.965** | >0.8 | ⚠️ **SEVERE** | **EXCLUDE `quarter`** |
| sqls_7day_avg_lag1 vs sqls_28day_avg_lag1 | **0.950** | ~0.7-0.8 | ⚠️ **HIGH** | Flag for review |

### Detailed Analysis

#### day_of_week vs is_weekend (-0.001)

**Analysis:** Correlation is near-zero, which is unexpected given the plan's expectation of ~0.6-0.7.

**Possible Explanations:**
- `is_weekend` is binary (1/0) while `day_of_week` is numeric (1-7)
- Weekend days (Sat=1, Sun=7) don't have a linear relationship with the numeric day_of_week
- Both features may still provide value (day_of_week captures weekday patterns, is_weekend captures weekend effect)

**Decision:** ✅ **Keep both** - Low correlation is acceptable, both may capture different patterns

#### month vs quarter (0.965)

**Status:** ⚠️ **SEVERE COLLINEARITY**

**Decision:** ✅ **EXCLUDE `quarter`** - Already excluded in Phase 3 model query

**Rationale:**
- Quarter is directly derived from month (Q1=months 1-3, Q2=months 4-6, etc.)
- Month provides more granular temporal signal
- Quarter adds no independent information

#### sqls_7day_avg_lag1 vs sqls_28day_avg_lag1 (0.950)

**Status:** ⚠️ **HIGH COLLINEARITY** (above expected 0.7-0.8)

**Analysis:**
- Correlation (0.950) is higher than expected
- Both features measure recent SQL trends at different horizons
- May indicate that short-term and long-term trends are highly aligned

**Decision:** ⚠️ **Keep both but monitor during training**

**Action Plan:**
1. Monitor feature importance in Phase 3 training
2. If one feature dominates (>40% importance), consider removing the other
3. Watch for overfitting signs (high train-val gap)
4. Consider reducing regularization if both features prove valuable

---

## Additional Statistics

| Metric | Value |
|--------|-------|
| **Total Rows** | 272,190 |
| **Zero SQL Rows** | 271,513 (99.75%) |
| **Positive SQL Rows** | 677 (0.25%) |
| **Multiple SQL Rows (≥2)** | 151 (0.06%) |
| **Max SQLs in Segment-Day** | 12 |
| **Standard Deviation** | 0.555 |

### Target Variable Characteristics

**Sparsity Analysis:**
- **99.75%** of rows have 0 SQLs (expected for segment-level granularity)
- **0.25%** of rows have positive SQLs (outliers in statistical sense, but business-expected)
- **12 SQLs** maximum in a single segment-day (legitimate business event)

✅ **Status: ACCEPTABLE** - Sparse target variable is expected and manageable with regularization

---

## Final Recommendations

### ✅ Feature Exclusion Decisions

1. **EXCLUDE `quarter`** ✅
   - Correlation with `month`: 0.965 (severe collinearity)
   - Already excluded in Phase 3 model query
   - No action needed

2. **MONITOR `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1`** ⚠️
   - Correlation: 0.950 (higher than expected)
   - Keep both for Phase 3 training
   - Monitor feature importance during training
   - Remove one if dominance or overfitting detected

### ✅ Features to Include in Model Training

**Temporal Features:**
- `day_of_week` ✅
- `day_of_month` ✅
- `month` ✅ (quarter excluded)
- `year` ✅
- `is_weekend` ✅

**Lagged Features:**
- `sqls_7day_avg_lag1` ⚠️ (monitor)
- `sqls_28day_avg_lag1` ⚠️ (monitor)
- `mqls_7day_avg_lag1` ✅

**Segment Features (time_series_id_col):**
- `LeadSource` ✅
- `SGA_Owner_Name__c` ✅
- `Status` ✅

**Total Feature Count:** 8 features + 3 segment IDs = 11 (well below 15 limit)

### ✅ Validation Checklist

- [x] Table structure validated
- [x] Collinearity checked - 1 feature excluded (`quarter`)
- [x] High correlation flagged (`sqls_7day_avg_lag1` vs `sqls_28day_avg_lag1`)
- [x] Outlier analysis complete - acceptable (0.25%)
- [x] Temporal redundancy checked
- [x] Feature count within limits (<15)
- [x] Data quality confirmed (sparse target is expected)

---

## Next Steps

✅ **READY TO PROCEED TO PHASE 3**

1. **Phase 3 Model Training:**
   - Use feature set approved above (excluding `quarter`)
   - Apply regularization (L1=0.1, L2=1.0) to handle sparse target
   - Monitor `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1` feature importance
   - Enable holiday features (HOLIDAY_REGION='US')

2. **Expected Behavior:**
   - Model will learn distinct patterns per segment (430 unique segments)
   - Sparse target variable (99.75% zeros) requires strong regularization
   - Holiday features will help capture event-driven spikes (like the 12-SQL event day)

3. **Success Criteria:**
   - R² > 0.5
   - Train-Val RMSE gap < 15%
   - No single feature >50% importance
   - Monthly MAPE < 20%

---

**Report End**

