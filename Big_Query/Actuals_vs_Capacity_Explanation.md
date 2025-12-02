# Actuals vs Capacity - Key Distinction

## The Difference

### `current_quarter_joined_margin_aum` (Actuals)
- **What it is**: Margin AUM from deals that have **already closed/joined** this quarter
- **Time period**: October 1 - November 15, 2025 (current quarter to date)
- **For Bre McDaniel**: **$86.14M** ✅
- **Meaning**: This is **historical/actual** performance - deals that are done

### `sgm_capacity_expected_joined_aum_millions_estimate` (Capacity/Forecast)
- **What it is**: **Forecast** of expected joined Margin AUM based on **current pipeline**
- **Time period**: Future (what we expect to close from current pipeline)
- **For Bre McDaniel**: **$21.89M**
- **Meaning**: This is a **forward-looking forecast** based on:
  - Active (non-stale) SQOs currently in pipeline
  - Stage probabilities
  - Historical conversion rates

---

## Why They're Different

### Bre McDaniel's Situation:

**Actuals (Already Closed):**
- $86.14M in joined Margin AUM this quarter
- These are deals that **already closed** between Oct 1 - Nov 15
- This is **past performance**

**Capacity (Future Forecast):**
- $21.89M expected from current pipeline
- This is what we expect to close **going forward** from her current pipeline
- Based on: Active pipeline value ($148.07M) × Conversion rate (14.78%) = $21.89M

---

## The Key Insight

**These metrics answer different questions:**

1. **`current_quarter_joined_margin_aum`** = "How much has she already closed this quarter?"
   - Answer: $86.14M ✅ (She's already exceeded her $3.67M target!)

2. **`sgm_capacity_expected_joined_aum_millions_estimate`** = "How much can we expect from her current pipeline?"
   - Answer: $21.89M (Forecast based on what's in pipeline now)

---

## Why Capacity Might Be Lower Than Actuals

**Scenario**: Bre McDaniel has already closed $86.14M this quarter, but her capacity forecast is only $21.89M.

**Possible reasons:**
1. **She already closed her big deals** - The $86.14M came from deals that were in her pipeline earlier, but have now closed
2. **Pipeline refresh needed** - Her current pipeline might be smaller now that big deals have closed
3. **Different time periods** - Actuals are Oct 1 - Nov 15 (past), Capacity is forecast for future (Nov 15 - end of quarter)
4. **Conversion rate applied** - Capacity applies a 14.78% conversion rate to pipeline value, which is conservative

---

## How to Use Both Metrics

### In Looker Studio Dashboard:

**Scorecard 1: Current Quarter Actuals**
- Metric: `current_quarter_joined_margin_aum`
- Label: "Actual Joined This Quarter"
- Shows: What has already happened
- For Bre: $86.14M ✅

**Scorecard 2: Capacity Forecast**
- Metric: `sgm_capacity_expected_joined_aum_millions_estimate`
- Label: "Expected Capacity (Pipeline)"
- Shows: What we expect from current pipeline
- For Bre: $21.89M

**Comparison:**
- Bre has already exceeded her target ($86.14M vs $3.67M target)
- But her current pipeline suggests $21.89M more capacity
- Total potential: $86.14M (actuals) + $21.89M (capacity) = $108.03M potential

---

## Summary

| Metric | Value | Meaning |
|--------|-------|---------|
| `current_quarter_joined_margin_aum` | $86.14M | **Actual** joined Margin AUM this quarter (Oct 1 - Nov 15) |
| `sgm_capacity_expected_joined_aum_millions_estimate` | $21.89M | **Forecast** of expected joined Margin AUM from current pipeline |

**They're both correct** - they just measure different things:
- **Actuals** = Past performance (what closed)
- **Capacity** = Future forecast (what's expected from pipeline)

Bre McDaniel is doing great - she's already closed $86.14M this quarter, which is 23.5x her target! The $21.89M capacity is additional expected value from her current pipeline.

