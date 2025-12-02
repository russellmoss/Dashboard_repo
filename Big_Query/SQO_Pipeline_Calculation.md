# SQO Pipeline Calculation: Total SQOs Needed Across All SGMs

## Summary
**Total SQOs needed in pipeline at any given point: 190 SQOs**

This is the sum of `required_sqos_per_quarter` across all 9 active SGMs.

---

## The Math

### Step 1: Per-SGM Calculation

For each SGM, the formula in `vw_sgm_capacity_model_refined.sql` calculates:

```
Required SQOs per Quarter = CEILING(
  CEILING(Quarterly Target / Avg Margin AUM per Joined)
  / SQO→Joined Conversion Rate
)
```

Where:
- **Quarterly Target** = $3.67M margin AUM per SGM
- **Avg Margin AUM per Joined** = Historical average (varies by SGM, or firm-wide for On Ramp)
- **SQO→Joined Conversion Rate** = Historical conversion rate (varies by SGM, or firm-wide for On Ramp)

### Step 2: Why This Represents "At Any Given Point"

The `required_sqos_per_quarter` metric represents the **minimum pipeline size** needed at any point because:

1. **Continuous Conversion**: SQOs convert to Joined over time (not all at once)
2. **Pipeline Velocity**: As SQOs convert, new ones must enter the pipeline
3. **Steady State**: To maintain quarterly targets, you need a constant pipeline of SQOs

**Example:**
- If an SGM needs 22 SQOs to convert per quarter
- And SQOs take ~45-90 days to convert (typical sales cycle)
- Then you need at least 22 SQOs in the pipeline at any point to ensure continuous conversion

### Step 3: Aggregation Across All SGMs

**Current Data (from BigQuery):**
- Total Active SGMs: **9**
- Sum of Required SQOs per Quarter: **190 SQOs**
- Current Total Pipeline SQOs: **125 SQOs**
- **Gap: 65 SQOs** (190 - 125)

---

## Detailed Breakdown by SGM

| SGM Name | Required SQOs/Qtr | Current Pipeline | Gap |
|----------|-------------------|------------------|-----|
| Erin Pearson | 54 | 20 | +34 |
| Jade Bingham | 31 | 14 | +17 |
| Bryan Belville | 22 | 17 | +5 |
| Ariana Butler | 19 | 4 | +15 |
| Lexi Harrison | 19 | 5 | +14 |
| Tim Mackey | 19 | 2 | +17 |
| Corey Marcello | 12 | 29 | -17 (over) |
| GinaRose Galli | 7 | 8 | -1 (over) |
| Bre McDaniel | 7 | 26 | -19 (over) |
| **TOTAL** | **190** | **125** | **+65** |

---

## Key Assumptions

1. **Conversion Rate**: Uses historical SQO→Joined conversion rate (last 12 months)
   - Individual rate for established SGMs
   - Firm-wide rate for "On Ramp" SGMs (created within 90 days)

2. **Margin AUM per Joined**: Uses historical average (last 12 months)
   - Individual average for established SGMs
   - Firm-wide average for "On Ramp" SGMs or SGMs with no joined history

3. **Pipeline Definition**: SQOs are considered "in pipeline" if:
   - `IsClosed = FALSE`
   - `advisor_join_date__c IS NULL` (not yet joined)
   - `StageName != 'Closed Lost'` and `StageName != 'On Hold'`

4. **Active vs Stale**: The view distinguishes between:
   - **Active SQOs**: Age ≤ 120 days (used in capacity calculations)
   - **Stale SQOs**: Age > 120 days (excluded from active capacity)

---

## Formula Reference

From `vw_sgm_capacity_model_refined.sql` (lines 351-359):

```sql
required_sqos_per_quarter = CEILING(
  CEILING(3.67 / effective_avg_margin_aum_per_joined)
  / effective_sqo_to_joined_conversion_rate
)
```

**Why CEILING twice?**
1. First CEILING: Ensures we get whole number of Joined advisors needed (can't convert 0.45 people!)
2. Second CEILING: Ensures we get whole number of SQOs needed to achieve those Joined advisors

---

## Example Calculation

**For an SGM with:**
- Avg Margin AUM per Joined: $10M
- SQO→Joined Conversion Rate: 10% (0.10)

**Step 1: Calculate Required Joined per Quarter**
```
Required Joined = CEILING(3.67 / 10) = CEILING(0.367) = 1 Joined
```

**Step 2: Calculate Required SQOs per Quarter**
```
Required SQOs = CEILING(1 / 0.10) = CEILING(10) = 10 SQOs
```

**Result:** This SGM needs **10 SQOs in pipeline at any given point** to hit quarterly target.

---

## Answer to Your Question

**Q: How many SQOs should we have open at any given point in order to have enough in the pipeline for all of our SGMs?**

**A: 190 SQOs total across all 9 active SGMs**

**Current Status:**
- Currently have: **125 SQOs**
- Need: **190 SQOs**
- **Gap: 65 SQOs** (34% short of target)

---

## Notes

1. This calculation assumes steady-state pipeline management
2. Individual SGM requirements vary based on their historical performance
3. "On Ramp" SGMs (created within 90 days) use firm-wide averages
4. The view excludes stale SQOs (>120 days old) from active capacity calculations
5. This is a minimum target; having a buffer above 190 would provide safety margin

