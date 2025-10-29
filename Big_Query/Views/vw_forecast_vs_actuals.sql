WITH
-- 1. FILTERED data for conversion rates and open pipeline
Funnel_With_Flags AS (
  SELECT
    f.*
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2` f
  WHERE 
    (f.SGA_Owner_Name__c IN (
      SELECT DISTINCT Name 
      FROM `savvy-gtm-analytics.SavvyGTMData.User` 
      WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE)
        AND IsActive = TRUE
    ))
    OR
    (f.Opportunity_Owner_Name__c IN (
      SELECT DISTINCT Name 
      FROM `savvy-gtm-analytics.SavvyGTMData.User` 
      WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE)
        AND IsActive = TRUE
    ))
),

-- 2. UNFILTERED data for actuals
Funnel_Unfiltered AS (
  SELECT
    *
  FROM `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
),

-- 3. Forecast Data Processing
Forecast_Data AS (
  SELECT
    month_key,
    CASE WHEN Channel = 'Inbound' THEN 'Marketing' ELSE Channel END AS channel_grouping_name,
    original_source,
    metric,
    CASE
      WHEN LOWER(stage) = 'mql' THEN 'mqls'
      WHEN LOWER(stage) = 'sql' THEN 'sqls'
      WHEN LOWER(stage) = 'sqo' THEN 'sqos'
      ELSE LOWER(stage)
    END AS stage,
    CAST(forecast_value AS INT64) AS forecast_value
  FROM `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
  WHERE metric = 'Cohort_source'
    AND original_source != 'All'
),

-- 4. Q4 Forecast Total
Forecast_Q4_Total AS (
  SELECT
    channel_grouping_name,
    original_source,
    stage,
    SUM(forecast_value) AS forecast_value
  FROM Forecast_Data
  WHERE month_key IN ('2025-10', '2025-11', '2025-12')
  GROUP BY channel_grouping_name, original_source, stage
),

-- 5. QTD Actuals - Using UNFILTERED data
QTD_Actuals AS (
  SELECT channel_grouping_name, original_source, 'prospects' AS stage, 
         COUNT(DISTINCT Full_prospect_id__c) AS actual_value
  FROM Funnel_Unfiltered
  WHERE DATE(CreatedDate) BETWEEN '2025-10-01' AND CURRENT_DATE()
  GROUP BY 1, 2
  
  UNION ALL
  
  SELECT channel_grouping_name, original_source, 'mqls' AS stage,
         COUNT(DISTINCT Full_prospect_id__c) AS actual_value
  FROM Funnel_Unfiltered
  WHERE is_mql = 1 
    AND DATE(mql_stage_entered_ts) BETWEEN '2025-10-01' AND CURRENT_DATE()
  GROUP BY 1, 2
  
  UNION ALL
  
  SELECT channel_grouping_name, original_source, 'sqls' AS stage,
         COUNT(DISTINCT Full_prospect_id__c) AS actual_value
  FROM Funnel_Unfiltered
  WHERE is_sql = 1 
    AND DATE(converted_date_raw) BETWEEN '2025-10-01' AND CURRENT_DATE()
  GROUP BY 1, 2
  
  UNION ALL
  
  SELECT channel_grouping_name, original_source, 'sqos' AS stage,
         COUNT(DISTINCT Full_Opportunity_ID__c) AS actual_value
  FROM Funnel_Unfiltered
  WHERE is_sqo = 1 
    AND DATE(Date_Became_SQO__c) BETWEEN '2025-10-01' AND CURRENT_DATE()
  GROUP BY 1, 2
  
  UNION ALL
  
  SELECT channel_grouping_name, original_source, 'joined' AS stage,
         COUNT(DISTINCT Full_Opportunity_ID__c) AS actual_value
  FROM Funnel_Unfiltered
  WHERE is_joined = 1 
    AND DATE(advisor_join_date__c) BETWEEN '2025-10-01' AND CURRENT_DATE()
  GROUP BY 1, 2
),

-- 6. Trailing 90-day Conversion Rates - Using FILTERED data
-- 90-day trailing rates (no decay) with hierarchical backoff (source -> channel -> global)
Daily_Segments AS (
  SELECT
    DATE(FilterDate) AS day,
    channel_grouping_name,
    original_source,
    COUNT(DISTINCT IF(is_contacted = 1, Full_prospect_id__c, NULL)) AS den_contacted,
    COUNT(DISTINCT IF(is_contacted = 1 AND is_mql = 1, Full_prospect_id__c, NULL)) AS num_c2m,
    COUNT(DISTINCT IF(is_mql = 1, Full_prospect_id__c, NULL)) AS den_mql,
    COUNT(DISTINCT IF(is_mql = 1 AND is_sql = 1, Full_prospect_id__c, NULL)) AS num_m2s,
    COUNT(DISTINCT CASE WHEN is_sql = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS den_sql_opp,
    COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS num_s2q,
    COUNT(DISTINCT CASE WHEN is_sqo = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS den_sqo_opp,
    COUNT(DISTINCT CASE WHEN is_joined = 1 AND Full_Opportunity_ID__c IS NOT NULL THEN Full_Opportunity_ID__c END) AS num_q2j
  FROM Funnel_With_Flags
  WHERE DATE(FilterDate) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
  GROUP BY 1, 2, 3
),
Source_Level AS (
  SELECT
    d.channel_grouping_name,
    d.original_source,
    SAFE_DIVIDE(SUM(d.num_c2m), SUM(d.den_contacted)) AS c2m_rate,
    SUM(d.den_contacted) AS c2m_den_w,
    SAFE_DIVIDE(SUM(d.num_m2s), SUM(d.den_mql)) AS m2s_rate,
    SUM(d.den_mql) AS m2s_den_w,
    SAFE_DIVIDE(SUM(d.num_s2q), SUM(d.den_sql_opp)) AS s2q_rate,
    SUM(d.den_sql_opp) AS s2q_den_w,
    SAFE_DIVIDE(SUM(d.num_q2j), SUM(d.den_sqo_opp)) AS q2j_rate,
    SUM(d.den_sqo_opp) AS q2j_den_w
  FROM Daily_Segments d
  GROUP BY 1, 2
),
Channel_Level AS (
  SELECT
    d.channel_grouping_name,
    SAFE_DIVIDE(SUM(d.num_c2m), SUM(d.den_contacted)) AS c2m_rate,
    SUM(d.den_contacted) AS c2m_den_w,
    SAFE_DIVIDE(SUM(d.num_m2s), SUM(d.den_mql)) AS m2s_rate,
    SUM(d.den_mql) AS m2s_den_w,
    SAFE_DIVIDE(SUM(d.num_s2q), SUM(d.den_sql_opp)) AS s2q_rate,
    SUM(d.den_sql_opp) AS s2q_den_w,
    SAFE_DIVIDE(SUM(d.num_q2j), SUM(d.den_sqo_opp)) AS q2j_rate,
    SUM(d.den_sqo_opp) AS q2j_den_w
  FROM Daily_Segments d
  GROUP BY 1
),
Global_Level AS (
  SELECT
    SAFE_DIVIDE(SUM(d.num_c2m), SUM(d.den_contacted)) AS c2m_rate,
    SUM(d.den_contacted) AS c2m_den_w,
    SAFE_DIVIDE(SUM(d.num_m2s), SUM(d.den_mql)) AS m2s_rate,
    SUM(d.den_mql) AS m2s_den_w,
    SAFE_DIVIDE(SUM(d.num_s2q), SUM(d.den_sql_opp)) AS s2q_rate,
    SUM(d.den_sql_opp) AS s2q_den_w,
    SAFE_DIVIDE(SUM(d.num_q2j), SUM(d.den_sqo_opp)) AS q2j_rate,
    SUM(d.den_sqo_opp) AS q2j_den_w
  FROM Daily_Segments d
),
Trailing_Rates AS (
  SELECT
    s.channel_grouping_name,
    s.original_source,
    -- choose c2m with backoff
    CASE 
      WHEN s.c2m_den_w >= 5 THEN s.c2m_rate
      WHEN c.c2m_den_w >= 5 THEN c.c2m_rate
      ELSE g.c2m_rate
    END AS prospect_to_mql_rate,
    CASE 
      WHEN s.c2m_den_w >= 5 THEN s.c2m_den_w
      WHEN c.c2m_den_w >= 5 THEN c.c2m_den_w
      ELSE g.c2m_den_w
    END AS c2m_den_w,
    -- choose m2s with backoff
    CASE 
      WHEN s.m2s_den_w >= 5 THEN s.m2s_rate
      WHEN c.m2s_den_w >= 5 THEN c.m2s_rate
      ELSE g.m2s_rate
    END AS mql_to_sql_rate,
    CASE 
      WHEN s.m2s_den_w >= 5 THEN s.m2s_den_w
      WHEN c.m2s_den_w >= 5 THEN c.m2s_den_w
      ELSE g.m2s_den_w
    END AS m2s_den_w,
    -- choose s2q with backoff
    CASE 
      WHEN s.s2q_den_w >= 5 THEN s.s2q_rate
      WHEN c.s2q_den_w >= 5 THEN c.s2q_rate
      ELSE g.s2q_rate
    END AS sql_to_sqo_rate,
    CASE 
      WHEN s.s2q_den_w >= 5 THEN s.s2q_den_w
      WHEN c.s2q_den_w >= 5 THEN c.s2q_den_w
      ELSE g.s2q_den_w
    END AS s2q_den_w,
    -- choose q2j with backoff
    CASE 
      WHEN s.q2j_den_w >= 5 THEN s.q2j_rate
      WHEN c.q2j_den_w >= 5 THEN c.q2j_rate
      ELSE g.q2j_rate
    END AS sqo_to_joined_rate,
    CASE 
      WHEN s.q2j_den_w >= 5 THEN s.q2j_den_w
      WHEN c.q2j_den_w >= 5 THEN c.q2j_den_w
      ELSE g.q2j_den_w
    END AS q2j_den_w
  FROM Source_Level s
  LEFT JOIN Channel_Level c
    ON s.channel_grouping_name = c.channel_grouping_name
  CROSS JOIN Global_Level g
),

-- 7. Open Pipeline - Using FILTERED data
Open_Pipeline AS (
  SELECT
    channel_grouping_name,
    original_source,
    COUNT(DISTINCT IF(is_contacted = 1 AND is_mql = 0, Full_prospect_id__c, NULL)) AS open_prospects,
    COUNT(DISTINCT IF(is_mql = 1 AND is_sql = 0, Full_prospect_id__c, NULL)) AS open_mqls,
    COUNT(DISTINCT IF(is_sql = 1 AND is_sqo = 0 AND LOWER(SQO_raw) IS NULL, Full_Opportunity_ID__c, NULL)) AS open_sqls,
    COUNT(DISTINCT IF(is_sqo = 1 AND is_joined = 0, Full_Opportunity_ID__c, NULL)) AS open_sqos
  FROM Funnel_With_Flags
  WHERE DATE(FilterDate) BETWEEN '2025-10-01' AND CURRENT_DATE()
    AND (StageName IS NULL OR StageName NOT LIKE '%Closed Lost%')
  GROUP BY 1, 2
),

-- 8. Remaining Forecast
Remaining_Forecast AS (
  SELECT
    f.channel_grouping_name,
    f.original_source,
    f.stage,
    GREATEST(0, f.forecast_value - COALESCE(a.actual_value, 0)) AS remaining_value
  FROM Forecast_Q4_Total f
  LEFT JOIN QTD_Actuals a
    ON f.channel_grouping_name = a.channel_grouping_name
    AND f.original_source = a.original_source
    AND f.stage = a.stage
),

-- 9. Future Conversions
Future_Conversions AS (
  SELECT
    COALESCE(p.channel_grouping_name, r.channel_grouping_name, rf_p.channel_grouping_name) AS channel_grouping_name,
    COALESCE(p.original_source, r.original_source, rf_p.original_source) AS original_source,
    
    -- Future MQLs: open prospects + remaining prospects flowed via c2m
    (COALESCE(p.open_prospects, 0) * COALESCE(r.prospect_to_mql_rate, 0)) + 
    (COALESCE(rf_p.remaining_value, 0) * COALESCE(r.prospect_to_mql_rate, 0)) AS future_mqls,
    
    -- Future SQLs: open mqls plus derived mqls flowed via m2s
    ((COALESCE(p.open_mqls, 0) + 
      (COALESCE(p.open_prospects, 0) * COALESCE(r.prospect_to_mql_rate, 0)) + 
      (COALESCE(rf_p.remaining_value, 0) * COALESCE(r.prospect_to_mql_rate, 0)))
     * COALESCE(r.mql_to_sql_rate, 0)) AS future_sqls,
    
    -- Future SQOs: open sqls plus derived sqls flowed via s2q
    ((COALESCE(p.open_sqls, 0) +
      ((COALESCE(p.open_mqls, 0) + 
        (COALESCE(p.open_prospects, 0) * COALESCE(r.prospect_to_mql_rate, 0)) + 
        (COALESCE(rf_p.remaining_value, 0) * COALESCE(r.prospect_to_mql_rate, 0)))
       * COALESCE(r.mql_to_sql_rate, 0)))
     * COALESCE(r.sql_to_sqo_rate, 0)) AS future_sqos,
    
    -- Future Joined: open sqos plus derived sqos flowed via q2j
    (
      COALESCE(p.open_sqos, 0)
      + (
          (
            COALESCE(p.open_sqls, 0)
            + (
                (
                  COALESCE(p.open_mqls, 0)
                  + (COALESCE(p.open_prospects, 0) * COALESCE(r.prospect_to_mql_rate, 0))
                  + (COALESCE(rf_p.remaining_value, 0) * COALESCE(r.prospect_to_mql_rate, 0))
                ) * COALESCE(r.mql_to_sql_rate, 0)
              )
          ) * COALESCE(r.sql_to_sqo_rate, 0)
        )
    ) * COALESCE(r.sqo_to_joined_rate, 0) AS future_joined
    
  FROM Open_Pipeline p
  FULL OUTER JOIN Trailing_Rates r
    ON p.channel_grouping_name = r.channel_grouping_name 
    AND p.original_source = r.original_source
  FULL OUTER JOIN (
    SELECT * FROM Remaining_Forecast WHERE stage = 'prospects'
  ) rf_p
    ON COALESCE(p.channel_grouping_name, r.channel_grouping_name) = rf_p.channel_grouping_name 
    AND COALESCE(p.original_source, r.original_source) = rf_p.original_source
),

-- 10. Historical Volatility - Using UNFILTERED data
Historical_Volatility AS (
  SELECT
    channel_grouping_name,
    original_source,
    stage,
    STDDEV(daily_count) AS stddev_daily
  FROM (
    SELECT DATE(mql_stage_entered_ts) AS event_date, channel_grouping_name, original_source,
           'mqls' AS stage, COUNT(DISTINCT Full_prospect_id__c) AS daily_count
    FROM Funnel_Unfiltered
    WHERE is_mql = 1 
      AND DATE(mql_stage_entered_ts) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY 1, 2, 3, 4
    
    UNION ALL
    
    SELECT DATE(converted_date_raw) AS event_date, channel_grouping_name, original_source,
           'sqls' AS stage, COUNT(DISTINCT Full_prospect_id__c) AS daily_count
    FROM Funnel_Unfiltered
    WHERE is_sql = 1 
      AND DATE(converted_date_raw) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY 1, 2, 3, 4
    
    UNION ALL
    
    SELECT DATE(Date_Became_SQO__c) AS event_date, channel_grouping_name, original_source,
           'sqos' AS stage, COUNT(DISTINCT Full_Opportunity_ID__c) AS daily_count
    FROM Funnel_Unfiltered
    WHERE is_sqo = 1 
      AND DATE(Date_Became_SQO__c) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY 1, 2, 3, 4
    
    UNION ALL
    
    SELECT DATE(advisor_join_date__c) AS event_date, channel_grouping_name, original_source,
           'joined' AS stage, COUNT(DISTINCT Full_Opportunity_ID__c) AS daily_count
    FROM Funnel_Unfiltered
    WHERE is_joined = 1 
      AND DATE(advisor_join_date__c) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    GROUP BY 1, 2, 3, 4
  )
  GROUP BY 1, 2, 3
)

-- FINAL SELECT
SELECT
  COALESCE(a.channel_grouping_name, f.channel_grouping_name, fc.channel_grouping_name) AS channel_grouping_name,
  COALESCE(a.original_source, f.original_source, fc.original_source) AS original_source,
  stages.stage,
  COALESCE(f.forecast_value, 0) AS forecast_value,
  COALESCE(a.actual_value, 0) AS actual_value,
  -- Days remaining in quarter (avoid divide-by-zero)
  GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)) AS days_remaining,
  
  -- Future-only raw component by stage
  CASE stages.stage
    WHEN 'mqls' THEN COALESCE(fc.future_mqls, 0)
    WHEN 'sqls' THEN COALESCE(fc.future_sqls, 0)
    WHEN 'sqos' THEN COALESCE(fc.future_sqos, 0)
    WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
    ELSE 0
  END AS future_raw,

  -- Daily-capped future component by stage using historical p90s: MQL=14/day, SQL=5/day, SQO=4/day
  CASE stages.stage
    WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                      * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
    WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                      * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
    WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                      * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
    WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
    ELSE 0
  END AS future_capped,

  -- Confidence weight (less aggressive): log1p of denominators per stage
  COALESCE(CASE stages.stage
    WHEN 'mqls' THEN LN(1 + tr.c2m_den_w)
    WHEN 'sqls' THEN LN(1 + tr.m2s_den_w)
    WHEN 'sqos' THEN LN(1 + tr.s2q_den_w)
    WHEN 'joined' THEN LN(1 + tr.q2j_den_w)
    ELSE 1
  END, 1) AS confidence_weight,

  -- Stage-level remaining forecast and unweighted sum of capped future (only where forecast exists for the stage)
  (SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
   - SUM(COALESCE(a.actual_value, 0)) OVER (PARTITION BY stages.stage)) AS remaining_stage,
  SUM( CASE WHEN COALESCE(f.forecast_value, 0) > 0 THEN 
              (CASE stages.stage
                 WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                       * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                 WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                       * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                 WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                       * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                 WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
                 ELSE 0
               END)
            ELSE 0 END ) 
      OVER (PARTITION BY stages.stage) AS future_sum,

  -- Partial reconciliation with β=0.5 and ±10% band (scale only future component)
  CASE
    WHEN stages.stage = 'prospects' THEN COALESCE(a.actual_value, 0)
    ELSE 
      COALESCE(a.actual_value, 0) + (
        CASE 
          WHEN (SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
                - SUM(COALESCE(a.actual_value, 0)) OVER (PARTITION BY stages.stage)) <= 0
            THEN 0
          ELSE 
            -- compute band and blended scale
            (CASE 
               WHEN (
                 SUM(COALESCE(a.actual_value, 0)) OVER (PARTITION BY stages.stage)
                 + SUM( CASE WHEN COALESCE(f.forecast_value, 0) > 0 THEN 
                               (CASE stages.stage
                                  WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                                        * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                  WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                                        * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                  WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                                        * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                  WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
                                  ELSE 0
                                END)
                              ELSE 0 END ) 
                   OVER (PARTITION BY stages.stage)
               ) BETWEEN 0.9 * SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
                   AND     1.1 * SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
                 THEN 
  -- Asymmetric reconciliation: only scale down if model_total > 110% of forecast; otherwise use capped future
  (CASE 
     WHEN (
            SUM(COALESCE(a.actual_value, 0)) OVER (PARTITION BY stages.stage)
            + SUM( CASE WHEN COALESCE(f.forecast_value, 0) > 0 THEN 
                            (CASE stages.stage
                               WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                               WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                               WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                               WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
                               ELSE 0 END)
                         ELSE 0 END ) OVER (PARTITION BY stages.stage)
          ) > 1.1 * SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
       THEN 
         (CASE stages.stage
            WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                  * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
            WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                  * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
            WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                  * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
            WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
            ELSE 0 END)
         * LEAST(
             1,
             ( (SUM(COALESCE(f.forecast_value, 0)) OVER (PARTITION BY stages.stage)
                 - SUM(COALESCE(a.actual_value, 0)) OVER (PARTITION BY stages.stage)) )
             / NULLIF( ( 1.0 + SUM( CASE WHEN COALESCE(f.forecast_value, 0) > 0 THEN 
                                            (CASE stages.stage
                                               WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                               WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                               WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                                                     * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                                               WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
                                               ELSE 0 END)
                                          ELSE 0 END ) 
                                OVER (PARTITION BY stages.stage) ), 0)
           )
       ELSE 
         (CASE stages.stage
                      WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
            ELSE 0 END)
       END)
                  ELSE 
                    (CASE stages.stage
                      WHEN 'mqls' THEN LEAST(COALESCE(fc.future_mqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 14.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'sqls' THEN LEAST(COALESCE(fc.future_sqls, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 5.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'sqos' THEN LEAST(COALESCE(fc.future_sqos, 0) / GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY)), 4.0)
                                            * GREATEST(1, DATE_DIFF(DATE '2025-12-31', CURRENT_DATE(), DAY))
                      WHEN 'joined' THEN COALESCE(fc.future_joined, 0)
                      ELSE 0 END)
              END)
        END
      )
  END AS predicted_value,
  
  hv.stddev_daily
  
FROM (
  SELECT DISTINCT channel_grouping_name, original_source, stage 
  FROM QTD_Actuals
  UNION DISTINCT
  SELECT DISTINCT channel_grouping_name, original_source, stage 
  FROM Forecast_Q4_Total
) stages
LEFT JOIN QTD_Actuals a
  ON stages.channel_grouping_name = a.channel_grouping_name
  AND stages.original_source = a.original_source
  AND stages.stage = a.stage
LEFT JOIN Forecast_Q4_Total f
  ON stages.channel_grouping_name = f.channel_grouping_name
  AND stages.original_source = f.original_source
  AND stages.stage = f.stage
LEFT JOIN Future_Conversions fc
  ON stages.channel_grouping_name = fc.channel_grouping_name
  AND stages.original_source = fc.original_source
LEFT JOIN Trailing_Rates tr
  ON stages.channel_grouping_name = tr.channel_grouping_name
  AND stages.original_source = tr.original_source
LEFT JOIN Historical_Volatility hv
  ON stages.channel_grouping_name = hv.channel_grouping_name
  AND stages.original_source = hv.original_source
  AND stages.stage = hv.stage
