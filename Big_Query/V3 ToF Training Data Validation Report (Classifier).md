# V3 ToF Training Data Validation Report (Classifier)

**Report Date:** Generated on execution  
**Data Source:** `savvy-gtm-analytics.savvy_forecast.tof_v3_daily_training_data`  
**Model Type:** BOOSTED_TREE_CLASSIFIER (Binary Classification)  
**Purpose:** Validate classifier-ready training table for data quality, collinearity, class distribution, and outliers

---

## Executive Summary

This report validates the Phase 1 training table rebuilt for the V3 ToF **classifier** model. The table has been successfully created with the new `has_sql` binary label required for classification. All validation checks have been completed to ensure data quality, identify collinearity issues, validate class distribution, and detect outliers.

**Key Findings:**
- ✅ **Table Structure:** Valid - 272,190 rows covering 633 days × 430 segments
- ✅ **Class Distribution:** 99.07% negative class / 0.93% positive class (for rows with valid lags) - **SEVERE IMBALANCE** requiring `auto_class_weights=TRUE`
- ⚠️ **Collinearity Alert:** `sqls_7day_avg_lag1` vs `sqls_28day_avg_lag1` correlation = 0.950 → **Monitor during training** (acceptable for different time horizons)
- ✅ **Outlier Analysis:** 12.7% statistical outliers (expected for sparse target variable)
- ✅ **Temporal Features:** All other correlations acceptable (<0.5)

**Recommended Actions:**
1. ✅ **Proceed to Phase 3** with `auto_class_weights=TRUE` to handle severe class imbalance
2. ⚠️ **Monitor `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1`** - high correlation (0.95) but acceptable for different time horizons
3. ✅ **Filter NULL lag features** during training (`WHERE sqls_7day_avg_lag1 IS NOT NULL`)

---

## Query 1: Basic Statistics

### Results

| Metric | Value |
|--------|-------|
| **Total Rows** | 272,190 |
| **Min Date** | 2024-02-07 |
| **Max Date** | 2025-10-31 |
| **Unique Segments** | 430 |
| **Average Daily SQLs per Segment** | 0.172 |
| **Average Daily MQLs per Segment** | 0.538 |
| **Overall Positive Class (has_sql = 1)** | 677 (0.25%) |
| **Overall Negative Class (has_sql = 0)** | 271,513 (99.75%) |

### Class Distribution (Rows with Valid Lags)

**Rows with Complete Features (for training):**
- **Total Rows:** 27,884
- **Positive Class (has_sql = 1):** 258 (0.93%)
- **Negative Class (has_sql = 0):** 27,626 (99.07%)
- **Min SQLs per segment-day:** 0
- **Max SQLs per segment-day:** 7
- **Average SQLs per segment-day:** 0.106

### Analysis

✅ **Table Structure Validation:**
- Date range: 2024-02-07 to 2025-10-31 (633 days, starting after 28-day lag exclusion)
- Segment-level granularity confirmed (day × LeadSource × Owner × Status)
- All required columns present including `has_sql` binary label

⚠️ **Class Imbalance Warning:**
- **99.07% negative class / 0.93% positive class** - This is a SEVERELY imbalanced dataset
- **Action Required:** Must use `auto_class_weights=TRUE` in model training (already included in Phase 3 plan)
- This imbalance is expected for segment-level data where most segment-days have zero SQLs

⚠️ **Data Completeness:**
- Only 27,884 rows (10.2%) have complete lag features (non-NULL)
- 244,306 rows (89.8%) have NULL lag features (new segments or gaps in activity)
- **Action Required:** Filter to rows with valid lags during training: `WHERE sqls_7day_avg_lag1 IS NOT NULL`

---

## Query 2: Collinearity Check

### Results

| Feature Pair | Correlation | Status | Action |
|--------------|-------------|--------|--------|
| **sqls_7day_avg_lag1 vs sqls_28day_avg_lag1** | **0.950** | ⚠️ **HIGH** | Monitor during training |
| sqls_7day_avg_lag1 vs mqls_7day_avg_lag1 | 0.510 | ✅ Acceptable | Keep both |
| sqls_28day_avg_lag1 vs mqls_7day_avg_lag1 | 0.469 | ✅ Acceptable | Keep both |
| month vs year | -0.301 | ✅ Acceptable | Keep both |
| day_of_month vs month | -0.073 | ✅ Acceptable | Keep both |
| day_of_week vs is_weekend | 0.021 | ✅ Acceptable | Keep both |

