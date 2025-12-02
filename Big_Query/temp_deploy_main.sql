CREATE OR REPLACE VIEW savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined AS
-- vw_sgm_capacity_model_refined: SGM Capacity Model with Quarterly Targets
-- Provides capacity planning metrics including:
-- - Quarterly Margin AUM target: $36,750,000 per SGM
-- - Required SQOs based on average Margin AUM per SQO
-- - Required Joined based on average Margin AUM per Joined
-- - Current pipeline analysis
-- - Gap analysis and pipeline sufficiency indicators

WITH Active_SGMs AS (
  SELECT DISTINCT
    u.Name AS sgm_name,
    u.Id AS sgm_user_id,
    u.Is_SGM__c,
    u.IsActive
  FROM `savvy-gtm-analytics.SavvyGTMData.User` u
  WHERE u.Is_SGM__c = TRUE 
    AND u.IsActive = TRUE
    AND u.Name NOT IN ('Savvy Marketing', 'Savvy Operations')
),

Current_Date_Context AS (
  SELECT
    CURRENT_DATE() AS current_date,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) AS current_quarter_start,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS last_quarter_start,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 6 MONTH) AS last_quarter_end,
    DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AS rolling_12_months_start,
    DATE_TRUNC(CURRENT_DATE(), YEAR) AS current_year_start
),

