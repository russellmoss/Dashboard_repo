-- vw_conversion_rate_table: Time-period comparison view for Looker Studio tables
-- Queries vw_conversion_rates and aggregates by QTD, Last Quarter, and YTD
-- Designed to cross-filter with vw_funnel_lead_to_joined_v2 and vw_conversion_rates
-- Grouping dimensions: SGA_Owner_Name__c, sgm_name, Original_source, Channel_Grouping_Name
-- UPDATED: Uses event-based cohort months for accurate date filtering:
-- - Contacted to MQL: filter by contacted_cohort_month
-- - MQL to SQL: filter by mql_cohort_month
-- - SQL to SQO: filter by sql_cohort_month
-- - Post-SQO rates: filter by sqo_cohort_month and corresponding stage cohort months

CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_conversion_rate_table` AS

WITH
-- 1. This Quarter to Date (QTD)
QTD AS (
  SELECT
    1 AS sort_order,
    'This Quarter to Date' AS time_period,
    SGA_Owner_Name__c,
    sgm_name,
    Original_source,
    Channel_Grouping_Name,
    -- Pre-SQO Denominators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN contacted_denominator ELSE 0 END) AS contacted_denominator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN mql_denominator ELSE 0 END) AS mql_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_denominator ELSE 0 END) AS sql_denominator,
    -- Pre-SQO Numerators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN contacted_to_mql_numerator ELSE 0 END) AS contacted_to_mql_numerator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN mql_to_sql_numerator ELSE 0 END) AS mql_to_sql_numerator,
    -- SQL to SQO (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sql_cohort_month
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_numerator,
    -- Post-SQO Denominators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sqo_cohort_month and corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_denominator ELSE 0 END) AS sqo_denominator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN discovery_denominator ELSE 0 END) AS discovery_denominator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sales_process_denominator ELSE 0 END) AS sales_process_denominator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN negotiating_denominator ELSE 0 END) AS negotiating_denominator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN signed_denominator ELSE 0 END) AS signed_denominator,
    -- Post-SQO Numerators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_to_discovery_numerator ELSE 0 END) AS sqo_to_discovery_numerator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN discovery_to_sales_process_numerator ELSE 0 END) AS discovery_to_sales_process_numerator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sales_process_to_negotiating_numerator ELSE 0 END) AS sales_process_to_negotiating_numerator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN negotiating_to_signed_numerator ELSE 0 END) AS negotiating_to_signed_numerator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN signed_to_joined_numerator ELSE 0 END) AS signed_to_joined_numerator,
    -- Combined Rates Denominators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_to_signed_denominator ELSE 0 END) AS sqo_to_signed_denominator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denominator,
    -- Combined Rates Numerators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_to_signed_numerator ELSE 0 END) AS sqo_to_signed_numerator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_numerator
  FROM
    `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  GROUP BY
    1, 2, 3, 4, 5, 6
),