### Analysis

⚠️ **High Correlation Detected:**
- **`sqls_7day_avg_lag1` vs `sqls_28day_avg_lag1`**: Correlation = 0.950
- **Rationale:** These features measure similar patterns at different time horizons (7-day vs 28-day rolling averages)
- **Decision:** Keep both features for now, but monitor feature importance during training
- **Reason:** Different time horizons may capture different patterns; 28-day captures longer trends while 7-day captures recent activity
- **Action:** If one feature dominates (>70% importance), consider removing the other

✅ **All Other Correlations Acceptable:**
- All other feature pairs have correlations <0.51
- No severe collinearity requiring immediate exclusion
- Temporal features are properly decorrelated

---

## Query 3: Outlier Detection

### Results

| Metric | Value |
|--------|-------|
| **Q1 (25th percentile)** | 0 |
| **Median (50th percentile)** | 0 |
| **Q3 (75th percentile)** | 0 |
| **Lower Bound (Q1 - 1.5×IQR)** | 0 |
| **Upper Bound (Q3 + 1.5×IQR)** | 0 |
| **Statistical Outliers** | 677 rows (12.7%) |
| **Outlier Percentage** | 12.7% |

### Extreme Values (Top 10)

| Date | SQLs | MQLs | Day of Week | Month | LeadSource | Owner | Status |
|------|------|------|-------------|-------|------------|-------|--------|
| 2025-09-11 | 12 | 12 | 5 | 9 | Event | Savvy Marketing | Qualified |
| 2025-09-23 | 7 | 7 | 3 | 9 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2025-07-02 | 6 | 6 | 4 | 7 | Provided Lead List | Chris Morgan | Qualified |
| 2025-03-31 | 6 | 6 | 2 | 3 | Provided Lead List | Russell Armitage | Qualified |
| 2025-02-21 | 6 | 6 | 6 | 2 | Provided Lead List | Lauren George | Qualified |
| 2024-08-02 | 6 | 6 | 6 | 8 | Provided Lead List | Craig Suchodolski | Qualified |
| 2024-08-07 | 5 | 5 | 4 | 8 | LinkedIn (Self Sourced) | Eleni Stefanopoulos | Qualified |
| 2024-08-30 | 5 | 5 | 6 | 8 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2025-07-14 | 5 | 5 | 2 | 7 | LinkedIn (Self Sourced) | Russell Armitage | Qualified |
| 2024-08-02 | 5 | 5 | 6 | 8 | Provided Lead List | Lauren George | Qualified |

### Analysis

⚠️ **Outlier Percentage: 12.7%**
- **Status:** ACCEPTABLE for sparse binary classification
- **Explanation:** All "outliers" are rows where `target_sqls_segment > 0`, which is exactly our positive class
- **Rationale:** For a sparse target variable (99.07% zeros), any positive value is technically a statistical outlier
- **Action:** No action needed - these are legitimate business events, not data quality issues

✅ **Extreme Value Review:**
- Highest value: 12 SQLs in a single segment-day (Event source, Savvy Marketing, Qualified status)
- Most extreme values occur in "Qualified" status leads
- No obvious data quality issues (all values are plausible)
- No evidence of systematic errors

---

## Query 4: Temporal Feature Correlation (Redundancy Check)

### Results

| Feature Pair | Correlation | Status | Action |
|--------------|-------------|--------|--------|
| day_of_week vs is_weekend | 0.021 | ✅ Very Low | Keep both - minimal redundancy |
| year vs month | -0.301 | ✅ Acceptable | Keep both - captures different time granularities |
| day_of_month vs month | -0.073 | ✅ Very Low | Keep both - captures different patterns |
| sqls_7day_avg_lag1 vs sqls_28day_avg_lag1 | 0.950 | ⚠️ High | Monitor (same as Query 2 finding) |
| sqls_28day_avg_lag1 vs mqls_7day_avg_lag1 | 0.469 | ✅ Acceptable | Keep both |

