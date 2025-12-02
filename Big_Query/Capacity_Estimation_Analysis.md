# Capacity Estimation Analysis: `sgm_capacity_expected_joined_aum_millions_estimate`

## Current Calculation Method

The `sgm_capacity_expected_joined_aum_millions_estimate` is calculated as:

```sql
current_pipeline_active_weighted_margin_aum_estimate * effective_sqo_to_joined_conversion_rate
```

### Step-by-Step Breakdown

1. **`current_pipeline_active_weighted_margin_aum_estimate`** (from `vw_sgm_capacity_model_refined`):
   ```sql
   SUM(estimated_margin_aum * stage_probability) 
   FOR active SQOs (sqo_age_days <= 120)
   ```
   
   Where:
   - `estimated_margin_aum` = Actual `Margin_AUM__c` if available, otherwise fallback:
     - `Underwritten_AUM__c / 3.125` if available
     - `Amount / 3.22` if available
   - `stage_probability` = Probability that an opportunity in this stage will eventually become Joined
     - From `vw_stage_to_joined_probability`
     - Examples:
       - Signed: 89.0%
       - Negotiating: 36.4%
       - Sales Process: 13.8%
       - Discovery: 7.0%
       - Qualifying: 7.9%

2. **`effective_sqo_to_joined_conversion_rate`**:
   - For "On Ramp" SGMs: Firm-wide average conversion rate
   - For others: Individual SGM's historical SQO→Joined conversion rate (last 12 months)
   - This is calculated as: `(SQOs that became Joined) / (Total SQOs)`

## The Problem: Double-Counting Conversion

### Issue Identified

**We are applying TWO conversion factors, which double-counts the conversion probability:**

1. **First conversion factor**: `stage_probability` 
   - This already accounts for the probability that an opportunity in a given stage will become Joined
   - Example: A deal in "Negotiating" has a 36.4% chance of becoming Joined

2. **Second conversion factor**: `sqo_to_joined_conversion_rate`
   - This is the overall SQO→Joined conversion rate (e.g., 15.6% for Bre McDaniel)
   - This represents the historical rate at which SQOs convert to Joined

### Why This Is Incorrect

The `stage_probability` already incorporates the conversion from stage to Joined. When we then multiply by `sqo_to_joined_conversion_rate`, we're applying a second conversion factor that's redundant.

**Example:**
- Pipeline has a deal with $10M Margin_AUM in "Negotiating" stage
- `stage_probability` for Negotiating = 36.4%
- Weighted value = $10M × 0.364 = $3.64M (expected value accounting for conversion)
- Then multiply by `sqo_to_joined_conversion_rate` = 15.6%
- Final estimate = $3.64M × 0.156 = **$0.57M**

This is **too conservative** because:
- The $3.64M already represents the expected value (accounting for the 36.4% chance)
- Multiplying by 15.6% again reduces it further, essentially saying "only 15.6% of the already-probability-adjusted value will convert"

## What Should We Use Instead?

### Option 1: Use Weighted Pipeline Directly (Recommended)
```sql
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_active_weighted_margin_aum_estimate
```

**Rationale:**
- The `stage_probability` already accounts for conversion probability
- This gives us the expected Margin_AUM that will convert from the current pipeline
- This is the most accurate estimate for capacity planning

### Option 2: Use Unweighted Pipeline × Conversion Rate
```sql
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_sqo_margin_aum_estimate * sqo_to_joined_conversion_rate
```

**Rationale:**
- Uses the overall SQO→Joined conversion rate
- Simpler calculation
- But doesn't account for stage-specific probabilities (a deal in "Signed" should have higher expected value than one in "Discovery")

### Option 3: Hybrid Approach (Current, but needs correction)
If we want to account for both stage probabilities AND overall conversion rates, we need to understand:
- Are `stage_probability` values calculated from ALL opportunities that reached that stage?
- Or are they calculated only from SQOs that reached that stage?

**If `stage_probability` includes non-SQOs:**
- Then we might need to adjust, but the current double-multiplication is still wrong
- We'd need: `weighted_pipeline * (sqo_to_joined_rate / avg_stage_probability_for_sqos)`

