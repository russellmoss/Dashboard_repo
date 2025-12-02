# Conversion Rate Calculation Logic: Accounting for Multiple Funnel Entry Points

## Executive Summary

This document explains how we calculate conversion rates in the SGA funnel view (`vw_sga_funnel_improved`). The key challenge is that prospects can enter our sales funnel at different stages, which caused traditional conversion rate calculations to produce impossible values (over 100%). We've fixed this by tracking actual progressions between stages rather than just counting stage achievements.

---

## The Problem: Impossible Conversion Rates

### What Was Happening?

Traditional conversion rate calculations were producing rates like:
- **176% Contact → MQL conversion rate** ❌
- **112% Contact → SQO conversion rate** ❌

These rates are mathematically impossible - you can't convert more than 100% of prospects!

### Why Was This Happening?

**The core issue**: Prospects can enter our sales funnel at different stages, but traditional calculations didn't account for this.

**Example Scenario:**
- Jacqueline has **19 prospects** who entered at the "Contacted" stage
- Jacqueline has **22 prospects** who entered directly at the "MQL" stage (skipping "Contacted")
- Traditional calculation: `Total MQLs / Total Contacted = 33 / 19 = 173.68%` ❌

This is wrong because those 22 MQLs were **never contacted**, so they shouldn't be counted in a "Contact to MQL" conversion rate!

---

## Understanding Our Sales Funnel

### Standard Funnel Stages

Our sales funnel has four main stages:

1. **Prospect** - A lead exists in our system
2. **Contacted** - We've reached out to the prospect
3. **MQL (Marketing Qualified Lead)** - Prospect scheduled a call
4. **SQL (Sales Qualified Lead)** - Prospect converted to an opportunity
5. **SQO (Sales Qualified Opportunity)** - Opportunity became qualified

### How Prospects Can Enter the Funnel

Unlike a simple linear funnel, prospects can enter at different stages:

| Entry Point | Description | Example Sources |
|------------|-------------|-----------------|
| **Prospect** | Standard entry point | Most inbound leads |
| **Contacted** | Enters directly at contacted | Event attendees, some referrals |
| **MQL** | Enters directly as MQL | Recruitment firms, self-sourced LinkedIn |
| **SQL** | Enters directly as SQL | Re-engagement campaigns |
| **SQO** | Enters directly as SQO | High-value direct opportunities |

### Why Do Different Entry Points Exist?

Different sources have different engagement patterns:
- **Recruitment Firms**: Often provide pre-qualified leads that skip directly to MQL
- **Re-Engagement**: Past prospects may skip to SQL or SQO
- **Events**: Attendees may enter directly at Contacted or MQL
- **Advisor Referrals**: May enter at various stages depending on relationship

---

## The Solution: Tracking Actual Progressions

### Core Concept

Instead of asking "How many MQLs are there?" we ask **"How many prospects actually progressed from Contacted to MQL?"**

### Key Components

Our improved view includes several flags to track this properly:

#### 1. **Eligibility Flags** (Denominators)
These identify which records should be included in conversion rate denominators:

- `eligible_for_contacted_conversions`: Prospects who were actually contacted
- `eligible_for_mql_conversions`: Prospects who actually became MQLs
- `eligible_for_sql_conversions`: Prospects who actually became SQLs
- `eligible_for_sqo_conversions`: **UPDATED** - Only SQOs with final outcome (Joined or Closed Lost) - excludes open SQOs

#### 2. **Progression Flags** (Numerators)
These identify actual movements between stages:

- `contacted_to_mql_progression`: Contacted AND became MQL
- `contacted_to_sql_progression`: Contacted AND became SQL
- `contacted_to_sqo_progression`: Contacted AND became SQO
- `mql_to_sql_progression`: MQL AND became SQL
- `mql_to_sqo_progression`: MQL AND became SQO
- `sql_to_sqo_progression`: SQL AND became SQO

#### 3. **Funnel Entry Point**
A descriptive field that tells us how each prospect entered:

