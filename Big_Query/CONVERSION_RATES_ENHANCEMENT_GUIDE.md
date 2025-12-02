# Conversion Rates Dashboard Enhancement Guide

## Overview
This guide explains how to add two new features to the Conversion Rates Looker Studio dashboard:
1. **Volume Table** - Shows volume counts for each stage across Custom Date Range, Previous Quarter, and Year to Date
2. **Opportunity AUM Filter** - Slider filter to filter all metrics by Opportunity AUM ($M)

## Changes Made to Views

### 1. Updated `vw_conversion_rates`
- **Added `Opportunity_AUM_M`**: Opportunity AUM in millions (aggregated using MAX)
- **Added Volume Metrics**: 
  - `contacted_volume` (same as `contacted_denominator`)
  - `mql_volume` (same as `mql_denominator`)
  - `sql_volume` (same as `sql_denominator`)
  - `sqo_volume` (same as `sqo_denominator`)
  - `qualifying_volume` (same as `sqo_denominator`)
  - `discovery_volume` (same as `discovery_denominator`)
  - `sales_process_volume` (same as `sales_process_denominator`)
  - `negotiating_volume` (same as `negotiating_denominator`)
  - `signed_volume` (same as `signed_denominator`)

### 2. Created `vw_conversion_volume_table`
- New view that aggregates volumes for three time periods:
  - This Quarter to Date (QTD)
  - Last Quarter
  - Year to Date
- Structure mirrors `vw_conversion_rate_table` but shows volumes instead of rates

## Implementation Steps

### Step 1: Deploy Views to BigQuery

Deploy the updated views using the MCP BigQuery tool or BigQuery console:

1. **Update `vw_conversion_rates`**:
   ```sql
   -- Run the SQL from Views/vw_conversion_rates.sql
   ```

2. **Create `vw_conversion_volume_table`**:
   ```sql
   -- Run the SQL from Views/vw_conversion_volume_table.sql
   ```

### Step 2: Add Volume Table to Looker Studio

1. **Add New Data Source**:
   - In Looker Studio, add a new data source: `vw_conversion_volume_table`
   - Connect it to your existing BigQuery connection

2. **Create Volume Table Component**:
   - Insert a **Table** component
   - Set the data source to `vw_conversion_volume_table`
   - **Dimensions**:
     - `time_period` (for rows)
     - `SGA_Owner_Name__c` (optional, if you want to break down by SGA)
   - **Metrics** (add all volume columns):
     - `contacted_volume`
     - `mql_volume`
     - `sql_volume`
     - `sqo_volume`
     - `qualifying_volume`
     - `discovery_volume`
     - `sales_process_volume`
     - `negotiating_volume`
     - `signed_volume`
   - **Sort**: By `sort_order` (ascending) to ensure QTD, Last Quarter, YTD order

3. **Format the Table**:
   - Format numbers as integers (no decimals)
   - Add conditional formatting if desired
   - Add a title: "Funnel Volume by Time Period"

### Step 3: Add Opportunity AUM Filter

**Important Note**: Since `vw_conversion_rates` aggregates data, filtering by AUM at the aggregated level has limitations. For proper AUM filtering, you have two options:

#### Option A: Filter on Base Data Source (Recommended)

1. **Add `vw_funnel_lead_to_joined_v2` as a Data Source**:
   - Add `vw_funnel_lead_to_joined_v2` as a separate data source
   - This view has `Opportunity_AUM` field (in dollars, not millions)

2. **Create Calculated Fields in `vw_funnel_lead_to_joined_v2` Data Source**:
   - **Field 1**: `cohort_month`
     - **Formula**: `DATE_TRUNC(DATE(FilterDate), MONTH)`
     - **Type**: Date
   - **Field 2**: `Opportunity_AUM_M`
     - **Formula**: `ROUND(Opportunity_AUM / 1000000, 2)`
     - **Type**: Number

