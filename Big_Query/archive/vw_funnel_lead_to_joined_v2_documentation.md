# vw_funnel_lead_to_joined_v2 Documentation

## Overview

The `vw_funnel_lead_to_joined_v2` view creates a unified dataset that tracks prospects/leads through the entire sales funnel, from initial lead creation through conversion to opportunities and ultimately to when advisors join Savvy. This view combines lead and opportunity data to provide a complete funnel view, handling cases where people enter the system as opportunities without ever being leads.

**Location**: `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`

---

## Architecture

The view is built using two Common Table Expressions (CTEs) that pull from different source tables:
1. **Lead_Base** - Extracts and enriches lead/prospect data
2. **Opp_Base** - Extracts and enriches opportunity data

The final SELECT statement performs a FULL OUTER JOIN between these CTEs and adds attribution logic.

---

## Primary Key Design

### The Challenge
- Some people enter the funnel as **leads** and later convert to **opportunities**
- Some people enter the funnel directly as **opportunities** (no lead record exists)
- We need a single, consistent way to uniquely identify each person across both source systems

### The Solution
```sql
COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key
```

The `primary_key` field uses `COALESCE` to create a unique identifier that:
- Uses the prospect ID if a lead exists
- Falls back to the opportunity ID if no lead exists
- Ensures every record has a unique identifier, regardless of entry point

This allows us to:
- Track the complete journey of leads who convert to opportunities
- Track opportunities that never had a lead record
- Query and analyze the funnel without gaps or duplicates

---

## CTE 1: Lead_Base

**Purpose**: Extract lead/prospect information and calculate funnel stage indicators based on lead status.

**Source Table**: `savvy-gtm-analytics.SavvyGTMData.Lead`

### Key Fields Extracted

#### Basic Lead Information
- `Full_prospect_id__c` - Unique lead identifier
- `Name` (aliased as `Prospect_Name`) - Name of the prospect
- `CreatedDate` - When the lead was created
- `OwnerID` - Owner of the lead record
- `SGA_Owner_Name__c` - Assigned SGA owner
- `Company` - Company name
- `Status` - Current lead status
- `LeadSource` (aliased as `Lead_Original_Source`) - Original lead source

#### Lead List & Experimentation
- `lead_list_name__c` - List the lead came from
- `Experimentation_Tag__c` - Tag for experiment tracking
- `Disposition__c` - Lead disposition

#### Funnel Stage Timestamps
- `stage_entered_contacting__c` - When lead entered "contacting" stage
- `Initial_Call_Scheduled_Date__c` - When initial call was scheduled
- `stage_entered_new__c` - When lead entered "new" stage
- `Stage_Entered_Call_Scheduled__c` - When lead entered MQL stage (call scheduled)
- `ConvertedDate` - When lead was converted to opportunity
- `ConvertedOpportunityId` - ID of the converted opportunity

### Calculated Fields

#### Funnel Stage Indicators (Binary Flags)
```sql
CASE WHEN stage_entered_contacting__c IS NOT NULL THEN 1 ELSE 0 END AS is_contacted
```
- **Purpose**: Indicates if the lead has been contacted
- **Logic**: True when the lead entered the "contacting" stage

```sql
CASE WHEN Stage_Entered_Call_Scheduled__c IS NOT NULL THEN 1 ELSE 0 END AS is_mql
```
- **Purpose**: Indicates if the lead is a Marketing Qualified Lead (MQL)
- **Logic**: True when a call was scheduled
- **Business Logic**: MQL is defined as someone who has scheduled an initial call

```sql
CASE WHEN initial_call_scheduled_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_initial_call
```
- **Purpose**: Indicates if an initial call was scheduled
- **Logic**: Redundant with `is_mql` but provides explicit flag for call scheduling

```sql
CASE WHEN IsConverted IS TRUE THEN 1 ELSE 0 END AS is_sql
```
- **Purpose**: Indicates if the lead is a Sales Qualified Lead (SQL)
- **Logic**: True when the lead has been converted to an opportunity
- **Note**: SQL definition is simply "converted lead"

```sql
CASE WHEN is_converted_raw IS TRUE THEN 1 ELSE 0 END AS is_converted_raw
```
- **Purpose**: Direct copy of Salesforce's `IsConverted` field
- **Note**: Also available as `is_converted_raw` boolean

#### Weekly Bucketing
```sql
FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(initial_call_scheduled_date__c), WEEK(MONDAY))) AS Week_Bucket_MQL_Call
```
- **Purpose**: Formats the initial call date into a week bucket (e.g., "01/15/2024")
- **Use Case**: Weekly aggregation and reporting

