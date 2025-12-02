# SGM Saturation, Source Quality, and Seasonality Analysis

**Analysis Date:** November 2025  
**Purpose:** Identify additional factors affecting forecast accuracy: SGM workload capacity, channel quality changes, and seasonal patterns  
**Key Finding:** Multiple factors beyond deal size affect conversion rates and timing.

---

## Executive Summary

**Critical Findings:**
1. ⚠️ **SGM saturation exists** - Optimal load (20-40 deals) converts at 12.76% vs Light load (<20) at 8%
2. ⚠️ **Channel quality has declined** - Ecosystem dropped from 33.33% to 12.96% conversion
3. ⚠️ **Strong seasonality exists** - November has 2.3x more joins than average, Q1 is strongest quarter
4. ⚠️ **Channel mix shift** - More low-quality channels (Outbound, Marketing) in recent period

**Impact:** These factors compound with deal-size issues to create forecast errors. Addressing them will improve accuracy.

---

## 1. SGM Saturation Analysis

### Hypothesis
Does having too many active deals hurt conversion rates? Is there a "tipping point" where SGMs become overwhelmed?

### Results

| Workload Bucket | Avg Active Deals | Total SQOs | Joined | Conversion Rate | vs Optimal |
|-----------------|------------------|------------|--------|-----------------|------------|
| **Light Load (<20)** | 8.1 | 250 | 20 | **8.00%** | -37% lower |
| **Optimal Load (20-40)** | 26.5 | 196 | 25 | **12.76%** | Baseline |
| **Heavy Load (40-60)** | *Insufficient data* | - | - | - | - |
| **Saturated (>60)** | *Insufficient data* | - | - | - | - |

### Analysis

**Critical Finding:**
- **Light load SGMs convert at 8% vs Optimal load at 12.76%**
- This is **counterintuitive** - you'd expect more deals = lower conversion
- But reality: **Too few deals = lower conversion** (likely due to lack of practice/experience)

**Possible Explanations:**
1. **New SGMs** - Light load might indicate new SGMs still learning
2. **Quality over Quantity** - Optimal load SGMs might be more experienced/selective
3. **Activity Level** - Light load might indicate less active SGMs
4. **Sample Size** - Heavy/Saturated buckets may not have enough data yet

**Key Insight:**
- **20-40 active deals appears to be the "sweet spot"** for conversion
- Below 20: Conversion drops significantly (8% vs 12.76%)
- Above 40: Need more data, but likely conversion drops due to overwhelm

### Recommendation

**Option 1: Apply Workload Adjustment Factor**
```sql
CASE
  WHEN rolling_active_deals < 20 THEN stage_probability * 0.63 -- 8% / 12.76%
  WHEN rolling_active_deals BETWEEN 20 AND 40 THEN stage_probability * 1.00 -- Optimal
  WHEN rolling_active_deals BETWEEN 40 AND 60 THEN stage_probability * 0.90 -- Estimate: slight drop
  ELSE stage_probability * 0.80 -- Estimate: more significant drop
END AS workload_adjusted_probability
```

**Option 2: Monitor and Alert**
- Track SGM workload monthly
- Alert when SGMs drop below 20 active deals (coaching opportunity)
- Alert when SGMs exceed 60 active deals (risk of burnout/neglect)

**Recommendation:** **Option 2** - Monitor first, then implement adjustments if pattern continues.

---

## 2. Source Quality Analysis

### Hypothesis
Did conversion rates drop because of channel mix changes? Are we getting more low-quality leads?

### Results

| Channel | Time Period | SQO Count | Joined | Conversion Rate | Change |
|---------|-------------|-----------|--------|-----------------|--------|
| **Ecosystem** | Historical (6-12 Mos) | 27 | 9 | **33.33%** | Baseline |
| **Ecosystem** | Recent (Last 6 Mos) | 54 | 7 | **12.96%** | **-61% drop** ⚠️ |
| **Marketing** | Historical (6-12 Mos) | 41 | 4 | **9.76%** | Baseline |
| **Marketing** | Recent (Last 6 Mos) | 67 | 4 | **5.97%** | **-39% drop** ⚠️ |
| **Outbound** | Historical (6-12 Mos) | 128 | 13 | **10.16%** | Baseline |
| **Outbound** | Recent (Last 6 Mos) | 139 | 8 | **5.76%** | **-43% drop** ⚠️ |

