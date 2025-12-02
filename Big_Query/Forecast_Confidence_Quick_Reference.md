# Forecast Confidence Quick Reference Guide

## At-a-Glance Summary

### Overall Performance
- ✅ **Quarter Accuracy**: 81.48% (Reliable for quarterly planning)
- ⚠️ **Date Precision**: 10-day median error (Moderate precision)
- ✅ **Within One Quarter**: 100% (No major misses)

---

## Confidence Levels by Use Case

### 🟢 HIGH CONFIDENCE: Quarterly Planning
- **Accuracy**: 81.48% correct quarter
- **Use For**: 
  - Quarterly target forecasting
  - Executive reporting
  - Capacity planning
- **Recommendation**: Use with ±20% margin

### 🟡 MODERATE CONFIDENCE: Monthly Planning
- **Accuracy**: 85.2% within 30 days
- **Use For**:
  - Monthly revenue forecasting
  - Pipeline reviews
- **Recommendation**: Use with ±30% margin

### 🔴 LOW CONFIDENCE: Weekly/Daily Planning
- **Accuracy**: 33.3% within 7 days
- **Not Suitable For**:
  - Daily/weekly forecasting
  - Precise date commitments
- **Recommendation**: Don't use for short-term planning

---

## How to Interpret Forecasts

### For Quarterly Targets

**Formula**: `Expected Range = Forecast ± 20%`

**Example**:
- Forecast: $30M
- **Range**: $24M - $36M (80% confidence)
- **Decision**: 
  - >$36.75M: ✅ High confidence
  - $30M-$36.75M: 🟡 Monitor closely
  - <$30M: 🔴 Action needed

### For Pipeline Planning

**Formula**: `Pipeline Sufficiency = Forecast / Target`

**Confidence Levels**:
- **>1.2**: 🟢 High confidence (20% buffer)
- **1.0-1.2**: 🟡 Moderate confidence
- **0.85-1.0**: 🟠 At risk
- **<0.85**: 🔴 Under-capacity

---

## Stage-Specific Confidence

### Signed Stage (Highest Confidence) 🟢
- **Quarter Accuracy**: 80.77%
- **Median Error**: 9 days
- **Weight**: Use at 100% confidence
- **Range**: ±15% margin

### Other Stages (Moderate Confidence) 🟡
- **Quarter Accuracy**: Varies
- **Median Error**: 10-25 days
- **Weight**: Use at 80% confidence
- **Range**: ±25% margin

---

## Recommended Confidence Intervals

| Confidence Level | Date Range | Margin AUM Range |
|-----------------|------------|-----------------|
| **80% Confidence** | ±20 days | ±20% |
| **90% Confidence** | ±30 days | ±30% |
| **95% Confidence** | ±45 days | ±40% |

**Example**: $30M forecast
- **80% Range**: $24M - $36M
- **90% Range**: $21M - $39M
- **95% Range**: $18M - $42M

---

## Key Metrics from Validation

### Overall Accuracy
- **Total Deals Analyzed**: 54
- **Quarter Accuracy**: 81.48%
- **Median Date Error**: 10 days
- **Within 30 Days**: 85.19%

### By Stage (Signed - 96% of deals)
- **Quarter Accuracy**: 80.77%
- **Median Date Error**: 9 days
- **Within 30 Days**: 84.62%

---

## Best Practices

### ✅ Do's
1. Use for quarterly planning
2. Always use ranges (±20%)
3. Monitor trends over time
4. Compare to actuals regularly
5. Weight Signed deals heavily

### ❌ Don'ts
1. Don't use for daily/weekly planning
2. Don't treat as guarantees
3. Don't ignore actuals
4. Don't over-react to small changes
5. Don't ignore context

---

## Quick Decision Matrix

| Forecast vs Target | Confidence Level | Action |
|-------------------|------------------|--------|
| >120% of target | 🟢 High | Proceed with confidence |
| 100-120% of target | 🟡 Moderate | Monitor closely |
| 85-100% of target | 🟠 At Risk | Take action |
| <85% of target | 🔴 Low | Urgent action needed |

---

## Summary

**The forecasts are**:
- ✅ **Reliable** for quarterly planning (81% accuracy)
- ⚠️ **Moderate precision** for exact dates (10-day median error)
- ✅ **Suitable** for executive reporting and capacity planning
- ❌ **Not suitable** for daily/weekly operational planning

**Use forecasts as a planning tool with appropriate confidence intervals, not as guarantees.**

