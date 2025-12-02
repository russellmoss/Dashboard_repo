# MQL Disposition Analysis Guide

## Overview
These views help analyze why MQL to SQL conversion rates changed over time by examining the distribution of `Disposition__c` values across **ALL MQLs** (not just non-converting ones). This answers: "Out of all MQLs, what percentage had each disposition?"

## Views Created

### 1. `vw_mql_disposition_ratios`
**Purpose**: Detailed view showing all dispositions with their ratios for each quarter across the entire MQL population.

**Key Question Answered**: "Out of ALL MQLs in a quarter, what percentage had 'No Book' disposition?" (or any other disposition)

**Filters Applied**:
- `is_mql = 1` (ALL MQLs, including those that converted to SQL)
- Excludes `SGA_Owner_Name__c = 'Savvy Operations'`
- Uses `mql_stage_entered_ts` as the date field

**Columns**:
- `mql_quarter`: Quarter date (for filtering/sorting)
- `quarter_display`: Human-readable quarter (e.g., "2025 Q4")
- `disposition`: The Disposition__c value (or "No Disposition" if NULL)
- `total_mqls`: Total MQLs in that quarter (ALL MQLs)
- `disposition_count`: Count of MQLs with this disposition (from ALL MQLs)
- `disposition_ratio`: Ratio as decimal (0.0 to 1.0) - "Out of ALL MQLs, what % had this disposition?"
- `disposition_ratio_pct`: Ratio as percentage (0.0 to 100.0)
- `disposition_count_converted`: How many MQLs with this disposition converted to SQL (note: most dispositions have very low conversion rates ~3-4%, but some like "No Response" can be ~20%+)
- `disposition_count_not_converted`: How many MQLs with this disposition did NOT convert
- `disposition_conversion_rate_pct`: Conversion rate for MQLs with this specific disposition
- `disposition_rank`: Rank within quarter (1 = most common)

**Usage Example**:
```sql
-- See all dispositions for Q4 2025
SELECT *
FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
WHERE quarter_display = '2025 Q4'
ORDER BY disposition_rank;
```

### 2. `vw_mql_disposition_summary`
**Purpose**: Quarter-level summary showing totals, conversion rates, and top disposition for quick comparison.

**Columns**:
- `mql_quarter`: Quarter date
- `quarter_display`: Human-readable quarter
- `total_mqls`: Total MQLs in that quarter (ALL MQLs)
- `total_converted`: How many MQLs converted to SQL
- `total_not_converted`: How many MQLs did NOT convert
- `overall_conversion_rate_pct`: Overall MQL to SQL conversion rate for the quarter
- `top_disposition`: Most common disposition
- `top_disposition_count`: Count of top disposition
- `top_disposition_pct`: Percentage of ALL MQLs that had the top disposition
- `unique_disposition_count`: Number of unique dispositions

**Usage Example**:
```sql
-- Compare quarters side-by-side
SELECT *
FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_summary`
ORDER BY mql_quarter DESC;
```

## Analysis Workflow

### Step 1: Identify the Problem Quarter
Use the summary view to see which quarter had the lowest conversion:
```sql
SELECT 
  quarter_display,
  total_mqls,
  top_disposition,
  top_disposition_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_summary`
WHERE mql_quarter >= DATE('2024-01-01')
ORDER BY mql_quarter DESC;
```

### Step 2: Drill into Disposition Details
For the problem quarter (e.g., Q4 2025), see all dispositions and their impact:
```sql
SELECT 
  disposition,
  disposition_count,
  disposition_ratio_pct,
  disposition_count_not_converted,
  disposition_conversion_rate_pct,
  disposition_rank
FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
WHERE quarter_display = '2025 Q4'
ORDER BY disposition_rank;
```

This shows:
- What % of ALL MQLs had each disposition
- How many with that disposition didn't convert
- The conversion rate for MQLs with that disposition

### Step 3: Compare Across Quarters
See how a specific disposition changed over time:
```sql
SELECT 
  quarter_display,
  disposition,
  disposition_count,
  disposition_ratio_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
WHERE disposition = 'Not Interested'  -- Replace with your disposition
ORDER BY mql_quarter DESC;
```

### Step 4: Identify Trends
Compare Q4 2025 vs previous quarters:
```sql
WITH q4_2025 AS (
  SELECT 
    disposition,
    disposition_ratio_pct AS q4_ratio
  FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
  WHERE quarter_display = '2025 Q4'
),
q3_2025 AS (
  SELECT 
    disposition,
    disposition_ratio_pct AS q3_ratio
  FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
  WHERE quarter_display = '2025 Q3'
)
SELECT 
  COALESCE(q4.disposition, q3.disposition) AS disposition,
  q3.q3_ratio,
  q4.q4_ratio,
  q4.q4_ratio - q3.q3_ratio AS change_pct
FROM q4_2025 q4
FULL OUTER JOIN q3_2025 q3
  ON q4.disposition = q3.disposition
ORDER BY ABS(q4.q4_ratio - q3.q3_ratio) DESC;
```

## Key Questions to Answer

1. **What percentage of ALL MQLs had 'No Book' in Q4 2025?**
   ```sql
   SELECT disposition_ratio_pct
   FROM `savvy-gtm-analytics.savvy_analytics.vw_mql_disposition_ratios`
   WHERE quarter_display = '2025 Q4' AND disposition = 'No Book';
   ```

2. **Which negative dispositions increased most in Q4 2025?**
   - Compare Q4 ratios vs Q3 ratios
   - Look for dispositions with low conversion rates that increased

3. **Which disposition is most prevalent overall?**
   - Check `disposition_rank = 1` for each quarter
   - See if the top disposition changed and if it's a negative one

4. **What percentage of ALL MQLs have no disposition?**
   - Filter for `disposition = 'No Disposition'`
   - See if this increased in Q4 (could indicate data quality issues)

5. **Which dispositions have the lowest conversion rates?**
   - Sort by `disposition_conversion_rate_pct` ASC
   - These are the "negative" dispositions preventing SQL conversion

## Notes

- **MQL definition**: `is_mql = 1` (based on `Stage_Entered_Call_Scheduled__c IS NOT NULL`)
- **Date attribution**: Uses `mql_stage_entered_ts` (when they became an MQL)
- **Population**: ALL MQLs are included (both converting and non-converting)
- **Ratios**: Show "Out of ALL MQLs, what % had this disposition?" (they sum to 100% per quarter)
- **Disposition and Conversion**: While having a `Disposition__c` is strongly correlated with non-conversion (~3.5% conversion rate vs ~75% for those without disposition), some dispositions do still convert (e.g., "No Response" ~23%, "Auto-Closed by Operations" ~25%). The conversion metrics help identify these exceptions.
- **Dispositions are case-sensitive** - ensure exact matches when filtering

