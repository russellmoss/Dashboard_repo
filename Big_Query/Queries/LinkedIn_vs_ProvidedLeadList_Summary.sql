-- Summary Query: LinkedIn (Self Sourced) vs Provided Lead List
-- Q1 2024 - Q3 2025 Conversion Rate Comparison
-- Use this query for quick reference or dashboard visualization

WITH QuarterlyData AS (
  SELECT
    DATE_TRUNC(cohort_month, QUARTER) AS quarter,
    FORMAT_DATE('%Y-Q%Q', DATE_TRUNC(cohort_month, QUARTER)) AS quarter_label,
    Original_source,
    -- Pre-SQO metrics
    SUM(contacted_denominator) AS contacted_denominator,
    SUM(contacted_to_mql_numerator) AS contacted_to_mql_numerator,
    SUM(mql_denominator) AS mql_denominator,
    SUM(mql_to_sql_numerator) AS mql_to_sql_numerator,
    -- SQL to SQO
    SUM(sql_to_sqo_denominator) AS sql_to_sqo_denominator,
    SUM(sql_to_sqo_numerator) AS sql_to_sqo_numerator,
    -- Rates
    SAFE_DIVIDE(SUM(contacted_to_mql_numerator), SUM(contacted_denominator)) AS contacted_to_mql_rate,
    SAFE_DIVIDE(SUM(mql_to_sql_numerator), SUM(mql_denominator)) AS mql_to_sql_rate,
    SAFE_DIVIDE(SUM(sql_to_sqo_numerator), SUM(sql_to_sqo_denominator)) AS sql_to_sqo_rate
  FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
    AND cohort_month >= '2024-01-01'
    AND cohort_month < '2025-10-01'
  GROUP BY 1, 2, 3
),

SummaryStats AS (
  SELECT
    Original_source,
    -- Counts
    SUM(sql_to_sqo_numerator) AS total_sqos,
    COUNT(*) AS n_quarters,
    -- Contacted to MQL
    AVG(contacted_to_mql_rate) AS avg_contacted_to_mql_rate,
    STDDEV(contacted_to_mql_rate) AS stddev_contacted_to_mql_rate,
    MIN(contacted_to_mql_rate) AS min_contacted_to_mql_rate,
    MAX(contacted_to_mql_rate) AS max_contacted_to_mql_rate,
    -- MQL to SQL
    AVG(mql_to_sql_rate) AS avg_mql_to_sql_rate,
    STDDEV(mql_to_sql_rate) AS stddev_mql_to_sql_rate,
    MIN(mql_to_sql_rate) AS min_mql_to_sql_rate,
    MAX(mql_to_sql_rate) AS max_mql_to_sql_rate,
    -- SQL to SQO
    AVG(sql_to_sqo_rate) AS avg_sql_to_sqo_rate,
    STDDEV(sql_to_sqo_rate) AS stddev_sql_to_sqo_rate,
    MIN(sql_to_sqo_rate) AS min_sql_to_sqo_rate,
    MAX(sql_to_sqo_rate) AS max_sql_to_sqo_rate
  FROM QuarterlyData
  GROUP BY Original_source
)

-- Quarterly Detail View
SELECT
  'Quarterly Detail' AS view_type,
  quarter_label,
  Original_source,
  contacted_denominator,
  contacted_to_mql_numerator,
  ROUND(contacted_to_mql_rate * 100, 2) AS contacted_to_mql_rate_pct,
  mql_denominator,
  mql_to_sql_numerator,
  ROUND(mql_to_sql_rate * 100, 2) AS mql_to_sql_rate_pct,
  sql_to_sqo_denominator,
  sql_to_sqo_numerator,
  ROUND(sql_to_sqo_rate * 100, 2) AS sql_to_sqo_rate_pct
FROM QuarterlyData

UNION ALL

-- Summary Statistics View
SELECT
  'Summary Stats' AS view_type,
  'All Quarters' AS quarter_label,
  Original_source,
  NULL AS contacted_denominator,
  NULL AS contacted_to_mql_numerator,
  ROUND(avg_contacted_to_mql_rate * 100, 2) AS contacted_to_mql_rate_pct,
  NULL AS mql_denominator,
  NULL AS mql_to_sql_numerator,
  ROUND(avg_mql_to_sql_rate * 100, 2) AS mql_to_sql_rate_pct,
  NULL AS sql_to_sqo_denominator,
  total_sqos AS sql_to_sqo_numerator,
  ROUND(avg_sql_to_sqo_rate * 100, 2) AS sql_to_sqo_rate_pct
FROM SummaryStats

ORDER BY view_type, quarter_label, Original_source














