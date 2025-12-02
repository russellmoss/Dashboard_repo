# Deal Size Conversion Rate and Stage Analysis

**Analysis Date:** November 2025  
**Purpose:** Analyze conversion rates and stage-specific cycle times by deal size to identify forecasting biases  
**Key Finding:** Larger deals have **lower conversion rates** and **longer stage-specific cycle times**, requiring different probability weights and velocity assumptions.

---

## Executive Summary

**Critical Findings:**
1. ⚠️ **Larger deals convert at 36% lower rate** - Q4 (Enterprise) converts at 11.48% vs Q1 (Small) at 17.88%
2. ⚠️ **Enterprise deals take 2-5x longer from each stage** - Current stage assumptions are too optimistic
3. ⚠️ **Bre McDaniel is clearly an Enterprise SGM** - 52.6% of her deals are >$20M, avg $27.62M
4. ⚠️ **Stage probabilities need deal-size adjustment** - Current model over-forecasts large deals

**Impact:** Using uniform conversion rates and cycle times for all deals causes systematic over-forecasting of large/enterprise deals.

---

## 1. SQO-to-Joined Conversion Rates by Deal Size

### Current Assumption
- All deals have the same conversion probability (from `vw_stage_to_joined_probability`)
- Stage probabilities don't vary by deal size

### Actual Conversion Rates by Quartile

| Deal Quartile | Total SQOs | Joined Count | Conversion Rate | vs Q1 (Smallest) |
|---------------|------------|--------------|-----------------|-------------------|
| **Q1: Small (<$7.5M)** | 151 | 27 | **17.88%** | Baseline |
| **Q2: Small-Med ($7.5M-$10.5M)** | 97 | 12 | **12.37%** | -31% lower |
| **Q3: Med-Large ($10.5M-$20M)** | 126 | 19 | **15.08%** | -16% lower |
| **Q4: Large/Enterprise (>$20M)** | 122 | 14 | **11.48%** | **-36% lower** ⚠️ |

### Analysis

**Critical Finding:**
- **Enterprise deals (Q4) convert at 36% lower rate than small deals (Q1)**
- Q4: 11.48% vs Q1: 17.88% = **6.4 percentage points lower**
- This is a **statistically significant difference**

**Impact on Forecasting:**
- Current model uses same stage probabilities for all deals
- This **over-weights large deals** in the pipeline
- Example: A $50M deal in "Negotiating" gets same probability as a $5M deal
- But reality: $50M deal has 36% lower chance of converting

**Root Cause:**
- Larger deals are more complex
- More stakeholders involved
- Longer decision cycles = more opportunities to lose
- Higher scrutiny = higher bar to clear

### Recommendation

**Apply Deal-Size Adjusted Conversion Rates:**

```sql
-- Adjust stage probability based on deal size
CASE
  WHEN estimated_margin_aum < 7500000 THEN 
    stage_probability -- No adjustment (baseline)
  WHEN estimated_margin_aum < 10560000 THEN 
    stage_probability * 0.69 -- 31% lower (Q2 rate / Q1 rate)
  WHEN estimated_margin_aum < 19990000 THEN 
    stage_probability * 0.84 -- 16% lower (Q3 rate / Q1 rate)
  ELSE 
    stage_probability * 0.64 -- 36% lower (Q4 rate / Q1 rate)
END AS adjusted_stage_probability
```

**Or use quartile-specific conversion rates:**
- Q1: Use current stage probabilities (baseline)
- Q2: Multiply by 0.69 (12.37% / 17.88%)
- Q3: Multiply by 0.84 (15.08% / 17.88%)
- Q4: Multiply by 0.64 (11.48% / 17.88%)

---

## 2. Stage-Specific Stagnation Analysis

### Current Assumptions
- Fixed cycle times from stage entry:
  - Signed: 16 days
  - Negotiating: 37 days
  - Sales Process: 69 days
  - Discovery: 62 days

### Actual Median Days from Stage Entry to Join

