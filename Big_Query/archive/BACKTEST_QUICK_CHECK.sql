-- Quick backtest validation checklist
-- Run these queries in order when backtest completes

-- ============================================
-- 1. VERIFY IT WORKED
-- ============================================

-- 1.1 Does table exist and have data?
SELECT 
  '✅ SUCCESS: Table exists' AS status,
  COUNT(*) AS total_rows,
  COUNT(DISTINCT train_end_date) AS num_backtest_weeks
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`;

-- 1.2 Coverage check
SELECT 
  '✅ SUCCESS: Coverage check' AS status,
  COUNT(*) AS num_segments,
  COUNTIF(num_backtests >= 12) AS segments_with_full_coverage,
  ROUND(COUNTIF(num_backtests >= 12) * 100.0 / COUNT(*), 1) AS pct_full_coverage
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`;

-- ============================================
-- 2. MEASURE ACCURACY
-- ============================================

-- 2.1 Overall performance
SELECT 
  '📊 ACCURACY: Overall' AS status,
  ROUND(AVG(mqls_mape) * 100, 1) AS mql_mape_pct,
  ROUND(AVG(sqls_mape) * 100, 1) AS sql_mape_pct,
  ROUND(AVG(sqos_mape) * 100, 1) AS sqo_mape_pct
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
WHERE num_backtests >= 3;

-- 2.2 Best performing segments
SELECT 
  '🏆 BEST: Top 5' AS status,
  Channel_Grouping_Name,
  Original_source,
  ROUND(sqos_mape * 100, 1) AS sqo_mape_pct,
  total_sqos_actual
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
WHERE num_backtests >= 3
ORDER BY sqos_mape ASC
LIMIT 5;

-- 2.3 Worst performing segments
SELECT 
  '⚠️ WORST: Bottom 5' AS status,
  Channel_Grouping_Name,
  Original_source,
  ROUND(sqos_mape * 100, 1) AS sqo_mape_pct,
  total_sqos_actual
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
WHERE num_backtests >= 3
ORDER BY sqos_mape DESC
LIMIT 5;

-- ============================================
-- 3. CHECK DATA VOLUME
-- ============================================

-- 3.1 Total data in backtest
SELECT 
  '📈 DATA VOLUME: Total' AS status,
  SUM(total_mqls_actual) AS total_mqls,
  SUM(total_sqls_actual) AS total_sqls,
  SUM(total_sqos_actual) AS total_sqos,
  COUNT(*) AS num_segments
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`;

-- 3.2 Data sufficiency by segment
SELECT 
  '📊 DATA VOLUME: By Volume Tier' AS status,
  CASE 
    WHEN total_sqos_actual < 10 THEN 'Insufficient (<10)'
    WHEN total_sqos_actual < 50 THEN 'Minimal (10-50)'
    WHEN total_sqos_actual < 100 THEN 'Adequate (50-100)'
    ELSE 'Good (>100)'
  END AS volume_tier,
  COUNT(*) AS num_segments,
  AVG(sqos_mape) AS avg_sqo_mape
FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
WHERE num_backtests >= 3
GROUP BY 1
ORDER BY 
  CASE volume_tier
    WHEN 'Good (>100)' THEN 1
    WHEN 'Adequate (50-100)' THEN 2
    WHEN 'Minimal (10-50)' THEN 3
    ELSE 4
  END;

-- ============================================
-- 4. FINAL ASSESSMENT
-- ============================================

WITH overall AS (
  SELECT 
    AVG(sqos_mape) AS avg_sqo_mape,
    AVG(sqls_mape) AS avg_sql_mape,
    AVG(mqls_mape) AS avg_mql_mape,
    SUM(total_sqos_actual) AS total_sqos,
    COUNT(*) AS num_segments,
    COUNTIF(num_backtests >= 12) AS full_coverage_segments
  FROM `savvy-gtm-analytics.savvy_forecast.backtest_results`
  WHERE num_backtests >= 3
)
SELECT 
  '🎯 FINAL ASSESSMENT' AS status,
  ROUND(avg_mql_mape * 100, 1) AS mql_mape_pct,
  ROUND(avg_sql_mape * 100, 1) AS sql_mape_pct,
  ROUND(avg_sqo_mape * 100, 1) AS sqo_mape_pct,
  total_sqos,
  num_segments,
  full_coverage_segments,
  
  -- Quality gates
  CASE WHEN avg_sqo_mape < 0.30 THEN '✅ PASS' ELSE '❌ FAIL' END AS accuracy_check,
  CASE WHEN total_sqos >= 100 THEN '✅ PASS' ELSE '❌ FAIL' END AS data_volume_check,
  CASE WHEN full_coverage_segments >= num_segments * 0.8 THEN '✅ PASS' ELSE '❌ FAIL' END AS coverage_check,
  
  -- Overall verdict
  CASE 
    WHEN avg_sqo_mape < 0.30 AND total_sqos >= 100 AND full_coverage_segments >= num_segments * 0.8 
    THEN '🎉 PRODUCTION READY'
    ELSE '⚠️ NEEDS IMPROVEMENT'
  END AS final_verdict
FROM overall;

