# SGM Capacity Metric Explanation

## What is `sgm_capacity_expected_joined_aum_millions_estimate`?

This metric represents **the expected quarterly joined Margin AUM for an individual SGM** based on their current active (non-stale) pipeline.

### Formula:
```
SGM Capacity = Active Weighted Pipeline Value × SQO→Joined Conversion Rate
```

Where:
- **Active Weighted Pipeline Value** = Sum of (non-stale SQOs × stage probability × estimated margin AUM)
- **SQO→Joined Conversion Rate** = Historical conversion rate for that SGM (last 12 months)

### What it means:
- **Per-SGM metric**: Each row in `vw_sgm_capacity_coverage` has one value for that SGM
- **Expected value**: This is a forecast, not actual results
- **Active only**: Excludes stale deals (SQOs older than 120 days)
- **Weighted**: Accounts for stage probabilities (e.g., Negotiating has higher probability than Discovery)
- **Estimated**: Uses fallback logic when Margin_AUM__c is missing

### Example:
If an SGM has:
- Active weighted pipeline value: $10M
- SQO→Joined conversion rate: 25% (0.25)

Then their capacity = $10M × 0.25 = **$2.5M expected joined AUM**

---

## Should you SUM it in Looker Studio?

**YES, if you want firm-wide capacity.**

### Use Cases:

#### 1. **Per-SGM Analysis** (Do NOT sum)
- Show individual SGM capacity in a table
- Compare each SGM's capacity to their target ($3.67M)
- Identify which SGMs are above/below target

**Looker Setup:**
- Dimension: `sgm_name`
- Metric: `sgm_capacity_expected_joined_aum_millions_estimate` (no aggregation, or use `MAX` per SGM)
- Format: Currency (Millions)

#### 2. **Firm-Wide Capacity** (DO sum)
- Total expected joined AUM across all SGMs
- Compare to total firm target
- Calculate firm-wide coverage ratio

**Looker Setup:**
- Metric: `SUM(sgm_capacity_expected_joined_aum_millions_estimate)`
- Format: Currency (Millions)
- Label: "Total Firm Capacity" or "Total Expected Joined AUM"

**Example Calculation:**
- 9 SGMs
- Average capacity per SGM: ~$4.95M
- Total firm capacity: ~$44.5M
- Total firm target: 9 × $3.67M = $33.03M
- Firm coverage: $44.5M / $33.03M = 1.35 (135% - sufficient capacity)

---

## How to Use in Looker Studio

### Scorecard: Total Firm Capacity
1. **Metric**: `SUM(sgm_capacity_expected_joined_aum_millions_estimate)`
2. **Label**: "Total SGM Capacity"
3. **Subtitle**: "Expected Joined AUM"
4. **Format**: Currency (Millions, 2 decimals)

### Table: Individual SGM Capacity
1. **Dimension**: `sgm_name`
2. **Metric**: `sgm_capacity_expected_joined_aum_millions_estimate`
3. **Additional Metrics**:
   - `quarterly_target_margin_aum_millions` (Target)
   - `coverage_ratio_estimate` (Coverage)
   - `capacity_gap_millions_estimate` (Gap)

### Bar Chart: Capacity vs Target
1. **Dimension**: `sgm_name`
2. **Metrics**:
   - `sgm_capacity_expected_joined_aum_millions_estimate` (Capacity)
   - `quarterly_target_margin_aum_millions` (Target)

---

## Key Points:

1. **It's a per-SGM metric** - Each SGM has their own capacity value
2. **Sum for firm-wide** - Use `SUM()` to get total firm capacity
3. **Compare to target** - Each SGM's capacity should be compared to $3.67M target
4. **It's a forecast** - Based on current pipeline, not actual results
5. **Active deals only** - Excludes stale deals for more realistic forecast

---

## Relationship to Other Metrics:

- **`coverage_ratio_estimate`** = `sgm_capacity_expected_joined_aum_millions_estimate` / `quarterly_target_margin_aum_millions`
- **`capacity_gap_millions_estimate`** = `quarterly_target_margin_aum_millions` - `sgm_capacity_expected_joined_aum_millions_estimate`
- **Firm-wide capacity** = `SUM(sgm_capacity_expected_joined_aum_millions_estimate)` across all SGMs

---

## Example Dashboard Usage:

### Top Section (Firm-Wide):
- **Scorecard**: `SUM(sgm_capacity_expected_joined_aum_millions_estimate)` = Total Firm Capacity
- **Scorecard**: `COUNT(sgm_name) * 3.67` = Total Firm Target
- **Gauge**: `AVG(coverage_ratio_estimate)` = Average Coverage Ratio

### Bottom Section (Per-SGM):
- **Table**: Individual SGMs with their capacity, target, coverage ratio
- **Bar Chart**: Each SGM's capacity vs target

