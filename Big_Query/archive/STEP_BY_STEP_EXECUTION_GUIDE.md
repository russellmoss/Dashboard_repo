# Step-by-Step: Run the Forecast Pipeline in BigQuery

## ✅ YES - You need to run this in BigQuery yourself

The MCP tool has type-casting issues that BigQuery Console handles automatically.

---

## Step-by-Step Instructions

### Step 1: Open BigQuery Console

1. Go to: https://console.cloud.google.com/bigquery
2. Make sure you're in the `savvy-gtm-analytics` project

### Step 2: Create the Table (First Time Only)

Copy and run this SQL:

```sql
CREATE TABLE IF NOT EXISTS `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
(
  forecast_date DATE,
  forecast_version TIMESTAMP,
  Channel_Grouping_Name STRING,
  Original_source STRING,
  date_day DATE,
  mqls_forecast FLOAT64,
  mqls_lower FLOAT64,
  mqls_upper FLOAT64,
  sqls_forecast FLOAT64,
  sqls_lower FLOAT64,
  sqls_upper FLOAT64,
  sqos_forecast FLOAT64,
  sqos_lower FLOAT64,
  sqos_upper FLOAT64,
  mql_cap_applied FLOAT64,
  sql_cap_applied FLOAT64,
  sqo_cap_applied FLOAT64
)
PARTITION BY forecast_date
CLUSTER BY Channel_Grouping_Name, Original_source;
```

**Click "Run"** ✓

---

### Step 3: Generate and Insert Forecasts

Copy and run this **full INSERT statement**:

```sql
INSERT INTO `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WITH 
mql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS mqls_forecast_raw,
    prediction_interval_lower_bound AS mqls_lower_raw,
    prediction_interval_upper_bound AS mqls_upper_raw
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_mqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
sql_forecast AS (
  SELECT
    Channel_Grouping_Name,
    Original_source,
    CAST(forecast_timestamp AS DATE) AS date_day,
    forecast_value AS sqls_forecast_raw,
    prediction_interval_lower_bound AS sqls_lower_raw,
    prediction_interval_upper_bound AS sqls_upper_raw
  FROM ML.FORECAST(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_arima_sqls`,
    STRUCT(90 AS horizon, 0.9 AS confidence_level)
  )
),
caps AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    mql_cap_recommended,
    sql_cap_recommended,
    sqo_cap_recommended
  FROM `savvy-gtm-analytics.savvy_forecast.daily_cap_reference`
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
  FROM mql_forecast m
  FULL OUTER JOIN sql_forecast s
    ON m.Channel_Grouping_Name = s.Channel_Grouping_Name
    AND m.Original_source = s.Original_source
    AND m.date_day = s.date_day
  LEFT JOIN caps c
    ON COALESCE(m.Channel_Grouping_Name, s.Channel_Grouping_Name) = c.Channel_Grouping_Name
    AND COALESCE(m.Original_source, s.Original_source) = c.Original_source
),
segment_enrichment AS (
  SELECT 
    Channel_Grouping_Name,
    Original_source,
    AVG(log_rep_years) AS avg_log_rep_years,
    AVG(log_rep_aum) AS avg_log_rep_aum,
    AVG(log_rep_clients) AS avg_log_rep_clients,
    AVG(COALESCE(rep_aum_growth_1y, 0)) AS avg_rep_aum_growth_1y,
    AVG(CAST(rep_hnw_client_count AS FLOAT64)) AS avg_rep_hnw_client_count,
    AVG(log_firm_aum) AS avg_log_firm_aum,
    AVG(log_firm_reps) AS avg_log_firm_reps,
    AVG(COALESCE(firm_aum_growth_1y, 0)) AS avg_firm_aum_growth_1y,
    AVG(CAST(is_lead_converted AS FLOAT64)) AS avg_is_lead_converted,
    AVG(CAST(is_opp_direct AS FLOAT64)) AS avg_is_opp_direct,
    AVG(COALESCE(combined_growth, 0)) AS avg_combined_growth,
    AVG(mapping_confidence) AS avg_mapping_confidence
  FROM `savvy-gtm-analytics.savvy_forecast.sql_sqo_propensity_training`
  WHERE sql_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY) AND CURRENT_DATE()
  GROUP BY 1,2
),
propensity_input AS (
  SELECT
    c.Channel_Grouping_Name,
    c.Original_source,
    c.date_day,
    c.sqls_forecast,
    c.sqo_cap_applied,
    r.s2q_rate_selected AS trailing_sql_sqo_rate,
    r.m2s_rate_selected AS trailing_mql_sql_rate,
    CAST(ROUND(c.sqls_forecast) AS INT64) AS same_day_sql_count,
    CAST(ROUND(c.sqls_forecast) AS INT64) AS sql_count_7d,
    CAST(EXTRACT(DAYOFWEEK FROM c.date_day) AS INT64) AS day_of_week,
    CAST(EXTRACT(MONTH FROM c.date_day) AS INT64) AS month,
    CAST(CASE WHEN EXTRACT(DAYOFWEEK FROM c.date_day) IN (1, 7) THEN 0 ELSE 1 END AS INT64) AS is_business_day,
    COALESCE(se.avg_log_rep_years, 0.0) AS log_rep_years,
    COALESCE(se.avg_log_rep_aum, 0.0) AS log_rep_aum,
    COALESCE(se.avg_log_rep_clients, 0.0) AS log_rep_clients,
    COALESCE(se.avg_rep_aum_growth_1y, 0.0) AS rep_aum_growth_1y,
    CAST(COALESCE(se.avg_rep_hnw_client_count, 0.0) AS INT64) AS rep_hnw_client_count,
    COALESCE(se.avg_log_firm_aum, 0.0) AS log_firm_aum,
    COALESCE(se.avg_log_firm_reps, 0.0) AS log_firm_reps,
    COALESCE(se.avg_firm_aum_growth_1y, 0.0) AS firm_aum_growth_1y,
    CAST(COALESCE(se.avg_is_lead_converted, 0.0) AS INT64) AS is_lead_converted,
    CAST(COALESCE(se.avg_is_opp_direct, 0.0) AS INT64) AS is_opp_direct,
    COALESCE(se.avg_combined_growth, 0.0) AS combined_growth,
    CAST(0 AS INT64) AS days_in_sql_stage,
    COALESCE(se.avg_mapping_confidence, 0.0) AS mapping_confidence
  FROM capped_forecasts c
  LEFT JOIN `savvy-gtm-analytics.savvy_forecast.trailing_rates_features` r
    ON r.date_day = CURRENT_DATE()
    AND c.Channel_Grouping_Name = r.Channel_Grouping_Name
    AND c.Original_source = r.Original_source
  LEFT JOIN segment_enrichment se
    ON c.Channel_Grouping_Name = se.Channel_Grouping_Name
    AND c.Original_source = se.Original_source
),
sqo_propensity AS (
  SELECT
    date_day,
    Channel_Grouping_Name,
    Original_source,
    predicted_label_probs[OFFSET(1)].prob AS conversion_prob
  FROM ML.PREDICT(
    MODEL `savvy-gtm-analytics.savvy_forecast.model_sql_sqo_propensity`,
    (SELECT * FROM propensity_input)
  )
)
SELECT 
  CURRENT_DATE() AS forecast_date,
  CURRENT_TIMESTAMP() AS forecast_version,
  c.Channel_Grouping_Name,
  c.Original_source,
  c.date_day,
  c.mqls_forecast,
  c.mqls_lower,
  c.mqls_upper,
  c.sqls_forecast,
  c.sqls_lower,
  c.sqls_upper,
  LEAST(
    COALESCE(p_in.sqls_forecast, 0) * COALESCE(s_prop.conversion_prob, 0.6),
    p_in.sqo_cap_applied
  ) AS sqos_forecast,
  LEAST(
    GREATEST(0, COALESCE(p_in.sqls_forecast, 0) * COALESCE(s_prop.conversion_prob, 0.6) * 0.7),
    p_in.sqo_cap_applied
  ) AS sqos_lower,
  LEAST(
    COALESCE(p_in.sqls_forecast, 0) * COALESCE(s_prop.conversion_prob, 0.6) * 1.3,
    p_in.sqo_cap_applied * 1.5
  ) AS sqos_upper,
  c.mql_cap_applied,
  c.sql_cap_applied,
  p_in.sqo_cap_applied AS sqo_cap_applied
