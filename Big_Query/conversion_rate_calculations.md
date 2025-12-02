# Conversion Rate Calculations Documentation

**Date:** November 2025  
**Purpose:** Comprehensive guide to conversion rate calculations across the entire sales funnel, including post-SQO Opportunity stages

---

## Table of Contents

1. [Current Conversion Rate Methodology](#current-conversion-rate-methodology)
2. [Funnel Stages and Definitions](#funnel-stages-and-definitions)
3. [Opportunity Stage Progression](#opportunity-stage-progression)
4. [Stage Skipping Analysis](#stage-skipping-analysis)
5. [Conversion Rate Calculation Logic](#conversion-rate-calculation-logic)
6. [Implementation for New View](#implementation-for-new-view)

---

## Current Conversion Rate Methodology

### Overview

**✅ RECOMMENDED: Progression-Based Conversion Rates**

Our conversion rate calculations use **progression-based logic** to avoid inflation from prospects who enter the funnel at different stages. This approach ensures that:

1. **Only true progressions are counted** - A prospect must have entered the prior stage to be eligible for conversion from that stage
2. **Stage entry tracking** - We track when prospects enter each stage using timestamp fields
3. **Opportunity-level tracking** - Post-SQO conversions are tracked at the Opportunity level using `Full_Opportunity_ID__c`

**Why Progression-Based is Preferred:**

- **Prevents Inflation:** Simple `SUM(is_sql)/SUM(is_mql)` can be inflated if leads enter directly at SQL stage (skipping MQL)
- **Accurate Stage-to-Stage Rates:** Only counts SQLs that actually came from MQLs, not all SQLs
- **Consistent with Business Logic:** Measures true progression through the funnel stages
- **Used in Production:** `vw_sga_funnel_team_agg.sql` implements this as "corrected" rates

**Critical Distinction - Date Attribution Methods:**

1. **✅ Progression-based (Recommended):** Uses progression flags to ensure only true stage-to-stage progressions are counted, accounting for prospects who enter at different stages. Formula: `SUM(mql_to_sql_progression) / SUM(eligible_for_mql_conversions)`

2. **⚠️ FilterDate-based (Dashboard Method - Legacy):** Uses `DATE(FilterDate)` to filter leads by when they entered the funnel. Conversion rates are calculated as `SUM(is_sql)/SUM(is_mql)` for all leads in that FilterDate cohort. **Can be inflated** if leads enter at different stages.

3. **Event-date-based:** Uses the actual event dates (e.g., `DATE(mql_stage_entered_ts)`, `DATE(converted_date_raw)`) to count events that occurred in a specific period. Useful for time-series analysis.

### Implementation in Current Views

#### `vw_sga_funnel.sql` and `vw_sga_funnel_team_agg.sql`

These views implement progression-based conversion rates using:

1. **Eligibility Flags** - Determine if a record is eligible to be counted in a conversion rate denominator:
   ```sql
   CASE WHEN is_contacted = 1 THEN 1 ELSE 0 END AS eligible_for_contacted_conversions
   CASE WHEN is_mql = 1 THEN 1 ELSE 0 END AS eligible_for_mql_conversions
   CASE WHEN is_sql = 1 THEN 1 ELSE 0 END AS eligible_for_sql_conversions
   CASE WHEN is_sqo = 1 THEN 1 ELSE 0 END AS eligible_for_sqo_conversions
   ```

2. **Progression Flags** - Track actual progressions between stages:
   ```sql
   CASE WHEN eligible_for_contacted_conversions = 1 AND is_mql = 1 THEN 1 ELSE 0 END AS contacted_to_mql_progression
   CASE WHEN eligible_for_mql_conversions = 1 AND is_sql = 1 THEN 1 ELSE 0 END AS mql_to_sql_progression
   CASE WHEN eligible_for_sql_conversions = 1 AND is_sqo = 1 THEN 1 ELSE 0 END AS sql_to_sqo_progression
   ```

3. **Conversion Rate Calculation**:
   ```sql
   Conversion_Rate = SUM(progression_flag) / SUM(eligible_for_source_stage)
   ```

#### `vw_sga_funnel.sql` (Dashboard Method - FilterDate-based)

**⚠️ Legacy Method - Use with Caution**

This view uses **FilterDate** for date attribution and calculates conversion rates as simple sums:

1. **MQL → SQL** (Dashboard calculation):
   ```sql
   mql_to_sql_rate = SUM(is_sql) / SUM(is_mql)
   ```
   Where leads are filtered by `DATE(FilterDate)` in the selected period.

   **Example:** For Q3 2025 (FilterDate between July 1 - Sep 30):
   - 202 SQLs / 601 MQLs = **33.61%** (or ~36% on dashboard depending on aggregation)

2. **Limitation:** This method counts all SQLs and MQLs for leads that entered the funnel in the period, regardless of when the MQL/SQL events actually occurred. **Can be inflated** if leads enter at different stages.

3. **Recommendation:** For new implementations, use the progression-based method from `vw_sga_funnel_team_agg.sql` instead.

#### `vw_forecast_vs_actuals.sql`

This view uses a **direct counting approach with event dates**:

1. **Contacted → MQL**:
   ```sql
   COUNT(DISTINCT IF(is_contacted = 1 AND is_mql = 1, Full_prospect_id__c, NULL)) AS num_c2m
   COUNT(DISTINCT IF(is_contacted = 1, Full_prospect_id__c, NULL)) AS den_contacted
   c2m_rate = SAFE_DIVIDE(num_c2m, den_contacted)
   ```

2. **MQL → SQL**:
   ```sql
   COUNT(DISTINCT IF(is_mql = 1 AND is_sql = 1, Full_prospect_id__c, NULL)) AS num_m2s
   COUNT(DISTINCT IF(is_mql = 1, Full_prospect_id__c, NULL)) AS den_mql
   m2s_rate = SAFE_DIVIDE(num_m2s, den_mql)
   ```
   **Note:** Uses event dates (`DATE(mql_stage_entered_ts)`, `DATE(converted_date_raw)`) for filtering.

3. **SQL → SQO**:
   ```sql
   COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                      THEN Full_Opportunity_ID__c END) AS num_s2q
   COUNT(DISTINCT CASE WHEN is_sql = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                      THEN Full_Opportunity_ID__c END) AS den_sql_opp
   s2q_rate = SAFE_DIVIDE(num_s2q, den_sql_opp)
   ```

**Key Difference:** 
- `vw_sga_funnel.sql` uses **FilterDate** for date attribution (when lead entered funnel)
- `vw_forecast_vs_actuals.sql` uses **event dates** (when MQL/SQL events actually occurred)

---

## Funnel Stages and Definitions

### Pre-SQO Stages (Lead-Based)

These stages are tracked on the **Lead** object and use `Full_prospect_id__c` as the identifier.

| Stage | Definition | Flag | Date Anchor | Field Name |
|-------|------------|------|-------------|------------|
| **Prospect** | Lead exists in system | N/A | `DATE(FilterDate)` | `FilterDate` (GREATEST of CreatedDate, stage_entered_new__c, stage_entered_contacting__c) |
| **Contacted** | Lead entered "Contacted" stage | `is_contacted = 1` | `DATE(FilterDate)` | `stage_entered_contacting__c IS NOT NULL` |
| **MQL** | Lead scheduled a call | `is_mql = 1` | `DATE(mql_stage_entered_ts)` | `Stage_Entered_Call_Scheduled__c IS NOT NULL` |
| **SQL** | Lead converted to Opportunity | `is_sql = 1` | `DATE(converted_date_raw)` | `IsConverted = TRUE` |

### Post-SQO Stages (Opportunity-Based)

These stages are tracked on the **Opportunity** object and use `Full_Opportunity_ID__c` as the identifier.

| Stage | Definition | Flag | Date Anchor | Field Name |
|-------|------------|------|-------------|------------|
| **SQO** | Opportunity qualified (business-approved) | `is_sqo = 1` | `DATE(Date_Became_SQO__c)` | `SQL__c = 'Yes' AND Date_Became_SQO__c IS NOT NULL` |
| **Qualifying** | Entry point for SQO opportunities | `is_qualifying = 1` | `DATE(Date_Became_SQO__c)` | `Date_Became_SQO__c IS NOT NULL` (no separate entry field) |
| **Discovery** | Discovery stage entered | `is_discovery = 1` | `DATE(Stage_Entered_Discovery__c)` | `Stage_Entered_Discovery__c IS NOT NULL` |
| **Sales Process** | Sales Process stage entered | `is_sales_process = 1` | `DATE(Stage_Entered_Sales_Process__c)` | `Stage_Entered_Sales_Process__c IS NOT NULL` |
| **Negotiating** | Negotiating stage entered | `is_negotiating = 1` | `DATE(Stage_Entered_Negotiating__c)` | `Stage_Entered_Negotiating__c IS NOT NULL` |
| **Signed** | Signed stage entered | `is_signed = 1` | `DATE(Stage_Entered_Signed__c)` | `Stage_Entered_Signed__c IS NOT NULL` |
| **Joined** | Advisor joined | `is_joined = 1` | `DATE(advisor_join_date__c)` or `DATE(Stage_Entered_Joined__c)` | `advisor_join_date__c IS NOT NULL OR Stage_Entered_Joined__c IS NOT NULL` |

**Note:** `StageName` is the current stage field, but we use the `Stage_Entered_*` timestamp fields for date attribution to track when the opportunity entered each stage.

---

## Opportunity Stage Progression

### Expected Progression Path

```
SQO (Qualifying) → Discovery → Sales Process → Negotiating → Signed → Joined
```

### Stage Entry Fields

All stage entry fields are **TIMESTAMP** fields in the Opportunity object:

- **Qualifying Entry:** `Date_Became_SQO__c` (TIMESTAMP) - This is when the opportunity became SQO, serving as the entry point to Qualifying
- **Discovery Entry:** `Stage_Entered_Discovery__c` (TIMESTAMP)
- **Sales Process Entry:** `Stage_Entered_Sales_Process__c` (TIMESTAMP)
- **Negotiating Entry:** `Stage_Entered_Negotiating__c` (TIMESTAMP)
- **Signed Entry:** `Stage_Entered_Signed__c` (TIMESTAMP)
- **Joined Entry:** `Stage_Entered_Joined__c` (TIMESTAMP) OR `advisor_join_date__c` (DATE)

### Stage Progression Statistics

Based on analysis of SQO opportunities (1,157 total):

| Stage | Count Entered | Percentage of SQOs |
|-------|---------------|-------------------|
| **Qualifying (SQO)** | 1,157 | 100% (all SQOs start here) |
| **Discovery** | 42 | 3.6% |
| **Sales Process** | 485 | 41.9% |
| **Negotiating** | 176 | 15.2% |
| **Signed** | 86 | 7.4% |
| **Joined** | 89 | 7.7% |

---

## Stage Skipping Analysis

### Stage Skipping Patterns

Analysis of 1,157 SQO opportunities shows that **stage skipping is common**, especially for Discovery:

| Skip Pattern | Count | Percentage |
|--------------|-------|------------|
| **No Skip** (Normal progression) | 673 | 58.2% |
| **Skipped Discovery** | 460 | 39.8% |
| **Skipped Sales Process** | 20 | 1.7% |
| **Skipped Negotiating** | 4 | 0.3% |

### Key Insights

1. **Discovery is frequently skipped** - 39.8% of SQO opportunities skip Discovery and go directly to Sales Process
2. **Sales Process and Negotiating are rarely skipped** - Only 1.7% and 0.3% respectively
3. **Most opportunities follow normal progression** - 58.2% follow the expected sequence

### Implications for Conversion Rate Calculation

When calculating conversion rates, we must:

1. **Track eligibility correctly** - An opportunity is only eligible to convert from a stage if it has entered that stage
2. **Handle skipped stages** - If an opportunity skipped Discovery, it should NOT be counted in Discovery → Sales Process conversion rate
3. **Use Opportunity ID tracking** - Use `Full_Opportunity_ID__c` to ensure we're tracking the same opportunity across stages

---

## Conversion Rate Calculation Logic

### Pre-SQO Conversion Rates (Current Implementation)

#### 1. Contacted → MQL

**Eligibility:** `is_contacted = 1`  
**Conversion:** `is_contacted = 1 AND is_mql = 1`  
**Formula:**
```sql
contacted_to_mql_rate = SUM(contacted_to_mql_progression) / SUM(eligible_for_contacted_conversions)
```

**Example:**
- 1,000 leads are contacted (`eligible_for_contacted_conversions = 1`)
- 350 of those also became MQL (`contacted_to_mql_progression = 1`)
- **Rate = 350 / 1,000 = 35%**

#### 2. MQL → SQL

**✅ RECOMMENDED: Progression-Based Formula**

**Eligibility:** `is_mql = 1`  
**Conversion:** `is_mql = 1 AND is_sql = 1`  

**Formula (Progression-Based - Recommended):**
```sql
mql_to_sql_rate = SUM(mql_to_sql_progression) / SUM(eligible_for_mql_conversions)
```

Where:
- `mql_to_sql_progression = CASE WHEN is_mql = 1 AND is_sql = 1 THEN 1 ELSE 0 END`
- `eligible_for_mql_conversions = CASE WHEN is_mql = 1 THEN 1 ELSE 0 END`

This ensures only SQLs that came from MQLs are counted, preventing inflation from leads that enter directly at SQL stage.

**⚠️ Alternative Methods (Legacy/Dashboard):**

1. **FilterDate-based (Dashboard Method):**
   ```sql
   mql_to_sql_rate = SUM(is_sql) / SUM(is_mql)
   ```
   - Used in `vw_sga_funnel.sql` for dashboard simplicity
   - Counts all SQLs divided by all MQLs for leads where `DATE(FilterDate)` is in the selected period
   - **Can be inflated** if leads enter at different stages
   - Example Q3 2025: 202 SQLs / 601 MQLs = **33.61%**

2. **Event-date-based:**
   - Counts MQLs/SQLs based on when the event occurred (e.g., `DATE(mql_stage_entered_ts)`)
   - Example Q3 2025: 221 SQLs from MQLs / 547 MQLs = **40.4%**

**Recommendation:** Use progression-based for accurate stage-to-stage conversion rates. FilterDate-based can be used for dashboard simplicity but should be understood as potentially inflated.

#### 3. SQL → SQO

**Eligibility:** `is_sql = 1` (opportunity created) AND `Full_Opportunity_ID__c IS NOT NULL`  
**Conversion:** `is_sql = 1 AND is_sqo = 1` (opportunity has `SQL__c = 'Yes'` and `Date_Became_SQO__c IS NOT NULL`)  
**Formula:**
```sql
sql_to_sqo_rate = COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                                     THEN Full_Opportunity_ID__c END) 
                  / COUNT(DISTINCT CASE WHEN is_sql = 1 AND Full_Opportunity_ID__c IS NOT NULL 
                                       THEN Full_Opportunity_ID__c END)
```

**Note:** 
- Uses `COUNT(DISTINCT Full_Opportunity_ID__c)` because one Lead can convert to one Opportunity, but we track at the Opportunity level for SQO
- The `Full_Opportunity_ID__c IS NOT NULL` check ensures we only count SQLs that have converted to opportunities (as implemented in `vw_forecast_vs_actuals.sql`)

### Post-SQO Conversion Rates (New Implementation Needed)

#### 4. SQO (Qualifying) → Discovery

**Eligibility:** `is_sqo = 1` (opportunity became SQO)  
**Conversion:** `is_sqo = 1 AND is_discovery = 1`  
**Date Anchor:** 
- Denominator: `DATE(Date_Became_SQO__c)`
- Numerator: `DATE(Stage_Entered_Discovery__c)`

**Formula:**
```sql
sqo_to_discovery_rate = COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_discovery = 1 THEN Full_Opportunity_ID__c END)
                        / COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)
```

**Handling Skipped Stages:** 
- If an opportunity skips Discovery (goes directly to Sales Process), it should NOT be counted in Discovery numerator
- However, it should still be in the denominator (they were eligible for Discovery)

#### 5. Discovery → Sales Process

**Eligibility:** `is_discovery = 1` (opportunity entered Discovery stage)  
**Conversion:** `is_discovery = 1 AND is_sales_process = 1`  
**Date Anchor:**
- Denominator: `DATE(Stage_Entered_Discovery__c)`
- Numerator: `DATE(Stage_Entered_Sales_Process__c)`

**Formula:**
```sql
discovery_to_sales_process_rate = COUNT(DISTINCT CASE WHEN is_discovery = 1 AND is_sales_process = 1 THEN Full_Opportunity_ID__c END)
                                   / COUNT(DISTINCT CASE WHEN is_discovery = 1 THEN Full_Opportunity_ID__c END)
```

**Handling Skipped Stages:**
- Opportunities that skip Discovery are NOT eligible for this conversion rate
- Only count opportunities that actually entered Discovery

#### 6. Sales Process → Negotiating

**Eligibility:** `is_sales_process = 1` (opportunity entered Sales Process stage)  
**Conversion:** `is_sales_process = 1 AND is_negotiating = 1`  
**Date Anchor:**
- Denominator: `DATE(Stage_Entered_Sales_Process__c)`
- Numerator: `DATE(Stage_Entered_Negotiating__c)`

**Formula:**
```sql
sales_process_to_negotiating_rate = COUNT(DISTINCT CASE WHEN is_sales_process = 1 AND is_negotiating = 1 THEN Full_Opportunity_ID__c END)
                                     / COUNT(DISTINCT CASE WHEN is_sales_process = 1 THEN Full_Opportunity_ID__c END)
```

#### 7. Negotiating → Signed

**Eligibility:** `is_negotiating = 1` (opportunity entered Negotiating stage)  
**Conversion:** `is_negotiating = 1 AND is_signed = 1`  
**Date Anchor:**
- Denominator: `DATE(Stage_Entered_Negotiating__c)`
- Numerator: `DATE(Stage_Entered_Signed__c)`

**Formula:**
```sql
negotiating_to_signed_rate = COUNT(DISTINCT CASE WHEN is_negotiating = 1 AND is_signed = 1 THEN Full_Opportunity_ID__c END)
                              / COUNT(DISTINCT CASE WHEN is_negotiating = 1 THEN Full_Opportunity_ID__c END)
```

#### 8. Signed → Joined

**Eligibility:** `is_signed = 1` (opportunity entered Signed stage)  
**Conversion:** `is_signed = 1 AND is_joined = 1`  
**Date Anchor:**
- Denominator: `DATE(Stage_Entered_Signed__c)`
- Numerator: `DATE(advisor_join_date__c)` or `DATE(Stage_Entered_Joined__c)`

**Formula:**
```sql
signed_to_joined_rate = COUNT(DISTINCT CASE WHEN is_signed = 1 AND is_joined = 1 THEN Full_Opportunity_ID__c END)
                        / COUNT(DISTINCT CASE WHEN is_signed = 1 THEN Full_Opportunity_ID__c END)
```

### Combined Conversion Rates

#### SQO → Joined (End-to-End)

**Eligibility:** `is_sqo = 1`  
**Conversion:** `is_sqo = 1 AND is_joined = 1`  
**Formula:**
```sql
sqo_to_joined_rate = COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_joined = 1 THEN Full_Opportunity_ID__c END)
                     / COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)
```

#### SQO → Signed (Pre-Joined)

**Eligibility:** `is_sqo = 1`  
**Conversion:** `is_sqo = 1 AND is_signed = 1`  
**Formula:**
```sql
sqo_to_signed_rate = COUNT(DISTINCT CASE WHEN is_sqo = 1 AND is_signed = 1 THEN Full_Opportunity_ID__c END)
                      / COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END)
```

---

## Implementation for New View

### View Requirements

The new view should:

1. **Track all conversion rates** across the entire funnel (Pre-SQO and Post-SQO)
2. **Support filtering by:**
   - `SGA_Owner_Name__c` (from `vw_funnel_lead_to_joined_v2`)
   - `sgm_name` (Opportunity Manager, from `vw_funnel_lead_to_joined_v2`)
   - `Original_source` (from `vw_funnel_lead_to_joined_v2`)
   - `Channel_Grouping_Name` (from `vw_funnel_lead_to_joined_v2`)
3. **Use same field names** as `vw_funnel_lead_to_joined_v2` for cross-filtering in Looker
4. **Handle stage skipping** correctly using eligibility flags
5. **Track by Opportunity ID** for post-SQO stages

### Key Field Mappings (Must Match vw_funnel_lead_to_joined_v2)

To ensure cross-filtering works in Looker, the following fields must have the exact same names:

| Field Name | Source | Description |
|------------|--------|-------------|
| `SGA_Owner_Name__c` | Lead/Opportunity | SGA owner name |
| `sgm_name` | Opportunity | Opportunity Manager name |
| `Original_source` | Lead/Opportunity | Original source (LeadSource) |
| `Channel_Grouping_Name` | Channel mapping | Channel grouping name |
| `Full_prospect_id__c` | Lead | Lead identifier |
| `Full_Opportunity_ID__c` | Opportunity | Opportunity identifier |

### Stage Flag Definitions for New View

```sql
-- Pre-SQO Flags (Lead-based)
CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted,
CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql,
CASE WHEN IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql,

-- SQO Flag (Opportunity-based)
CASE WHEN LOWER(SQL__c) = 'yes' AND Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END AS is_sqo,

-- Post-SQO Flags (Opportunity-based)
CASE WHEN Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END AS is_qualifying,
CASE WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 1 ELSE 0 END AS is_discovery,
CASE WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 1 ELSE 0 END AS is_sales_process,
CASE WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 1 ELSE 0 END AS is_negotiating,
CASE WHEN Stage_Entered_Signed__c IS NOT NULL THEN 1 ELSE 0 END AS is_signed,
CASE WHEN advisor_join_date__c IS NOT NULL OR Stage_Entered_Joined__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined
```

### Eligibility Flags for Post-SQO Stages

```sql
-- Eligibility for each stage (denominator)
CASE WHEN is_sqo = 1 THEN 1 ELSE 0 END AS eligible_for_sqo_conversions,
CASE WHEN is_discovery = 1 THEN 1 ELSE 0 END AS eligible_for_discovery_conversions,
CASE WHEN is_sales_process = 1 THEN 1 ELSE 0 END AS eligible_for_sales_process_conversions,
CASE WHEN is_negotiating = 1 THEN 1 ELSE 0 END AS eligible_for_negotiating_conversions,
CASE WHEN is_signed = 1 THEN 1 ELSE 0 END AS eligible_for_signed_conversions
```

### Progression Flags for Post-SQO Stages

```sql
-- Progression flags (numerator)
CASE WHEN eligible_for_sqo_conversions = 1 AND is_discovery = 1 THEN 1 ELSE 0 END AS sqo_to_discovery_progression,
CASE WHEN eligible_for_discovery_conversions = 1 AND is_sales_process = 1 THEN 1 ELSE 0 END AS discovery_to_sales_process_progression,
CASE WHEN eligible_for_sales_process_conversions = 1 AND is_negotiating = 1 THEN 1 ELSE 0 END AS sales_process_to_negotiating_progression,
CASE WHEN eligible_for_negotiating_conversions = 1 AND is_signed = 1 THEN 1 ELSE 0 END AS negotiating_to_signed_progression,
CASE WHEN eligible_for_signed_conversions = 1 AND is_joined = 1 THEN 1 ELSE 0 END AS signed_to_joined_progression,

-- Combined progressions
CASE WHEN eligible_for_sqo_conversions = 1 AND is_signed = 1 THEN 1 ELSE 0 END AS sqo_to_signed_progression,
CASE WHEN eligible_for_sqo_conversions = 1 AND is_joined = 1 THEN 1 ELSE 0 END AS sqo_to_joined_progression
```

### Conversion Rate Calculation (Aggregated View)

When aggregating, calculate rates as:

```sql
-- Pre-SQO Rates
ROUND(SUM(contacted_to_mql_progression) / NULLIF(SUM(eligible_for_contacted_conversions), 0), 4) AS contacted_to_mql_rate,
ROUND(SUM(mql_to_sql_progression) / NULLIF(SUM(eligible_for_mql_conversions), 0), 4) AS mql_to_sql_rate,
ROUND(COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN is_sql = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS sql_to_sqo_rate,

-- Post-SQO Rates
ROUND(COUNT(DISTINCT CASE WHEN sqo_to_discovery_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS sqo_to_discovery_rate,
ROUND(COUNT(DISTINCT CASE WHEN discovery_to_sales_process_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_discovery_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS discovery_to_sales_process_rate,
ROUND(COUNT(DISTINCT CASE WHEN sales_process_to_negotiating_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_sales_process_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS sales_process_to_negotiating_rate,
ROUND(COUNT(DISTINCT CASE WHEN negotiating_to_signed_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_negotiating_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS negotiating_to_signed_rate,
ROUND(COUNT(DISTINCT CASE WHEN signed_to_joined_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_signed_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS signed_to_joined_rate,

-- Combined Rates
ROUND(COUNT(DISTINCT CASE WHEN sqo_to_signed_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS sqo_to_signed_rate,
ROUND(COUNT(DISTINCT CASE WHEN sqo_to_joined_progression = 1 THEN Full_Opportunity_ID__c END) / NULLIF(COUNT(DISTINCT CASE WHEN eligible_for_sqo_conversions = 1 THEN Full_Opportunity_ID__c END), 0), 4) AS sqo_to_joined_rate
```

### Important Notes for Implementation

1. **Use COUNT(DISTINCT Full_Opportunity_ID__c)** for post-SQO stages since multiple opportunities can have the same attributes
2. **Date Anchoring:** Each stage should use its specific entry date for time-series analysis
3. **Stage Skipping:** Only count opportunities that actually entered the source stage (eligible_for_X_conversions = 1)
4. **FilterDate:** Pre-SQO stages use `FilterDate` for date attribution; post-SQO stages use their specific entry dates
5. **Active SGA/SGM Filter:** Consider applying the active owner filter (from `vw_sga_funnel.sql`) if needed:
   ```sql
   INNER JOIN Active_SGA_SGM_Users a
     ON SGA_Owner_Name__c = a.Name
   ```

---

## Summary

### Current State

- ✅ Pre-SQO conversion rates are implemented and working
- ✅ Progression-based logic prevents inflation from non-sequential entrants
- ✅ Uses eligibility flags and progression flags correctly

### Future State (To Be Implemented)

- ⏳ Post-SQO conversion rates need to be added
- ⏳ Stage skipping must be handled correctly (only count eligible opportunities)
- ⏳ New view should support filtering by SGA, SGM, Source, and Channel
- ⏳ Field names must match `vw_funnel_lead_to_joined_v2` for Looker cross-filtering

### Key Principles

1. **✅ Progression-Based Logic (Recommended):** Only count actual progressions, not just stage achievements. Use progression flags to ensure accurate stage-to-stage conversion rates.

2. **Eligibility Tracking:** Track which opportunities are eligible for each conversion rate using eligibility flags.

3. **Opportunity ID Tracking:** Use `Full_Opportunity_ID__c` for post-SQO stages to ensure accurate counting.

4. **Stage Skipping:** Handle skipped stages by only counting eligible opportunities (opportunities must have entered the source stage).

5. **Date Anchoring:** 
   - For **cohort analysis**: Use `FilterDate` to group leads by when they entered the funnel
   - For **event analysis**: Use specific stage entry dates (e.g., `DATE(mql_stage_entered_ts)`) for time-series analysis
   - For **conversion rates**: Use progression-based logic regardless of date attribution method

6. **Avoid Inflation:** Never use simple `SUM(is_sql)/SUM(is_mql)` without progression flags when leads can enter at different stages. Always use progression-based calculations for accurate rates.

