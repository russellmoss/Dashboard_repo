-- vw_sgm_capacity_coverage: Simplified view for Looker Studio Capacity & Coverage Dashboard
-- Provides executive-ready metrics: Capacity (Expected Joined AUM) and Coverage Ratio
-- Designed for high-level reporting and visualization
-- UPDATED: Includes "On Ramp" status logic based on SGM User CreatedDate
-- UPDATED: Uses stage_probability only (no double-counting with SQO→Joined conversion rate)
-- The weighted pipeline already accounts for stage-specific conversion probabilities

WITH Firm_Wide_Conversion_Rate AS (
  -- Calculate firm-wide average SQO to Joined conversion rate for fallback
  SELECT
    AVG(sqo_to_joined_conversion_rate) AS overall_sqo_to_joined_conversion_rate
  FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`
  WHERE sqo_to_joined_conversion_rate IS NOT NULL
    AND IsActive = TRUE
),
SGM_Data AS (
  SELECT
    r.sgm_name,
    r.sgm_user_id,
    r.Is_SGM__c,
    r.IsActive,
    r.current_pipeline_active_weighted_margin_aum_estimate,
    r.current_pipeline_sqo_weighted_margin_aum,
    r.current_pipeline_sqo_weighted_margin_aum_estimate,
    r.current_pipeline_sqo_margin_aum,
    r.current_pipeline_sqo_margin_aum_estimate,
    r.current_pipeline_sqo_count,
    r.current_pipeline_stale_sqo_count,
    r.sqo_to_joined_conversion_rate,
    r.avg_margin_aum_per_joined,
    r.enterprise_365_average_margin_aum,
    r.enterprise_365_sqo_to_joined_conversion,
    r.standard_365_average_margin_aum,
    r.standard_365_sqo_to_joined_conversion,
    r.required_sqos_per_quarter,
    r.current_quarter_joined_margin_aum,
    r.current_quarter_joined_pct_of_target,
    r.as_of_date,
    u.CreatedDate AS sgm_created_date,
    -- Determine if SGM is "On Ramp" (created within 120 days)
    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), DATE(u.CreatedDate), DAY) <= 120 THEN 1
      ELSE 0
    END AS is_on_ramp,
    -- Use firm-wide conversion rate for "On Ramp" SGMs, otherwise use individual rate
    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), DATE(u.CreatedDate), DAY) <= 120 
        THEN f.overall_sqo_to_joined_conversion_rate
      ELSE COALESCE(r.sqo_to_joined_conversion_rate, f.overall_sqo_to_joined_conversion_rate)
    END AS effective_sqo_to_joined_conversion_rate
  FROM `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined` r
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` u
    ON r.sgm_user_id = u.Id
  CROSS JOIN Firm_Wide_Conversion_Rate f
  WHERE r.IsActive = TRUE
)
SELECT
  sgm_name,
  sgm_user_id,
  Is_SGM__c,
  IsActive,
  
  -- TARGET
  36.75 AS quarterly_target_margin_aum_millions,
  
  -- CAPACITY CALCULATION (ESTIMATE VERSION)
  -- Expected Quarterly Joined AUM = Active Weighted Pipeline Value
  -- Uses estimates (includes fallback calculations for missing Margin_AUM__c)
  -- The weighted pipeline already accounts for stage-specific conversion probabilities (stage_probability)
  -- No additional conversion rate multiplication needed (would be double-counting)
  COALESCE(
    current_pipeline_active_weighted_margin_aum_estimate,
    0
  ) AS sgm_capacity_expected_joined_aum_millions_estimate,
  
  -- CAPACITY CALCULATION (ACTUAL VERSION - includes stale deals)
  -- Uses only actual Margin_AUM__c values (no estimates)
  -- NOTE: This includes stale deals, so it's higher than the active estimate version
  -- The weighted pipeline already accounts for stage-specific conversion probabilities
  COALESCE(
    current_pipeline_sqo_weighted_margin_aum,
    0
  ) AS sgm_capacity_expected_joined_aum_millions_actual_includes_stale,
  
  -- COVERAGE RATIO (ESTIMATE VERSION)
  -- Coverage = Capacity / Target
  -- 1.00 = Perfectly staffed, >1.00 = Sufficient capacity, <1.00 = Under-capacity
  -- Uses weighted pipeline directly (stage probabilities already accounted for)
  SAFE_DIVIDE(
    COALESCE(
      current_pipeline_active_weighted_margin_aum_estimate,
      0
    ),
    36.75
  ) AS coverage_ratio_estimate,
  
  -- COVERAGE RATIO (ACTUAL VERSION - includes stale deals)
  -- Uses weighted pipeline directly (stage probabilities already accounted for)
  SAFE_DIVIDE(
    COALESCE(
      current_pipeline_sqo_weighted_margin_aum,
      0
    ),
    36.75
  ) AS coverage_ratio_actual_includes_stale,
  
  -- *** COVERAGE STATUS LOGIC ***
  -- Checks for "On Ramp" status first (SGM created within 120 days)
  -- Uses weighted pipeline directly (stage probabilities already accounted for)
  CASE
    WHEN is_on_ramp = 1 THEN 'On Ramp'
    WHEN SAFE_DIVIDE(
      COALESCE(
        current_pipeline_active_weighted_margin_aum_estimate,
        0
      ),
      36.75
    ) >= 1.0 THEN 'Sufficient'
    WHEN SAFE_DIVIDE(
      COALESCE(
        current_pipeline_active_weighted_margin_aum_estimate,
        0
      ),
      36.75
    ) >= 0.85 THEN 'At Risk'
    ELSE 'Under-Capacity'
  END AS coverage_status,
  
  -- SUPPORTING METRICS (for context)
  -- Pipeline Values (both actual and estimate)
  -- ACTIVE (non-stale) weighted value - estimate only (most realistic for capacity planning)
  current_pipeline_active_weighted_margin_aum_estimate AS active_weighted_pipeline_value_millions_estimate,
  -- TOTAL weighted value (includes stale) - actual values only
  current_pipeline_sqo_weighted_margin_aum AS total_weighted_pipeline_value_millions_actual,
  -- TOTAL weighted value (includes stale) - with estimates
  current_pipeline_sqo_weighted_margin_aum_estimate AS total_weighted_pipeline_value_millions_estimate,
  -- Unweighted pipeline values
  current_pipeline_sqo_margin_aum AS pipeline_sqo_margin_aum_actual,
  current_pipeline_sqo_margin_aum_estimate AS pipeline_sqo_margin_aum_estimate,
  
  -- SQO Counts
  current_pipeline_sqo_count AS active_sqo_count,
  (current_pipeline_sqo_count - current_pipeline_stale_sqo_count) AS non_stale_sqo_count,
  current_pipeline_stale_sqo_count AS stale_sqo_count,
  
  -- Conversion Metrics (for reference only - not used in capacity calculations)
  sqo_to_joined_conversion_rate AS sqo_to_joined_conversion_rate, -- Individual rate (12-month historical, for reference)
  effective_sqo_to_joined_conversion_rate AS effective_sqo_to_joined_conversion_rate, -- For reference (not used in calculations)
  avg_margin_aum_per_joined AS avg_margin_aum_per_joined_millions,
  
  -- Enterprise/Standard Metrics (for Looker Studio scorecard visibility)
  -- These show which metrics are being used for required_sqos_per_quarter calculations
  enterprise_365_average_margin_aum AS enterprise_365_average_margin_aum,
  enterprise_365_sqo_to_joined_conversion AS enterprise_365_sqo_to_joined_conversion,
  standard_365_average_margin_aum AS standard_365_average_margin_aum,
  standard_365_sqo_to_joined_conversion AS standard_365_sqo_to_joined_conversion,
  required_sqos_per_quarter AS required_sqos_per_quarter, -- Uses enterprise metrics for Bre, standard for others
  
  -- CURRENT QUARTER ACTUALS (for comparison)
  current_quarter_joined_margin_aum AS current_quarter_actual_joined_aum_millions,
  current_quarter_joined_pct_of_target AS current_quarter_pct_of_target,
  
  -- GAP METRICS (using estimate - more complete)
  -- Uses weighted pipeline directly (stage probabilities already accounted for)
  36.75 - COALESCE(
    current_pipeline_active_weighted_margin_aum_estimate,
    0
  ) AS capacity_gap_millions_estimate,
  
  -- GAP METRICS (using actual - includes stale, so gap appears smaller)
  -- Uses weighted pipeline directly (stage probabilities already accounted for)
  36.75 - COALESCE(
    current_pipeline_sqo_weighted_margin_aum,
    0
  ) AS capacity_gap_millions_actual_includes_stale,
  
  as_of_date,
  sgm_created_date,
  is_on_ramp -- Flag indicating if SGM is On Ramp (for reference)

FROM SGM_Data
ORDER BY coverage_ratio_estimate ASC, sgm_name
