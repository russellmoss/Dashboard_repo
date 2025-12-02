# Contacted to MQL Conversion Rate Definition

**Source Views:**
- `vw_funnel_lead_to_joined_v2.sql`
- `vw_sga_funnel.sql`

---

## Definition

The **Contacted → MQL conversion rate** is a **progression-based metric** that measures:

**Numerator:** Leads that have entered BOTH stages:
- `stage_entered_contacting__c IS NOT NULL` (Contacted stage)
- `Stage_Entered_Call_Scheduled__c IS NOT NULL` (MQL stage)

**Denominator:** Leads that have entered the Contacted stage:
- `stage_entered_contacting__c IS NOT NULL`

---

## Code Implementation

### In `vw_funnel_lead_to_joined_v2.sql`:

```sql
-- Binary flags
CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
```

### In `vw_sga_funnel.sql`:

```sql
-- Binary flags (same definitions)
CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,

-- Progression flag
CASE WHEN eligible_for_contacted_conversions = 1 AND is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression
```

Where `eligible_for_contacted_conversions` = `CASE WHEN is_contacted = 1 THEN 1 ELSE 0 END`

---

## How It Works

### Stage Entry Timestamps

1. **Contacted Stage:**
   - **Field:** `stage_entered_contacting__c` (timestamp)
   - **Meaning:** The lead entered the "Contacted" stage (initial outreach made)
   - **Binary Flag:** `is_contacted = 1` when this timestamp exists

2. **MQL Stage:**
   - **Field:** `Stage_Entered_Call_Scheduled__c` (timestamp, aliased as `mql_stage_entered_ts`)
   - **Meaning:** The lead entered the "MQL" stage (call scheduled)
   - **Binary Flag:** `is_mql = 1` when this timestamp exists

### Conversion Rate Calculation

```sql
Contacted → MQL Conversion Rate = 
  COUNT(DISTINCT leads WHERE is_contacted = 1 AND is_mql = 1)
  / 
  COUNT(DISTINCT leads WHERE is_contacted = 1)
```

**Example:**
- 1,000 leads entered "Contacted" stage (`stage_entered_contacting__c IS NOT NULL`)
- 350 of those also entered "MQL" stage (`Stage_Entered_Call_Scheduled__c IS NOT NULL`)
- **Conversion Rate = 350 / 1,000 = 35%**

---

## Key Characteristics

### 1. **Progression-Based (Not Date-Window Based)**

This is **NOT** a time-bound conversion window (e.g., "MQLs that became SQLs within 30 days").

Instead, it's a **progression-based metric**:
- If a lead has entered both stages (regardless of when), they count as converted
- There's no time limit between stages
- The conversion is binary: either the lead progressed or they didn't

### 2. **Normal Progression**

In most cases, the progression follows this order:
```
Created → Contacted (stage_entered_contacting__c) → MQL (Stage_Entered_Call_Scheduled__c) → SQL → SQO
```

**Expected timing:**
- `stage_entered_contacting__c` happens first
- `Stage_Entered_Call_Scheduled__c` happens later (or same day)
- Days between: Usually 0-7 days, but can be longer

### 3. **Anomalies Handled**

The views handle edge cases:
- Leads that enter MQL without being "Contacted" (entered at MQL stage directly)
- Leads that are contacted but never become MQL (stay in denominator, not numerator)

---

## Why This Approach?

1. **Business Logic:**
   - The "Contacted" stage represents initial outreach
   - The "MQL" stage represents qualified interest (call scheduled)
   - Conversion rate measures: "Of leads we contacted, how many scheduled a call?"

2. **Data Quality:**
   - Uses stage entry timestamps, which are reliable milestone markers
   - Avoids issues with date attribution mismatches
   - Binary flags make aggregation simple

3. **Consistency:**
   - Same definition across both views
   - Progression flags in `vw_sga_funnel.sql` enable easy conversion rate calculations in BI tools

---

## Usage in Forecasting

For forecasting models:
- This conversion rate can be used to predict MQLs from contacted leads
- It's a **milestone-based** conversion, not time-bound
- When forecasting, you'd apply this rate to predicted "Contacted" volume to get predicted "MQL" volume

---

**Status:** ✅ Definition Documented