- `"Entered at MQL"`: Skipped Contacted, started at MQL
- `"Entered at SQL"`: Skipped to SQL
- `"Entered at SQO"`: Skipped directly to SQO
- `"Normal flow: Contacted → MQL"`: Standard progression
- And other combinations...

---

## How Conversion Rates Are Calculated

### General Formula

For any conversion rate from Stage A to Stage B:

```
Conversion Rate = (Prospects who progressed from A → B) / (Prospects eligible at Stage A) × 100
```

### Specific Examples

#### 1. Contact → MQL Conversion Rate

**Old (Broken) Formula:**
```
Total MQLs / Total Contacted × 100
= 33 / 19 × 100
= 173.68% ❌ (Impossible!)
```

**New (Correct) Formula:**
```
contacted_to_mql_progression / eligible_for_contacted_conversions × 100
= 11 / 19 × 100
= 57.89% ✅ (Makes sense!)
```

**What Changed:**
- **Numerator**: Only counts the 11 prospects who were contacted AND became MQL
- **Denominator**: Only counts the 19 prospects who were actually contacted
- **Excluded**: The 22 prospects who entered directly at MQL (never contacted)

#### 2. SQL → SQO Conversion Rate

**Old (Broken) Formula:**
```
Total SQOs / Total SQLs × 100
= 355 / 525 × 100
= 67.62%
```

**New (Correct) Formula:**
```
sql_to_sqo_progression / eligible_for_sql_conversions × 100
= 333 / 525 × 100
= 63.43% ✅
```

**What Changed:**
- **Numerator**: Only counts SQLs that progressed to SQO (excludes direct SQO entries)
- **Denominator**: Counts all SQLs (including those that later became SQO)
- **Result**: More accurate rate showing true SQL→SQO progression

#### 3. SQO → Joined Conversion Rate (Updated Logic)

**Previous (Incomplete) Formula:**
```
Total Joined / Total SQOs × 100
= 30 / 100 × 100
= 30%
```
This included open SQOs in the denominator, which artificially lowered the rate.

**New (Correct) Formula:**
```
Total Joined / (Total Joined + Total Closed Lost) × 100
= 30 / (30 + 20) × 100
= 60% ✅
```

**What Changed:**
- **Numerator**: Counts SQOs that became Joined (unchanged)
- **Denominator**: **UPDATED** - Only counts SQOs with final outcome (Joined OR Closed Lost)
- **Excluded**: Open SQOs that haven't reached a final outcome yet
- **Result**: More accurate rate showing true SQO→Joined conversion for completed opportunities

**Why This Matters:**
- Open SQOs haven't had time to convert yet, so including them biases the rate downward
- Only counting opportunities with final outcomes gives a true historical conversion rate
- This rate is used for capacity planning and forecasting, so accuracy is critical

---

## Complete Conversion Rate Formulas

Here are all the conversion rate formulas we use:

### 1. Prospect → Contact %
```
SUM(is_contacted) / COUNT(*) × 100
```
**Meaning**: What percentage of all prospects were contacted?

### 2. Contact → MQL % (Corrected)
```
SUM(contacted_to_mql_progression) / SUM(eligible_for_contacted_conversions) × 100
```
**Meaning**: Of prospects who were contacted, what percentage became MQLs?

### 3. MQL → SQL %
```
SUM(mql_to_sql_progression) / SUM(eligible_for_mql_conversions) × 100
```
**Meaning**: Of prospects who became MQLs, what percentage became SQLs?

### 4. SQL → SQO %
```
SUM(sql_to_sqo_progression) / SUM(eligible_for_sql_conversions) × 100
```
**Meaning**: Of prospects who became SQLs, what percentage became SQOs?

### 5. SQO → Joined % (Updated - Excludes Open SQOs)
```
SUM(sqo_to_joined_numerator) / SUM(sqo_to_joined_denominator) × 100
```
**Where:**
- `sqo_to_joined_numerator`: SQOs that became Joined
- `sqo_to_joined_denominator`: **UPDATED** - Only SQOs with final outcome (Joined OR Closed Lost)

