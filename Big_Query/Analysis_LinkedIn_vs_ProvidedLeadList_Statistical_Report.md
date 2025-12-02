# Statistical Analysis: LinkedIn (Self Sourced) vs. Provided Lead List
## Comprehensive Analysis Using Raw Data (Q1 2024 - Q3 2025)

---

## Executive Summary

**Which lead source is better, and is the difference statistically significant?**

**Answer: LinkedIn (Self Sourced) is statistically significantly better for end-to-end conversion efficiency, but with important caveats regarding trends and predictability.**

### Primary Finding: Contacted → SQO Conversion Rate

**LinkedIn's Contacted→SQO rate of 1.28% was found to be statistically significantly higher than the Provided Lead List's rate of 0.47% (z = 9.06, p < 0.001).**

The difference of 0.81 percentage points represents a **2.7x higher conversion rate** for LinkedIn. This finding remains statistically significant even after excluding the Q1 2024 outlier (z = 8.91, p < 0.001).

### Key Findings:

1. **Absolute Volume:** LinkedIn produced 154 SQOs vs. Provided Lead List's 144 SQOs (7% more), despite LinkedIn having 61% fewer contacted leads (12,067 vs. 30,799).

2. **End-to-End Efficiency:** LinkedIn converts contacted leads to SQOs at a **2.7x higher rate** (1.28% vs. 0.47%), and this difference is **highly statistically significant** (p < 0.001).

3. **Staged Conversion Rates:**
   - **Contacted → MQL:** LinkedIn significantly higher (6.85% vs. 2.59%, z = 20.73, p < 0.001)
   - **MQL → SQL:** Not statistically different (33.16% vs. 34.93%, z = -0.79, p > 0.05)
   - **SQL → SQO:** Not statistically different (60.26% vs. 54.70%, z = 1.38, p > 0.05)

4. **Trend Analysis:** LinkedIn shows a **significant declining trend** (slope = -0.039% per quarter, R² = 0.51), while Provided Lead List shows a slight positive trend (slope = +0.0006% per quarter, R² = 0.30).

---

## Methodology

### Why This Analysis is More Robust

This analysis uses **two-proportion z-tests on the entire population of contacted leads** (N = 42,866), rather than t-tests on 7 quarterly averages. This approach provides:

1. **Greater Statistical Power:** Testing on the full population (n = 42,866) vs. 7 data points dramatically increases our ability to detect true differences.

2. **More Appropriate Test:** Two-proportion z-tests are the correct statistical method for comparing conversion rates (proportions), whereas t-tests are designed for comparing means of continuous variables.

3. **Direct Measurement:** We measure the end-to-end Contacted → SQO rate directly from raw data, which represents the true sales efficiency metric.

### Two-View Approach

We used two views to respect both business logic requirements:

1. **`vw_funnel_lead_to_joined_v2`:** Used for end-to-end Contacted → SQO analysis, providing raw, un-aggregated data at the `primary_key` level with correct definitions of `is_contacted = 1` and `is_sqo = 1`.

2. **`vw_conversion_rates`:** Used for staged conversion rate analysis, providing pre-calculated numerators and denominators that respect our progression-based calculation logic.

---

## Analysis 1: End-to-End Efficiency (Contacted → SQO)

### Raw Numbers

| Source | Total Contacted | Total SQOs | Conversion Rate |
|--------|----------------|------------|-----------------|
| **LinkedIn (Self Sourced)** | 12,067 | 154 | **1.28%** |
| **Provided Lead List** | 30,799 | 144 | **0.47%** |
| **Total** | 42,866 | 298 | 0.70% |

### Statistical Test Results

**Two-Proportion Z-Test:**

- **Null Hypothesis (H₀):** The Contacted→SQO conversion rate for LinkedIn equals the rate for Provided Lead List
- **Alternative Hypothesis (H₁):** The rates are not equal