3. **Blend Data Sources**:
   - Create a blended data source that joins:
     - Primary: `vw_conversion_rates` (or `vw_conversion_rate_table`)
     - Secondary: `vw_funnel_lead_to_joined_v2`
   - **Join keys** (all 5 dimensions that are used for filtering):
     1. `cohort_month` (Primary) = `DATE_TRUNC(DATE(FilterDate), MONTH)` (Secondary - create as calculated field)
     2. `SGA_Owner_Name__c`
     3. `sgm_name`
     4. `Original_source`
     5. `Channel_Grouping_Name`
   - **Important**: You must join on ALL 5 dimensions because you filter by SGA, SGM, Source, and Channel. If you only join on SGA and cohort_month, the blend will break when filtering by SGM, Source, or Channel.
   - Include `Opportunity_AUM_M` from the secondary source (create as calculated field: `ROUND(Opportunity_AUM / 1000000, 2)`)

4. **Add Slider Filter**:
   - Insert a **Range Slider** control
   - Set the data source to the blended data source
   - **Control Field**: `Opportunity_AUM_M`
   - **Min Value**: 0 (or minimum AUM in your data)
   - **Max Value**: Set to a reasonable maximum (e.g., 100 for $100M)
   - **Default Range**: Leave empty or set to full range

5. **Apply Filter to All Components**:
   - Select all components on the page
   - In the **Data** tab, ensure they all use the blended data source
   - The slider filter will automatically apply to all components using the same data source

#### Option B: Filter on Aggregated View (Simpler but Less Accurate)

1. **Add Slider Filter**:
   - Insert a **Range Slider** control
   - Set the data source to `vw_conversion_rates`
   - **Control Field**: `Opportunity_AUM_M`
   - **Note**: This filters on the MAX AUM in each aggregated group, which may not be as precise

2. **Apply to Components**:
   - Ensure all components use `vw_conversion_rates` as their data source
   - The filter will apply to all components

### Step 4: Update Existing Components (if using Option A)

If you use Option A (blended data source), you'll need to:

1. **Update Scorecards**:
   - Change data source to the blended data source
   - Metrics remain the same (they'll be filtered by AUM)

2. **Update Bar Chart**:
   - Change data source to the blended data source
   - Dimensions and metrics remain the same

3. **Update Channel & Source Tables**:
   - Change data source to the blended data source
   - All existing metrics will be filtered by AUM

## Field Reference

### Volume Metrics Available
- `contacted_volume` - Count of prospects who were contacted
- `mql_volume` - Count of MQLs
- `sql_volume` - Count of SQLs
- `sqo_volume` - Count of SQOs
- `qualifying_volume` - Count of opportunities in Qualifying stage (same as SQO)
- `discovery_volume` - Count of opportunities that entered Discovery
- `sales_process_volume` - Count of opportunities that entered Sales Process
- `negotiating_volume` - Count of opportunities that entered Negotiating
- `signed_volume` - Count of opportunities that entered Signed

### AUM Filter Field
- `Opportunity_AUM_M` - Opportunity AUM in millions (from `vw_conversion_rates`)
- `Opportunity_AUM` - Opportunity AUM in dollars (from `vw_funnel_lead_to_joined_v2`)

## Testing Checklist

- [ ] Volume table displays correctly with all three time periods
- [ ] Volume numbers match expected counts
- [ ] AUM filter slider works and filters all components
- [ ] Conversion rates update correctly when AUM filter is applied
- [ ] Volume table updates correctly when AUM filter is applied
- [ ] Existing filters (SGA, SGM, Source, Channel, Date Range) still work
- [ ] All components refresh correctly when filters change

## Notes

1. **AUM Filtering Limitation**: Since conversion rates are aggregated by cohort_month, SGA, etc., filtering by AUM at the aggregated level means you're filtering on the MAX AUM in each group. For more precise filtering, use Option A (blended data source).

2. **Volume vs Denominator**: The volume metrics are identical to the denominator metrics. They're included as separate fields for clarity and to make it easier to build the volume table.

3. **Qualifying Volume**: This is the same as `sqo_volume` since Qualifying stage begins when an opportunity becomes an SQO (`Date_Became_SQO__c IS NOT NULL`).

4. **Performance**: The volume table view (`vw_conversion_volume_table`) is optimized for performance by pre-aggregating the three time periods, similar to `vw_conversion_rate_table`.


