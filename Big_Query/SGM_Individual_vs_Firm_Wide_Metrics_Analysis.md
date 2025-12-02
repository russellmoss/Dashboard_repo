# SGM Individual vs Firm-Wide Metrics Analysis

**Analysis Date:** November 2025  
**Purpose:** Determine optimal thresholds for using individual SGM metrics vs firm-wide averages for capacity forecasting  
**Key Question:** When is individual SGM data reliable enough to use, and when should we use firm-wide fallbacks?

---

## Executive Summary

**Key Finding:** Even SGMs with high joined counts (10+) often have **high volatility** in both Margin_AUM and conversion rates, making individual metrics unreliable. **Firm-wide averages are more reliable** for most SGMs, even those with significant historical data.

### Critical Insights

1. **High Sample Size ≠ Low Volatility**: Bre McDaniel has 26 joined advisors but CV = 0.789 (high volatility)
2. **Conversion Rate Volatility is High**: Most SGMs have CV > 0.6 for conversion rates, indicating high quarter-to-quarter variation
3. **Margin_AUM Volatility Varies**: Some SGMs have lower volatility (GinaRose: CV = 0.373) but still high conversion rate volatility
4. **Recommendation**: Use firm-wide metrics for most SGMs, only use individual when BOTH sample size is high AND volatility is low

---

## Detailed SGM Analysis

### Top Performers (High Joined Count)

#### Bre McDaniel (26 Joined, 115 SQOs)
| Metric | Value | Assessment |
|--------|-------|------------|
| **Individual Avg Margin_AUM** | $20.19M | 61.6% higher than firm average ($12.49M) |
| **Margin_AUM CV** | 0.789 | ⚠️ **High volatility** (stddev = $21.8M) |
| **Individual Conversion Rate** | 15.65% | 73.7% higher than firm average (9.01%) |
| **Conversion Rate CV** | 0.684 | ⚠️ **High volatility** |
| **Reliability Score** | 30/100 | Low |
| **Recommendation** | **Use Firm-Wide** | Despite high sample size, volatility is too high |

**Quarterly Breakdown (Shows Volatility):**
- Q4 2024: $67.2M avg (2 deals) - **Extremely high**
- Q1 2025: $11.61M avg (5 deals) - **Very low** (83% drop!)
- Q2 2025: $26.38M avg (3 deals, range $7.82M - $58.92M) - **Huge range**
- Q3 2025: $21.92M avg (6 deals, range $6.6M - $45.63M) - **Wide range**
- Q4 2025: $40.57M avg (3 deals) - **High again**

**Quarterly Conversion Rate Breakdown:**
- Q4 2024: 25% (4 joined / 16 SQOs)
- Q1 2025: 21.2% (7 joined / 33 SQOs)
- Q2 2025: 9.7% (3 joined / 31 SQOs) - **Drop**
- Q3 2025: 16.7% (4 joined / 24 SQOs)
- Q4 2025: 0% (0 joined / 11 SQOs) - **Zero!**
- Average: 14.5%, Stddev: 9.9% - **High volatility**

**Analysis:**
- Has the highest joined count (26) but also the highest volatility
- **Margin_AUM quarter-to-quarter variation is extreme**: $67.2M → $11.61M → $26.38M → $21.92M → $40.57M
- **Conversion rate also volatile**: 25% → 21.2% → 9.7% → 16.7% → 0%
- Individual average ($20.19M) doesn't represent any single quarter accurately
- Margin_AUM ranges from $4.68M to $78M within quarters
- **Use firm-wide averages** for more stable forecasts

#### GinaRose Galli (13 Joined, 62 SQOs)
| Metric | Value | Assessment |
|--------|-------|------------|
| **Individual Avg Margin_AUM** | $14.49M | 16% higher than firm average |
| **Margin_AUM CV** | 0.373 | ✅ **Moderate volatility** (stddev = $5.03M) |
| **Individual Conversion Rate** | 16.13% | 79% higher than firm average |
| **Conversion Rate CV** | 0.961 | ⚠️ **Very high volatility** |
| **Reliability Score** | 30/100 | Low |
| **Recommendation** | **Hybrid Approach** | Use individual Margin_AUM + firm-wide conversion rate |

**Quarterly Breakdown (Shows More Consistency):**
- Q1 2025: $12.32M avg (4 deals, range $4M - $17.25M)
- Q2 2025: $8.85M avg (1 deal) - **Small sample**
- Q3 2025: $16.32M avg (2 deals, range $16.08M - $16.57M) - **Very consistent**
- Q4 2025: $15.39M avg (2 deals, range $10.79M - $19.99M)

**Quarterly Conversion Rate Breakdown (Shows High Volatility):**
- Q4 2024: 16.7% (1 joined / 6 SQOs)
- Q1 2025: 12% (3 joined / 25 SQOs)
- Q2 2025: 4.8% (1 joined / 21 SQOs) - **Very low**
- Q3 2025: 50% (5 joined / 10 SQOs) - **Extremely high!**
- Average: 20.9%, Stddev: 20% - **Huge quarter-to-quarter swings**