**If `stage_probability` is SQO-specific:**
- Then Option 1 is correct (use weighted pipeline directly)

## Verification Against Actual Data

### Average Margin_AUM per Joined Advisor
- **Average**: $17.65M ± $16.45M
- **Median**: $10.56M
- **Range**: $1.20M to $34.09M (mean ± 1 std dev)

### Current Calculation Impact

Looking at sample SGMs:
- **Bre McDaniel**: 
  - Weighted pipeline: $111.65M
  - Conversion rate: 15.6%
  - Current estimate: $17.48M
  - This suggests ~1 joined advisor worth of capacity
  - But weighted pipeline of $111.65M suggests much more capacity

- **Corey Marcello**:
  - Weighted pipeline: $171.38M
  - Conversion rate: 8.7%
  - Current estimate: $14.84M
  - This suggests <1 joined advisor worth of capacity
  - But weighted pipeline suggests ~5-10 joined advisors worth

## Recommendation

**Use Option 1: Weighted Pipeline Directly**

The `current_pipeline_active_weighted_margin_aum_estimate` already accounts for:
1. Stage-specific conversion probabilities
2. Active vs stale deals (excludes deals >120 days old)
3. Estimated Margin_AUM (includes fallback calculations)

Multiplying by `sqo_to_joined_conversion_rate` is redundant and makes the estimates too conservative.

### Updated Calculation
```sql
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_active_weighted_margin_aum_estimate
  -- Remove the multiplication by conversion_rate
```

### Expected Impact
- Capacity estimates will increase (more realistic)
- Coverage ratios will improve (more accurate assessment)
- Better alignment with actual pipeline value

## Verification: What Does `stage_probability` Represent?

**Confirmed:** `stage_probability` is calculated from ALL opportunities that reached that stage (not just SQOs).

From the data:
- **Discovery**: 6.78% overall conversion, 8.16% for SQOs (slight difference)
- **Negotiating**: 36.41% for both (all opportunities in this stage are SQOs)
- **Signed**: 89.01% for both (all opportunities in this stage are SQOs)

**Key Insight:** For later stages (Negotiating, Signed), virtually all opportunities are SQOs, so the probabilities are effectively SQO-specific. For earlier stages, there's a small difference, but it's minimal.

## Final Recommendation

**Use Option 1: Weighted Pipeline Directly**

The `stage_probability` already accounts for the probability that an opportunity in a given stage will become Joined. Since we're calculating capacity from SQOs in the pipeline, and the stage probabilities are effectively SQO-specific for the stages we care about (Negotiating, Signed), we should use the weighted pipeline value directly.

### Updated Calculation
```sql
-- CURRENT (INCORRECT):
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_active_weighted_margin_aum_estimate * effective_sqo_to_joined_conversion_rate

-- RECOMMENDED (CORRECT):
sgm_capacity_expected_joined_aum_millions_estimate = 
  current_pipeline_active_weighted_margin_aum_estimate
```

### Why This Is Correct

1. **Stage probabilities already account for conversion**: A deal in "Signed" has an 89% chance of becoming Joined, which is already reflected in the weighted value.

2. **No double-counting**: The weighted pipeline = `SUM(Margin_AUM × stage_probability)` already gives us the expected value. Multiplying by `sqo_to_joined_conversion_rate` applies a second, redundant conversion factor.

3. **More accurate capacity assessment**: Using the weighted pipeline directly will give more realistic capacity estimates that better reflect actual pipeline value.

### Expected Impact

- **Capacity estimates will increase** (more realistic, less conservative)
- **Coverage ratios will improve** (better assessment of pipeline sufficiency)
- **Better alignment with actual results** (weighted pipeline should correlate better with actual joined Margin_AUM)

### Example Comparison

**Current Method (Double-Counting):**
- Deal: $10M Margin_AUM in "Negotiating" (36.4% stage probability)
- Weighted: $10M × 0.364 = $3.64M
- Then: $3.64M × 0.156 (conversion rate) = **$0.57M** ❌ Too conservative

**Recommended Method (Correct):**
- Deal: $10M Margin_AUM in "Negotiating" (36.4% stage probability)
- Weighted: $10M × 0.364 = **$3.64M** ✅ Expected value

