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
- `eligible_for_sqo_conversions`: Prospects who actually became SQOs

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

### 5. Contact → SQO % (Overall)
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

## Why This Matters: Statistical Interpretation

### Understanding Conversion Rates

A conversion rate is fundamentally asking: **"Given that someone reached Stage A, what's the probability they'll reach Stage B?"**

### Statistical Requirements

For this probability to be meaningful, we need:

1. **Proper Denominator**: Only count prospects who actually reached Stage A
2. **Proper Numerator**: Only count prospects who progressed from A → B
3. **Exclusion of Direct Entries**: Don't count people who started at Stage B

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

---

## Summary

**The Problem**: Traditional conversion rates were inflated because they didn't account for prospects entering the funnel at different stages.

**The Solution**: We track actual progressions between stages and only count prospects in conversion rates when they've actually progressed from the previous stage.

**The Result**: Accurate, meaningful conversion rates that:
- Stay between 0% and 100%
- Reflect true business performance
- Provide actionable insights
- Enable fair performance comparison

**Key Takeaway**: When measuring conversion rates, always ensure your numerator and denominator represent the same population - prospects who actually had the opportunity to convert!
