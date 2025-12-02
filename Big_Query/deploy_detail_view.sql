CREATE OR REPLACE VIEW `savvy-gtm-analytics.savvy_analytics.vw_sgm_open_sqos_detail` AS 
WITH Dynamic_Valuation_Params AS (
  SELECT 
    COALESCE(AVG(SAFE_DIVIDE(Underwritten_AUM__c, Margin_AUM__c)), 3.30) AS dyn_und_div,
    COALESCE(AVG(SAFE_DIVIDE(Amount, Margin_AUM__c)), 3.80) AS dyn_amt_div
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity`
  WHERE StageName = 'Joined' 
    AND Margin_AUM__c > 0
    AND advisor_join_date__c >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),

Active_SGMs AS (
  SELECT DISTINCT
    u.Name AS sgm_name,
    u.Id AS sgm_user_id
  FROM `savvy-gtm-analytics.SavvyGTMData.User` u
  WHERE u.Is_SGM__c = TRUE 
    AND u.IsActive = TRUE
    AND u.Name NOT IN ('Savvy Marketing', 'Savvy Operations')
),

Current_Date_Context AS (
  SELECT 
    CURRENT_DATE() AS current_date,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) AS current_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS current_quarter_end,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS next_quarter_start,
    DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 6 MONTH) AS next_quarter_end
),

Opp_Base AS (
  SELECT
    o.*,
    opp_owner_user.Name AS sgm_name,
    opp_owner_user.Id AS sgm_user_id,
    CASE
      WHEN o.Date_Became_SQO__c IS NOT NULL AND o.advisor_join_date__c IS NULL THEN
        CASE
          WHEN (CASE WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c ELSE COALESCE((o.Underwritten_AUM__c / vp.dyn_und_div) * 1000000, (o.Amount / vp.dyn_amt_div) * 1000000) END) >= 30000000 THEN
            CASE
              WHEN o.Stage_Entered_Signed__c IS NOT NULL AND DATE(o.Stage_Entered_Signed__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 38 DAY)
              WHEN o.Stage_Entered_Negotiating__c IS NOT NULL AND DATE(o.Stage_Entered_Negotiating__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 49 DAY)
              WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL AND DATE(o.Stage_Entered_Sales_Process__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 94 DAY)
              ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 120 DAY)
            END
          WHEN (CASE WHEN o.Margin_AUM__c IS NOT NULL AND o.Margin_AUM__c > 0 THEN o.Margin_AUM__c ELSE COALESCE((o.Underwritten_AUM__c / vp.dyn_und_div) * 1000000, (o.Amount / vp.dyn_amt_div) * 1000000) END) >= 15000000 THEN
            CASE
              WHEN o.Stage_Entered_Signed__c IS NOT NULL AND DATE(o.Stage_Entered_Signed__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 18 DAY)
              WHEN o.Stage_Entered_Negotiating__c IS NOT NULL AND DATE(o.Stage_Entered_Negotiating__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 37 DAY)
              WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL AND DATE(o.Stage_Entered_Sales_Process__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 66 DAY)
              ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 90 DAY)
            END
          ELSE
            CASE
              WHEN o.Stage_Entered_Signed__c IS NOT NULL AND DATE(o.Stage_Entered_Signed__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Signed__c), INTERVAL 10 DAY)
              WHEN o.Stage_Entered_Negotiating__c IS NOT NULL AND DATE(o.Stage_Entered_Negotiating__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Negotiating__c), INTERVAL 18 DAY)
              WHEN o.Stage_Entered_Sales_Process__c IS NOT NULL AND DATE(o.Stage_Entered_Sales_Process__c) <= c.current_date
                THEN DATE_ADD(DATE(o.Stage_Entered_Sales_Process__c), INTERVAL 49 DAY)
              ELSE DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 50 DAY)
            END
        END
      ELSE NULL
    END AS velocity_projected_close_date
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  CROSS JOIN Current_Date_Context c
  CROSS JOIN Dynamic_Valuation_Params vp
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
    AND LOWER(o.SQL__c) = 'yes'
    AND o.IsClosed = FALSE
    AND o.advisor_join_date__c IS NULL
    AND o.StageName != 'Closed Lost'
    AND o.StageName != 'On Hold'
    AND o.StageName IS NOT NULL
)

SELECT
  ob.sgm_name,
  ob.sgm_user_id,
  ob.Name AS opportunity_name,
  ob.Full_Opportunity_ID__c,
  ob.StageName,
  ob.Date_Became_SQO__c,
  -- All AUM values are divided by 1,000,000 to present in millions
  ob.Margin_AUM__c / 1000000 AS Margin_AUM__c,
  ob.Underwritten_AUM__c / 1000000 AS Underwritten_AUM__c,
  ob.Amount / 1000000 AS Amount,
  COALESCE(ob.Underwritten_AUM__c, ob.Amount) / 1000000 AS Opportunity_AUM,
  -- Estimated Margin_AUM__c using V2 dynamic fallback logic:
  -- 1. Use actual Margin_AUM__c if available and > 0
  -- 2. If Margin_AUM__c is NULL or 0, estimate from Underwritten_AUM__c using dynamic divisor (3.30)
  -- 3. If both are NULL or 0, estimate from Amount using dynamic divisor (3.80)
  -- Dynamic divisors are calculated from recent joined deals (last 12 months) for better accuracy
  -- Result is divided by 1,000,000 to present in millions
  CASE
    WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000
    WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000
    WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000
    ELSE 0
  END AS estimated_margin_aum,
  -- Days open since becoming SQO
  CASE 
    WHEN ob.Date_Became_SQO__c IS NOT NULL
    THEN DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY)
    ELSE NULL
  END AS days_open_since_sqo,
  -- Is this stale? (V2 Logic - Deal-size dependent thresholds)
  -- Small deals (<$5M): Stale if >90 days
  -- Medium deals ($5M-$15M): Stale if >120 days
  -- Large deals ($15M-$30M): Stale if >180 days
  -- Enterprise deals (â‰¥$30M): Stale if >240 days
  CASE 
    WHEN ob.Date_Became_SQO__c IS NOT NULL THEN
      CASE
        WHEN (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) < 5
          AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 90
        THEN 'Yes'
        WHEN (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) >= 5
          AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) < 15
          AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 120
        THEN 'Yes'
        WHEN (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) >= 15
          AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) < 30
          AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 180
        THEN 'Yes'
        WHEN (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 ELSE COALESCE((ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000, (ob.Amount / vp.dyn_amt_div) / 1000000) END) >= 30
          AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 240
        THEN 'Yes'
        ELSE 'No'
      END
    ELSE 'N/A'
  END AS is_stale,
  ob.CreatedDate AS opp_created_date,
  ob.CloseDate,
  ob.IsClosed,
  ob.advisor_join_date__c,
  -- Pipeline status
  CASE 
    WHEN ob.IsClosed = FALSE 
      AND ob.advisor_join_date__c IS NULL 
      AND ob.StageName != 'Closed Lost'
      AND ob.StageName != 'On Hold'
      AND ob.StageName IS NOT NULL
    THEN 'In Pipeline'
    ELSE 'Not In Pipeline'
  END AS pipeline_status,
  -- Velocity-Based Forecasting Fields (V2 Logic - Deal-size + Stage dependent cycle times)
  -- 1. The Physics-Based Close Date (using deal-size dependent cycle times and current stage)
  -- Enterprise (>$30M): Signed=38d, Negotiating=49d, Sales Process=94d, Default=120d
  -- Large ($15M-$30M): Signed=18d, Negotiating=37d, Sales Process=66d, Default=90d
  -- Standard (<$15M): Signed=10d, Negotiating=18d, Sales Process=49d, Default=50d
  ob.velocity_projected_close_date,
  -- 2. The Forecast Bucket (Where does it land? - Uses V2 deal-size + stage dependent velocity)
  CASE 
    -- If it's already closed/joined
    WHEN ob.advisor_join_date__c IS NOT NULL THEN 
        CASE 
            WHEN DATE_TRUNC(ob.advisor_join_date__c, QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN '1. Closed (Current Qtr)'
            ELSE '0. Closed (Past/Future)'
        END
    -- If it's Open but "Overdue" (Projected date has passed) -> Push to "Slip Risk" bucket
    WHEN ob.Date_Became_SQO__c IS NOT NULL
      AND ob.velocity_projected_close_date IS NOT NULL
      AND ob.velocity_projected_close_date < c.current_date
    THEN '3. Overdue / Slip Risk'
    -- If Physics says it lands This Quarter
    WHEN ob.Date_Became_SQO__c IS NOT NULL
      AND DATE_TRUNC(ob.velocity_projected_close_date, QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) 
    THEN '2. Forecast (Current Qtr)'
    -- If Physics says it lands Next Quarter
    WHEN ob.Date_Became_SQO__c IS NOT NULL
      AND DATE_TRUNC(ob.velocity_projected_close_date, QUARTER) = DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 1 QUARTER) 
    THEN '4. Forecast (Next Qtr)'
    -- Future quarters
    WHEN ob.Date_Became_SQO__c IS NOT NULL
    THEN '5. Forecast (Future)'
    ELSE NULL
  END AS forecast_bucket,
  -- FORECAST WEIGHT COLUMNS (for verification against vw_sgm_capacity_coverage_with_forecast)
  -- Stage probability (conversion weight from vw_stage_to_joined_probability)
  COALESCE(cr.probability_to_join, 0) AS stage_probability,
  -- Forecast quarter assignment (matching vw_sgm_capacity_coverage_with_forecast logic)
  -- Compares velocity_projected_close_date to quarter boundaries
  CASE
    WHEN ob.Date_Became_SQO__c IS NOT NULL AND ob.advisor_join_date__c IS NULL AND ob.velocity_projected_close_date IS NOT NULL THEN
      CASE
        WHEN ob.velocity_projected_close_date <= c.current_quarter_end THEN 'Current Quarter'
        WHEN ob.velocity_projected_close_date <= c.next_quarter_end THEN 'Next Quarter'
        ELSE 'Beyond Next Quarter'
      END
    ELSE NULL
  END AS forecast_quarter,
  -- Stale decay factor (0.80 if >180 days, else 1.0) - matching forecast view logic
  CASE
    WHEN ob.Date_Became_SQO__c IS NOT NULL AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 180 THEN 0.80
    ELSE 1.0
  END AS stale_decay_factor,
  -- Weighted margin AUM estimate (used in forecast calculations)
  -- Formula: estimated_margin_aum Ã— stage_probability Ã— stale_decay_factor
  -- This matches the calculation in vw_sgm_capacity_coverage_with_forecast
  CASE
    WHEN ob.IsClosed = FALSE 
      AND ob.advisor_join_date__c IS NULL 
      AND ob.StageName != 'Closed Lost'
      AND ob.StageName != 'On Hold'
      AND ob.StageName IS NOT NULL
      AND LOWER(ob.SQL__c) = 'yes'
      -- Check if deal is not stale (using deal-size dependent thresholds)
      AND (
        ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 5 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 90))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 5 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 15 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 120))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 15 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 180))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 240))
      )
      -- Check if forecast_quarter is Current or Next Quarter
      AND (
        (ob.velocity_projected_close_date IS NOT NULL AND ob.velocity_projected_close_date <= c.current_quarter_end)
        OR (ob.velocity_projected_close_date IS NOT NULL AND ob.velocity_projected_close_date <= c.next_quarter_end)
      )
    THEN (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) * COALESCE(cr.probability_to_join, 0) * 
      CASE
        WHEN ob.Date_Became_SQO__c IS NOT NULL AND DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) > 180 THEN 0.80
        ELSE 1.0
      END
    ELSE 0
  END AS weighted_margin_aum_estimate,
  -- Boolean flags for forecast inclusion
  CASE
    WHEN ob.IsClosed = FALSE 
      AND ob.advisor_join_date__c IS NULL 
      AND ob.StageName != 'Closed Lost'
      AND ob.StageName != 'On Hold'
      AND ob.StageName IS NOT NULL
      AND LOWER(ob.SQL__c) = 'yes'
      AND (
        ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 5 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 90))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 5 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 15 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 120))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 15 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 180))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 240))
      )
      AND ob.velocity_projected_close_date IS NOT NULL 
      AND ob.velocity_projected_close_date <= c.current_quarter_end
    THEN 1
    ELSE 0
  END AS is_in_current_quarter_forecast,
  CASE
    WHEN ob.IsClosed = FALSE 
      AND ob.advisor_join_date__c IS NULL 
      AND ob.StageName != 'Closed Lost'
      AND ob.StageName != 'On Hold'
      AND ob.StageName IS NOT NULL
      AND LOWER(ob.SQL__c) = 'yes'
      AND (
        ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 5 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 90))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 5 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 15 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 120))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 15 AND (CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) < 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 180))
        OR ((CASE WHEN ob.Margin_AUM__c IS NOT NULL AND ob.Margin_AUM__c > 0 THEN ob.Margin_AUM__c / 1000000 WHEN ob.Underwritten_AUM__c IS NOT NULL AND ob.Underwritten_AUM__c > 0 THEN (ob.Underwritten_AUM__c / vp.dyn_und_div) / 1000000 WHEN ob.Amount IS NOT NULL AND ob.Amount > 0 THEN (ob.Amount / vp.dyn_amt_div) / 1000000 ELSE 0 END) >= 30 AND (ob.Date_Became_SQO__c IS NULL OR DATE_DIFF(c.current_date, DATE(ob.Date_Became_SQO__c), DAY) <= 240))
      )
      AND ob.velocity_projected_close_date IS NOT NULL 
      AND ob.velocity_projected_close_date > c.current_quarter_end
      AND ob.velocity_projected_close_date <= c.next_quarter_end
    THEN 1
    ELSE 0
  END AS is_in_next_quarter_forecast

FROM Opp_Base ob
LEFT JOIN `savvy-gtm-analytics.savvy_analytics.vw_stage_to_joined_probability` cr
  ON ob.StageName = cr.StageName
CROSS JOIN Current_Date_Context c
CROSS JOIN Dynamic_Valuation_Params vp
ORDER BY 
  ob.sgm_name,
  ob.Date_Became_SQO__c DESC


