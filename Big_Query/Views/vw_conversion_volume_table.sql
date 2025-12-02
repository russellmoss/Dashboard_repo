-- vw_conversion_volume_table: Volume metrics by time period for Looker Studio
-- Uses CONVERSION DATES (not cohort dates) to match vw_actual_vs_forecast_by_source logic
-- This ensures volumes match the actual conversion dates, not when prospects entered the funnel
-- Grouping dimensions: SGA_Owner_Name__c, sgm_name, Original_source, Channel_Grouping_Name

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_conversion_volume_table` AS

WITH
-- Source-Channel mapping
Source_Channel_Map AS (
  SELECT
    Original_Source_Salesforce AS original_source,
    Channel_Grouping_Name
  FROM `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping`
),

-- Pre-SQO volumes from vw_funnel_lead_to_joined_v2 (using conversion dates)
Contacted_Volumes AS (
  SELECT
    v.Channel_Grouping_Name,
    v.Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(v.stage_entered_contacting__c) AS conversion_date,
    COUNT(DISTINCT CASE WHEN v.is_contacted = 1 THEN v.primary_key END) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  WHERE v.stage_entered_contacting__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

MQL_Volumes AS (
  SELECT
    v.Channel_Grouping_Name,
    v.Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(v.mql_stage_entered_ts) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    COUNT(DISTINCT CASE WHEN v.is_mql = 1 THEN v.primary_key END) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  WHERE v.mql_stage_entered_ts IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

SQL_Volumes AS (
  SELECT
    v.Channel_Grouping_Name,
    v.Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(v.converted_date_raw) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    COUNT(DISTINCT CASE WHEN v.is_sql = 1 THEN v.primary_key END) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
  WHERE v.converted_date_raw IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

-- Post-SQO volumes from Opportunity table directly (using conversion dates)
-- Join with vw_funnel_lead_to_joined_v2 to get SGA_Owner_Name__c and other dimensions
SQO_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.Date_Became_SQO__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' THEN o.Full_Opportunity_ID__c END) AS sqo_volume,
    COUNT(DISTINCT CASE WHEN LOWER(o.SQL__c) = 'yes' THEN o.Full_Opportunity_ID__c END) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.Date_Became_SQO__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

Discovery_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.Stage_Entered_Discovery__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    COUNT(DISTINCT CASE WHEN o.Stage_Entered_Discovery__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.Stage_Entered_Discovery__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

Sales_Process_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.Stage_Entered_Sales_Process__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    COUNT(DISTINCT CASE WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.Stage_Entered_Sales_Process__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

Negotiating_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.Stage_Entered_Negotiating__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    COUNT(DISTINCT CASE WHEN o.Stage_Entered_Negotiating__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.Stage_Entered_Negotiating__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

Signed_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.Stage_Entered_Signed__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    COUNT(DISTINCT CASE WHEN o.Stage_Entered_Signed__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS signed_volume,
    CAST(0 AS INT64) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.Stage_Entered_Signed__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

Joined_Volumes AS (
  SELECT
    COALESCE(map.Channel_Grouping_Name, COALESCE(v.Channel_Grouping_Name, 'Other')) AS Channel_Grouping_Name,
    COALESCE(v.Original_source, COALESCE(o.LeadSource, 'Unknown')) AS Original_source,
    v.SGA_Owner_Name__c,
    v.sgm_name,
    DATE(o.advisor_join_date__c) AS conversion_date,
    CAST(0 AS INT64) AS contacted_volume,
    CAST(0 AS INT64) AS mql_volume,
    CAST(0 AS INT64) AS sql_volume,
    CAST(0 AS INT64) AS sqo_volume,
    CAST(0 AS INT64) AS qualifying_volume,
    CAST(0 AS INT64) AS discovery_volume,
    CAST(0 AS INT64) AS sales_process_volume,
    CAST(0 AS INT64) AS negotiating_volume,
    CAST(0 AS INT64) AS signed_volume,
    COUNT(DISTINCT CASE WHEN o.advisor_join_date__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS joined_volume
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` v
    ON o.Full_Opportunity_ID__c = v.Full_Opportunity_ID__c
  LEFT JOIN Source_Channel_Map map
    ON COALESCE(v.Original_source, o.LeadSource) = map.original_source
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND o.advisor_join_date__c IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5
),