**SQL Implementation:**
```sql
-- Numerator: SQOs that became Joined
COUNT(DISTINCT CASE 
  WHEN is_sqo = 1 AND is_joined = 1 
  THEN Full_Opportunity_ID__c 
END) AS sqo_to_joined_numerator

-- Denominator: Only SQOs with final outcome (Joined OR Closed Lost)
COUNT(DISTINCT CASE 
  WHEN is_sqo = 1 
    AND (is_joined = 1 OR StageName = 'Closed Lost')
  THEN Full_Opportunity_ID__c 
END) AS sqo_to_joined_denominator
```

**Meaning**: Of SQOs that reached a final outcome, what percentage became Joined?

**Key Difference**: This excludes open SQOs from the denominator because they haven't had time to reach a final outcome yet.

### 6. Contact → SQO % (Overall)
```
SUM(contacted_to_sqo_progression) / SUM(eligible_for_contacted_conversions) × 100
```
**Meaning**: Of prospects who were contacted, what percentage reached SQO?

---

## Real-World Example

Let's trace through Jacqueline Tully's data (July-September 2025) to see how this works:

### The Data
- **Total Prospects**: 44
- **Entered at Contacted**: 19 prospects
- **Entered at MQL**: 22 prospects (never contacted!)
- **Entered other ways**: 3 prospects

### Stage Counts
- **Total Contacted**: 19
- **Total MQL**: 33 (19 + 22 who entered directly + others)
- **Total SQL**: 20
- **Total SQO**: 19

### Traditional (Broken) Calculation
```
Contact → MQL = 33 / 19 = 173.68% ❌
```
This is wrong because it includes the 22 prospects who skipped Contacted!

### Corrected Calculation
```
Contact → MQL = contacted_to_mql_progression / eligible_for_contacted
              = 11 / 19
              = 57.89% ✅
```
This correctly shows: "Of the 19 prospects we contacted, 11 became MQLs"

---

## Excluding Open Opportunities: Final Outcome Logic

### The Problem with Open Opportunities

When calculating conversion rates for post-SQO stages (especially SQO → Joined), including open opportunities in the denominator creates a significant bias:

