## Best-in-Class BQML Forecasting Plan (ARIMA_PLUS + Propensity)

### Purpose
This document specifies the data, definitions, modeling approach, features, backtesting, reconciliation, and deployment plan to build a production-grade forecasting system for MQLs, SQLs, and SQOs in BigQuery (BQML). It is designed for iterative refinement by Gemini/Claude and to be executed agentically later.

### Scope and Targets
- Stages to forecast: `mqls`, `sqls`, `sqos` (optionally `joined` downstream)
- Granularity: daily at segment level, with rollups
- Segments: `Channel_Grouping_Name` × `Original_source` (primary); fallbacks: Channel-only, Global
- Cohort: active SGA/SGM owners only for rate/flow estimates; actuals are unfiltered for reporting parity

---

## 1) Data Sources in BigQuery

### Funnel base (existing)
- `savvy-gtm-analytics.savvy_analytics.vw_funnel_lead_to_joined_v2`
  - Keys: `Full_prospect_id__c`, `Full_Opportunity_ID__c`, `SGA_Owner_Name__c`, `Opportunity_Owner_Name__c`
  - Segments: `Channel_Grouping_Name`, `Original_source`
  - Dates/timestamps:
    - `FilterDate` (cohort/date anchor per record)
    - `mql_stage_entered_ts`, `converted_date_raw` (SQL), `Date_Became_SQO__c`, `advisor_join_date__c`
  - Stage flags (0/1): `is_contacted`, `is_mql`, `is_sql`, `is_sqo`, `is_joined`
  - SQO evaluation fields: `SQL__c`/`SQO_raw` and opp identifiers for denominators

### Forecast targets (existing)
- `savvy-gtm-analytics.SavvyGTMData.q4_2025_forecast`
  - Dimensions: `Channel` (mapped to `Channel_Grouping_Name`), `original_source`, `stage`, `metric='Cohort_source'`
  - Aggregation: monthly rows → quarterly targets

### Active owner filter (existing)
- `savvy-gtm-analytics.SavvyGTMData.User` with `(IsSGA__c OR Is_SGM__c) AND IsActive=TRUE`

### Rep and firm enrichment (new, to be leveraged)
- `savvy-gtm-analytics.LeadScoring.discovery_reps_current`
  - Key fields: `RepCRD` (join key to reps), `RIAFirmCRD`
  - Advisor attributes: licenses, disclosures, education, veteran indicator, dually registered, years at firm, clients and AUM breakdowns, geography (home/branch), custodian relationships, growth metrics (1y/5y), stability & momentum scores
  - Useful to engineer: advisor seniority, focus, product mix, HNW concentration, distance, firm association intensity, disclosure risk

- `savvy-gtm-analytics.LeadScoring.discovery_firms_current`
  - Key: `RIAFirmCRD`, `RIAFirmName`
  - Firm aggregates: total/avg AUM, growth 1y/5y, client counts, per-rep distributions, credential concentration (CFP/Series 7), size tiers, multi-state/metro indicators
  - Useful to engineer: firm growth momentum, scale, credential intensity, custodian concentration

Join concept (attribution):
- Leads and Opportunities → Rep → RepCRD → Firm via `RIAFirmCRD`
- You will need mapping tables from Salesforce rep identifiers to `RepCRD`. If not present, build a keyed linkage (e.g., by email/name + firm) and track match confidence.

---

## 2) Canonical Definitions and Nuances

### Date conventions
- `FilterDate`: canonical daily anchor for each record; use `DATE(FilterDate)` as the date dimension.
- Event dates:
  - MQL: `DATE(mql_stage_entered_ts)`
  - SQL: `DATE(converted_date_raw)`
  - SQO: `DATE(Date_Became_SQO__c)`

### Corrected progression logic (avoid non-sequential inflation)
- prospect→MQL: numerator = contacted∧MQL; denominator = contacted
- MQL→SQL: numerator = MQL∧SQL; denominator = MQL
- SQL→SQO: numerator = SQL∧SQO opp IDs; denominator = SQL opp IDs (evaluated)
- SQO→Joined: numerator = SQO∧Joined; denominator = SQO opp IDs

### Active cohort for rate estimation
- Restrict rate calculations and open-pipeline counts to active SGA/SGM owners.
- Actuals used for reporting can remain unfiltered to match dashboards.

### Segmentation strategy
- Primary: source-level (channel+source)
- Backoff: channel-only if denominators sparse; global if still sparse. Use consistent thresholds (e.g., ≥30 events/90 days) and expose both rate and denominator in features.

---

## 3) Targets and Problem Formulation

We blend two model types:
1) Time-series volume forecasting (per stage per segment): ARIMA_PLUS
2) Propensity modeling for stage transitions: logistic/XGBoost (MQL→SQL, SQL→SQO)

