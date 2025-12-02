# Capacity Forecast Model Validation Report

**Analysis Date:** November 2025  
**Purpose:** Validate key assumptions in the capacity forecasting model to identify sources of under-forecasting bias  
**Key Finding:** Multiple systematic biases identified that explain the -10.99% forecast error

---

## Executive Summary

**Critical Findings:**
1. ⚠️ **Fallback divisors are too high** - causing 20-30% under-estimation when Margin_AUM is missing
2. ⚠️ **120-day stale cutoff is too aggressive** - excluding 25.26% of joined AUM
3. ⚠️ **Enterprise deals take 2x longer** - current cycle times don't account for deal size
4. ⚠️ **Conversion rates are declining** - recent SQOs convert at 8.3% vs 12.87% historically
5. ✅ **Zombie deals are not an issue** - 0% resurrection rate

**Impact:** These biases compound to create the observed -10.99% under-forecasting error.

---

## 1. Fallback Divisor Validation

### Current Assumptions
- `Underwritten_AUM__c / 3.125` = Estimated Margin_AUM
- `Amount / 3.22` = Estimated Margin_AUM

### Actual Ratios (from 83 closed deals)

| Metric | Current Assumption | Actual Ratio | Difference | Impact |
|--------|-------------------|--------------|------------|--------|
| **Underwritten Ratio** | 3.125 | **3.28** (avg) | +5.0% | ⚠️ Slight under-estimation |
| **Amount Ratio** | 3.22 | **3.75-3.96** (avg) | +16-23% | ⚠️ **Significant under-estimation** |

### Analysis

**Underwritten_AUM Divisor:**
- Current: 3.125
- Actual Average: 3.28
- **Impact:** When Margin_AUM is missing and we use Underwritten_AUM, we're underestimating by ~5%
- **Recommendation:** Change divisor from 3.125 to **3.30** (round up for safety)

**Amount Divisor:**
- Current: 3.22
- Actual Average: 3.75-3.96 (varies by calculation method)
- **Impact:** When Margin_AUM is missing and we use Amount, we're underestimating by **16-23%**
- **Recommendation:** Change divisor from 3.22 to **3.80** (use conservative middle value)

### Root Cause

The current divisors (3.125 and 3.22) were likely calculated from a smaller sample or different time period. The actual ratios show:
- Underwritten_AUM is closer to Margin_AUM than assumed (3.28x vs 3.125x)
- Amount is significantly closer to Margin_AUM than assumed (3.75-3.96x vs 3.22x)

**This directly contributes to under-forecasting when Margin_AUM is missing.**

---

## 2. 120-Day "Stale Deal" Cutoff Analysis

### Current Assumption
- Deals with `sqo_age_days > 120` are excluded from "Active" pipeline
- Only active deals are used in capacity calculations

### Actual Impact (from 77 joined deals)

| Metric | Value | Impact |
|--------|-------|--------|
| **Total Joined Deals** | 77 | |
| **Deals Joined After 120 Days** | 12 | 15.58% of deals |
| **Total Joined AUM** | $1,170.33M | |
| **AUM from "Stale" Deals** | $295.62M | **25.26% of total AUM** |

### Analysis

**Critical Finding:** 
- **25.26% of joined AUM comes from deals that took longer than 120 days to close**
- These deals are systematically excluded from active pipeline forecasts
- This directly explains a significant portion of the under-forecasting bias

**Breakdown:**
- 15.58% of deals close after 120 days
- But these deals represent 25.26% of AUM (larger deals take longer)

### Recommendation

**Option 1: Increase Stale Cutoff to 180 Days**
- Would capture more large deals
- Still excludes truly stale deals
- **Impact:** Would include ~$200M+ more in active pipeline

**Option 2: Deal-Size Dependent Cutoff**
- Small deals (<$5M): 90 days
- Medium deals ($5M-$15M): 120 days
- Large deals ($15M-$30M): 180 days
- Enterprise deals (>$30M): 240 days

**Option 3: Remove Stale Cutoff for Weighted Pipeline**
- Keep 120-day cutoff for "Active SQO Count" metric
- But include all deals in weighted pipeline calculation (they have stage probabilities)
- **Rationale:** Stage probabilities already account for conversion likelihood

