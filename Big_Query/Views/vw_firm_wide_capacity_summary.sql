-- vw_firm_wide_capacity_summary: New view for high-level dashboard scorecards
-- Produces a single row of firm-wide aggregate metrics for capacity and health.
-- FINAL UPDATE: Includes "Active" (non-stale) pipeline metrics for both Quantity and Value.

WITH model_aggs AS (
  -- First CTE: Aggregate all metrics from the SGM capacity model
  SELECT
    SUM(required_sqos_per_quarter) AS total_required_sqos,
    SUM(current_pipeline_sqo_count) AS total_current_sqos,
    SUM(current_pipeline_stale_sqo_count) AS total_stale_sqos,
    SUM(current_pipeline_sqo_weighted_margin_aum_estimate) AS total_weighted_pipeline_value, -- (Total)
    SUM(current_pipeline_active_weighted_margin_aum_estimate) AS total_active_weighted_pipeline_value, -- (Active-Only)
    SUM(quarterly_target_margin_aum) AS total_target_value,
    SUM(current_pipeline_sqo_stale_margin_aum_estimate) AS total_stale_pipeline_value,
    SUM(current_pipeline_sqo_margin_aum_estimate) AS total_pipeline_value_estimate
  FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined` -- References the updated view
),

risk_aggs AS (
  -- Second CTE: Aggregate high-risk SQOs from the risk analysis view
  SELECT
    COUNT(DISTINCT Full_Opportunity_ID__c) AS total_at_risk_sqos
  FROM `savvy-gtm-analytics.savvy_forecast.vw_sqo_risk_analysis`
  WHERE risk_category = 'High Risk'
)

-- Final Select: Cross join to produce one row and calculate all percentages
SELECT
  -- Raw Counts
  m.total_required_sqos,
  m.total_current_sqos,
  m.total_stale_sqos,
  (m.total_current_sqos - m.total_stale_sqos) AS total_active_sqos,
  r.total_at_risk_sqos,

  -- Coverage & Health Percentages
  -- NOTE: These return decimal values (e.g., 1.546 = 154.6%)
  -- Format as percentage in Looker Studio (do NOT multiply by 100 in SQL)
  
  -- Quantity Percentages
  SAFE_DIVIDE(m.total_current_sqos, m.total_required_sqos) AS pipeline_sqo_coverage_pct, -- (Total) - Returns decimal, e.g., 1.546 = 154.6%
  SAFE_DIVIDE((m.total_current_sqos - m.total_stale_sqos), m.total_required_sqos) AS active_pipeline_sqo_coverage_pct, -- (Active-Only) - Returns decimal
  
  -- Value Percentages
  SAFE_DIVIDE(m.total_weighted_pipeline_value, m.total_target_value) AS pipeline_value_pct_of_target, -- (Total) - Returns decimal, e.g., 1.546 = 154.6%
  SAFE_DIVIDE(m.total_active_weighted_pipeline_value, m.total_target_value) AS active_pipeline_value_pct_of_target, -- (Active-Only) - Returns decimal
  
  -- Health Percentage
  SAFE_DIVIDE(m.total_stale_pipeline_value, m.total_pipeline_value_estimate) AS stale_pipeline_pct -- Returns decimal, e.g., 0.237 = 23.7%

FROM model_aggs m
CROSS JOIN risk_aggs r