Opp_Base AS (
  SELECT
    o.Full_Opportunity_ID__c,
    o.CreatedDate AS Opp_CreatedDate,
    o.Underwritten_AUM__c,
    o.Margin_AUM__c,
    o.Amount,
    o.StageName,
    o.Date_Became_SQO__c,
    o.Stage_Entered_Signed__c,
    o.advisor_join_date__c,
    o.SQL__c AS SQO_raw,
    o.IsClosed,
    o.CloseDate,
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    opp_owner_user.Id AS sgm_user_id,
    COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM,
    CASE WHEN LOWER(o.SQL__c) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    CASE WHEN o.StageName = 'Signed' THEN 1 ELSE 0 END AS is_signed,
    DATE_TRUNC(DATE(o.CreatedDate), QUARTER) AS opp_created_quarter,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), QUARTER) AS sqo_quarter,
    DATE_TRUNC(DATE(o.advisor_join_date__c), QUARTER) AS joined_quarter,
    -- Pipeline status: is this opportunity currently in pipeline (not closed, not joined, not on hold, not closed lost, not null stage)
    -- Excludes: Closed opportunities, Joined opportunities, "Closed Lost" stage, "On Hold" stage, and NULL StageName
    -- This ensures we only count active, viable opportunities in the pipeline
    CASE 
      WHEN o.IsClosed = FALSE 
        AND o.advisor_join_date__c IS NULL 
        AND o.StageName != 'Closed Lost'
        AND o.StageName != 'On Hold'
        AND o.StageName IS NOT NULL
      THEN 1 
      ELSE 0 
    END AS is_in_pipeline,
    -- Stage probability from stage-to-joined probability lookup view
    COALESCE(cr.probability_to_join, 0) AS stage_probability,
    -- SQO age in days (for staleness calculation)
    -- Uses Date_Became_SQO__c instead of CreatedDate to measure sales cycle staleness
    -- This is more accurate because it measures time since the opportunity became a qualified SQO,
    -- not time since the opportunity was first created (which may include pre-qualification time)
    -- Only calculated for SQOs; NULL for non-SQOs since staleness is only relevant for SQOs
    CASE 
      WHEN LOWER(o.SQL__c) = 'yes' AND o.Date_Became_SQO__c IS NOT NULL
      THEN DATE_DIFF(c.current_date, DATE(o.Date_Became_SQO__c), DAY)
      ELSE NULL
    END AS sqo_age_days
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` cr
    ON o.StageName = cr.StageName
  CROSS JOIN Current_Date_Context c
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
),

-- Historical averages and conversion rates per SGM
SGM_Historical_Metrics AS (
  SELECT
    o.sgm_name,
    -- Average Margin AUM per SQO (historical, last 12 months)
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN SUM(CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Margin_AUM__c ELSE 0 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS avg_margin_aum_per_sqo,
    -- Average Margin AUM per Joined (historical, last 12 months)
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN SUM(CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Margin_AUM__c ELSE 0 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS avg_margin_aum_per_joined,
    -- SQO to Joined conversion rate (historical, last 12 months)
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND o.is_joined = 1
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS sqo_to_joined_conversion_rate,
    -- Total SQOs in last 12 months (for context)
    COUNT(DISTINCT CASE 
      WHEN o.is_sqo = 1 
      AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
      THEN o.Full_Opportunity_ID__c 
    END) AS historical_sqo_count_12m,
    -- Total Joined in last 12 months (for context)
    COUNT(DISTINCT CASE 
      WHEN o.is_joined = 1 
      AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
      THEN o.Full_Opportunity_ID__c 
    END) AS historical_joined_count_12m
  FROM Opp_Base o
  CROSS JOIN Current_Date_Context c
  WHERE o.sgm_name IS NOT NULL
  GROUP BY o.sgm_name
),

-- Overall averages (fallback if SGM doesn't have enough history)
Overall_Historical_Metrics AS (
  SELECT
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN SUM(CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Margin_AUM__c ELSE 0 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS overall_avg_margin_aum_per_sqo,
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN SUM(CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Margin_AUM__c ELSE 0 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_joined = 1 
        AND DATE(o.advisor_join_date__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS overall_avg_margin_aum_per_joined,
    CASE 
      WHEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) > 0
      THEN COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND o.is_joined = 1
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END) / COUNT(DISTINCT CASE 
        WHEN o.is_sqo = 1 
        AND DATE(o.Date_Became_SQO__c) >= c.rolling_12_months_start
        THEN o.Full_Opportunity_ID__c 
      END)
      ELSE NULL
    END AS overall_sqo_to_joined_conversion_rate
  FROM Opp_Base o
  CROSS JOIN Current_Date_Context c
  WHERE o.sgm_name IS NOT NULL
),

-- Current pipeline status per SGM
SGM_Current_Pipeline AS (
  SELECT
    o.sgm_name,
    -- Current pipeline SQOs (in pipeline, not closed, not joined)
    COUNT(DISTINCT CASE 
      WHEN o.is_sqo = 1 
      AND o.is_in_pipeline = 1
      THEN o.Full_Opportunity_ID__c 
    END) AS current_pipeline_sqo_count,
    -- Current pipeline SQO Margin AUM
    SUM(CASE 
      WHEN o.is_sqo = 1 
      AND o.is_in_pipeline = 1
      THEN COALESCE(o.Margin_AUM__c, 0) ELSE 0 
    END) AS current_pipeline_sqo_margin_aum,
    -- Current pipeline SQO Weighted Margin AUM (Margin AUM * stage probability)
    SUM(CASE 
      WHEN o.is_sqo = 1 
      AND o.is_in_pipeline = 1
      THEN COALESCE(o.Margin_AUM__c, 0) * o.stage_probability
      ELSE 0 
    END) AS current_pipeline_sqo_weighted_margin_aum,
    -- Current pipeline SQO Stale Margin AUM (SQOs older than 120 days from Date_Became_SQO__c)
    -- Staleness threshold: 120 days (based on data analysis showing average SQO-to-Joined cycle is 77 days,
    -- with 90th percentile at 148 days. 120 days flags ~17% of deals, catching at-risk opportunities
    -- while not over-flagging normal sales cycles)
    -- This metric helps identify pipeline health risks and can be used to filter out stale deals
    -- to avoid over-inflating pipeline numbers when assessing capacity sufficiency
    SUM(CASE 
      WHEN o.is_sqo = 1
      AND o.is_in_pipeline = 1
      AND o.sqo_age_days IS NOT NULL
      AND o.sqo_age_days > 120
      THEN COALESCE(o.Margin_AUM__c, 0)
      ELSE 0 
    END) AS current_pipeline_sqo_stale_margin_aum,
    -- Current pipeline opportunities (all stages, in pipeline)
    COUNT(DISTINCT CASE 
      WHEN o.is_in_pipeline = 1
      THEN o.Full_Opportunity_ID__c 
    END) AS current_pipeline_opp_count,
    -- Current pipeline Margin AUM (all stages)
    SUM(CASE 
      WHEN o.is_in_pipeline = 1
      THEN COALESCE(o.Margin_AUM__c, 0) ELSE 0 
    END) AS current_pipeline_margin_aum,
    -- Current quarter SQOs (became SQO this quarter)
    COUNT(DISTINCT CASE 
      WHEN o.is_sqo = 1 
      AND o.sqo_quarter = c.current_quarter_start
      THEN o.Full_Opportunity_ID__c 
    END) AS current_quarter_sqo_count,
    -- Current quarter SQO Margin AUM
    SUM(CASE 
      WHEN o.is_sqo = 1 
      AND o.sqo_quarter = c.current_quarter_start
      THEN COALESCE(o.Margin_AUM__c, 0) ELSE 0 
    END) AS current_quarter_sqo_margin_aum,
    -- Current quarter Joined
    COUNT(DISTINCT CASE 
      WHEN o.is_joined = 1 
      AND o.joined_quarter = c.current_quarter_start
      THEN o.Full_Opportunity_ID__c 
    END) AS current_quarter_joined_count,
    -- Current quarter Joined Margin AUM
    SUM(CASE 
      WHEN o.is_joined = 1 
      AND o.joined_quarter = c.current_quarter_start
      THEN COALESCE(o.Margin_AUM__c, 0) ELSE 0 
    END) AS current_quarter_joined_margin_aum
  FROM Opp_Base o
  CROSS JOIN Current_Date_Context c
  WHERE o.sgm_name IS NOT NULL
  GROUP BY o.sgm_name
)

SELECT
  sgm.sgm_name,
  sgm.sgm_user_id,
  sgm.Is_SGM__c,
  sgm.IsActive,
  
  -- TARGET
  36750000 AS quarterly_target_margin_aum,
  
  -- HISTORICAL METRICS (for calculations)
  COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo) AS avg_margin_aum_per_sqo,
  COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined) AS avg_margin_aum_per_joined,
  COALESCE(h.sqo_to_joined_conversion_rate, o.overall_sqo_to_joined_conversion_rate) AS sqo_to_joined_conversion_rate,
  h.historical_sqo_count_12m,
  h.historical_joined_count_12m,
  
  -- REQUIRED CALCULATIONS
  -- Required SQOs to meet quarterly target
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo) > 0
    THEN CEILING(36750000 / COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo))
    ELSE NULL
  END AS required_sqos_per_quarter,
  -- Required Joined to meet quarterly target
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined) > 0
    THEN CEILING(36750000 / COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined))
    ELSE NULL
  END AS required_joined_per_quarter,
  -- Required SQOs accounting for conversion rate (if we need X Joined, we need X / conversion_rate SQOs)
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined) > 0
      AND COALESCE(h.sqo_to_joined_conversion_rate, o.overall_sqo_to_joined_conversion_rate) > 0
    THEN CEILING(
      (36750000 / COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined)) 
      / COALESCE(h.sqo_to_joined_conversion_rate, o.overall_sqo_to_joined_conversion_rate)
    )
    ELSE NULL
  END AS required_sqos_with_conversion_rate,
  
  -- CURRENT PIPELINE STATUS
  COALESCE(p.current_pipeline_sqo_count, 0) AS current_pipeline_sqo_count,
  COALESCE(p.current_pipeline_sqo_margin_aum, 0) AS current_pipeline_sqo_margin_aum,
  COALESCE(p.current_pipeline_sqo_weighted_margin_aum, 0) AS current_pipeline_sqo_weighted_margin_aum,
  COALESCE(p.current_pipeline_sqo_stale_margin_aum, 0) AS current_pipeline_sqo_stale_margin_aum,
  COALESCE(p.current_pipeline_opp_count, 0) AS current_pipeline_opp_count,
  COALESCE(p.current_pipeline_margin_aum, 0) AS current_pipeline_margin_aum,
  
  -- CURRENT QUARTER ACTUALS
  COALESCE(p.current_quarter_sqo_count, 0) AS current_quarter_sqo_count,
  COALESCE(p.current_quarter_sqo_margin_aum, 0) AS current_quarter_sqo_margin_aum,
  COALESCE(p.current_quarter_joined_count, 0) AS current_quarter_joined_count,
  COALESCE(p.current_quarter_joined_margin_aum, 0) AS current_quarter_joined_margin_aum,
  
  -- GAP ANALYSIS
  -- Gap: Required SQOs vs Current Pipeline SQOs
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo) > 0
    THEN CEILING(36750000 / COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo)) 
         - COALESCE(p.current_pipeline_sqo_count, 0)
    ELSE NULL
  END AS sqo_gap_count,
  -- Gap: Required Margin AUM vs Current Pipeline Margin AUM
  36750000 - COALESCE(p.current_pipeline_sqo_margin_aum, 0) AS margin_aum_gap,
  -- Gap: Required Joined vs Current Quarter Joined
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined) > 0
    THEN CEILING(36750000 / COALESCE(h.avg_margin_aum_per_joined, o.overall_avg_margin_aum_per_joined)) 
         - COALESCE(p.current_quarter_joined_count, 0)
    ELSE NULL
  END AS joined_gap_count,
  -- Gap: Target Margin AUM vs Current Quarter Joined Margin AUM
  36750000 - COALESCE(p.current_quarter_joined_margin_aum, 0) AS joined_margin_aum_gap,
  
  -- PIPELINE SUFFICIENCY INDICATORS
  -- Do we have enough SQOs in pipeline?
  CASE 
    WHEN COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo) > 0
      AND COALESCE(p.current_pipeline_sqo_count, 0) >= 
          CEILING(36750000 / COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo))
    THEN 'Yes'
    WHEN COALESCE(h.avg_margin_aum_per_sqo, o.overall_avg_margin_aum_per_sqo) > 0
    THEN 'No'
    ELSE 'Unknown'
  END AS has_sufficient_sqos_in_pipeline,
  -- Do we have enough Margin AUM in pipeline?
  CASE 
    WHEN COALESCE(p.current_pipeline_sqo_margin_aum, 0) >= 36750000
    THEN 'Yes'
    ELSE 'No'
  END AS has_sufficient_margin_aum_in_pipeline,
  -- Are we on track for quarterly target?
  CASE 
    WHEN COALESCE(p.current_quarter_joined_margin_aum, 0) >= 36750000
    THEN 'On Track'
    WHEN COALESCE(p.current_quarter_joined_margin_aum, 0) > 0
    THEN 'Behind'
    ELSE 'No Activity'
  END AS quarterly_target_status,
  
  -- PERCENTAGE OF TARGET
  CASE 
    WHEN COALESCE(p.current_pipeline_sqo_margin_aum, 0) > 0
    THEN ROUND((COALESCE(p.current_pipeline_sqo_margin_aum, 0) / 36750000) * 100, 1)
    ELSE 0
  END AS pipeline_margin_aum_pct_of_target,
  CASE 
    WHEN COALESCE(p.current_quarter_joined_margin_aum, 0) > 0
    THEN ROUND((COALESCE(p.current_quarter_joined_margin_aum, 0) / 36750000) * 100, 1)
    ELSE 0
  END AS current_quarter_joined_pct_of_target,
  
  -- CURRENT DATE
  CURRENT_DATE() AS as_of_date

FROM Active_SGMs sgm
LEFT JOIN SGM_Historical_Metrics h
  ON sgm.sgm_name = h.sgm_name
CROSS JOIN Overall_Historical_Metrics o
LEFT JOIN SGM_Current_Pipeline p
  ON sgm.sgm_name = p.sgm_name
ORDER BY sgm.sgm_name