-- Combine all volumes by date and dimensions
All_Volumes AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    SGA_Owner_Name__c,
    sgm_name,
    conversion_date,
    SUM(contacted_volume) AS contacted_volume,
    SUM(mql_volume) AS mql_volume,
    SUM(sql_volume) AS sql_volume,
    SUM(sqo_volume) AS sqo_volume,
    SUM(qualifying_volume) AS qualifying_volume,
    SUM(discovery_volume) AS discovery_volume,
    SUM(sales_process_volume) AS sales_process_volume,
    SUM(negotiating_volume) AS negotiating_volume,
    SUM(signed_volume) AS signed_volume,
    SUM(joined_volume) AS joined_volume
  FROM (
    SELECT * FROM Contacted_Volumes
    UNION ALL
    SELECT * FROM MQL_Volumes
    UNION ALL
    SELECT * FROM SQL_Volumes
    UNION ALL
    SELECT * FROM SQO_Volumes
    UNION ALL
    SELECT * FROM Discovery_Volumes
    UNION ALL
    SELECT * FROM Sales_Process_Volumes
    UNION ALL
    SELECT * FROM Negotiating_Volumes
    UNION ALL
    SELECT * FROM Signed_Volumes
    UNION ALL
    SELECT * FROM Joined_Volumes
  )
  GROUP BY 1, 2, 3, 4, 5
),

-- 1. This Quarter to Date (QTD) - filter by conversion_date (up to today, not future dates)
QTD AS (
  SELECT
    1 AS sort_order,
    'This Quarter to Date' AS time_period,
    Channel_Grouping_Name,
    Original_source,
    SGA_Owner_Name__c,
    sgm_name,
    SUM(contacted_volume) AS contacted_volume,
    SUM(mql_volume) AS mql_volume,
    SUM(sql_volume) AS sql_volume,
    SUM(sqo_volume) AS sqo_volume,
    SUM(qualifying_volume) AS qualifying_volume,
    SUM(discovery_volume) AS discovery_volume,
    SUM(sales_process_volume) AS sales_process_volume,
    SUM(negotiating_volume) AS negotiating_volume,
    SUM(signed_volume) AS signed_volume,
    SUM(joined_volume) AS joined_volume
  FROM All_Volumes
  WHERE conversion_date >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
    AND conversion_date <= CURRENT_DATE()
  GROUP BY 1, 2, 3, 4, 5, 6
),

-- 2. Previous Quarter - filter by conversion_date
LastQuarter AS (
  SELECT
    2 AS sort_order,
    'Last Quarter' AS time_period,
    Channel_Grouping_Name,
    Original_source,
    SGA_Owner_Name__c,
    sgm_name,
    SUM(contacted_volume) AS contacted_volume,
    SUM(mql_volume) AS mql_volume,
    SUM(sql_volume) AS sql_volume,
    SUM(sqo_volume) AS sqo_volume,
    SUM(qualifying_volume) AS qualifying_volume,
    SUM(discovery_volume) AS discovery_volume,
    SUM(sales_process_volume) AS sales_process_volume,
    SUM(negotiating_volume) AS negotiating_volume,
    SUM(signed_volume) AS signed_volume,
    SUM(joined_volume) AS joined_volume
  FROM All_Volumes
  WHERE conversion_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER)
    AND conversion_date < DATE_TRUNC(CURRENT_DATE(), QUARTER)
  GROUP BY 1, 2, 3, 4, 5, 6
),

-- 3. Year to Date (YTD) - filter by conversion_date (up to today, not future dates)
YTD AS (
  SELECT
    3 AS sort_order,
    'Year to Date' AS time_period,
    Channel_Grouping_Name,
    Original_source,
    SGA_Owner_Name__c,
    sgm_name,
    SUM(contacted_volume) AS contacted_volume,
    SUM(mql_volume) AS mql_volume,
    SUM(sql_volume) AS sql_volume,
    SUM(sqo_volume) AS sqo_volume,
    SUM(qualifying_volume) AS qualifying_volume,
    SUM(discovery_volume) AS discovery_volume,
    SUM(sales_process_volume) AS sales_process_volume,
    SUM(negotiating_volume) AS negotiating_volume,
    SUM(signed_volume) AS signed_volume,
    SUM(joined_volume) AS joined_volume
  FROM All_Volumes
  WHERE conversion_date >= DATE_TRUNC(CURRENT_DATE(), YEAR)
    AND conversion_date <= CURRENT_DATE()
  GROUP BY 1, 2, 3, 4, 5, 6
)

-- Stack all three tables on top of each other
SELECT * FROM QTD
UNION ALL
SELECT * FROM LastQuarter
UNION ALL
SELECT * FROM YTD