We will forecast daily counts by stage. There are two viable routes:
- Route A (pure ARIMA per stage): Fit ARIMA_PLUS to daily counts for each stage/segment.
- Route B (hybrid): Fit ARIMA_PLUS to upstream stages (e.g., MQLs) and use propensity models to project SQLs and SQOs from MQLs, reflecting pipeline quality.

Recommendation: Start with Route A for MQLs and SQLs; use propensity for SQL→SQO to capture evaluation and quality effects.

---

## 4) Feature Engineering

### Time-series (per segment, daily)
- Stage daily counts: `mqls_daily`, `sqls_daily`, `sqos_daily`
- Calendar features: day-of-week, week-of-quarter, month, business day flags, holiday flags (US), end-of-month proximity
- Seasonality proxies: last-year same-weekday counts (if history exists)
- Source-mix context: rolling proportions by channel/source

### Propensity features (row- or day-aggregated)
- Recent rates: trailing 30/60/90-day corrected rates and denominators
- Pipeline context: open counts in prior stage, recent arrivals in prior stage
- Evaluation quality: share of SQL opps with SQO flag present; average evaluation lag
- Discovery reps (RepCRD): seniority (years), credentials (CFP/Series7 etc.), disclosures, product focus, HNW concentration, distance/metro indicators, custodian relationships, growth momentum, stability score
- Discovery firms (RIAFirmCRD): firm size tier, growth 1y/5y, credential intensity, multi-state, custodian concentration, clients per rep
- Owner activity: active owner density per segment, changes in active headcount

Target definitions for propensity:
- MQL→SQL: binary label per MQL (1 if progressed to SQL within horizon H, else 0), with event-time windows
- SQL→SQO: binary label per SQL opportunity (1 if SQO within H, else 0)

Lag modeling:
- Include observed median and distributional lag features (e.g., median MQL→SQL ~1 day; SQL→SQO ~5 days) to inform timing of conversions in the daily simulation.

---

## 5) Data Preparation Views

### Daily actuals by stage
- For each date d and segment s, compute daily counts for MQL, SQL, SQO using event dates.

### Trailing rates tables
- For each date d and segment s, compute corrected progression rates and denominators over trailing windows (30/60/90 days). Include backoff-selected rate and raw denominators as features.

### Enrichment joins
- Map lead/opportunity owner → Rep → `RepCRD` → `RIAFirmCRD` → join attributes from `discovery_reps_current` and `discovery_firms_current` to the appropriate grain:
  - For propensity (row-level), join to the subject (MQL row or SQL opp) by best-available mapping.
  - For time-series, aggregate features daily per segment (e.g., average firm growth where reps contributing on that day belong to high-growth firms).

### Labeling sets
- For MQL→SQL: build labeled examples with MQL date and label=1 if SQL occurs within H days (try H∈{14,30}). Include censoring logic for near-present events.
- For SQL→SQO: similarly, with SQL date and label=1 if SQO within H days (e.g., 14 days).

---

## 6) Modeling in BQML

### ARIMA_PLUS: daily stage volumes per segment
Example (MQLs):
```sql
CREATE OR REPLACE MODEL `project.dataset.arima_mqls`
OPTIONS(
  model_type = 'ARIMA_PLUS',
  time_series_timestamp_col = 'date_day',
  time_series_data_col = 'mqls_daily',
  time_series_id_col = ['Channel_Grouping_Name','Original_source'],
  horizon = 90,
  decompose_time_series = TRUE,
  holiday_region = 'US',
  auto_arima = TRUE,
  data_frequency = 'DAILY'
)
AS
SELECT date_day, Channel_Grouping_Name, Original_source, mqls_daily
FROM `project.dataset.daily_stage_counts`;
```

Repeat for SQLs (or derive via propensity). For SQOs, prefer hybrid: forecast SQLs and apply propensity to get SQOs to reflect quality/evaluation.

### Propensity (LOGISTIC_REG or XGBOOST)
MQL→SQL propensity:
```sql
CREATE OR REPLACE MODEL `project.dataset.prop_mql_to_sql`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['label'],
  data_split_method = 'AUTO_SPLIT'
)
AS
SELECT
  label,  -- 1 if SQL within H days, else 0
  -- features
  trailing_c2m_rate_30, trailing_c2m_den_30,
  trailing_m2s_rate_30, trailing_m2s_den_30,
  open_mqls_prior_day, new_mqls_last_7d,
  rep_seniority_years, has_cfp, has_series7, disclosures_flag,
  firm_growth_1y, firm_size_tier, custodian_concentration,
  channel_grouping_name, original_source,
  dow, is_business_day
FROM `project.dataset.mql_sql_training_rows`;
```

SQL→SQO propensity: analogous, with SQL opp features including evaluation coverage (`SQO_raw` availability ratio), lags, and firm/rep quality.