**Results:**
- **Rate Difference:** +0.81 percentage points (LinkedIn higher)
- **Z-Score:** 9.06
- **P-Value:** < 0.001 (highly statistically significant)
- **95% Confidence Interval for Difference:** +0.63% to +0.98%

**Conclusion:** We reject the null hypothesis with extremely high confidence (p < 0.001). LinkedIn (Self Sourced) converts contacted leads to SQOs at a statistically significantly higher rate than Provided Lead List. The difference of 0.81 percentage points is both statistically significant and practically meaningful (2.7x higher rate).

### Interpretation

LinkedIn's 1.28% conversion rate means that for every 100 contacted leads, LinkedIn produces 1.28 SQOs, compared to Provided Lead List's 0.47 SQOs per 100 contacted leads. This represents a **172% improvement** in conversion efficiency.

Despite having 61% fewer contacted leads (12,067 vs. 30,799), LinkedIn still produced 7% more SQOs (154 vs. 144), demonstrating superior efficiency.

---

## Analysis 2: Staged Funnel Conversion (Re-Analysis)

### Summary of Z-Test Results

| Conversion Stage | LinkedIn Rate | Provided Lead List Rate | Difference | Z-Score | P-Value | Significant? |
|-----------------|---------------|------------------------|------------|---------|---------|--------------|
| **Contacted → MQL** | 6.85% | 2.59% | +4.25% | 20.73 | < 0.001 | ✅ **Yes** |
| **MQL → SQL** | 33.16% | 34.93% | -1.77% | -0.79 | > 0.05 | ❌ No |
| **SQL → SQO** | 60.26% | 54.70% | +5.57% | 1.38 | > 0.05 | ❌ No |

### Detailed Results

#### Contacted → MQL

- **LinkedIn:** 826 MQLs from 12,067 contacted (6.85%)
- **Provided Lead List:** 799 MQLs from 30,799 contacted (2.59%)
- **Difference:** +4.25 percentage points
- **Z-Score:** 20.73
- **P-Value:** < 0.001
- **95% CI:** +3.85% to +4.65%

**Conclusion:** LinkedIn shows a highly statistically significant advantage in the Contacted → MQL stage, converting at 2.6x the rate of Provided Lead List.

#### MQL → SQL

- **LinkedIn:** 317 SQLs from 956 MQLs (33.16%)
- **Provided Lead List:** 299 SQLs from 856 MQLs (34.93%)
- **Difference:** -1.77 percentage points (LinkedIn lower)
- **Z-Score:** -0.79
- **P-Value:** > 0.05
- **95% CI:** -6.14% to +2.60%

**Conclusion:** No statistically significant difference. Provided Lead List actually shows a slightly higher (but not significant) conversion rate at this stage.

#### SQL → SQO

- **LinkedIn:** 182 SQOs from 302 SQLs (60.26%)
- **Provided Lead List:** 163 SQOs from 298 SQLs (54.70%)
- **Difference:** +5.57 percentage points
- **Z-Score:** 1.38
- **P-Value:** > 0.05
- **95% CI:** -2.34% to +13.48%

**Conclusion:** No statistically significant difference, though LinkedIn shows a higher rate with a wide confidence interval.

### Comparison to Preliminary Analysis

The preliminary analysis using t-tests on 7 quarterly averages found no statistically significant differences. This re-analysis using two-proportion z-tests on the full population confirms:

1. **Contacted → MQL:** The preliminary analysis was correct in identifying a large difference, but lacked statistical power. The z-test confirms this is highly significant.

2. **MQL → SQL & SQL → SQO:** The preliminary analysis was correct - these stages show no statistically significant differences.

3. **End-to-End Rate:** The preliminary analysis did not test this metric. Our analysis reveals a highly significant difference that was not previously identified.

---

## Analysis 3: Trend & Volatility

### Contacted → SQO Rate Trends (Quarterly)

