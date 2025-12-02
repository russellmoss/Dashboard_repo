-- vw_sgm_capacity_model: SGM Capacity Model View
-- Provides aggregated metrics by SGM including AUM, Margin AUM, and opportunity counts
-- Supports multiple time period aggregations for capacity planning

WITH Active_SGMs AS (
  -- Get list of active SGMs
  SELECT DISTINCT
    u.Name AS sgm_name,
    u.Id AS sgm_user_id
  FROM `savvy-gtm-analytics.SavvyGTMData.User` u
  WHERE u.Is_SGM__c = TRUE 
    AND u.IsActive = TRUE
    AND u.Name NOT IN ('Savvy Marketing', 'Savvy Operations')
),

Opp_Base AS (
  -- Base opportunity data with SGM identification and AUM fields
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
    -- SGM identification from opportunity owner
    CASE WHEN opp_owner_user.Is_SGM__c = TRUE THEN opp_owner_user.Name ELSE NULL END AS sgm_name,
    opp_owner_user.Id AS sgm_user_id,
    -- Calculate Opportunity AUM (fallback to Amount if Underwritten_AUM is null)
    COALESCE(o.Underwritten_AUM__c, o.Amount) AS Opportunity_AUM,
    -- Stage flags
    CASE WHEN LOWER(o.SQL__c) = 'yes' THEN 1 ELSE 0 END AS is_sqo,
    CASE WHEN o.advisor_join_date__c IS NOT NULL THEN 1 ELSE 0 END AS is_joined,
    CASE WHEN o.StageName = 'Signed' THEN 1 ELSE 0 END AS is_signed,
    -- Time dimensions
    DATE_TRUNC(DATE(o.CreatedDate), MONTH) AS opp_created_month,
    DATE_TRUNC(DATE(o.CreatedDate), QUARTER) AS opp_created_quarter,
    EXTRACT(YEAR FROM DATE(o.CreatedDate)) AS opp_created_year,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), MONTH) AS sqo_month,
    DATE_TRUNC(DATE(o.Date_Became_SQO__c), QUARTER) AS sqo_quarter,
    DATE_TRUNC(DATE(o.Stage_Entered_Signed__c), MONTH) AS signed_month,
    DATE_TRUNC(DATE(o.Stage_Entered_Signed__c), QUARTER) AS signed_quarter,
    DATE_TRUNC(DATE(o.advisor_join_date__c), MONTH) AS joined_month,
    DATE_TRUNC(DATE(o.advisor_join_date__c), QUARTER) AS joined_quarter
  FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
  LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.User` opp_owner_user
    ON o.OwnerId = opp_owner_user.Id
  WHERE o.recordtypeid = '012Dn000000mrO3IAI'
    AND opp_owner_user.Is_SGM__c = TRUE
    AND opp_owner_user.IsActive = TRUE
),

Current_Date_Context AS (
  -- Get current date for relative time period calculations
  SELECT
    CURRENT_DATE() AS current_date,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) AS current_quarter_start,
    DATE_TRUNC(CURRENT_DATE(), YEAR) AS current_year_start,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 3 MONTH) AS last_quarter_start,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 6 MONTH) AS last_quarter_end,
    DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AS rolling_12_months_start
),

SGM_Opportunity_Metrics AS (
  -- Aggregate opportunities by SGM and time period
  SELECT
    o.sgm_name,
    o.sgm_user_id,
    -- Time period dimensions (using opportunity created date as primary)
    o.opp_created_month,
    o.opp_created_quarter,
    o.opp_created_year,
    -- Stage breakdown
    o.StageName,
    -- Count metrics
    COUNT(DISTINCT o.Full_Opportunity_ID__c) AS opportunity_count,
    COUNT(DISTINCT CASE WHEN o.is_sqo = 1 THEN o.Full_Opportunity_ID__c END) AS sqo_count,
    COUNT(DISTINCT CASE WHEN o.is_signed = 1 THEN o.Full_Opportunity_ID__c END) AS signed_count,
    COUNT(DISTINCT CASE WHEN o.is_joined = 1 THEN o.Full_Opportunity_ID__c END) AS joined_count,
    -- AUM metrics
    SUM(o.Underwritten_AUM__c) AS total_aum,
    SUM(o.Margin_AUM__c) AS total_margin_aum,
    SUM(o.Opportunity_AUM) AS total_opportunity_aum,
    -- AUM by stage
    SUM(CASE WHEN o.StageName = 'Qualifying' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_qualifying,
    SUM(CASE WHEN o.StageName = 'Discovery' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_discovery,
    SUM(CASE WHEN o.StageName = 'Sales Process' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_sales_process,
    SUM(CASE WHEN o.StageName = 'Negotiating' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_negotiating,
    SUM(CASE WHEN o.StageName = 'Signed' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_signed,
    SUM(CASE WHEN o.StageName = 'Joined' THEN o.Underwritten_AUM__c ELSE 0 END) AS aum_joined,
    -- Margin AUM by stage
    SUM(CASE WHEN o.StageName = 'Qualifying' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_qualifying,
    SUM(CASE WHEN o.StageName = 'Discovery' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_discovery,
    SUM(CASE WHEN o.StageName = 'Sales Process' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_sales_process,
    SUM(CASE WHEN o.StageName = 'Negotiating' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_negotiating,
    SUM(CASE WHEN o.StageName = 'Signed' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_signed,
    SUM(CASE WHEN o.StageName = 'Joined' THEN o.Margin_AUM__c ELSE 0 END) AS margin_aum_joined,
    -- Open vs Closed
    COUNT(DISTINCT CASE WHEN o.IsClosed = FALSE THEN o.Full_Opportunity_ID__c END) AS open_opportunity_count,
    COUNT(DISTINCT CASE WHEN o.IsClosed = TRUE THEN o.Full_Opportunity_ID__c END) AS closed_opportunity_count
  FROM Opp_Base o
  INNER JOIN Active_SGMs sgm
    ON o.sgm_name = sgm.sgm_name
  GROUP BY
    o.sgm_name,
    o.sgm_user_id,
    o.opp_created_month,
    o.opp_created_quarter,
    o.opp_created_year,
    o.StageName
),

SGM_Time_Period_Aggregates AS (
  -- Aggregate by SGM across different time periods
  SELECT
    m.sgm_name,
    m.sgm_user_id,
    -- Current Quarter metrics
    SUM(CASE 
      WHEN m.opp_created_quarter = c.current_quarter_start 
      THEN m.opportunity_count ELSE 0 
    END) AS current_quarter_opp_count,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.current_quarter_start 
      THEN m.total_aum ELSE 0 
    END) AS current_quarter_aum,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.current_quarter_start 
      THEN m.total_margin_aum ELSE 0 
    END) AS current_quarter_margin_aum,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.current_quarter_start 
      THEN m.sqo_count ELSE 0 
    END) AS current_quarter_sqo_count,
    -- Year to Date metrics
    SUM(CASE 
      WHEN m.opp_created_year = EXTRACT(YEAR FROM c.current_date)
        AND DATE(m.opp_created_month) >= c.current_year_start
      THEN m.opportunity_count ELSE 0 
    END) AS ytd_opp_count,
    SUM(CASE 
      WHEN m.opp_created_year = EXTRACT(YEAR FROM c.current_date)
        AND DATE(m.opp_created_month) >= c.current_year_start
      THEN m.total_aum ELSE 0 
    END) AS ytd_aum,
    SUM(CASE 
      WHEN m.opp_created_year = EXTRACT(YEAR FROM c.current_date)
        AND DATE(m.opp_created_month) >= c.current_year_start
      THEN m.total_margin_aum ELSE 0 
    END) AS ytd_margin_aum,
    SUM(CASE 
      WHEN m.opp_created_year = EXTRACT(YEAR FROM c.current_date)
        AND DATE(m.opp_created_month) >= c.current_year_start
      THEN m.sqo_count ELSE 0 
    END) AS ytd_sqo_count,
    -- Last Quarter metrics
    SUM(CASE 
      WHEN m.opp_created_quarter = c.last_quarter_start
      THEN m.opportunity_count ELSE 0 
    END) AS last_quarter_opp_count,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.last_quarter_start
      THEN m.total_aum ELSE 0 
    END) AS last_quarter_aum,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.last_quarter_start
      THEN m.total_margin_aum ELSE 0 
    END) AS last_quarter_margin_aum,
    SUM(CASE 
      WHEN m.opp_created_quarter = c.last_quarter_start
      THEN m.sqo_count ELSE 0 
    END) AS last_quarter_sqo_count,
    -- Rolling 12 Months metrics
    SUM(CASE 
      WHEN DATE(m.opp_created_month) >= c.rolling_12_months_start
      THEN m.opportunity_count ELSE 0 
    END) AS rolling_12m_opp_count,
    SUM(CASE 
      WHEN DATE(m.opp_created_month) >= c.rolling_12_months_start
      THEN m.total_aum ELSE 0 
    END) AS rolling_12m_aum,
    SUM(CASE 
      WHEN DATE(m.opp_created_month) >= c.rolling_12_months_start
      THEN m.total_margin_aum ELSE 0 
    END) AS rolling_12m_margin_aum,
    SUM(CASE 
      WHEN DATE(m.opp_created_month) >= c.rolling_12_months_start
      THEN m.sqo_count ELSE 0 
    END) AS rolling_12m_sqo_count,
    -- All Time metrics (current state)
    SUM(m.opportunity_count) AS total_opp_count,
    SUM(m.total_aum) AS total_aum_all_time,
    SUM(m.total_margin_aum) AS total_margin_aum_all_time,
    SUM(m.sqo_count) AS total_sqo_count,
    SUM(m.signed_count) AS total_signed_count,
    SUM(m.joined_count) AS total_joined_count,
    SUM(m.open_opportunity_count) AS total_open_opp_count,
    SUM(m.closed_opportunity_count) AS total_closed_opp_count
  FROM SGM_Opportunity_Metrics m
  CROSS JOIN Current_Date_Context c
  GROUP BY
    m.sgm_name,
    m.sgm_user_id
)

SELECT
  sgm.sgm_name,
  sgm.sgm_user_id,
  -- Current Quarter
  COALESCE(a.current_quarter_opp_count, 0) AS current_quarter_opp_count,
  COALESCE(a.current_quarter_aum, 0) AS current_quarter_aum,
  COALESCE(a.current_quarter_margin_aum, 0) AS current_quarter_margin_aum,
  COALESCE(a.current_quarter_sqo_count, 0) AS current_quarter_sqo_count,
  -- Year to Date
  COALESCE(a.ytd_opp_count, 0) AS ytd_opp_count,
  COALESCE(a.ytd_aum, 0) AS ytd_aum,
  COALESCE(a.ytd_margin_aum, 0) AS ytd_margin_aum,
  COALESCE(a.ytd_sqo_count, 0) AS ytd_sqo_count,
  -- Last Quarter
  COALESCE(a.last_quarter_opp_count, 0) AS last_quarter_opp_count,
  COALESCE(a.last_quarter_aum, 0) AS last_quarter_aum,
  COALESCE(a.last_quarter_margin_aum, 0) AS last_quarter_margin_aum,
  COALESCE(a.last_quarter_sqo_count, 0) AS last_quarter_sqo_count,
  -- Rolling 12 Months
  COALESCE(a.rolling_12m_opp_count, 0) AS rolling_12m_opp_count,
  COALESCE(a.rolling_12m_aum, 0) AS rolling_12m_aum,
  COALESCE(a.rolling_12m_margin_aum, 0) AS rolling_12m_margin_aum,
  COALESCE(a.rolling_12m_sqo_count, 0) AS rolling_12m_sqo_count,
  -- All Time (Current State)
  COALESCE(a.total_opp_count, 0) AS total_opp_count,
  COALESCE(a.total_aum_all_time, 0) AS total_aum_all_time,
  COALESCE(a.total_margin_aum_all_time, 0) AS total_margin_aum_all_time,
  COALESCE(a.total_sqo_count, 0) AS total_sqo_count,
  COALESCE(a.total_signed_count, 0) AS total_signed_count,
  COALESCE(a.total_joined_count, 0) AS total_joined_count,
  COALESCE(a.total_open_opp_count, 0) AS total_open_opp_count,
  COALESCE(a.total_closed_opp_count, 0) AS total_closed_opp_count,
  -- Calculated metrics for Looker Studio
  CASE 
    WHEN COALESCE(a.total_opp_count, 0) > 0 
    THEN COALESCE(a.total_aum_all_time, 0) / a.total_opp_count 
    ELSE 0 
  END AS avg_aum_per_opp,
  CASE 
    WHEN COALESCE(a.total_opp_count, 0) > 0 
    THEN COALESCE(a.total_margin_aum_all_time, 0) / a.total_opp_count 
    ELSE 0 
  END AS avg_margin_aum_per_opp,
  CASE 
    WHEN COALESCE(a.total_sqo_count, 0) > 0 
    THEN COALESCE(a.total_aum_all_time, 0) / a.total_sqo_count 
    ELSE 0 
  END AS avg_aum_per_sqo,
  CASE 
    WHEN COALESCE(a.total_sqo_count, 0) > 0 
    THEN COALESCE(a.total_margin_aum_all_time, 0) / a.total_sqo_count 
    ELSE 0 
  END AS avg_margin_aum_per_sqo,
  -- Current date for reference
  CURRENT_DATE() AS as_of_date
FROM Active_SGMs sgm
LEFT JOIN SGM_Time_Period_Aggregates a
  ON sgm.sgm_name = a.sgm_name
ORDER BY sgm.sgm_name

