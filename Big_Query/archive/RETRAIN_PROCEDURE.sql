-- Create the final stored procedure
CREATE OR REPLACE PROCEDURE `savvy-gtm-analytics.savvy_forecast.retrain_forecast_models`()
BEGIN
  DECLARE retrain_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE error_message STRING;
  
  -- Error handling
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SET error_message = @@error.message;
    INSERT INTO `savvy-gtm-analytics.savvy_forecast.model_training_log`
    VALUES (
      CURRENT_DATE(), 'AUTO_RETRAIN', 'FAILED',
      error_message, retrain_timestamp, CURRENT_TIMESTAMP()
    );
  END;
  
  -- ======== Step 1: Rebuild Trailing Rates Table ========
  -- (This re-runs the logic from our backfill fix for the last 180 days)
  CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.trailing_rates_features` AS
  WITH 
  active_cohort AS (
    SELECT DISTINCT Name FROM `savvy-gtm-analytics.SavvyGTMData.User`
    WHERE (IsSGA__c = TRUE OR Is_SGM__c = TRUE) AND IsActive = TRUE
  ),
  daily_progressions AS (
    SELECT
      DATE(FilterDate) AS date_day, Channel_Grouping_Name, Original_source,
      COUNT(DISTINCT CASE WHEN is_contacted = 1 THEN primary_key END) AS contacted_denom,
      COUNT(DISTINCT CASE WHEN is_mql = 1 THEN primary_key END) AS mql_denom,
      COUNT(DISTINCT CASE WHEN is_sql = 1 THEN primary_key END) AS sql_denom,
      COUNT(DISTINCT CASE WHEN is_sqo = 1 THEN Full_Opportunity_ID__c END) AS sqo_denom,
      COUNT(DISTINCT CASE WHEN is_contacted = 1 AND is_mql = 1 THEN primary_key END) AS contacted_to_mql,
      COUNT(DISTINCT CASE WHEN is_mql = 1 AND is_sql = 1 THEN primary_key END) AS mql_to_sql,
      COUNT(DISTINCT CASE WHEN is_sql = 1 AND is_sqo = 1 THEN Full_Opportunity_ID__c END) AS sql_to_sqo
    FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched` f
    INNER JOIN active_cohort a ON f.SGA_Owner_Name__c = a.Name
    WHERE DATE(FilterDate) >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY) -- Only need 180d of history
    GROUP BY 1, 2, 3
  ),
  target_dates AS (
    -- Only calculate for the last 180 days
    SELECT date_day FROM UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY), CURRENT_DATE(), INTERVAL 1 DAY)) AS date_day
  ),
  all_combinations AS (
    SELECT td.date_day AS processing_date, dp.Channel_Grouping_Name, dp.Original_source
    FROM target_dates td
    CROSS JOIN (SELECT DISTINCT Channel_Grouping_Name, Original_source FROM daily_progressions) dp
  ),
  date_calculations AS (
    SELECT 
      ac.processing_date, ac.Channel_Grouping_Name, ac.Original_source,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 29 THEN dp.contacted_to_mql END) AS c2m_num_30d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 29 THEN dp.contacted_denom END) AS c2m_den_30d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 29 THEN dp.mql_to_sql END) AS m2s_num_30d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 29 THEN dp.mql_denom END) AS m2s_den_30d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 59 THEN dp.contacted_to_mql END) AS c2m_num_60d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 59 THEN dp.contacted_denom END) AS c2m_den_60d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 59 THEN dp.sql_to_sqo END) AS s2q_num_60d,
      SUM(CASE WHEN DATE_DIFF(ac.processing_date, dp.date_day, DAY) BETWEEN 0 AND 59 THEN dp.sql_denom END) AS s2q_den_60d
    FROM all_combinations ac
    LEFT JOIN daily_progressions dp
      ON dp.date_day BETWEEN DATE_SUB(ac.processing_date, INTERVAL 90 DAY) AND ac.processing_date
      AND dp.Channel_Grouping_Name = ac.Channel_Grouping_Name
      AND dp.Original_source = ac.Original_source
    GROUP BY 1, 2, 3
  ),
  source_rates AS (
    SELECT
      processing_date AS date_day,
      Channel_Grouping_Name, Original_source,
      (c2m_num_30d + 1) / NULLIF(c2m_den_30d + 25, 0) AS c2m_rate_30d_smooth,
      (m2s_num_30d + 7) / NULLIF(m2s_den_30d + 20, 0) AS m2s_rate_30d_smooth,
      (s2q_num_60d + 6) / NULLIF(s2q_den_60d + 10, 0) AS s2q_rate_60d_smooth,
      c2m_num_60d, c2m_den_30d, m2s_den_30d, c2m_den_60d, s2q_den_60d
    FROM date_calculations
  ),
  channel_rates AS (
    SELECT
      processing_date AS date_day, Channel_Grouping_Name,
      SUM(c2m_num_30d) / NULLIF(SUM(c2m_den_30d), 0) AS c2m_rate_channel,
      SUM(c2m_den_30d) AS c2m_den_channel,
      SUM(m2s_num_30d) / NULLIF(SUM(m2s_den_30d), 0) AS m2s_rate_channel,
      SUM(m2s_den_30d) AS m2s_den_channel,
      SUM(s2q_num_60d) / NULLIF(SUM(s2q_den_60d), 0) AS s2q_rate_channel,
      SUM(s2q_den_60d) AS s2q_den_channel
    FROM date_calculations GROUP BY 1, 2
  ),
  global_rates AS (
    SELECT
      processing_date AS date_day,
      SUM(c2m_num_30d) / NULLIF(SUM(c2m_den_30d), 0) AS c2m_rate_global,
      SUM(m2s_num_30d) / NULLIF(SUM(m2s_den_30d), 0) AS m2s_rate_global,
      SUM(s2q_num_60d) / NULLIF(SUM(s2q_den_60d), 0) AS s2q_rate_global
    FROM date_calculations GROUP BY 1
  )
  SELECT
    s.date_day, s.Channel_Grouping_Name, s.Original_source,
    s.c2m_rate_30d_smooth, s.m2s_rate_30d_smooth, s.s2q_rate_60d_smooth,
    CASE 
      WHEN s.c2m_den_30d >= 20 THEN s.c2m_rate_30d_smooth
      WHEN s.c2m_den_60d >= 20 THEN (s.c2m_num_60d + 1) / NULLIF(s.c2m_den_60d + 25, 0)
      WHEN c.c2m_den_channel >= 20 THEN c.c2m_rate_channel
      ELSE g.c2m_rate_global
    END AS c2m_rate_selected,
    CASE
      WHEN s.m2s_den_30d >= 10 THEN s.m2s_rate_30d_smooth
      WHEN c.m2s_den_channel >= 10 THEN c.m2s_rate_channel
      ELSE g.m2s_rate_global
    END AS m2s_rate_selected,
    CASE
      WHEN s.s2q_den_60d >= 10 THEN s.s2q_rate_60d_smooth
      WHEN c.s2q_den_channel >= 10 THEN c.s2q_rate_channel
      ELSE g.s2q_rate_global
    END AS s2q_rate_selected,
    CASE 
      WHEN s.c2m_den_30d >= 20 THEN 'SOURCE_30D'
      WHEN s.c2m_den_60d >= 20 THEN 'SOURCE_60D'
      WHEN c.c2m_den_channel >= 20 THEN 'CHANNEL'
      ELSE 'GLOBAL'
    END AS backoff_level,
    s.c2m_den_30d, s.m2s_den_30d, s.s2q_den_60d
  FROM source_rates s
  LEFT JOIN channel_rates c ON s.date_day = c.date_day AND s.Channel_Grouping_Name = c.Channel_Grouping_Name
  CROSS JOIN global_rates g ON g.date_day = s.date_day;



  -- ======== Step 2: Rebuild Propensity Training Table ========
  CREATE OR REPLACE TABLE `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training` AS
  WITH sql_opportunities AS (
    SELECT Full_Opportunity_ID__c, primary_key,
          DATE(converted_date_raw) AS sql_date,
          DATE(Date_Became_SQO__c) AS sqo_date,
          SGA_Owner_Name__c,
          Channel_Grouping_Name, Original_source,
          CASE WHEN Date_Became_SQO__c IS NOT NULL
                  AND DATE_DIFF(DATE(Date_Became_SQO__c), DATE(converted_date_raw), DAY) BETWEEN 0 AND 14 THEN 1
                WHEN Date_Became_SQO__c IS NULL
                  AND DATE_DIFF(CURRENT_DATE(), DATE(converted_date_raw), DAY) <= 14 THEN NULL
                ELSE 0 END AS label,
          DATE_DIFF(DATE(Date_Became_SQO__c), DATE(converted_date_raw), DAY) AS days_to_sqo,
          entry_path,
          rep_years_at_firm, rep_client_count, rep_aum_total, rep_aum_growth_1y, rep_hnw_client_count,
          firm_total_aum, firm_total_reps, firm_aum_growth_1y, mapping_confidence
    FROM `savvy-gtm-analytics.savvy_forecast.vw_funnel_enriched`
    WHERE is_sql = 1 AND converted_date_raw IS NOT NULL 
      AND DATE(converted_date_raw) >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
  ), 
  with_context AS (
    SELECT s.*, r.m2s_rate_selected AS trailing_mql_sql_rate, r.s2q_rate_selected AS trailing_sql_sqo_rate,
          EXTRACT(DAYOFWEEK FROM s.sql_date) AS day_of_week,
          EXTRACT(MONTH FROM s.sql_date) AS month,
          CASE WHEN EXTRACT(DAYOFWEEK FROM s.sql_date) IN (1,7) THEN 0 ELSE 1 END AS is_business_day,
          COUNT(*) OVER (PARTITION BY s.Channel_Grouping_Name, s.Original_source, s.sql_date) AS same_day_sql_count,
          COUNT(*) OVER (PARTITION BY s.Channel_Grouping_Name, s.Original_source ORDER BY s.sql_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sql_count_7d
    FROM sql_opportunities s
    LEFT JOIN `savvy-gtm-analytics.savvy_forecast.trailing_rates_features` r
      ON r.date_day = DATE_SUB(s.sql_date, INTERVAL 1 DAY)
      AND s.Channel_Grouping_Name = r.Channel_Grouping_Name
      AND s.Original_source = r.Original_source
  )
  SELECT *,
        DATE_DIFF(CURRENT_DATE(), sql_date, DAY) AS days_in_sql_stage,
        LN(1 + COALESCE(rep_years_at_firm, 0)) AS log_rep_years,
        LN(1 + COALESCE(rep_aum_total, 0)) AS log_rep_aum,
        LN(1 + COALESCE(rep_client_count, 0)) AS log_rep_clients,
        LN(1 + COALESCE(firm_total_aum, 0)) AS log_firm_aum,
        LN(1 + COALESCE(firm_total_reps, 0)) AS log_firm_reps,
        rep_aum_growth_1y * firm_aum_growth_1y AS combined_growth,
        CASE entry_path WHEN 'LEAD_CONVERTED' THEN 1 ELSE 0 END AS is_lead_converted,
        CASE entry_path WHEN 'OPP_DIRECT' THEN 1 ELSE 0 END AS is_opp_direct
  FROM with_context
  WHERE label IS NOT NULL;

  

  -- ======== Step 3: Retrain ARIMA Models (90-day window) ========
  CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`
  OPTIONS(model_type='ARIMA_PLUS', time_series_timestamp_col='date_day', time_series_data_col='mqls_daily', time_series_id_col=['Channel_Grouping_Name','Original_source'],
    horizon=90, auto_arima=TRUE, auto_arima_max_order=5, decompose_time_series=TRUE, clean_spikes_and_dips=TRUE, adjust_step_changes=TRUE
  ) AS
  SELECT d.date_day, d.Channel_Grouping_Name, d.Original_source, d.mqls_daily
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts` d
  WHERE d.date_day BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    AND d.Channel_Grouping_Name IS NOT NULL AND d.Original_source IS NOT NULL
    AND (Channel_Grouping_Name, Original_source) IN (
      ('Outbound', 'LinkedIn (Self Sourced)'),
      ('Outbound', 'Provided Lead List'),
      ('Marketing', 'Advisor Waitlist'),
      ('Ecosystem', 'Recruitment Firm')
    );

  CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls`
  OPTIONS(model_type='ARIMA_PLUS', time_series_timestamp_col='date_day', time_series_data_col='sqls_daily', time_series_id_col=['Channel_Grouping_Name','Original_source'],
    horizon=90, auto_arima=TRUE, auto_arima_max_order=5, decompose_time_series=TRUE, clean_spikes_and_dips=TRUE, adjust_step_changes=TRUE
  ) AS
  SELECT d.date_day, d.Channel_Grouping_Name, d.Original_source, d.sqls_daily
  FROM `savvy-gtm-analytics.savvy_forecast.vw_daily_stage_counts` d
  WHERE d.date_day BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    AND d.Channel_Grouping_Name IS NOT NULL AND d.Original_source IS NOT NULL
    AND (Channel_Grouping_Name, Original_source) IN (
      ('Outbound', 'LinkedIn (Self Sourced)'),
      ('Outbound', 'Provided Lead List'),
      ('Marketing', 'Advisor Waitlist'),
      ('Ecosystem', 'Recruitment Firm')
    );

  -- ======== Step 4: Retrain Propensity Model (180-day window) ========
  CREATE OR REPLACE MODEL `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity`
  OPTIONS(model_type='BOOSTED_TREE_CLASSIFIER', input_label_cols=['label'], data_split_method='NO_SPLIT', enable_global_explain=TRUE, auto_class_weights=TRUE,
    max_iterations=50, early_stop=TRUE, learn_rate=0.05, subsample=0.8, max_tree_depth=6
  ) AS
  SELECT
    label,
    COALESCE(trailing_sql_sqo_rate, 0.0) AS trailing_sql_sqo_rate,
    COALESCE(trailing_mql_sql_rate, 0.0) AS trailing_mql_sql_rate,
    same_day_sql_count, sql_count_7d,
    day_of_week, month, is_business_day,
    log_rep_years, log_rep_aum, log_rep_clients,
    rep_aum_growth_1y, rep_hnw_client_count,
    log_firm_aum, log_firm_reps, firm_aum_growth_1y,
    is_lead_converted, is_opp_direct,
    combined_growth, days_in_sql_stage, mapping_confidence
  FROM `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training`;


  -- ======== Step 5: Generate New Hybrid Forecast ========
  DELETE FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts` WHERE forecast_date = CURRENT_DATE();

  INSERT INTO `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
  -- Use the exact hybrid forecast logic from complete_forecast_insert_hybrid.sql
  WITH 
  arima_forecast AS (
    SELECT
      Channel_Grouping_Name, Original_source,
      CAST(forecast_timestamp AS DATE) AS date_day,
      forecast_value AS mqls_forecast_raw,
      prediction_interval_lower_bound AS mqls_lower_raw,
      prediction_interval_upper_bound AS mqls_upper_raw,
      'ARIMA' AS forecast_method
    FROM ML.FORECAST(
      MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
      STRUCT(90 AS horizon, 0.9 AS confidence_level)
    )
  ),
  arima_sql_forecast AS (
    SELECT
      Channel_Grouping_Name, Original_source,
      CAST(forecast_timestamp AS DATE) AS date_day,
      forecast_value AS sqls_forecast_raw,
      prediction_interval_lower_bound AS sqls_lower_raw,
      prediction_interval_upper_bound AS sqls_upper_raw,
      'ARIMA' AS forecast_method
    FROM ML.FORECAST(
      MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls`,
      STRUCT(90 AS horizon, 0.9 AS confidence_level)
    )
  ),
  heuristic_forecast AS (
    SELECT
      Channel_Grouping_Name, Original_source, date_day,
      mqls_forecast AS mqls_forecast_raw,
      mqls_forecast * 0.7 AS mqls_lower_raw,
      mqls_forecast * 1.3 AS mqls_upper_raw,
      'Heuristic' AS forecast_method
    FROM `savvy-gtm-analytics.savvy_forecast.vw_heuristic_forecast`
    WHERE date_day >= CURRENT_DATE()
  ),
  heuristic_sql_forecast AS (
    SELECT
      Channel_Grouping_Name, Original_source, date_day,
      sqls_forecast AS sqls_forecast_raw,
      sqls_forecast * 0.7 AS sqls_lower_raw,
      sqls_forecast * 1.3 AS sqls_upper_raw,
      'Heuristic' AS forecast_method
    FROM `savvy-gtm-analytics.savvy_forecast.vw_heuristic_forecast`
    WHERE date_day >= CURRENT_DATE()
  ),
  caps AS (
    SELECT Channel_Grouping_Name, Original_source, mql_cap_recommended, sql_cap_recommended, sqo_cap_recommended
    FROM `savvy-gtm-analytics.savvy_forecast.daily_cap_reference`
  ),
  all_forecasts AS (
    SELECT
      COALESCE(am.Channel_Grouping_Name, hm.Channel_Grouping_Name) AS Channel_Grouping_Name,
      COALESCE(am.Original_source, hm.Original_source) AS Original_source,
      COALESCE(am.date_day, hm.date_day) AS date_day,
      COALESCE(am.mqls_forecast_raw, hm.mqls_forecast_raw, 0) AS mqls_forecast_raw,
      COALESCE(am.mqls_lower_raw, hm.mqls_lower_raw, 0) AS mqls_lower_raw,
      COALESCE(am.mqls_upper_raw, hm.mqls_upper_raw, 0) AS mqls_upper_raw,
      COALESCE(am.forecast_method, hm.forecast_method) AS mql_method
    FROM arima_forecast am
    FULL OUTER JOIN heuristic_forecast hm
      ON am.Channel_Grouping_Name = hm.Channel_Grouping_Name
      AND am.Original_source = hm.Original_source
      AND am.date_day = hm.date_day
  ),
  all_sql_forecasts AS (
    SELECT
      COALESCE(am.Channel_Grouping_Name, hm.Channel_Grouping_Name) AS Channel_Grouping_Name,
      COALESCE(am.Original_source, hm.Original_source) AS Original_source,
      COALESCE(am.date_day, hm.date_day) AS date_day,
      COALESCE(am.sqls_forecast_raw, hm.sqls_forecast_raw, 0) AS sqls_forecast_raw,
      COALESCE(am.sqls_lower_raw, hm.sqls_lower_raw, 0) AS sqls_lower_raw,
      COALESCE(am.sqls_upper_raw, hm.sqls_upper_raw, 0) AS sqls_upper_raw,
      COALESCE(am.forecast_method, hm.forecast_method) AS sql_method
    FROM arima_sql_forecast am
    FULL OUTER JOIN heuristic_sql_forecast hm
      ON am.Channel_Grouping_Name = hm.Channel_Grouping_Name
      AND am.Original_source = hm.Original_source
      AND am.date_day = hm.date_day
  ),
  capped_forecasts AS (
    SELECT
      COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) AS Channel_Grouping_Name,
      COALESCE(m.Original_source, s.Original_source) AS Original_source,
      COALESCE(m.date_day, s.date_day) AS date_day,
      LEAST(GREATEST(0, m.mqls_forecast_raw), COALESCE(c.mql_cap_recommended, 10)) AS mqls_forecast,
      GREATEST(0, m.mqls_lower_raw) AS mqls_lower,
      LEAST(m.mqls_upper_raw, COALESCE(c.mql_cap_recommended, 10) * 1.5) AS mqls_upper,
      LEAST(GREATEST(0, s.sqls_forecast_raw), COALESCE(c.sql_cap_recommended, 5)) AS sqls_forecast,
      GREATEST(0, s.sqls_lower_raw) AS sqls_lower,
      LEAST(s.sqls_upper_raw, COALESCE(c.sql_cap_recommended, 5) * 1.5) AS sqls_upper,
      COALESCE(c.mql_cap_recommended, 10) AS mql_cap_applied,
      COALESCE(c.sql_cap_recommended, 5) AS sql_cap_applied,
      COALESCE(c.sqo_cap_recommended, 3) AS sqo_cap_applied
    FROM all_forecasts m
    FULL OUTER JOIN all_sql_forecasts s
      ON m.Channel_Grouping_Name = s.Channel_Grouping_Name
      AND m.Original_source = s.Original_source
      AND m.date_day = s.date_day
    LEFT JOIN caps c
      ON COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) = c.Channel_Grouping_Name
      AND COALESCE(m.Original_source, s.Original_source) = c.Original_source
  ),
  trailing_rates_latest AS (
    SELECT 
      Channel_Grouping_Name, Original_source,
      s2q_rate_selected AS sql_to_sqo_rate
    FROM `savvy-gtm-analytics.savvy_forecast.trailing_rates_features`
    WHERE date_day = CURRENT_DATE()
  )
  SELECT 
    CURRENT_DATE() AS forecast_date,
    CURRENT_TIMESTAMP() AS forecast_version,
    c.Channel_Grouping_Name, c.Original_source, c.date_day,
    c.mqls_forecast, c.mqls_lower, c.mqls_upper,
    c.sqls_forecast, c.sqls_lower, c.sqls_upper,
    COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) AS sqos_forecast,
    GREATEST(0, COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) * 0.7) AS sqos_lower,
    COALESCE(c.sqls_forecast, 0) * COALESCE(r.sql_to_sqo_rate, 0.60) * 1.3 AS sqos_upper,
    c.mql_cap_applied, c.sql_cap_applied, c.sqo_cap_applied AS sqo_cap_applied
  FROM capped_forecasts c
  LEFT JOIN trailing_rates_latest r
    ON c.Channel_Grouping_Name = r.Channel_Grouping_Name
    AND c.Original_source = r.Original_source;

  
  -- ======== Step 6: Log Success ========
  INSERT INTO `savvy-gtm-analytics.savvy_forecast.model_training_log`
  VALUES (
    CURRENT_DATE(), 'AUTO_RETRAIN', 'SUCCESS',
    'Hybrid model (ARIMA+Heuristic) retrained with 90-day window.',
    retrain_timestamp, CURRENT_TIMESTAMP()
  );
  
END;