| Quarter | LinkedIn Rate | Provided Lead List Rate |
|---------|---------------|------------------------|
| 2024-Q1 | 33.33% | 0.00% |
| 2024-Q2 | 6.45% | 0.54% |
| 2024-Q3 | 2.89% | 0.37% |
| 2024-Q4 | 1.48% | 0.38% |
| 2025-Q1 | 1.24% | 0.58% |
| 2025-Q2 | 0.86% | 0.76% |
| 2025-Q3 | 1.05% | 0.35% |

**Note:** Q1 2024 shows extreme values due to very small sample sizes (LinkedIn: n=3 contacted, Provided Lead List: n=228 contacted with 0 SQOs).

### Linear Regression Analysis

**LinkedIn (Self Sourced):**
- **Slope:** -0.03917 per quarter (declining trend)
- **Intercept:** 0.2243 (22.43% at time 0)
- **R²:** 0.5072 (moderate fit)
- **Interpretation:** LinkedIn's Contacted → SQO rate is declining by approximately 0.04 percentage points per quarter. The model explains 51% of the variance.

**Provided Lead List:**
- **Slope:** +0.000608 per quarter (slight positive trend)
- **Intercept:** 0.001835 (0.18% at time 0)
- **R²:** 0.3017 (weak fit)
- **Interpretation:** Provided Lead List shows a very slight positive trend, but the model explains only 30% of the variance, suggesting high volatility.

### Trend Significance

**LinkedIn's Declining Trend:**
- The negative slope (-0.039% per quarter) suggests that LinkedIn's efficiency advantage may be eroding over time.
- If this trend continues, LinkedIn's rate could converge with Provided Lead List's rate within 2-3 years.
- The moderate R² (0.51) indicates the trend is meaningful but other factors also influence the rate.

**Provided Lead List's Stability:**
- The near-zero slope (+0.0006% per quarter) suggests relative stability, though the low R² (0.30) indicates high volatility.
- Provided Lead List's rates have remained consistently low (0.35% - 0.76%) across most quarters.

### Volatility Analysis

**LinkedIn:**
- **Range:** 0.86% - 33.33% (excluding Q1 2024 outlier: 0.86% - 6.45%)
- **Coefficient of Variation:** High (especially with Q1 2024 included)
- **Pattern:** High early rates followed by declining trend with some volatility

**Provided Lead List:**
- **Range:** 0.00% - 0.76% (excluding Q1 2024: 0.35% - 0.76%)
- **Coefficient of Variation:** Moderate
- **Pattern:** Consistently low rates with moderate volatility

---

## Analysis 4: Sensitivity Analysis (Q1 2024 Outlier)

### Results Excluding Q1 2024

| Source | Total Contacted | Total SQOs | Conversion Rate |
|--------|----------------|------------|-----------------|
| **LinkedIn (Self Sourced)** | 12,064 | 153 | **1.27%** |
| **Provided Lead List** | 30,571 | 144 | **0.47%** |

### Statistical Test Results (Excluding Q1 2024)

- **Rate Difference:** +0.80 percentage points (LinkedIn higher)
- **Z-Score:** 8.91
- **P-Value:** < 0.001 (still highly statistically significant)
- **95% Confidence Interval:** +0.62% to +0.97%

### Conclusion

**Removing Q1 2024 does not change the overall conclusion.** LinkedIn's Contacted → SQO rate remains statistically significantly higher than Provided Lead List's rate (p < 0.001). The rate difference is virtually unchanged (0.80% vs. 0.81%), and the z-score remains extremely high (8.91 vs. 9.06).

This confirms that the statistical significance is not driven by the Q1 2024 outlier, but rather by a consistent pattern across all quarters.

---

## Key Limitations

1. **No Cost Analysis:** This analysis does not include Cost Per Lead (CPL) or Cost Per SQO (CPSQO). LinkedIn may have higher acquisition costs that could offset its conversion rate advantage.

2. **No Quality Metrics:** Beyond conversion rates, we don't have data on:
   - SQO quality or close rates
   - Revenue per SQO
   - Customer lifetime value
   - Sales cycle length