**Analysis:**
- Lower Margin_AUM volatility (CV = 0.373) - **More stable than Bre**
- Quarterly averages range from $8.85M to $16.32M (more consistent)
- **But conversion rate volatility is extreme**: 4.8% → 50% → 12% (10x variation!)
- Conversion rate CV = 0.961 means 96.1% coefficient of variation
- **Hybrid approach recommended**: Individual Margin_AUM ($14.49M) + Firm-wide conversion rate (9.01%)

#### Corey Marcello (12 Joined, 127 SQOs)
| Metric | Value | Assessment |
|--------|-------|------------|
| **Individual Avg Margin_AUM** | $11.53M | 7.7% lower than firm average |
| **Margin_AUM CV** | 0.67 | ⚠️ **Moderate-high volatility** |
| **Individual Conversion Rate** | 8.66% | 3.9% lower than firm average |
| **Conversion Rate CV** | 0.68 | ⚠️ **High volatility** |
| **Reliability Score** | 70/100 | Medium |
| **Recommendation** | **Consider Individual** | Close to firm average, moderate volatility |

**Analysis:**
- Metrics are close to firm-wide averages (within 10%)
- Volatility is moderate but still present
- **Could use individual**, but firm-wide might be safer

---

## Volatility Analysis

### Margin_AUM Volatility (Coefficient of Variation)

| SGM | Joined Count | CV | Interpretation |
|-----|--------------|----| ----------------|
| Bre McDaniel | 26 | 0.789 | ⚠️ Very High (78.9% variation) |
| Corey Marcello | 12 | 0.67 | ⚠️ High (67% variation) |
| GinaRose Galli | 13 | 0.373 | ✅ Moderate (37.3% variation) |
| Bryan Belville | 3 | 0.345 | ✅ Low (but small sample) |
| Erin Pearson | 2 | 0.073 | ✅ Very Low (but tiny sample) |

**Key Insight:** Even with 26 joined advisors, Bre McDaniel has 78.9% coefficient of variation, meaning Margin_AUM values vary widely. This makes individual averages unreliable.

### Conversion Rate Volatility

| SGM | Quarters | CV | Interpretation |
|-----|----------|----| ----------------|
| Bre McDaniel | 5 | 0.684 | ⚠️ High (68.4% variation) |
| Corey Marcello | 5 | 0.68 | ⚠️ High (68% variation) |
| GinaRose Galli | 4 | 0.961 | ⚠️ Very High (96.1% variation) |
| Bryan Belville | 4 | 1.264 | ⚠️ Extremely High (126.4% variation) |
| Erin Pearson | 3 | 0.925 | ⚠️ Very High (92.5% variation) |

**Key Insight:** Conversion rates show high quarter-to-quarter volatility across all SGMs. This suggests conversion rates are inherently variable and firm-wide averages may be more stable.

---

## Recommended Thresholds

### For Using Individual Metrics

**Use Individual Metrics When ALL of the following are true:**

1. **Sample Size:**
   - ✅ `historical_joined_count_12m >= 10` (minimum 10 joined advisors)
   - ✅ `historical_sqo_count_12m >= 30` (minimum 30 SQOs for conversion rate)

2. **Volatility Thresholds:**
   - ✅ Margin_AUM CV < 0.5 (coefficient of variation < 50%)
   - ✅ Conversion Rate CV < 0.5 (quarterly variation < 50%)

3. **Significant Difference from Firm Average:**
   - ✅ Margin_AUM differs by > 15% from firm average
   - ✅ Conversion Rate differs by > 10 percentage points from firm average

4. **Consistency:**
   - ✅ At least 3 quarters of data
   - ✅ No extreme outliers (values > 3 standard deviations from mean)

### Current Status: **NO SGMs Meet All Criteria**

**Analysis:**
- Even Bre McDaniel (26 joined) fails due to high volatility (CV = 0.789)
- GinaRose Galli (13 joined) has low Margin_AUM volatility but high conversion rate volatility
- **Recommendation: Use firm-wide metrics for all SGMs** until volatility decreases

---

## Hybrid Approach Recommendation

Since some SGMs have **low Margin_AUM volatility but high conversion rate volatility**, consider a **hybrid approach**:

### Option 1: Individual Margin_AUM + Firm-Wide Conversion Rate

**Use when:**
- `historical_joined_count_12m >= 10`
- Margin_AUM CV < 0.5
- Conversion Rate CV >= 0.5 (high volatility)

**Example:** GinaRose Galli
- Use individual Margin_AUM ($14.49M) - low volatility
- Use firm-wide conversion rate (9.01%) - more stable

### Option 2: Firm-Wide Margin_AUM + Individual Conversion Rate

**Use when:**
- `historical_joined_count_12m >= 10`
- Margin_AUM CV >= 0.5 (high volatility)
- Conversion Rate CV < 0.5 (low volatility)

