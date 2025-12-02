# Cycle Time Statistics by Margin_AUM Quartiles

**Analysis Date:** November 2025  
**Time Period:** Last 12 months  
**Metric:** Days from `Date_Became_SQO__c` to `advisor_join_date__c`

---

## Overall Statistics (All Joined Deals)

| Metric | Value |
|--------|-------|
| **Total Deals** | 47 |
| **Average Days to Join** | **72.7 days** |
| **Median Days to Join** | **69 days** |
| **25th Percentile** | **31 days** |
| **75th Percentile** | **100 days** |
| **Minimum** | 10 days |
| **Maximum** | 222 days |

---

## Statistics by Margin_AUM Quartile

### Q1: 0-25th Percentile (Smallest Deals)
**Margin_AUM Range:** $0 - $7.5M

| Metric | Value |
|--------|-------|
| **Deal Count** | 12 |
| **Average Days to Join** | **49.8 days** |
| **Median Days to Join** | **35 days** |
| **25th Percentile** | **20 days** |
| **75th Percentile** | **71 days** |
| **Minimum** | 17 days |
| **Maximum** | 110 days |

### Q2: 25th-50th Percentile (Small-Medium Deals)
**Margin_AUM Range:** $7.5M - $10.56M

| Metric | Value |
|--------|-------|
| **Deal Count** | 12 |
| **Average Days to Join** | **51.8 days** |
| **Median Days to Join** | **45 days** |
| **25th Percentile** | **27 days** |
| **75th Percentile** | **63 days** |
| **Minimum** | 13 days |
| **Maximum** | 109 days |

### Q3: 50th-75th Percentile (Medium-Large Deals)
**Margin_AUM Range:** $10.56M - $19.99M

| Metric | Value |
|--------|-------|
| **Deal Count** | 12 |
| **Average Days to Join** | **71.7 days** |
| **Median Days to Join** | **66 days** |
| **25th Percentile** | **21 days** |
| **75th Percentile** | **80 days** |
| **Minimum** | 10 days |
| **Maximum** | 222 days |

### Q4: 75th-100th Percentile (Largest Deals)
**Margin_AUM Range:** >$19.99M

| Metric | Value |
|--------|-------|
| **Deal Count** | 11 |
| **Average Days to Join** | **121.5 days** ⚠️ |
| **Median Days to Join** | **113 days** ⚠️ |
| **25th Percentile** | **89 days** |
| **75th Percentile** | **144 days** |
| **Minimum** | 42 days |
| **Maximum** | 195 days |

---

## Key Findings

### 1. Large Deals Take 2.4x Longer

| Comparison | Difference |
|------------|-----------|
| **Q4 Average vs Q1 Average** | 121.5 days vs 49.8 days = **2.4x longer** |
| **Q4 Median vs Q1 Median** | 113 days vs 35 days = **3.2x longer** |
| **Q4 P75 vs Q1 P75** | 144 days vs 71 days = **2.0x longer** |

### 2. Clear Pattern: Larger Deals = Longer Cycles

| Quartile | Average Days | Median Days | Trend |
|----------|-------------|-------------|-------|
| Q1 (Smallest) | 49.8 | 35 | Fastest |
| Q2 | 51.8 | 45 | Similar to Q1 |
| Q3 | 71.7 | 66 | **+40% slower** |
| Q4 (Largest) | 121.5 | 113 | **+144% slower** |

### 3. Current Model Assumption vs Reality

**Current Model Uses:** ~70 days for all deals (based on overall median)

**Reality:**
- Small deals (Q1-Q2): **35-45 days** (2x faster than assumed)
- Medium deals (Q3): **66 days** (close to assumed)
- Large deals (Q4): **113 days** (1.6x slower than assumed)

**Impact:** Large deals are systematically under-forecasted in terms of cycle time.

---

## Recommendations

### 1. Implement Deal-Size Dependent Cycle Times

Based on these quartiles, use:

| Deal Size | Median Days | P75 Days | Recommendation |
|-----------|-------------|----------|----------------|
| **< $7.5M** | 35 days | 71 days | Use 35-40 days |
| **$7.5M - $10.56M** | 45 days | 63 days | Use 45-50 days |
| **$10.56M - $19.99M** | 66 days | 80 days | Use 70-80 days |
| **> $19.99M** | 113 days | 144 days | Use 110-120 days |

### 2. Update Forecast Quarter Logic

Current logic uses fixed cycle times. Update to:

```sql
CASE
  WHEN estimated_margin_aum < 7500000 THEN 
    -- Q1-Q2: 35-45 days median
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 20
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 30
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 50
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 45
      ELSE 40
    END
  WHEN estimated_margin_aum < 10560000 THEN 
    -- Q2: 45 days median
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 25
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 35
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 55
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 50
      ELSE 50
    END
  WHEN estimated_margin_aum < 19990000 THEN 
    -- Q3: 66 days median
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 30
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 50
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 75
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 70
      ELSE 75
    END
  ELSE 
    -- Q4: 113 days median
    CASE
      WHEN Stage_Entered_Signed__c IS NOT NULL THEN 50
      WHEN Stage_Entered_Negotiating__c IS NOT NULL THEN 80
      WHEN Stage_Entered_Sales_Process__c IS NOT NULL THEN 120
      WHEN Stage_Entered_Discovery__c IS NOT NULL THEN 110
      ELSE 120
    END
END AS days_to_join_estimate
```

### 3. Update Stale Deal Cutoff

Based on P75 values:
- Q1-Q2: 71-63 days → Use 90-day cutoff
- Q3: 80 days → Use 120-day cutoff (current)
- Q4: 144 days → Use 180-day cutoff

**Or better:** Remove stale cutoff from weighted pipeline (as recommended in validation report).

---

## Summary Table

| Margin_AUM Quartile | Range | Deal Count | Avg Days | Median Days | P25 Days | P75 Days |
|---------------------|-------|------------|----------|-------------|----------|----------|
| **Q1 (Smallest)** | $0 - $7.5M | 12 | 49.8 | **35** | 20 | 71 |
| **Q2** | $7.5M - $10.56M | 12 | 51.8 | **45** | 27 | 63 |
| **Q3** | $10.56M - $19.99M | 12 | 71.7 | **66** | 21 | 80 |
| **Q4 (Largest)** | >$19.99M | 11 | 121.5 | **113** | 89 | 144 |
| **Overall** | All Deals | 47 | 72.7 | **69** | 31 | 100 |

**Key Insight:** The largest deals (Q4) take **3.2x longer** than the smallest deals (Q1) to go from SQO to Joined. This explains why enterprise deals (like Bre McDaniel's) are systematically under-forecasted in the current model.