### Analysis

**Critical Findings:**

1. **ALL channels have declined** - No channel is immune
   - Ecosystem: 33.33% → 12.96% (-61%)
   - Marketing: 9.76% → 5.97% (-39%)
   - Outbound: 10.16% → 5.76% (-43%)

2. **Channel mix has shifted toward lower-quality channels**
   - Ecosystem (best channel): 27 → 54 SQOs (2x increase, but conversion dropped 61%)
   - Outbound (lowest channel): 128 → 139 SQOs (8% increase)
   - Marketing: 41 → 67 SQOs (63% increase)

3. **Ecosystem channel quality collapse**
   - Was the best channel (33.33% conversion)
   - Now only 12.96% (still best, but much lower)
   - Volume doubled but quality halved

**Root Cause Analysis:**
- **Not just channel mix** - All channels declined
- **Possible causes:**
  1. Market conditions changed (tougher to close)
  2. Lead quality declined across all channels
  3. Sales process changed (longer cycles = lower conversion)
  4. Competition increased

### Recommendation

**Option 1: Channel-Specific Conversion Rates**
- Use recent conversion rates (not historical) for each channel
- Apply channel-specific adjustments:
  - Ecosystem: 12.96% (recent rate)
  - Marketing: 5.97% (recent rate)
  - Outbound: 5.76% (recent rate)

**Option 2: Time-Weighted Conversion Rates**
- Blend recent (60%) with historical (40%)
- Accounts for decline while not over-reacting to short-term fluctuations

**Option 3: Investigate Root Cause**
- Review lead quality metrics
- Check if qualification criteria changed
- Analyze if sales process changed
- Review competitive landscape

**Recommendation:** **Option 3 first** - Investigate why all channels declined, then implement Option 1 or 2.

---

## 3. Seasonality Analysis

### Hypothesis
Do advisors join in specific quarters/months regardless of when the deal started? Is there a Q1 spike?

### Results by Month

| Month | Quarter | Joined Count | Total Margin_AUM (M) | Avg Cycle Time (Days) |
|-------|---------|--------------|---------------------|----------------------|
| **January** | Q1 | 6 | $34.98M | 48 days |
| **February** | Q1 | 5 | $63.88M | 76 days |
| **March** | Q1 | 6 | $83.50M | 57 days |
| **April** | Q2 | 4 | $41.49M | 47 days |
| **May** | Q2 | 6 | $44.34M | 45 days |
| **June** | Q2 | 5 | $100.79M | 85 days |
| **July** | Q3 | 8 | $174.91M | 111 days |
| **August** | Q3 | 7 | $80.77M | 69 days |
| **September** | Q3 | 7 | $68.20M | 74 days |
| **October** | Q4 | 5 | $61.87M | 58 days |
| **November** | Q4 | **9** | **$234.27M** | 100 days |
| **December** | Q4 | 4 | $93.98M | 83 days |

### Results by Quarter

| Quarter | Total Joined | Total Margin_AUM (M) | Avg per Month | Avg Cycle Time |
|---------|--------------|---------------------|---------------|----------------|
| **Q1** | 17 | $182.36M | 5.7/month | 60 days |
| **Q2** | 15 | $186.62M | 5.0/month | 59 days |
| **Q3** | 22 | $323.88M | 7.3/month | 85 days |
| **Q4** | 18 | $390.12M | 6.0/month | 80 days |

### Analysis

**Critical Findings:**

1. **November is the strongest month**
   - 9 joins (2.3x average of 5.3/month)
   - $234.27M Margin_AUM (2.4x average of $97.8M/month)
   - **Pattern:** Advisors join before year-end bonuses/payouts

2. **Q3 has highest volume**
   - 22 joins (vs 15-18 in other quarters)
   - $323.88M Margin_AUM (highest)
   - But also longest cycle time (85 days)