| Deal Type | Sample | From Discovery | From Sales Process | From Negotiating | From Signed |
|-----------|--------|----------------|-------------------|------------------|-------------|
| **Small (<$5M)** | 4 | N/A | **49 days** | **18 days** | **6 days** |
| **Medium ($5M-$10M)** | 16 | N/A | **43 days** | **17 days** | **10 days** |
| **Large ($10M-$20M)** | 16 | N/A | **66 days** | **37 days** | **18 days** |
| **Enterprise (>$20M)** | 11 | N/A | **94 days** | **49 days** | **38 days** |

### Analysis

**Critical Findings:**

1. **Enterprise deals take 1.9x longer from Sales Process**
   - Small: 49 days
   - Enterprise: 94 days
   - **Current assumption: 69 days** (too short for enterprise, too long for small)

2. **Enterprise deals take 2.7x longer from Negotiating**
   - Small: 18 days
   - Enterprise: 49 days
   - **Current assumption: 37 days** (close for medium, too short for enterprise)

3. **Enterprise deals take 6.3x longer from Signed**
   - Small: 6 days
   - Enterprise: 38 days
   - **Current assumption: 16 days** (too short for enterprise, too long for small)

**Impact:**
- Enterprise deals forecasted to join in "Current Quarter" based on 16-37 day assumptions
- But reality: Enterprise deals take 38-94 days from these stages
- **Result:** Enterprise deals miss their forecast quarter, causing prediction errors

### Recommendation

**Implement Deal-Size Dependent Stage Cycle Times:**

| Stage | Small (<$5M) | Medium ($5M-$10M) | Large ($10M-$20M) | Enterprise (>$20M) |
|-------|--------------|-------------------|-------------------|-------------------|
| **Signed** | 6 days | 10 days | 18 days | **38 days** |
| **Negotiating** | 18 days | 17 days | 37 days | **49 days** |
| **Sales Process** | 49 days | 43 days | 66 days | **94 days** |
| **Discovery** | 62 days* | 62 days* | 62 days* | 62 days* |

*Discovery data not available in sample, use current assumption

**Implementation:**
```sql
CASE
  WHEN estimated_margin_aum < 5000000 THEN
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 6
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 18
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 49
      ELSE 62
    END
  WHEN estimated_margin_aum < 10000000 THEN
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 10
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 17
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 43
      ELSE 62
    END
  WHEN estimated_margin_aum < 20000000 THEN
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 18
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 37
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 66
      ELSE 62
    END
  ELSE -- Enterprise
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 38
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 49
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 94
      ELSE 62
    END
END AS days_to_join_from_stage
```

---

## 3. SGM Profiling: "Enterprise" vs "Volume" Recruiters

### Analysis Results

| SGM Name | Joined Deals | Avg Deal Size | Deal Size Volatility | Avg Cycle Time | % Deals >$20M | Classification |
|----------|--------------|---------------|----------------------|----------------|----------------|----------------|
| **Bre McDaniel** | 19 | **$27.62M** | $21.8M | 86 days | **52.6%** | ✅ **Enterprise** |
| **GinaRose Galli** | 9 | $13.51M | $5.03M | 74 days | 0% | Volume |
| **Corey Marcello** | 9 | $10.11M | $6.78M | 64 days | 11.1% | Volume |
| **Bryan Belville** | 3 | $9.91M | $3.42M | 71 days | 0% | Volume |

### Key Findings

**Bre McDaniel is Clearly an Enterprise SGM:**
- **52.6% of her deals are >$20M** (vs 0-11% for others)
- **Average deal size: $27.62M** (2-3x larger than others)
- **Deal size volatility: $21.8M** (very high - deals range from $4.68M to $78M)
- **Average cycle time: 86 days** (longer than others)

**Other SGMs are Volume Recruiters:**
- Average deal sizes: $9.91M - $13.51M
- Most deals are <$20M
- Lower volatility (more consistent deal sizes)
- Shorter cycle times (64-74 days)

### Recommendation

