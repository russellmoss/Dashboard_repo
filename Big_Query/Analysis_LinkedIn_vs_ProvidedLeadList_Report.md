# Conversion Rate Analysis: LinkedIn (Self Sourced) vs. Provided Lead List
## Q1 2024 - Q3 2025

---

## Executive Summary

This analysis compares the conversion funnel performance of **LinkedIn (Self Sourced)** and **Provided Lead List** across three key conversion stages from Q1 2024 through Q3 2025. The analysis examines both absolute SQO production and conversion rate performance, including statistical significance testing.

### Key Findings:
- **LinkedIn (Self Sourced) produced 182 SQOs** vs. **Provided Lead List produced 163 SQOs** (12% more)
- **LinkedIn shows much higher Contacted→MQL rates** (17.66% vs. 2.72%, 6.5x higher) - **NOT statistically significant** due to high volatility and small sample size
- **MQL→SQL rates are statistically similar** (47.71% vs. 42.74%, p > 0.05)
- **SQL→SQO rates are statistically similar** (59.46% vs. 54.74%, p > 0.05)
- **LinkedIn shows much higher volatility** in Contacted→MQL rates (std dev: 22.02% vs. 0.75%)

---

## 1. Absolute SQO Production

### Total SQOs by Source (Q1 2024 - Q3 2025)

| Source | Total SQOs | Percentage of Total |
|--------|------------|---------------------|
| **LinkedIn (Self Sourced)** | **182** | **52.8%** |
| **Provided Lead List** | **163** | **47.2%** |
| **Total** | **345** | **100%** |

**Finding:** LinkedIn (Self Sourced) produced 19 more SQOs (12% more) than Provided Lead List over the 7-quarter period.

---

## 2. Quarterly Conversion Rate Analysis

### 2.1 Contacted → MQL Conversion Rates

| Quarter | LinkedIn (Self Sourced) | Provided Lead List | Difference |
|---------|-------------------------|-------------------|------------|
| 2024-Q1 | 66.67% | 3.51% | +63.16% |
| 2024-Q2 | 16.94% | 2.02% | +14.92% |
| 2024-Q3 | 12.55% | 1.74% | +10.81% |
| 2024-Q4 | 9.98% | 2.08% | +7.90% |
| 2025-Q1 | 7.21% | 3.29% | +3.92% |
| 2025-Q2 | 4.85% | 3.03% | +1.82% |
| 2025-Q3 | 5.46% | 3.38% | +2.08% |

**Summary Statistics:**
- **LinkedIn Average:** 17.66% (Std Dev: 22.02%, Range: 4.85% - 66.67%)
- **Provided Lead List Average:** 2.72% (Std Dev: 0.75%, Range: 1.74% - 3.51%)
- **Average Difference:** +14.94 percentage points

**Volatility Analysis:**
- LinkedIn shows **29x higher volatility** (std dev: 22.02% vs. 0.75%)
- LinkedIn's rate has declined significantly from Q1 2024 (66.67%) to recent quarters (~5%)
- Provided Lead List shows very stable rates (consistently 1.7% - 3.5%)

### 2.2 MQL → SQL Conversion Rates

| Quarter | LinkedIn (Self Sourced) | Provided Lead List | Difference |
|---------|-------------------------|-------------------|------------|
| 2024-Q1 | 92.31% | 68.42% | +23.89% |
| 2024-Q2 | 76.92% | 59.32% | +17.60% |
| 2024-Q3 | 53.85% | 48.57% | +5.28% |
| 2024-Q4 | 24.12% | 33.33% | -9.21% |
| 2025-Q1 | 28.31% | 25.34% | +2.97% |
| 2025-Q2 | 29.38% | 40.58% | -11.20% |
| 2025-Q3 | 29.05% | 23.61% | +5.44% |

**Summary Statistics:**
- **LinkedIn Average:** 47.71% (Std Dev: 27.38%, Range: 24.12% - 92.31%)
- **Provided Lead List Average:** 42.74% (Std Dev: 16.98%, Range: 23.61% - 68.42%)
- **Average Difference:** +4.97 percentage points

**Volatility Analysis:**
- LinkedIn shows **1.6x higher volatility** (std dev: 27.38% vs. 16.98%)
- Both sources show declining trends from early 2024 peaks
- LinkedIn's rate dropped from 92.31% (Q1 2024) to ~29% (recent quarters)

### 2.3 SQL → SQO Conversion Rates

