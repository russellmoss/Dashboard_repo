-- Comprehensive Statistical Analysis: LinkedIn (Self Sourced) vs Provided Lead List
-- Q1 2024 - Q3 2025
-- This query file contains all the key queries used in the statistical analysis

-- ============================================================================
-- PRIMARY METRIC: Contacted → SQO (End-to-End Efficiency)
-- ============================================================================

-- Step 1: Calculate Primary Metric Aggregates
WITH ContactedSQOData AS (
  SELECT
    Original_source,
    primary_key,
    is_contacted,
    is_sqo
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
    AND FilterDate >= '2024-01-01'
    AND FilterDate < '2025-10-01'
    AND is_contacted = 1
)

SELECT
  Original_source,
  COUNT(DISTINCT primary_key) AS total_contacted,
  COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN primary_key END) AS total_sqos_from_contacted,
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN primary_key END),
    COUNT(DISTINCT primary_key)
  ) AS contacted_to_sqo_rate
FROM ContactedSQOData
GROUP BY Original_source
ORDER BY Original_source;

-- ============================================================================
-- TWO-PROPORTION Z-TEST: Contacted → SQO
-- ============================================================================

WITH Aggregates AS (
  SELECT
    Original_source,
    COUNT(DISTINCT primary_key) AS total_contacted,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN primary_key END) AS total_sqos
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
    AND FilterDate >= '2024-01-01'
    AND FilterDate < '2025-10-01'
    AND is_contacted = 1
  GROUP BY Original_source
),

LinkedIn AS (
  SELECT total_contacted AS n1, total_sqos AS x1 FROM Aggregates WHERE Original_source = 'LinkedIn (Self Sourced)'
),

ProvidedList AS (
  SELECT total_contacted AS n2, total_sqos AS x2 FROM Aggregates WHERE Original_source = 'Provided Lead List'
),

Stats AS (
  SELECT
    li.n1,
    li.x1,
    pl.n2,
    pl.x2,
    li.x1 / li.n1 AS p1,
    pl.x2 / pl.n2 AS p2,
    (li.x1 + pl.x2) / (li.n1 + pl.n2) AS p_pooled
  FROM LinkedIn li
  CROSS JOIN ProvidedList pl
)

SELECT
  n1 AS linkedin_contacted,
  x1 AS linkedin_sqos,
  ROUND(p1 * 100, 4) AS linkedin_rate_pct,
  n2 AS provided_list_contacted,
  x2 AS provided_list_sqos,
  ROUND(p2 * 100, 4) AS provided_list_rate_pct,
  ROUND((p1 - p2) * 100, 4) AS rate_difference_pct,
  ROUND((p1 - p2) / SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2)), 4) AS z_score,
  ROUND(((p1 - p2) - 1.96 * SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2))) * 100, 4) AS ci_lower_pct,
  ROUND(((p1 - p2) + 1.96 * SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2))) * 100, 4) AS ci_upper_pct
FROM Stats;

-- ============================================================================
-- STAGED CONVERSION RATE AGGREGATES
-- ============================================================================

SELECT
  Original_source,
  -- Contacted → MQL
  SUM(contacted_denominator) AS total_contacted_denominator,
  SUM(contacted_to_mql_numerator) AS total_contacted_to_mql_numerator,
  SAFE_DIVIDE(SUM(contacted_to_mql_numerator), SUM(contacted_denominator)) AS contacted_to_mql_rate,
  -- MQL → SQL
  SUM(mql_denominator) AS total_mql_denominator,
  SUM(mql_to_sql_numerator) AS total_mql_to_sql_numerator,
  SAFE_DIVIDE(SUM(mql_to_sql_numerator), SUM(mql_denominator)) AS mql_to_sql_rate,
  -- SQL → SQO
  SUM(sql_to_sqo_denominator) AS total_sql_to_sqo_denominator,
  SUM(sql_to_sqo_numerator) AS total_sql_to_sqo_numerator,
  SAFE_DIVIDE(SUM(sql_to_sqo_numerator), SUM(sql_to_sqo_denominator)) AS sql_to_sqo_rate
FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
  AND cohort_month >= '2024-01-01'
  AND cohort_month < '2025-10-01'
GROUP BY Original_source
ORDER BY Original_source;

-- ============================================================================
-- QUARTERLY TREND: Contacted → SQO Rate
-- ============================================================================

SELECT
  FORMAT_DATE('%Y-Q%Q', DATE_TRUNC(FilterDate, QUARTER)) AS quarter_label,
  Original_source,
  COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN primary_key END) AS contacted_count,
  COUNT(DISTINCT CASE WHEN is_contacted = 1 AND is_sqo = 1 THEN primary_key END) AS sqo_count,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN is_contacted = 1 AND is_sqo = 1 THEN primary_key END),
      COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN primary_key END)
    ) * 100, 4
  ) AS contacted_to_sqo_rate_pct
FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
  AND FilterDate >= '2024-01-01'
  AND FilterDate < '2025-10-01'
GROUP BY 1, 2
ORDER BY quarter_label, Original_source;

-- ============================================================================
-- SENSITIVITY ANALYSIS: Excluding Q1 2024
-- ============================================================================

WITH AggregatesExcludingQ1 AS (
  SELECT
    Original_source,
    COUNT(DISTINCT primary_key) AS total_contacted,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN primary_key END) AS total_sqos
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  WHERE Original_source IN ('LinkedIn (Self Sourced)', 'Provided Lead List')
    AND FilterDate >= '2024-04-01'  -- Excluding Q1 2024
    AND FilterDate < '2025-10-01'
    AND is_contacted = 1
  GROUP BY Original_source
),

LinkedIn AS (
  SELECT total_contacted AS n1, total_sqos AS x1 FROM AggregatesExcludingQ1 WHERE Original_source = 'LinkedIn (Self Sourced)'
),

ProvidedList AS (
  SELECT total_contacted AS n2, total_sqos AS x2 FROM AggregatesExcludingQ1 WHERE Original_source = 'Provided Lead List'
),

Stats AS (
  SELECT
    li.n1,
    li.x1,
    pl.n2,
    pl.x2,
    li.x1 / li.n1 AS p1,
    pl.x2 / pl.n2 AS p2,
    (li.x1 + pl.x2) / (li.n1 + pl.n2) AS p_pooled
  FROM LinkedIn li
  CROSS JOIN ProvidedList pl
)

SELECT
  'Excluding Q1 2024' AS analysis_period,
  n1 AS linkedin_contacted,
  x1 AS linkedin_sqos,
  ROUND(p1 * 100, 4) AS linkedin_rate_pct,
  n2 AS provided_list_contacted,
  x2 AS provided_list_sqos,
  ROUND(p2 * 100, 4) AS provided_list_rate_pct,
  ROUND((p1 - p2) * 100, 4) AS rate_difference_pct,
  ROUND((p1 - p2) / SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2)), 4) AS z_score,
  ROUND(((p1 - p2) - 1.96 * SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2))) * 100, 4) AS ci_lower_pct,
  ROUND(((p1 - p2) + 1.96 * SQRT(p_pooled * (1 - p_pooled) * (1.0/n1 + 1.0/n2))) * 100, 4) AS ci_upper_pct
FROM Stats;