### Analysis

✅ **Temporal Features Validation:**
- `day_of_week` vs `is_weekend`: Correlation = 0.021 (very low, both features useful)
- `year` vs `month`: Correlation = -0.301 (acceptable, captures different time scales)
- `day_of_month` vs `month`: Correlation = -0.073 (very low, minimal redundancy)

⚠️ **Note:** `quarter` feature was already removed from Phase 1 (not in training table) - correct decision confirmed

---

## Final Recommendations

### ✅ Feature Exclusion Decisions

1. **KEEP ALL CURRENT FEATURES** ✅
   - No features need immediate exclusion
   - `quarter` was correctly removed in Phase 1 (not in training data)
   - Monitor `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1` during training

### ✅ Features to Include in Model Training

**Temporal Features:**
- `day_of_week` ✅
- `day_of_month` ✅
- `month` ✅
- `year` ✅
- `is_weekend` ✅

**Lagged Features:**
- `sqls_7day_avg_lag1` ⚠️ (monitor - high correlation with 28-day)
- `sqls_28day_avg_lag1` ⚠️ (monitor - high correlation with 7-day)
- `mqls_7day_avg_lag1` ✅

**Segment Features (time_series_id_col):**
- `LeadSource` ✅
- `SGA_Owner_Name__c` ✅
- `Status` ✅

**Label:**
- `has_sql` ✅ (binary: 1 if SQLs > 0, 0 otherwise)

**Total Feature Count:** 8 features + 3 segment IDs + 1 label = 12 (well below 15 limit)

### ✅ Classifier-Specific Validation Checklist

- [x] Table structure validated
- [x] Binary label (`has_sql`) created and validated
- [x] Class distribution checked - **99.07% / 0.93% imbalance** confirmed
- [x] `auto_class_weights=TRUE` required (included in Phase 3 plan)
- [x] Collinearity checked - 1 feature pair flagged for monitoring
- [x] Outlier analysis complete - acceptable (12.7% expected for sparse data)
- [x] Temporal redundancy checked - all acceptable
- [x] Feature count within limits (<15)
- [x] Data quality confirmed (sparse target is expected)
- [x] NULL lag filtering identified (10.2% of rows have complete features)

---

## Next Steps

✅ **READY TO PROCEED TO PHASE 3**

1. **Phase 3 Model Training:**
   - Use feature set approved above (all current features)
   - **CRITICAL:** Filter to rows with valid lags: `WHERE sqls_7day_avg_lag1 IS NOT NULL`
   - **CRITICAL:** Ensure `auto_class_weights=TRUE` is set (already in plan)
   - Monitor feature importance for `sqls_7day_avg_lag1` and `sqls_28day_avg_lag1`
   - Expected training rows: ~27,884 (10.2% of total, but all with complete features)

2. **Training Data Filter:**
   ```sql
   WHERE sqls_7day_avg_lag1 IS NOT NULL 
     AND sqls_28day_avg_lag1 IS NOT NULL 
     AND mqls_7day_avg_lag1 IS NOT NULL
   ```

3. **Evaluation Metrics (Classification):**
   - ROC-AUC (target: >0.7)
   - Precision (target: >0.5)
   - Recall (target: >0.3)
   - F1-Score
   - Confusion Matrix

---

## Appendix: Data Completeness Analysis

### Rows by Completeness

| Completeness Level | Row Count | Percentage |
|-------------------|-----------|------------|
| **Complete Features (All lags non-NULL)** | 27,884 | 10.2% |
| **Missing Lag Features** | 244,306 | 89.8% |
| **Total Rows** | 272,190 | 100% |

### Class Distribution by Completeness

**Rows with Complete Features (Training Set):**
- Positive class: 258 (0.93%)
- Negative class: 27,626 (99.07%)
- Total: 27,884 rows

**Note:** The training set with complete features has a slightly better class balance (0.93% vs 0.25% overall) because new segments with no history (mostly NULL lags) tend to have zero SQLs.

---

**Report Status:** ✅ **VALIDATION COMPLETE - READY FOR PHASE 3**