```sql
DATE_TRUNC(DATE(Stage_Entered_Contacting__c), WEEK(MONDAY)) AS Week_Bucket_MQL_Date
```
- **Purpose**: Stores the week start date (Monday) for MQL date
- **Use Case**: Sorting and grouping by week

```sql
FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(ConvertedDate), WEEK(MONDAY))) AS Week_Bucket_SQL
```
- **Purpose**: Formats the conversion date into a week bucket
- **Use Case**: Weekly SQL conversion reporting

```sql
DATE_TRUNC(DATE(ConvertedDate), WEEK(MONDAY)) AS Week_Bucket_SQL_Date
```
- **Purpose**: Week start date for SQL conversion
- **Use Case**: Sorting and grouping

#### Filter Date
```sql
GREATEST(
  IFNULL(CreatedDate, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_new__c, TIMESTAMP('1900-01-01')),
  IFNULL(stage_entered_contacting__c, TIMESTAMP('1900-01-01'))
) AS FilterDate
```
- **Purpose**: Creates a single date field for filtering in dashboards and reports
- **Logic**: Takes the most recent date among creation date and stage entry dates
- **Use Case**: Allows filtering "all activities" by a single date range
- **Default**: Uses '1900-01-01' to ensure NULL safety in GREATEST function

---

## CTE 2: Opp_Base

**Purpose**: Extract opportunity information and enrich with user names from related User records.

**Source Table**: `savvy-gtm-analytics.SavvyGTMData.Opportunity`

**Filter**: Only includes opportunities where `recordtypeid = '012Dn000000mrO3IAI'` (likely "Advisor" or "FA" record type)

### Key Fields Extracted

#### Basic Opportunity Information
- `Full_Opportunity_ID__c` - Unique opportunity identifier
- `Name` (aliased as `Opp_Name`) - Opportunity name
- `CreatedDate` (aliased as `Opp_CreatedDate`) - When opportunity was created
- `Amount` - Opportunity amount in dollars
- `Underwritten_AUM__c` - Underwritten Assets Under Management
- `StageName` - Current sales stage
- `CloseDate` - Expected or actual close date
- `IsClosed` - Boolean indicating if opportunity is closed
- `LeadSource` (aliased as `Opp_Original_Source`) - Original lead source

#### Opportunity Owner & Manager
- `Opportunity_Owner_Name__c` - Name of opportunity owner
- `OwnerId` - ID of opportunity owner
- `SGA__c` - Links to SGA (Sales) user
- Manager information pulled from User hierarchy

#### Outcome Fields
- `Stage_Entered_Signed__c` - When opportunity entered "Signed" stage
- `Closed_Lost_Reason__c` - Reason if closed lost
- `Closed_Lost_Details__c` - Details for closed lost opportunities
- `SQL__c` (aliased as `SQO_raw`) - Sales Qualified Opportunity field (string)
- `Date_Became_SQO__c` - When opportunity became an SQO
- `advisor_join_date__c` - When advisor actually joined Savvy

#### Qualification Information
- `Qualification_Call_Date__c` - Date of qualification call
- `Firm_Name__c` - Firm name
- `Firm_Type__c` - Type of firm
- `City_State__c` - City and state
- `Office_Address__c` - Office address

### User Enrichment (JOINs)

The CTE performs three LEFT JOINs to enrich opportunity data with user names:

1. **SGA User**:
```sql
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` sga_user
  ON o.SGA__c = sga_user.Id
```
- Extracts SGA user name into `sga_name_from_opp`

2. **Opportunity Owner**:
```sql
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
  ON o.OwnerId = opp_owner_user.Id
```
- Used to get ManagerId from owner record

3. **Manager**:
```sql
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` manager_user
  ON opp_owner_user.ManagerId = manager_user.Id
```
- Extracts manager name into `sgm_name` (Sales Growth Manager)

---

## Final SELECT Statement

### Join Strategy
```sql
FROM Lead_Base l
FULL OUTER JOIN Opp_Base o
  ON l.converted_oppty_id = o.Full_Opportunity_ID__c
```

**Full Outer Join Logic**:
- **Match**: When a lead was converted to an opportunity, records are joined
- **Lead Only**: Leads that haven't converted yet (opportunity fields will be NULL)
- **Opp Only**: Opportunities that never had a lead record (lead fields will be NULL)