**Example Scenario:**
- 100 SQOs total
- 30 became Joined
- 20 became Closed Lost
- 50 are still open (haven't reached final outcome)

**Old (Incorrect) Calculation:**
```
SQO → Joined = 30 / 100 = 30%
```
This is misleading because the 50 open SQOs haven't had time to convert yet!

**New (Correct) Calculation:**
```
SQO → Joined = 30 / (30 + 20) = 60%
```
This shows the true conversion rate for opportunities that have reached a final outcome.

### Why We Exclude Open Opportunities

1. **Time Bias**: Open opportunities haven't had time to reach a final outcome
2. **Incomplete Data**: We don't know if they'll join or close lost yet
3. **Historical Accuracy**: Conversion rates should reflect completed journeys, not in-progress ones
4. **Forecasting Accuracy**: Using rates that include open opportunities underestimates true conversion potential

### Implementation: Final Outcome Logic

We define a "final outcome" as an opportunity that has either:
- **Joined**: `advisor_join_date__c IS NOT NULL`
- **Closed Lost**: `StageName = 'Closed Lost'`

**Open opportunities** are those that:
- Are still active (`IsClosed = FALSE`)
- Haven't joined (`advisor_join_date__c IS NULL`)
- Aren't closed lost (`StageName != 'Closed Lost'`)
- Aren't on hold (`StageName != 'On Hold'`)

### Where This Logic Applies

This exclusion logic is implemented in the following views:

1. **`vw_conversion_rates`**: SQO → Joined conversion rate denominator
2. **`vw_sga_funnel`**: SQO eligibility flags
3. **`vw_sga_funnel_team_agg`**: SQO eligibility flags
4. **`vw_forecast_vs_actuals`**: SQO denominator for trailing conversion rates
5. **`vw_experimentation_tag_performance`**: SQO denominator for tag performance
6. **`vw_sgm_capacity_model_refined`**: SQO → Joined conversion rates (enterprise, standard, and historical)
7. **`vw_stage_to_joined_probability`**: Stage probability denominators (all stages)

### Example: Stage Probability Calculation

**Before (Including Open Opportunities):**
- 100 opportunities reached "Negotiating" stage
- 30 became Joined
- 20 became Closed Lost
- 50 are still open in Negotiating
- Probability = 30 / 100 = 30% ❌

**After (Excluding Open Opportunities):**
- 50 opportunities reached "Negotiating" with final outcome (30 Joined + 20 Closed Lost)
- 30 became Joined
- Probability = 30 / 50 = 60% ✅

This more accurately reflects the true probability of joining for opportunities that have completed their journey.

### Impact on Capacity Planning

This logic is critical for capacity planning because:

1. **Required SQOs Calculation**: Uses SQO → Joined conversion rate to determine how many SQOs are needed
2. **Pipeline Weighting**: Uses stage probabilities to weight pipeline values
3. **Forecasting**: More accurate rates lead to better forecasts

**Example:**
- If conversion rate is 30% (including open): Need 100 SQOs to get 30 Joined
- If conversion rate is 60% (excluding open): Need 50 SQOs to get 30 Joined

The difference significantly impacts capacity planning and resource allocation!

---

## Why This Matters: Statistical Interpretation

### Understanding Conversion Rates

A conversion rate is fundamentally asking: **"Given that someone reached Stage A, what's the probability they'll reach Stage B?"**

### Statistical Requirements

For this probability to be meaningful, we need:

1. **Proper Denominator**: Only count prospects who actually reached Stage A
2. **Proper Numerator**: Only count prospects who progressed from A → B
3. **Exclusion of Direct Entries**: Don't count people who started at Stage B
4. **Exclusion of Open Opportunities**: **NEW** - For post-SQO stages, only count opportunities with final outcomes (Joined or Closed Lost)

### Example: Why Direct Entries Matter

Imagine you're measuring "Contact → MQL" conversion:

**Scenario A (Wrong):**
- 100 people contacted → 50 became MQL = 50% conversion ✅
- But you also have 50 people who entered directly as MQL
- Wrong calculation: (50 + 50) / 100 = 100% ❌

**Scenario B (Right):**
- 100 people contacted → 50 became MQL
- 50 people entered directly as MQL (shouldn't be counted)
- Correct calculation: 50 / 100 = 50% ✅

The direct MQL entries tell you about a different process (maybe recruitment firms are more effective), but they shouldn't inflate your "contact effectiveness" metric!

---

## Implementation in Looker

In Looker, we use these formulas as calculated fields:

```sql
-- Contact to MQL Rate (Corrected)
ROUND(SUM(contacted_to_mql_progression) * 100.0 / NULLIF(SUM(eligible_for_contacted_conversions), 0), 2)

-- SQL to SQO Rate
ROUND(SUM(sql_to_sqo_progression) * 100.0 / NULLIF(SUM(eligible_for_sql_conversions), 0), 2)

-- And so on...
```

**Key Components:**
- `NULLIF(denominator, 0)`: Prevents division by zero errors
- `* 100.0`: Converts decimal to percentage
- `ROUND(..., 2)`: Rounds to 2 decimal places

---

## Benefits of This Approach

### ✅ Accurate Metrics
- Conversion rates stay between 0% and 100%
- Reflects true business performance
- Comparable across time periods and SGAs

### ✅ Better Insights
- Understand which sources have different entry patterns
- Identify opportunities in funnel stages
- More accurate forecasting

### ✅ Fair Performance Measurement
- SGAs working with "easier" sources (direct MQL) aren't penalized
- SGAs working with "harder" sources are fairly evaluated
- Better performance attribution

---

## Common Questions

### Q: Why not just exclude direct entries from the calculation?

**A**: We do exclude them from the numerator, but we need to understand them separately. The `funnel_entry_point` field helps us analyze source behavior and understand why different sources perform differently.

### Q: What if someone is both contacted AND entered directly at MQL?

**A**: This shouldn't happen in practice, but our logic handles it: if `is_contacted = 1` and `is_mql = 1`, they're counted as "Normal flow: Contacted → MQL" and included in conversion rates.

### Q: Can conversion rates still exceed 100%?

**A**: No! With our corrected formulas, conversion rates will always be between 0% and 100% because:
- Numerator counts progressions (can't exceed denominator)
- Denominator counts eligible records (only those at the starting stage)

### Q: How do we handle NULL values?

**A**: Our eligibility flags convert NULL to 0, and progression flags only count 1 when both stages are achieved. The `NULLIF(denominator, 0)` prevents division by zero.

### Q: Why exclude open SQOs from conversion rate calculations?

**A**: Open SQOs haven't reached a final outcome yet, so including them in the denominator:
- Artificially lowers the conversion rate (makes it look worse than it is)
- Creates time bias (newer SQOs haven't had time to convert)
- Makes historical rates less accurate for forecasting
- Biases capacity planning calculations

By only counting SQOs with final outcomes (Joined or Closed Lost), we get a true historical conversion rate that reflects completed journeys.

### Q: Does this apply to all conversion rates or just SQO → Joined?

**A**: This logic primarily applies to:
- **SQO → Joined conversion rates**: Excludes open SQOs from denominator
- **Stage probabilities**: Excludes open opportunities from probability calculations (in `vw_stage_to_joined_probability`)

For earlier stages (Contact → MQL, MQL → SQL, etc.), we use progression flags which naturally handle the timing correctly.

### Q: What if an SQO is very new - shouldn't we wait before counting it?

**A**: We don't wait - we only count opportunities that have reached a **final outcome**. If an SQO is new and still open, it's excluded from the conversion rate calculation until it either joins or becomes closed lost. This ensures our rates reflect completed journeys, not in-progress ones.

### Q: How does this affect capacity planning?

**A**: This significantly improves capacity planning accuracy:
- **More accurate conversion rates** → Better calculation of required SQOs
- **More accurate stage probabilities** → Better pipeline weighting
- **Better forecasting** → More reliable predictions

For example, if the true conversion rate is 60% (excluding open) but we calculated 30% (including open), we'd plan for 2x more SQOs than actually needed!

---

## Summary

**The Problem**: Traditional conversion rates had two major issues:
1. **Multiple Entry Points**: Prospects can enter at different stages, causing rates to exceed 100%
2. **Open Opportunities**: Including open SQOs/opportunities in denominators artificially lowered conversion rates

**The Solution**: We use a two-part approach:
1. **Progression Tracking**: Track actual progressions between stages and only count prospects when they've actually progressed from the previous stage
2. **Final Outcome Logic**: For post-SQO conversion rates and stage probabilities, only count opportunities with final outcomes (Joined or Closed Lost), excluding open opportunities

**The Result**: Accurate, meaningful conversion rates that:
- Stay between 0% and 100%
- Reflect true business performance for completed journeys
- Provide actionable insights
- Enable fair performance comparison
- Support accurate capacity planning and forecasting

**Key Takeaways**: 
1. When measuring conversion rates, always ensure your numerator and denominator represent the same population - prospects who actually had the opportunity to convert
2. For post-SQO stages, only count opportunities with final outcomes to avoid time bias and get accurate historical rates
3. This logic is critical for capacity planning, as inaccurate rates lead to incorrect resource allocation

**Views Using This Logic:**
- `vw_conversion_rates` - SQO → Joined conversion rates
- `vw_sga_funnel` - SQO eligibility flags
- `vw_sga_funnel_team_agg` - SQO eligibility flags  
- `vw_forecast_vs_actuals` - Trailing conversion rate denominators
- `vw_experimentation_tag_performance` - Tag performance conversion rates
- `vw_sgm_capacity_model_refined` - SGM capacity and required SQOs calculations
- `vw_stage_to_joined_probability` - Stage probability calculations