FROM capped_forecasts c
LEFT JOIN propensity_input p_in
  ON p_in.Channel_Grouping_Name = c.Channel_Grouping_Name
  AND p_in.Original_source = c.Original_source
  AND p_in.date_day = c.date_day
LEFT JOIN sqo_propensity s_prop
  ON p_in.date_day = s_prop.date_day
  AND p_in.Channel_Grouping_Name = s_prop.Channel_Grouping_Name
  AND p_in.Original_source = s_prop.Original_source;
```

**Click "Run"** ✓

**Expected time**: 2-5 minutes  
**Expected output**: "This statement modified 2,160 rows in [time]"

---

### Step 4: Validate the Forecasts (Optional)

Run this to check your results:

```sql
SELECT 
  COUNT(*) AS total_forecasts,
  COUNT(DISTINCT Channel_Grouping_Name || ' - ' || Original_source) AS unique_segments,
  COUNT(DISTINCT date_day) AS forecast_horizon_days,
  MIN(sqos_forecast) AS min_sqo,
  AVG(sqos_forecast) AS avg_sqo,
  MAX(sqos_forecast) AS max_sqo
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`;
```

**Expected Results**:
- `total_forecasts`: ~2,160
- `unique_segments`: 24
- `forecast_horizon_days`: 90

---

### Step 5: View Sample Forecasts

```sql
SELECT *
FROM `savvy-gtm-analytics.savvy_forecast.daily_forecasts`
WHERE Channel_Grouping_Name = 'Outbound'
  AND Original_source = 'LinkedIn (Self Sourced)'
ORDER BY date_day
LIMIT 10;
```

---

## ✅ You're Done!

Your complete 90-day forecast is now in the `daily_forecasts` table!

**What's included**:
- MQL forecasts (with confidence intervals)
- SQL forecasts (with confidence intervals)
- SQO forecasts (ARIMA + Propensity hybrid, with confidence intervals)
- All capped to realistic values

---

## Troubleshooting

**If you get an error about the table not existing**: Run Step 2 first.

**If you get type errors**: The SQL should work as-is in BigQuery Console. If not, let me know the exact error message.

**If the query runs slowly**: This is normal. 2,160 rows with ML.PREDICT takes 2-5 minutes.