-- 2. Previous Quarter
LastQuarter AS (
  SELECT
    2 AS sort_order,
    'Last Quarter' AS time_period,
    SGA_Owner_Name__c,
    sgm_name,
    Original_source,
    Channel_Grouping_Name,
    -- Pre-SQO Denominators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND contacted_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN contacted_denominator ELSE 0 END) AS contacted_denominator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND mql_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN mql_denominator ELSE 0 END) AS mql_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sql_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sql_denominator ELSE 0 END) AS sql_denominator,
    -- Pre-SQO Numerators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND contacted_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN contacted_to_mql_numerator ELSE 0 END) AS contacted_to_mql_numerator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND mql_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN mql_to_sql_numerator ELSE 0 END) AS mql_to_sql_numerator,
    -- SQL to SQO (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sql_cohort_month
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sql_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sql_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_numerator,
    -- Post-SQO Denominators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sqo_cohort_month and corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_denominator ELSE 0 END) AS sqo_denominator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND discovery_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN discovery_denominator ELSE 0 END) AS discovery_denominator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sales_process_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sales_process_denominator ELSE 0 END) AS sales_process_denominator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND negotiating_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN negotiating_denominator ELSE 0 END) AS negotiating_denominator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND signed_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN signed_denominator ELSE 0 END) AS signed_denominator,
    -- Post-SQO Numerators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_to_discovery_numerator ELSE 0 END) AS sqo_to_discovery_numerator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND discovery_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN discovery_to_sales_process_numerator ELSE 0 END) AS discovery_to_sales_process_numerator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sales_process_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sales_process_to_negotiating_numerator ELSE 0 END) AS sales_process_to_negotiating_numerator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND negotiating_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN negotiating_to_signed_numerator ELSE 0 END) AS negotiating_to_signed_numerator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND signed_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN signed_to_joined_numerator ELSE 0 END) AS signed_to_joined_numerator,
    -- Combined Rates Denominators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_to_signed_denominator ELSE 0 END) AS sqo_to_signed_denominator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denominator,
    -- Combined Rates Numerators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_to_signed_numerator ELSE 0 END) AS sqo_to_signed_numerator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 QUARTER), QUARTER) 
             AND sqo_cohort_month < DATE_TRUNC(CURRENT_DATE(), QUARTER) 
             THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_numerator
  FROM
    `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  GROUP BY
    1, 2, 3, 4, 5, 6
),

-- 3. Year to Date (YTD)
YTD AS (
  SELECT
    3 AS sort_order,
    'Year to Date' AS time_period,
    SGA_Owner_Name__c,
    sgm_name,
    Original_source,
    Channel_Grouping_Name,
    -- Pre-SQO Denominators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN contacted_denominator ELSE 0 END) AS contacted_denominator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN mql_denominator ELSE 0 END) AS mql_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sql_denominator ELSE 0 END) AS sql_denominator,
    -- Pre-SQO Numerators (Lead-based, use SUM)
    -- UPDATED: Filter by event-based cohort months for each conversion rate
    SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN contacted_to_mql_numerator ELSE 0 END) AS contacted_to_mql_numerator,
    SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN mql_to_sql_numerator ELSE 0 END) AS mql_to_sql_numerator,
    -- SQL to SQO (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sql_cohort_month
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denominator,
    SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_numerator,
    -- Post-SQO Denominators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by sqo_cohort_month and corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_denominator ELSE 0 END) AS sqo_denominator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN discovery_denominator ELSE 0 END) AS discovery_denominator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sales_process_denominator ELSE 0 END) AS sales_process_denominator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN negotiating_denominator ELSE 0 END) AS negotiating_denominator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN signed_denominator ELSE 0 END) AS signed_denominator,
    -- Post-SQO Numerators (Opportunity-based, already COUNT DISTINCT in source, use SUM)
    -- UPDATED: Filter by corresponding stage cohort months
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_to_discovery_numerator ELSE 0 END) AS sqo_to_discovery_numerator,
    SUM(CASE WHEN discovery_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN discovery_to_sales_process_numerator ELSE 0 END) AS discovery_to_sales_process_numerator,
    SUM(CASE WHEN sales_process_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sales_process_to_negotiating_numerator ELSE 0 END) AS sales_process_to_negotiating_numerator,
    SUM(CASE WHEN negotiating_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN negotiating_to_signed_numerator ELSE 0 END) AS negotiating_to_signed_numerator,
    SUM(CASE WHEN signed_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN signed_to_joined_numerator ELSE 0 END) AS signed_to_joined_numerator,
    -- Combined Rates Denominators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_to_signed_denominator ELSE 0 END) AS sqo_to_signed_denominator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denominator,
    -- Combined Rates Numerators
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_to_signed_numerator ELSE 0 END) AS sqo_to_signed_numerator,
    SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(CURRENT_DATE(), YEAR) THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_numerator
  FROM
    `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  GROUP BY
    1, 2, 3, 4, 5, 6
)

-- Stack all three tables on top of each other
SELECT * FROM QTD
UNION ALL
SELECT * FROM LastQuarter
UNION ALL
SELECT * FROM YTD