| Quarter | LinkedIn (Self Sourced) | Provided Lead List | Difference |
|---------|-------------------------|-------------------|------------|
| 2024-Q1 | 50.00% | 52.38% | -2.38% |
| 2024-Q2 | 60.00% | 50.00% | +10.00% |
| 2024-Q3 | 42.86% | 42.00% | +0.86% |
| 2024-Q4 | 65.22% | 54.90% | +10.32% |
| 2025-Q1 | 64.44% | 70.27% | -5.83% |
| 2025-Q2 | 65.45% | 59.65% | +5.80% |
| 2025-Q3 | 68.25% | 54.00% | +14.25% |

**Summary Statistics:**
- **LinkedIn Average:** 59.46% (Std Dev: 9.46%, Range: 42.86% - 68.25%)
- **Provided Lead List Average:** 54.74% (Std Dev: 8.72%, Range: 42.00% - 70.27%)
- **Average Difference:** +4.72 percentage points

**Volatility Analysis:**
- Similar volatility levels (std dev: 9.46% vs. 8.72%)
- Both sources show relatively stable SQL→SQO rates
- LinkedIn shows slight upward trend in recent quarters

---

## 3. Statistical Significance Testing

### 3.1 Contacted → MQL Rate

**Two-Sample t-Test (Welch's t-test for unequal variances):**
- **Mean Difference:** 14.94 percentage points
- **t-statistic:** 1.79
- **Degrees of Freedom:** 6.01
- **Critical t-value (α=0.05, two-tailed):** ±2.447
- **Result:** **NOT statistically significant** at α=0.05 (t=1.79 < 2.447, p ≈ 0.12)

**Note:** While the difference is large (14.94 pp) and practically meaningful (6.5x higher), the high volatility in LinkedIn's rates (especially the Q1 2024 outlier of 66.67%) and small sample size (n=7 quarters) prevent statistical significance. The effect size (Cohen's d = 0.68) suggests a medium-to-large practical effect, but more data is needed for statistical confirmation.