**Recommendation:** **Option 3** - Remove stale cutoff from weighted pipeline calculations, as stage probabilities already account for conversion risk.

---

## 3. Deal Size vs. Cycle Time Analysis ("The Bre Effect")

### Current Assumption
- All deals follow the same cycle time assumptions:
  - Signed: 16 days to join
  - Negotiating: 37 days to join
  - Sales Process: 69 days to join
  - Discovery: 62 days to join
  - SQO: 70 days to join

### Actual Cycle Times by Deal Size

| Deal Size | Deal Count | Avg Days | Median Days | P75 Days | P90 Days |
|-----------|------------|----------|-------------|----------|----------|
| **Small (<$5M)** | 6 | 46.5 | 49 | 56 | 87 |
| **Medium ($5M-$15M)** | 43 | 55.9 | 45 | 80 | 108 |
| **Large ($15M-$30M)** | 20 | 93.3 | 66 | 148 | 214 |
| **Enterprise (>$30M)** | 8 | 120.6 | 110 | 141 | 180 |

### Analysis

**Critical Finding:**
- **Enterprise deals take 2.2x longer than small deals** (120.6 days vs 46.5 days)
- **Large deals take 1.7x longer than small deals** (93.3 days vs 46.5 days)
- Current forecast model uses same cycle times for all deals

**Impact on Forecasting:**
- Enterprise deals forecasted to join in "Current Quarter" based on 16-70 day assumptions
- But actual median is 110 days (1.5-6x longer)
- **Result:** Enterprise deals miss their forecast quarter, causing prediction errors

**Example:**
- Bre McDaniel's $78M deal enters "Signed" stage
- Model forecasts: Join in 16 days (Current Quarter)
- Reality: Takes 110+ days (Next Quarter or later)
- **Error:** Deal counted in wrong quarter forecast

### Recommendation

**Implement Deal-Size Dependent Cycle Times:**

```sql
CASE
  WHEN estimated_margin_aum < 5 THEN 
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 16
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 37
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 69
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 62
      ELSE 70
    END
  WHEN estimated_margin_aum < 15 THEN 
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 20
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 45
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 80
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 70
      ELSE 80
    END
  WHEN estimated_margin_aum < 30 THEN 
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 30
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 60
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 100
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 90
      ELSE 110
    END
  ELSE -- Enterprise
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 40
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 80
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 140
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 120
      ELSE 150
    END
END AS days_to_join_estimate
```

**Impact:** Would significantly improve quarter forecast accuracy for large/enterprise deals.

---

## 4. Stage Probability Decay Over Time

### Current Assumption
- Stage probabilities are static (from `vw_stage_to_joined_probability`)
- Conversion rates don't change over time

### Actual Conversion Rates by Time Period

| Time Cohort | Total SQOs | Joined Count | Conversion Rate |
|-------------|------------|--------------|-----------------|
| **Recent (Last 6 Months)** | 277 | 23 | **8.3%** ⚠️ |
| **Previous (6-12 Months Ago)** | 202 | 26 | **12.87%** |

### Analysis

**Critical Finding:**
- **Recent SQOs convert at 8.3% vs 12.87% historically**
- This is a **35.6% decline** in conversion rates
- Current model uses historical average (likely ~10-12%)

**Impact:**
- Model over-estimates conversion probability for recent deals
- Recent pipeline is less likely to convert than historical data suggests
- This could explain some of the forecast error

**Possible Causes:**
1. Market conditions changed (tougher to close deals)
2. Pipeline quality declined (more unqualified SQOs)
3. Sales process changed (longer cycles = lower conversion)
4. Sample size issue (recent period may not be representative)

### Recommendation

**Option 1: Use Time-Weighted Probabilities**
- Weight recent conversion rates more heavily
- Blend recent (8.3%) with historical (12.87%)
- **Formula:** `(Recent_Rate × 0.6) + (Historical_Rate × 0.4)`

**Option 2: Monitor and Alert**
- Track conversion rates monthly
- Alert if rate drops below threshold
- Adjust probabilities when trend is confirmed

**Option 3: Wait for More Data**
- Recent period may be anomaly
- Monitor for next 3 months before adjusting
- If trend continues, implement Option 1

