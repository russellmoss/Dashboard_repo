# SGM Capacity Calculation - What's Included/Excluded

## `sgm_capacity_expected_joined_aum_millions_estimate` Breakdown

### Formula:
```
Capacity = Active Weighted Pipeline Value × SQO→Joined Conversion Rate
```

Where:
- **Active Weighted Pipeline Value** = `current_pipeline_active_weighted_margin_aum_estimate`
- **SQO→Joined Conversion Rate** = Historical conversion rate for that SGM

---

## What's INCLUDED:

### ✅ Active SQOs Only
- Must have `SQL__c = 'yes'` (is an SQO)
- Must be in pipeline (`is_in_pipeline = 1`)

### ✅ Non-Stale Deals Only
- SQO date must be **≤ 120 days** from today
- OR SQO date is NULL (new deals without SQO date yet)
- **Excludes**: SQOs older than 120 days

### ✅ Pipeline Filters Applied
- `IsClosed = FALSE` (not closed)
- `advisor_join_date__c IS NULL` (not already joined)
- `StageName != 'Closed Lost'` ✅ **Excludes Closed Lost**
- `StageName != 'On Hold'` ✅ **Excludes On Hold**
- `StageName IS NOT NULL` (must have a stage)

### ✅ Stage Probability Weighting
- Each deal's estimated margin AUM is multiplied by its stage probability
- Example: $1M deal in "Negotiating" (70% prob) = $0.7M weighted value
- Example: $1M deal in "Discovery" (10% prob) = $0.1M weighted value

### ✅ Estimated Margin AUM
- Uses fallback logic when `Margin_AUM__c` is missing:
  1. Use actual `Margin_AUM__c` if available
  2. If not, use `Underwritten_AUM__c / 3.125`
  3. If not, use `Amount / 3.22`

### ✅ Conversion Rate Applied
- Multiplies by historical SQO→Joined conversion rate
- This converts pipeline value to expected joined value

---

## What's EXCLUDED:

### ❌ Closed Deals
- `IsClosed = TRUE` → Excluded

### ❌ Already Joined Deals
- `advisor_join_date__c IS NOT NULL` → Excluded

### ❌ "On Hold" Stage
- `StageName = 'On Hold'` → Excluded ✅

### ❌ "Closed Lost" Stage
- `StageName = 'Closed Lost'` → Excluded ✅

### ❌ Stale Deals
- SQOs with `sqo_age_days > 120` → Excluded ✅
- Only includes deals where SQO date is ≤ 120 days from today

### ❌ Non-SQOs
- Deals where `SQL__c != 'yes'` → Excluded
- Only SQOs are included in capacity calculation

### ❌ NULL Stages
- `StageName IS NULL` → Excluded

---

## SQL Logic Trace:

### Step 1: Define `is_in_pipeline`
```sql
CASE 
  WHEN o.IsClosed = FALSE 
    AND o.advisor_join_date__c IS NULL 
    AND o.StageName != 'Closed Lost'      -- ✅ Excludes Closed Lost
    AND o.StageName != 'On Hold'          -- ✅ Excludes On Hold
    AND o.StageName IS NOT NULL
  THEN 1 
  ELSE 0 
END AS is_in_pipeline
```

### Step 2: Calculate Active Weighted Pipeline Value
```sql
SUM(CASE 
  WHEN o.is_sqo = 1                        -- ✅ Only SQOs
    AND o.is_in_pipeline = 1               -- ✅ Pipeline filters applied
    AND (o.sqo_age_days IS NULL OR o.sqo_age_days <= 120)  -- ✅ Excludes stale (>120 days)
  THEN o.estimated_margin_aum * o.stage_probability
  ELSE 0 
END) AS current_pipeline_active_weighted_margin_aum_estimate
```

### Step 3: Calculate Capacity
```sql
current_pipeline_active_weighted_margin_aum_estimate * sqo_to_joined_conversion_rate
```

---

## Example: Bre McDaniel

From the data:
- **Active Weighted Pipeline**: $148.07M (non-stale, weighted by stage)
- **Total Weighted Pipeline**: $263.51M (includes stale)
- **Stale Portion**: $115.43M (excluded from capacity)
- **Conversion Rate**: 14.78%
- **Capacity**: $148.07M × 14.78% = **$21.89M**

This means:
- Her active (non-stale) pipeline is worth $148.07M weighted value
- After applying 14.78% conversion rate, we expect $21.89M to actually join
- Stale deals ($115.43M) are excluded from this calculation

---

## Summary

**YES**, `sgm_capacity_expected_joined_aum_millions_estimate`:
- ✅ **Excludes** "On Hold" deals
- ✅ **Excludes** "Closed Lost" deals  
- ✅ **Excludes** stale deals (SQO date > 120 days)
- ✅ **Includes** only active SQOs in pipeline
- ✅ **Applies** stage probability weighting
- ✅ **Applies** conversion rate to estimate joined value
- ✅ **Uses** estimated margin AUM (with fallback logic)

**It is an estimate of Margin AUM that will convert to joined from what's currently in the SGM's active (non-stale) pipeline.**