3. **Time Period Effects:** External factors (market conditions, campaign changes, targeting adjustments) may affect results and are not controlled for in this analysis.

4. **Sample Size Discrepancy:** LinkedIn has 61% fewer contacted leads than Provided Lead List, which could affect the precision of estimates, though our large sample sizes (n > 12,000) provide sufficient power.

5. **Q1 2024 Outlier:** The Q1 2024 data shows extreme values due to very small sample sizes, but our sensitivity analysis confirms this doesn't affect the main conclusion.

6. **Trend Extrapolation:** The declining trend for LinkedIn is based on 7 data points. Extrapolating future performance should be done cautiously.

---

## Conclusion & Recommendations

### For Volume: Which Source Produces More Absolute SQOs?

**Answer: LinkedIn (Self Sourced)** produced 154 SQOs vs. Provided Lead List's 144 SQOs (7% more), despite having 61% fewer contacted leads. However, the difference is relatively small (10 SQOs), and Provided Lead List's larger contacted lead volume (30,799 vs. 12,067) suggests it has greater potential for scaling.

### For Efficiency: Which Source Converts at a Statistically Higher Rate?

**Answer: LinkedIn (Self Sourced)** converts contacted leads to SQOs at a **statistically significantly higher rate** (1.28% vs. 0.47%, p < 0.001). This 2.7x advantage is both statistically significant and practically meaningful.

### For Predictability: Which Source is More Stable?

**Answer: Provided Lead List** shows more stable rates (0.35% - 0.76% range, excluding Q1 2024), while LinkedIn shows higher volatility and a declining trend. However, even at its lowest recent rates, LinkedIn still outperforms Provided Lead List.

### Final Recommendation

**Based on all factors, the business should:**

1. **Continue investing in LinkedIn (Self Sourced)** as the primary lead source for efficiency, but:
   - **Monitor the declining trend closely** - investigate root causes
   - **Conduct cost analysis** - if LinkedIn's CPL is significantly higher, the efficiency advantage may not translate to better ROI
   - **Segment LinkedIn sources** - identify high-performing sub-segments to optimize

2. **Maintain Provided Lead List** as a secondary source for:
   - **Volume scaling** when capacity allows
   - **Pipeline stability** and predictability
   - **Diversification** to reduce risk

3. **Immediate Actions:**
   - **Investigate LinkedIn's declining trend** - what changed from early 2024 to recent quarters?
   - **Calculate Cost Per SQO** for both sources to make final ROI determination
   - **Analyze lead quality** beyond conversion rates (close rates, revenue, LTV)
   - **Test optimization strategies** for LinkedIn to reverse the declining trend

4. **Strategic Approach:**
   - Use LinkedIn for **maximum efficiency** when resources are constrained
   - Use Provided Lead List for **volume and stability** when scaling
   - Implement a **hybrid approach** that leverages both sources' strengths

### Nuanced Answer

**LinkedIn (Self Sourced) is statistically significantly better for conversion efficiency (2.7x higher Contacted → SQO rate, p < 0.001), but the declining trend and lack of cost data create uncertainty about long-term superiority.** Provided Lead List offers more stability and potentially better scalability, but at lower efficiency.

**The optimal strategy depends on organizational priorities:**
- **If efficiency and resource optimization are priorities:** LinkedIn is clearly superior
- **If volume, scalability, and predictability are priorities:** Provided Lead List may be preferable
- **If balanced growth is the goal:** A hybrid approach leveraging both sources is recommended

**The critical next step is cost analysis** - without knowing the Cost Per SQO for each source, we cannot make a definitive recommendation on ROI.

---

*Report Generated: Comprehensive Statistical Analysis of Q1 2024 - Q3 2025 data*
*Statistical Tests: Two-proportion z-tests on full population (N = 42,866 contacted leads)*
*Analysis Date: Based on vw_funnel_lead_to_joined_v2 and vw_conversion_rates views*