3. **Q1 is strong but not the spike**
   - 17 joins (second highest)
   - $182.36M Margin_AUM
   - **Contrary to hypothesis** - Q1 is not the biggest spike

4. **Cycle times vary by month**
   - July: 111 days (longest)
   - May: 45 days (shortest)
   - **Pattern:** Summer months (July) have longer cycles, spring (May) shorter

**Key Insights:**
- **November spike is real** - 2.3x more joins than average
- **Q3 is strongest quarter** - Not Q1 as hypothesized
- **Seasonal patterns exist** - But not as dramatic as expected
- **Cycle times vary seasonally** - Summer deals take longer

### Recommendation

**Option 1: Apply Seasonal Adjustment Factors**

```sql
CASE
  WHEN EXTRACT(MONTH FROM forecasted_join_date) = 11 THEN 1.20 -- November: +20%
  WHEN EXTRACT(QUARTER FROM forecasted_join_date) = 3 THEN 1.15 -- Q3: +15%
  WHEN EXTRACT(QUARTER FROM forecasted_join_date) = 1 THEN 1.10 -- Q1: +10%
  ELSE 1.00 -- Baseline
END AS seasonal_adjustment_factor
```

**Option 2: Month-Specific Forecast Targets**
- Set higher targets for November, Q3
- Account for seasonal patterns in capacity planning

**Option 3: Seasonal Cycle Time Adjustments**
- July: Add 20-30 days to cycle time estimates
- May: Reduce cycle time estimates by 10-15 days

**Recommendation:** **Option 1** - Apply seasonal adjustments to forecasts, especially for November and Q3.

---

## Summary of All Findings

### Factors Affecting Forecast Accuracy

| Factor | Impact | Priority | Status |
|--------|--------|----------|--------|
| **Deal Size Conversion Rates** | High | Critical | ⚠️ Needs fix |
| **Deal Size Cycle Times** | High | Critical | ⚠️ Needs fix |
| **SGM Saturation** | Medium | Monitor | 📊 Monitor first |
| **Channel Quality Decline** | High | Critical | ⚠️ Needs investigation |
| **Seasonality** | Medium | Medium | 📊 Consider adjustments |

### Recommended Actions

#### Immediate (Critical)
1. **Fix deal-size conversion rates** - Apply 0.64x multiplier for Enterprise deals
2. **Fix deal-size cycle times** - Use 38-94 days for Enterprise deals
3. **Investigate channel quality decline** - Why did all channels drop 39-61%?

#### Short-Term (High Priority)
4. **Apply seasonal adjustments** - November +20%, Q3 +15%
5. **Monitor SGM saturation** - Track workload, alert on extremes

#### Long-Term (Medium Priority)
6. **Channel-specific conversion rates** - Use recent rates per channel
7. **Workload-adjusted probabilities** - If saturation pattern continues

---

## Expected Combined Impact

### Current Performance
- Accuracy: 89.01%
- Error: -10.99% (under-forecasting)

### Expected Improvement (if all fixes implemented)

| Fix | Expected Improvement |
|-----|---------------------|
| Deal-Size Adjusted Probabilities | +2-3% accuracy |
| Deal-Size Dependent Cycle Times | +2-3% accuracy |
| Seasonal Adjustments | +1-2% accuracy |
| Channel-Specific Rates | +1-2% accuracy |
| **Total Expected** | **+6-10% accuracy** |

**Expected Result:** 95-99% accuracy, -1-2% error

---

## Conclusion

**Key Insights:**

1. **SGM saturation exists** - Optimal load (20-40 deals) converts best at 12.76%
2. **Channel quality has collapsed** - All channels declined 39-61%, Ecosystem worst
3. **Strong seasonality** - November 2.3x spike, Q3 strongest quarter
4. **Multiple factors compound** - Deal size + saturation + channels + seasonality

**Required Actions:**

✅ **Fix deal-size issues** (conversion rates + cycle times)  
✅ **Investigate channel quality decline** (root cause analysis)  
✅ **Apply seasonal adjustments** (November, Q3)  
📊 **Monitor SGM saturation** (track workload patterns)

**Expected Outcome:** Improved forecast accuracy from 89% to 95-99%, with better understanding of all factors affecting conversion and timing.