**Current Status:** No SGMs meet this criteria (all have high conversion rate volatility)

### Option 3: Weighted Average

**Use when:**
- `historical_joined_count_12m >= 5`
- Moderate volatility (CV between 0.5 and 0.7)

**Formula:**
```
Weighted Metric = (Individual × Reliability_Weight) + (Firm-Wide × (1 - Reliability_Weight))
```

Where `Reliability_Weight` is based on:
- Sample size (more joined = higher weight)
- Volatility (lower CV = higher weight)
- Consistency (more quarters = higher weight)

---

## Statistical Analysis

### Margin_AUM Distribution

**Firm-Wide Average:** $12.49M ± $X.XXM

**Individual SGM Averages:**
- Bre McDaniel: $20.19M (61.6% above firm average) - **Significantly different**
- GinaRose Galli: $14.49M (16% above firm average) - **Moderately different**
- Corey Marcello: $11.53M (7.7% below firm average) - **Close to firm average**
- Others: Within 20% of firm average

**Key Finding:** Bre McDaniel's average is significantly higher, but the high volatility (CV = 0.789) means individual values range widely, making the average less reliable.

### Conversion Rate Distribution

**Firm-Wide Average:** 9.01%

**Individual SGM Averages:**
- Bre McDaniel: 15.65% (73.7% above firm average) - **Significantly different**
- GinaRose Galli: 16.13% (79% above firm average) - **Significantly different**
- Corey Marcello: 8.66% (3.9% below firm average) - **Close to firm average**

**Key Finding:** High-performing SGMs have higher conversion rates, but the high volatility suggests this may not be sustainable or predictable.

---

## Recommendations

### Immediate Action

1. **Use Firm-Wide Metrics for All SGMs** (except On Ramp)
   - Current individual metrics are too volatile
   - Firm-wide averages provide more stable forecasts
   - This aligns with current "On Ramp" logic (90 days)

2. **Consider Hybrid Approach for Margin_AUM**
   - For SGMs with `historical_joined_count_12m >= 10` AND `margin_aum_cv < 0.5`
   - Use individual Margin_AUM but firm-wide conversion rate
   - **Example:** GinaRose Galli could use individual Margin_AUM ($14.49M)

3. **Monitor Volatility Over Time**
   - Track CV metrics quarterly
   - When volatility decreases, reconsider individual metrics
   - Set up alerts when SGMs meet reliability thresholds

### Long-Term Strategy

1. **Increase Sample Size Requirements**
   - Current: 90 days for "On Ramp"
   - Consider: Require minimum 10 joined advisors AND 4 quarters of data
   - This ensures both sample size and time-based consistency

2. **Implement Reliability Scoring**
   - Calculate reliability score (0-100) based on:
     - Sample size (joined count)
     - Volatility (CV)
     - Consistency (quarters of data)
   - Use individual metrics only when score >= 70

3. **Weighted Blending**
   - For SGMs with reliability score 50-70, use weighted average:
     - `Weighted = (Individual × Score/100) + (Firm-Wide × (1 - Score/100))`
   - Provides gradual transition from firm-wide to individual

---

## Implementation Guide

### Updated Logic for `vw_sgm_capacity_model_refined`

**Current Logic:**
```sql
-- Uses firm-wide for On Ramp OR no joined history
CASE
  WHEN is_on_ramp = 1 OR has_no_joined_history = 1
  THEN firm_wide_metric
  ELSE individual_metric
END
```

**Recommended Logic:**
```sql
-- Uses firm-wide for On Ramp, no joined history, OR high volatility
CASE
  WHEN is_on_ramp = 1 THEN firm_wide_metric
  WHEN has_no_joined_history = 1 THEN firm_wide_metric
  WHEN historical_joined_count_12m < 10 THEN firm_wide_metric
  WHEN margin_aum_cv >= 0.5 THEN firm_wide_metric
  WHEN conversion_rate_cv >= 0.5 THEN firm_wide_metric
  ELSE individual_metric
END
```

**Or use reliability score:**
```sql
CASE
  WHEN reliability_score >= 70 THEN individual_metric
  WHEN reliability_score >= 50 THEN weighted_blend
  ELSE firm_wide_metric
END
```

---

## Conclusion

**Current State:**
- Even high-performing SGMs (26 joined) have high volatility
- Individual metrics are unreliable for capacity forecasting
- Firm-wide averages provide more stable and accurate forecasts

**Recommendation:**
- **Use firm-wide metrics for all non-On Ramp SGMs** until volatility decreases
- Consider hybrid approach (individual Margin_AUM + firm-wide conversion rate) for SGMs with low Margin_AUM volatility
- Implement reliability scoring system for future transition to individual metrics

**Next Steps:**
1. Update `vw_sgm_capacity_model_refined` to use firm-wide metrics for all SGMs (except On Ramp)
2. Monitor volatility quarterly
3. Re-evaluate when SGMs meet reliability thresholds