### Forecasting with propensity
1) Use ARIMA_PLUS forecasts for MQLs (and optionally SQLs).
2) Score propensities for entities arriving in the horizon:
   - For MQL→SQL: estimate expected SQLs on day d as forecast_mqls(d) × P(MQL→SQL | features_d)
   - For SQL→SQO: estimate expected SQOs on day d as forecast_sqls(d) × P(SQL→SQO | features_d)
3) Apply lag distributions to shift expected conversions forward by median/quantile lags.

---

## 7) Backtesting and Evaluation

### Backtest windows
- Prior 3 quarters: for each quarter Q:
  - Train cutoff: day 0 of Q (use history before Q)
  - Forecast horizon: the entire Q (90 days)

### Strategies
- Static: train-once at quarter start; forecast full horizon
- Rolling: retrain weekly; forecast remainder (more realistic operations)

### Metrics
- Point accuracy per stage and in aggregate: MAPE, sMAPE, RMSE
- Interval quality (ARIMA_PLUS): coverage of 80/95% prediction intervals
- Propensity calibration: AUC-ROC, PR-AUC, Brier score, calibration plots
- Operational: total by stage vs actual, segment mix error, peak daily error, slope stability post day 29

### Stress tests
- Source mix shifts: simulate channel/source swings and evaluate forecast robustness
- Evaluation gaps: model performance when SQO evaluation lag increases or coverage dips

---

## 8) Reconciliation and Guardrails

### Reconciliation
- When combining segment forecasts, reconcile to any official top-down target with a proportional method weighted by model uncertainty (e.g., inverse variance). For a pure data-first approach, skip target reconciliation, report bands.

### Guardrails (lightweight)
- Daily rate caps based on historical p90 per stage (as in the SQL prototype)
- Asymmetric downscale: if modeled totals exceed targets by >10%, scale down the future component; do not scale up if under
- Band limits: constrain daily SQO ramp to historical p90 unless recent per-day production exceeds p95

---

## 9) Data Quality and Mapping

### Mapping to RepCRD / RIAFirmCRD
- Build/validate mapping from SGA/SGM user or owner IDs/emails to `RepCRD`; derive `RIAFirmCRD` via `discovery_reps_current`
- Track mapping confidence; exclude low-confidence joins from training features or use neutral defaults

### Event correctness
- Ensure all event dates are derived consistently (e.g., timezone, missing values) and that deduplication of `Full_Opportunity_ID__c` is enforced for opp-based stages
- Monitor `SQO_raw` coverage among SQL opps; create an evaluation-coverage feature

### Segment stability
- Enforce minimum denominator thresholds; log segments falling back to channel/global

---

## 10) Deliverables & Execution Plan

### Artifacts to create
- Data prep views:
  - `daily_stage_counts` (date × segment × stage counts)
  - `trailing_rates_xy` (date × segment × corrected rates + denominators, with backoff choice)
  - `mql_sql_training_rows`, `sql_sqo_training_rows` (with labels and features)
  - Rep/Firm enrichment joins (rep- and firm-level rollups to segment/day)
- BQML models:
  - `arima_mqls`, `arima_sqls` (optional), or `arima_mqls` + propensity chain
  - `prop_mql_to_sql`, `prop_sql_to_sqo`
- Backtest scripts:
  - Parameterized SQL to run static and rolling backtests per quarter, store predictions
  - Evaluation scripts writing metrics to `forecast_eval_metrics`
- Serving view:
  - Daily time series with predicted, lower/upper bounds per stage and segment
  - Optional target line (stepped monthly → daily)

### Initial hyperparameters
- ARIMA_PLUS: accept auto_arima; consider `holiday_region='US'`, `decompose_time_series=TRUE`
- Propensity: start with `LOGISTIC_REG` (robust, explainable); move to `BOOSTED_TREE_CLASSIFIER` if non-linear gains are observed
- Lag: use empirical medians (MQL→SQL ≈ 1 day; SQL→SQO ≈ 5 days) and optionally a discrete distribution for allocation

### Governance
- Model registry: snapshot models each quarter; log training data ranges and feature schemas
- Monitoring: weekly drift checks on rates, segment mix, and daily caps engagement rate

---

## 11) Open Questions / To Refine
- Confirm reliable mapping from owners to `RepCRD`; define fallback when missing
- Choose propensity horizons (H) and lag distributions by backtest results
- Decide reconciliation policy (pure data vs top-down target alignment) per use-case
- Determine per-stage p90 caps from production history (current: MQL 14/day, SQL 5/day, SQO 4/day placeholders)

---

## 12) Summary
This plan formalizes a scalable BQML approach combining ARIMA_PLUS for daily stage volumes and propensity models for stage transitions, with corrected funnel logic, segment backoff, rep/firm enrichment, robust backtesting, and light guardrails. It is designed for iterative refinement and production deployment with clear evaluation checkpoints.