This ensures complete funnel visibility for both paths: lead → opportunity AND direct opportunity entry.

### Attribution Join
```sql
LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
  ON COALESCE(o.Opp_Original_Source, l.Lead_Original_Source) = g.Original_Source_Salesforce
```
- **Purpose**: Maps raw lead source to marketing channel groupings
- **Logic**: Prefers opportunity source, falls back to lead source
- **Output**: Provides cleaned channel names instead of raw Salesforce values

---

## Calculated Fields in Final SELECT

### Primary Key
```sql
COALESCE(l.Full_prospect_id__c, o.Full_Opportunity_ID__c) AS primary_key
```
- See [Primary Key Design](#primary-key-design) section above

### Advisor Name
```sql
COALESCE(o.Opp_Name, l.Prospect_Name) AS advisor_name
```
- Uses opportunity name if available, otherwise uses prospect name
- Ensures we always have a name for reporting

### SGA Owner Name
```sql
CASE
  WHEN l.Full_prospect_id__c IS NULL THEN o.sga_name_from_opp
  WHEN l.SGA_Owner_Name__c = 'Savvy Marketing' THEN o.sga_name_from_opp
  ELSE l.SGA_Owner_Name__c
END AS SGA_Owner_Name__c
```
- **Logic**:
  1. If no lead (opportunity-only), use opportunity SGA
  2. If lead is owned by "Savvy Marketing" (likely unassigned), use opportunity SGA
  3. Otherwise use lead SGA
- **Purpose**: Ensures accurate ownership tracking across the funnel

### Opportunity AUM
```sql
COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM
```
- **Purpose**: Single field for AUM value
- **Logic**: Prefers Underwritten AUM, falls back to Amount
- **Use Case**: Consistent AUM reporting

### Stage Name Code
```sql
CASE
  WHEN o.StageName = 'Qualifying' THEN 1
  WHEN o.StageName = 'Discovery' THEN 2
  WHEN o.StageName = 'Sales Process' THEN 3
  WHEN o.StageName = 'Negotiating' THEN 4
  WHEN o.StageName = 'Signed' THEN 5
  WHEN o.StageName = 'On Hold' THEN 6
  WHEN o.StageName = 'Closed' THEN 7
  ELSE NULL
END AS StageName_code
```
- **Purpose**: Numeric code for sorting stages in correct order
- **Use Case**: Sorting opportunities by sales stage progression
- **Note**: Stages without a code (e.g., "Closed Lost") will sort at the end

### Qualification Call Fields
```sql
CASE WHEN o.Qualification_Call_Date__c IS NOT NULL THEN 1 ELSE 0 END AS is_Qual_call
```
- Binary flag indicating if qualification call occurred

```sql
FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(o.Qualification_Call_Date__c), WEEK(MONDAY))) AS Week_Bucket_Qual_Call
```
- Weekly bucketing for qualification call date

### SQO Bucketing
```sql
FORMAT_TIMESTAMP('%b', o.Date_Became_SQO__c) AS Month_bucket_SQO
```
- Month abbreviation for SQO date (e.g., "Jan", "Feb")

```sql
FORMAT_DATE('%m/%d/%Y', DATE_TRUNC(DATE(o.Date_Became_SQO__c), WEEK(MONDAY))) AS Week_bucket_SQO
```
- Weekly bucket for SQO date

```sql
DATE_TRUNC(DATE(o.Date_Became_SQO__c), WEEK(MONDAY)) AS Week_Bucket_SQO_Date
```
- Week start date for sorting/grouping

### is_joined Flag
```sql
CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined
```
- **Purpose**: Indicates if advisor has actually joined Savvy
- **Logic**: True when `advisor_join_date__c` has a value
- **Business Logic**: Final stage of funnel - advisor is fully onboarded

### Filter Date Fallback
```sql
COALESCE(
  l.FilterDate,
  o.Opp_CreatedDate,
  o.Date_Became_SQO__c,
  TIMESTAMP(o.advisor_join_date__c)
) AS FilterDate
```
- **Purpose**: Ensures FilterDate exists even for opportunity-only records
- **Fallback Chain**:
  1. Lead FilterDate (if lead exists)
  2. Opportunity Created Date
  3. SQO Date
  4. Advisor Join Date
- **Use Case**: Single date field for filtering all records

### Attribution & Channel
```sql
IFNULL(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name
```
- Maps lead source to marketing channel (e.g., "Paid Search", "Referral")
- Uses "Other" as default for unmapped sources

```sql
COALESCE(o.Opp_Original_Source, l.Lead_Original_Source, 'Unknown') AS Original_source
```
- Single source field with fallback chain
- Ensures we always have an attribution source

---

## Funnel Stage Definitions

Based on the view, the funnel stages are:

1. **Lead Created** - `CreatedDate` is populated
2. **Contacted** (`is_contacted = 1`) - Lead entered "contacting" stage
3. **MQL** (`is_mql = 1`) - Call was scheduled
4. **SQL** (`is_sql = 1`) - Lead converted to opportunity
5. **SQO** - Opportunity became Sales Qualified Opportunity (`Date_Became_SQO__c` populated)
6. **Qualification Call** (`is_Qual_call = 1`) - Qualification call occurred
7. **Signed** - Opportunity entered "Signed" stage (`Stage_Entered_Signed__c` populated)
8. **Joined** (`is_joined = 1`) - Advisor officially joined (`advisor_join_date__c` populated)

### Important Notes on Stage Definitions

- **SQL vs SQO**: SQL is simply conversion from lead to opportunity. SQO is a separate qualification step within the opportunity.
- **No `is_sqo` flag**: Unlike MQL/SQL/Joined, SQO is identified by checking `Date_Became_SQO__c IS NOT NULL` or `SQO_raw = 'SQL'` (if needed)
- **Flexible entry points**: Records can enter the funnel at any stage (lead creation, opportunity creation, or later stages)

---

## Common Use Cases

### 1. Funnel Analysis
```sql
SELECT 
  COUNT(DISTINCT primary_key) as total_leads,
  SUM(is_contacted) as contacted,
  SUM(is_mql) as mqls,
  SUM(is_sql) as sqls,
  SUM(is_joined) as joined
FROM savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2
WHERE FilterDate >= '2024-01-01'
```

### 2. Conversion Rates
```sql
SELECT 
  SUM(is_sql) * 100.0 / SUM(is_mql) as mql_to_sql_rate,
  SUM(is_joined) * 100.0 / SUM(is_sql) as sql_to_joined_rate
FROM savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2
WHERE FilterDate >= '2024-01-01'
```

### 3. Channel Performance
```sql
SELECT 
  Channel_Grouping_Name,
  COUNT(DISTINCT primary_key) as leads,
  SUM(is_mql) as mqls,
  SUM(is_sql) as sqls,
  SUM(is_joined) as joined
FROM savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2
WHERE FilterDate >= '2024-01-01'
GROUP BY Channel_Grouping_Name
```

### 4. Opportunity-Only Records
```sql
SELECT *
FROM savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2
WHERE Full_prospect_id__c IS NULL  -- No lead record
AND Full_Opportunity_ID__c IS NOT NULL  -- Has opportunity
```

### 5. Weekly Funnel Trends
```sql
SELECT 
  Week_Bucket_MQL_Date,
  SUM(is_mql) as mqls,
  SUM(is_sql) as sqls,
  SUM(CASE WHEN Date_Became_SQO__c IS NOT NULL THEN 1 ELSE 0 END) as sqos
FROM savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2
WHERE Week_Bucket_MQL_Date >= '2024-01-01'
GROUP BY Week_Bucket_MQL_Date
ORDER BY Week_Bucket_MQL_Date
```

---

## Important Considerations

### Data Quality
- Always filter by `FilterDate` for accurate date-based reporting
- Some records may have incomplete stage progression (e.g., joined but never scheduled call)
- Not all leads will have all stages populated

### Performance
- View uses FULL OUTER JOIN which can be expensive on large datasets
- Consider filtering by date ranges when querying
- Primary key allows for efficient row lookups when needed

### Business Logic Assumptions
- MQL = Call Scheduled (only one definition in the view)
- SQL = Converted Lead (only one definition)
- Joined = Advisor Join Date populated
- **SQO requires checking date field** (no binary flag like other stages)

---

## Summary

The `vw_funnel_lead_to_joined_v2` view provides a unified, comprehensive view of the sales funnel by:
1. Combining lead and opportunity data through FULL OUTER JOIN
2. Using a primary key that works for both entry paths
3. Calculating clear binary flags for funnel stages (except SQO)
4. Providing weekly and monthly bucketing for trend analysis
5. Including attribution and channel grouping
6. Ensuring complete funnel visibility regardless of entry point

This view serves as the foundation for most funnel analysis, conversion rate calculations, and sales performance reporting across the organization.