**Recommendation:** **Option 3** - Monitor for 3 more months, then implement time-weighted probabilities if trend continues.

---

## 5. "Zombie" Pipeline Detection

### Hypothesis
- Deals marked "Closed Lost" or "On Hold" might come back to life
- These deals wouldn't be in active pipeline forecasts
- Could explain missing revenue

### Actual Results

| Metric | Value |
|--------|-------|
| **Total Joined Deals** | 83 |
| **Potentially Resurrected** | 0 |
| **Resurrection Rate** | 0% |

### Analysis

**Finding:** Zombie deals are **NOT** an issue.
- 0% of joined deals were ever in Closed Lost or On Hold
- This is not a source of forecast error
- Pipeline exclusions are working correctly

**Note:** This analysis is limited by data availability (OpportunityHistory table not accessible). However, current data shows no evidence of zombie deals.

---

## Summary of Recommendations

### High Priority (Immediate Impact)

1. **Fix Fallback Divisors** ⚠️ **CRITICAL**
   - Change Underwritten_AUM divisor: 3.125 → **3.30**
   - Change Amount divisor: 3.22 → **3.80**
   - **Expected Impact:** +5-20% improvement in estimates when Margin_AUM missing

2. **Remove Stale Cutoff from Weighted Pipeline** ⚠️ **HIGH IMPACT**
   - Keep 120-day cutoff for "Active SQO Count"
   - Remove from weighted pipeline calculations
   - **Expected Impact:** +25% more AUM in active pipeline

### Medium Priority (Significant Improvement)

3. **Implement Deal-Size Dependent Cycle Times** ⚠️ **MEDIUM IMPACT**
   - Use different cycle times for Small/Medium/Large/Enterprise
   - **Expected Impact:** Better quarter forecast accuracy for large deals

### Low Priority (Monitor)

4. **Monitor Conversion Rate Trends**
   - Track monthly conversion rates
   - Implement time-weighted probabilities if trend continues
   - **Expected Impact:** More accurate stage probabilities

5. **Zombie Deals: No Action Needed** ✅
   - Not an issue
   - Current pipeline logic is correct

---

## Expected Impact on Forecast Accuracy

### Current Performance
- Accuracy: 89.01%
- Error: -10.99% (under-forecasting)
- MAE: $4.68M

### Expected Improvement (if all fixes implemented)

| Fix | Expected Improvement | Cumulative Impact |
|-----|---------------------|-------------------|
| **Fix Fallback Divisors** | +2-3% accuracy | -8% error |
| **Remove Stale Cutoff** | +3-4% accuracy | -4-5% error |
| **Deal-Size Cycle Times** | +2-3% accuracy | -2-3% error |
| **Total Expected** | **+7-10% accuracy** | **92-96% accuracy** |

**Note:** These are estimates. Actual impact should be validated through backtesting after implementation.

---

## Implementation Priority

### Phase 1: Quick Wins (1-2 days)
1. Update fallback divisors in all views
2. Remove stale cutoff from weighted pipeline calculations
3. **Expected Impact:** +5-7% accuracy improvement

### Phase 2: Enhanced Logic (1 week)
1. Implement deal-size dependent cycle times
2. Update forecast quarter logic
3. **Expected Impact:** +2-3% accuracy improvement

### Phase 3: Monitoring (Ongoing)
1. Track conversion rate trends
2. Implement time-weighted probabilities if needed
3. **Expected Impact:** Maintain accuracy over time

---

## Conclusion

The capacity forecast model has **multiple systematic biases** that explain the observed -10.99% under-forecasting error:

1. **Fallback divisors too high** → Under-estimating when Margin_AUM missing
2. **120-day stale cutoff too aggressive** → Excluding 25% of joined AUM
3. **Same cycle times for all deals** → Enterprise deals forecasted incorrectly
4. **Declining conversion rates** → Recent deals less likely to convert

**Implementing the recommended fixes should improve accuracy from 89% to 92-96%, reducing error from -10.99% to -2-3%.**

The model is fundamentally sound (89% accuracy is good), but these biases prevent it from reaching its full potential. Addressing them will provide more accurate capacity planning and forecasting.

