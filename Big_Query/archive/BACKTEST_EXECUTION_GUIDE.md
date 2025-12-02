# Walk-Forward Backtest Execution Guide

## ⚠️ Important Warning

**This backtest will take 15-30 MINUTES to complete** because it:
- Trains 3 models (ARIMA MQL, ARIMA SQL, Propensity) for each week
- Walks forward 13 weeks (90 days ÷ 7 days per week)
- That's **39 model training runs** total!

---

## Step-by-Step Instructions

### Step 1: Open BigQuery Console

1. Go to: https://console.cloud.google.com/bigquery
2. Make sure you're in the `savvy-gtm-analytics` project

### Step 2: Open the SQL File

1. Open the file `backtest_validation.sql` in your editor
2. Copy the **ENTIRE contents** (all 273 lines)

### Step 3: Paste and Run in BigQuery

1. Paste the SQL into the BigQuery console
2. Click **"Run"**

### Step 4: Wait Patiently ⏰

- **Do not navigate away**
- **Do not close the tab**
- BigQuery will show progress in the query editor

**Progress indicators**:
- Query will show "RUNNING" status
- You may see interim logs for each week's training
- Final output will appear when complete

### Step 5: View Results

After completion, run this to see the backtest results:

```sql
SELECT *
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
ORDER BY sqos_mape DESC
LIMIT 20;
```

---

## What to Expect in Results

### Key Metrics

| Metric | Meaning | Good Value |
|--------|---------|------------|
| **MAPE** | Mean Absolute % Error | < 30% |
| **MAE** | Mean Absolute Error | Varies by volume |
| **num_backtests** | Number of weekly windows tested | ~13 |

### Sample Output

```
Channel_Grouping_Name | Original_source            | mqls_mape | sqls_mape | sqos_mape
--------------------- | -------------------------- | --------- | --------- | ---------
Outbound              | LinkedIn (Self Sourced)   | 0.12      | 0.15      | 0.18
Outbound              | Provided Lead List        | 0.18      | 0.22      | 0.25
Ecosystem             | Advisor Referral          | 0.45      | 0.38      | 0.42
```

---

## Understanding the Results

### MAPE Interpretation

- **< 10%**: Excellent
- **10-20%**: Good
- **20-30%**: Acceptable
- **> 30%**: Needs improvement (likely sparse data)

### Segment Analysis

**High-volume segments** (Outbound, LinkedIn):
- Should have **MAPE < 25%**
- These have enough data for stable forecasts

**Low-volume segments**:
- May have **MAPE > 40%**
- This is expected due to sparsity
- Consider aggregating these segments

---

## Troubleshooting

### "This query used X CPU seconds"

**Normal**: This backtest is computationally expensive. It's expected to use 30-60 CPU seconds per week × 13 weeks = **400-800 CPU seconds total**.

### Query Timeout

**If query takes > 60 minutes**:
1. The loop may have stalled on a specific week
2. Check BigQuery logs for error messages
3. Consider reducing to 4 weeks for initial test

**Quick test** (use this to test first):
```sql
-- Change line 1 to:
DECLARE start_date DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 28 DAY);
```

### Missing Data

**If MAPE is 100%+ for a segment**:
- That segment has too little data
- May need to exclude from final model

---

## Next Steps After Backtest

1. **Review segment performance**: Focus on high-volume segments
2. **Identify poor performers**: Flag segments needing attention
3. **Production deployment**: If results are acceptable, models are ready
4. **Document findings**: Update forecasting documentation

---

## SQL File Reference

**File**: `backtest_validation.sql`  
**Lines**: 273  
**Complexity**: High (uses scripting, loops, dynamic SQL)

All corrections have been applied:
- ✅ Proper type casts for INT64
- ✅ Date conversions
- ✅ Fixed propensity model features
- ✅ Historical rates integration