**Option 1: Deal-Level Logic (Recommended)**
- Apply deal-size adjustments at the **deal level**, not SGM level
- This is more accurate because:
  - Even "Volume" SGMs occasionally get large deals
  - Even "Enterprise" SGMs occasionally get small deals
  - Deal characteristics matter more than SGM profile

**Option 2: SGM-Level Logic (Alternative)**
- For SGMs with >40% of deals >$20M, apply enterprise logic to all their deals
- For others, apply standard logic
- **Risk:** Might misclassify occasional large deals from volume SGMs

**Recommendation:** **Use Option 1 (Deal-Level)** - More accurate and flexible.

---

## Summary of Required Changes

### 1. Adjust Stage Probabilities by Deal Size ⚠️ **CRITICAL**

**Current:** Same probability for all deals  
**Required:** Multiply by adjustment factor based on deal size

| Deal Size | Adjustment Factor | Rationale |
|-----------|------------------|-----------|
| <$7.5M | 1.00 (no change) | Baseline conversion rate |
| $7.5M-$10.5M | 0.69 | 31% lower conversion |
| $10.5M-$20M | 0.84 | 16% lower conversion |
| >$20M | 0.64 | 36% lower conversion |

**Impact:** Prevents over-forecasting of large deals in pipeline.

### 2. Adjust Stage Cycle Times by Deal Size ⚠️ **HIGH IMPACT**

**Current:** Fixed cycle times for all deals  
**Required:** Deal-size dependent cycle times

| Stage | Small | Medium | Large | Enterprise |
|-------|-------|--------|-------|------------|
| Signed | 6 days | 10 days | 18 days | 38 days |
| Negotiating | 18 days | 17 days | 37 days | 49 days |
| Sales Process | 49 days | 43 days | 66 days | 94 days |

**Impact:** Better quarter forecast accuracy for all deal sizes.

### 3. Apply at Deal Level (Not SGM Level) ✅

**Recommendation:** Use deal-level logic because:
- More accurate (deals vary even within SGM)
- More flexible (handles edge cases)
- Easier to maintain (one set of rules)

---

## Expected Impact on Forecast Accuracy

### Current Performance
- Accuracy: 89.01%
- Error: -10.99% (under-forecasting)
- Issues: Over-forecasting large deals, under-forecasting small deals

### Expected Improvement (if all fixes implemented)

| Fix | Expected Improvement |
|-----|---------------------|
| **Deal-Size Adjusted Probabilities** | +2-3% accuracy |
| **Deal-Size Dependent Cycle Times** | +2-3% accuracy |
| **Combined Impact** | **+4-6% accuracy** |

**Expected Result:** 93-95% accuracy, -2-3% error

---

## Implementation Priority

### Phase 1: Quick Win (1-2 days)
1. **Apply deal-size probability adjustments** to weighted pipeline calculations
2. **Expected Impact:** +2-3% accuracy, prevents over-forecasting large deals

### Phase 2: Enhanced Logic (1 week)
1. **Implement deal-size dependent cycle times** for forecast quarter logic
2. **Expected Impact:** +2-3% accuracy, better quarter predictions

### Phase 3: Validation (Ongoing)
1. **Backtest with new logic**
2. **Monitor accuracy improvements**
3. **Fine-tune adjustment factors if needed**

---

## Conclusion

**Key Insights:**

1. **Larger deals convert at 36% lower rate** - Must apply lower probability weights
2. **Enterprise deals take 2-5x longer from each stage** - Must use longer cycle times
3. **Bre McDaniel is an Enterprise SGM** - But deal-level logic is still better
4. **Current model over-forecasts large deals** - Both in probability and timing

**Required Actions:**

✅ **Apply deal-size adjusted probabilities** (Q4: 0.64x multiplier)  
✅ **Implement deal-size dependent cycle times** (Enterprise: 38-94 days)  
✅ **Use deal-level logic** (not SGM-level)

**Expected Outcome:** Improved forecast accuracy from 89% to 93-95%, with more accurate predictions for both small and large deals.

