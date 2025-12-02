-- SQL to SQO Conversion Rate Analysis by SGM
-- Date Range: Oct 1 to Nov 19, 2025
-- Includes: Individual SGM rates, 12-month trailing rates, QTD and YTD averages
--
-- Uses vw_conversion_rates directly to match Looker dashboard calculations:
-- - Groups by cohort_month (already done in vw_conversion_rates)
-- - SUM numerators and denominators across months (matching Looker aggregation)
-- - Final calculation: SUM(sql_to_sqo_numerator) / SUM(sql_to_sqo_denominator)

WITH
-- Period 1: Oct 1 to Nov 19, 2025
-- Filter to October and November 2025 cohort months, then SUM across months
period_oct_nov AS (
  SELECT
    sgm_name,
    SUM(sql_to_sqo_denominator) AS sql_to_sqo_denominator,
    SUM(sql_to_sqo_numerator) AS sql_to_sqo_numerator
  FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  WHERE sgm_name IS NOT NULL
    AND cohort_month IN ('2025-10-01', '2025-11-01')  -- October and November 2025
  GROUP BY sgm_name
),

-- Period 2: Last 12 months (trailing 12 months from Nov 19, 2025)
period_12mo AS (
  SELECT
    sgm_name,
    SUM(sql_to_sqo_denominator) AS sql_to_sqo_denominator,
    SUM(sql_to_sqo_numerator) AS sql_to_sqo_numerator
  FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  WHERE sgm_name IS NOT NULL
    AND cohort_month >= DATE_TRUNC(DATE_SUB('2025-11-19', INTERVAL 12 MONTH), MONTH)
    AND cohort_month <= DATE_TRUNC('2025-11-19', MONTH)  -- Last 12 months
  GROUP BY sgm_name
),

-- Period 3: Quarter to Date (Q4 2025: Oct 1 to Nov 19, 2025)
-- All SGMs combined
period_qtd AS (
  SELECT
    SUM(sql_to_sqo_denominator) AS sql_to_sqo_denominator,
    SUM(sql_to_sqo_numerator) AS sql_to_sqo_numerator
  FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  WHERE sgm_name IS NOT NULL
    AND cohort_month IN ('2025-10-01', '2025-11-01')  -- Q4 months
),

-- Period 4: Year to Date (Jan 1, 2025 to Nov 19, 2025)
-- All SGMs combined
period_ytd AS (
  SELECT
    SUM(sql_to_sqo_denominator) AS sql_to_sqo_denominator,
    SUM(sql_to_sqo_numerator) AS sql_to_sqo_numerator
  FROM `savvy-gtm-analytics.savvy_analytics.vw_conversion_rates`
  WHERE sgm_name IS NOT NULL
    AND cohort_month >= '2025-01-01'
    AND cohort_month <= DATE_TRUNC('2025-11-19', MONTH)  -- Year start to Nov 19
)

-- Main output: Individual SGM metrics with aggregated totals
-- Note: QTD and YTD metrics are repeated on each row for easy comparison
SELECT
  COALESCE(p1.sgm_name, p12.sgm_name) AS sgm_name,
  
  -- Oct 1 to Nov 19, 2025 metrics (per SGM)
  COALESCE(p1.sql_to_sqo_denominator, 0) AS sql_to_sqo_denominator_oct_nov,
  COALESCE(p1.sql_to_sqo_numerator, 0) AS sql_to_sqo_numerator_oct_nov,
  ROUND(SAFE_DIVIDE(COALESCE(p1.sql_to_sqo_numerator, 0), NULLIF(COALESCE(p1.sql_to_sqo_denominator, 0), 0)), 4) AS conversion_rate_oct_nov,
  
  -- Last 12 months metrics (per SGM)
  COALESCE(p12.sql_to_sqo_denominator, 0) AS sql_to_sqo_denominator_12mo,
  COALESCE(p12.sql_to_sqo_numerator, 0) AS sql_to_sqo_numerator_12mo,
  ROUND(SAFE_DIVIDE(COALESCE(p12.sql_to_sqo_numerator, 0), NULLIF(COALESCE(p12.sql_to_sqo_denominator, 0), 0)), 4) AS conversion_rate_12mo,
  
  -- Quarter to Date (All SGMs combined - same values on each row)
  p_qtd.sql_to_sqo_denominator AS qtd_sql_to_sqo_denominator,
  p_qtd.sql_to_sqo_numerator AS qtd_sql_to_sqo_numerator,
  ROUND(SAFE_DIVIDE(p_qtd.sql_to_sqo_numerator, NULLIF(p_qtd.sql_to_sqo_denominator, 0)), 4) AS qtd_avg_conversion_rate,
  
  -- Year to Date (All SGMs combined - same values on each row)
  p_ytd.sql_to_sqo_denominator AS ytd_sql_to_sqo_denominator,
  p_ytd.sql_to_sqo_numerator AS ytd_sql_to_sqo_numerator,
  ROUND(SAFE_DIVIDE(p_ytd.sql_to_sqo_numerator, NULLIF(p_ytd.sql_to_sqo_denominator, 0)), 4) AS ytd_avg_conversion_rate

FROM period_oct_nov p1
FULL OUTER JOIN period_12mo p12
  ON p1.sgm_name = p12.sgm_name
CROSS JOIN period_qtd p_qtd
CROSS JOIN period_ytd p_ytd

ORDER BY sgm_name;