**Effect Size (Cohen's d):** 0.68 (Medium effect)

### 3.2 MQL → SQL Rate

**Two-Sample t-Test:**
- **Mean Difference:** 4.97 percentage points
- **t-statistic:** 0.41
- **Degrees of Freedom:** 10.02
- **Critical t-value (α=0.05, two-tailed):** ±2.228
- **Result:** **NOT statistically significant** (t=0.41 < 2.228)

**Effect Size (Cohen's d):** 0.20 (Small effect)

### 3.3 SQL → SQO Rate

**Two-Sample t-Test:**
- **Mean Difference:** 4.72 percentage points
- **t-statistic:** 0.97
- **Degrees of Freedom:** 11.92
- **Critical t-value (α=0.05, two-tailed):** ±2.179
- **Result:** **NOT statistically significant** (t=0.97 < 2.179)

**Effect Size (Cohen's d):** 0.50 (Medium effect)

---

## 4. Volatility Analysis

### Coefficient of Variation (CV = Std Dev / Mean)

| Conversion Stage | LinkedIn CV | Provided Lead List CV | Ratio |
|-----------------|-------------|----------------------|-------|
| Contacted → MQL | 124.6% | 27.6% | **4.5x** |
| MQL → SQL | 57.4% | 39.7% | **1.4x** |
| SQL → SQO | 15.9% | 15.9% | **1.0x** |

**Key Insight:** LinkedIn shows dramatically higher volatility in the Contacted→MQL stage, making it less predictable than Provided Lead List.

---

## 5. Trend Analysis

### 5.1 Contacted → MQL Trends

**LinkedIn (Self Sourced):**
- **Q1 2024:** 66.67% (outlier - very small sample: n=3 contacted)
- **Q2-Q3 2024:** ~12-17% (more stable)
- **Q4 2024 - Q3 2025:** Declining to ~5-7% range
- **Trend:** Significant decline from early 2024 peaks

**Provided Lead List:**
- **Consistently stable:** 1.7% - 3.5% across all quarters
- **Trend:** No significant trend, very predictable

### 5.2 MQL → SQL Trends

**Both sources show declining trends:**
- LinkedIn: 92.31% (Q1 2024) → ~29% (recent)
- Provided Lead List: 68.42% (Q1 2024) → ~24% (recent)

### 5.3 SQL → SQO Trends

**Both sources show relatively stable rates:**
- LinkedIn: Slight upward trend (50% → 68%)
- Provided Lead List: Relatively flat (50% - 70%)

---

## 6. Key Insights & Recommendations

### 6.1 Is LinkedIn (Self Sourced) Actually Better?

**Answer: It depends on the metric:**

1. **Absolute SQO Production:** ✅ **Yes** - LinkedIn produced 12% more SQOs (182 vs. 163)

2. **Contacted → MQL Rate:** ✅ **Yes** - LinkedIn averages 17.66% vs. 2.72% (6.5x higher), but:
   - Extremely high volatility (std dev: 22.02%)
   - Significant decline from early 2024
   - Q1 2024 outlier (66.67%) skews average
   - Recent quarters show only 2-3x advantage

3. **MQL → SQL Rate:** ⚠️ **Marginally Better** - LinkedIn averages 47.71% vs. 42.74% (+4.97 pp), but:
   - Not statistically significant
   - Both sources show declining trends
   - High volatility in both

4. **SQL → SQO Rate:** ⚠️ **Marginally Better** - LinkedIn averages 59.46% vs. 54.74% (+4.72 pp), but:
   - Not statistically significant
   - Similar volatility levels

### 6.2 Volatility Concerns

**LinkedIn's high volatility in Contacted→MQL creates:**
- **Predictability challenges** for forecasting and planning
- **Resource allocation uncertainty** (hard to know how many MQLs to expect)
- **Quality concerns** - the dramatic decline suggests potential quality degradation

**Provided Lead List's stability provides:**
- **Predictable pipeline** for planning
- **Consistent resource allocation**
- **Lower risk** for forecasting

### 6.3 Recommendations

1. **For Volume:** Continue investing in LinkedIn (Self Sourced) if the goal is maximum SQO production, but:
   - Monitor the declining Contacted→MQL trend closely
   - Investigate root causes of volatility
   - Consider segmenting LinkedIn sources to identify high-performing sub-segments

2. **For Predictability:** Provided Lead List offers more stable, predictable conversion rates, making it better for:
   - Budget planning
   - Resource allocation
   - Consistent pipeline generation

3. **Hybrid Approach:** Consider:
   - Using LinkedIn for volume when capacity allows
   - Using Provided Lead List for consistent baseline pipeline
   - Segmenting LinkedIn sources to identify and focus on high-performing segments

4. **Further Analysis Needed:**
   - Investigate why LinkedIn's Contacted→MQL rate declined so dramatically
   - Analyze cost per SQO for both sources (not just conversion rates)
   - Segment LinkedIn sources (e.g., by campaign type, targeting criteria)
   - Analyze lead quality differences beyond conversion rates

---

## 7. Limitations & Caveats

1. **Small Sample Size:** Only 7 quarters of data limits statistical power
2. **Q1 2024 Outlier:** LinkedIn's Q1 2024 Contacted→MQL rate (66.67%) is based on only 3 contacted leads, making it unreliable
3. **No Cost Analysis:** This analysis doesn't consider cost per lead or cost per SQO
4. **No Quality Metrics:** Beyond conversion rates, we don't have data on SQO quality, close rates, or revenue
5. **Time Period Effects:** External factors (market conditions, campaign changes) may affect results
6. **Statistical Tests:** With n=7, statistical tests have limited power; larger sample sizes would provide more definitive results

---

## 8. Conclusion

**LinkedIn (Self Sourced) shows superior absolute SQO production (182 vs. 163) and significantly higher Contacted→MQL rates (17.66% vs. 2.72%), but with important caveats:**

1. The Contacted→MQL advantage has declined significantly from early 2024 peaks
2. High volatility makes LinkedIn less predictable
3. MQL→SQL and SQL→SQO rates are not statistically different between sources
4. Provided Lead List offers more stable, predictable performance

**The data suggests LinkedIn (Self Sourced) is better for volume, but Provided Lead List is better for predictability and consistency.** The choice depends on organizational priorities: maximum SQO production vs. predictable pipeline.

**Recommendation:** Continue using both sources, but:
- Monitor LinkedIn's declining Contacted→MQL trend
- Investigate root causes of volatility
- Consider cost-per-SQO analysis to make final determination
- Segment LinkedIn sources to optimize performance

---

*Report Generated: Analysis of Q1 2024 - Q3 2025 data from vw_conversion_rates*
*Statistical Tests: Two-sample t-tests (Welch's method for unequal variances)*

