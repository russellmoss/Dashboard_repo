# Pipeline Forecasting Feasibility Study
**Date:** January 2025  
**Dataset:** `savvy-gtm-analytics.savvy_analytics`  
**Views Analyzed:** `vw_sgm_open_sqos_detail`, `vw_funnel_lead_to_joined_v2`

---

## Executive Summary

This study evaluates the reliability of using `CloseDate` vs. calculated projected close dates for forecasting Current Quarter vs. Next Quarter revenue. Based on the analysis, **we recommend using a calculated `Projected_Close_Date` based on historical cycle times** rather than relying solely on `CloseDate` or `Earliest_Anticipated_Start_Date__c`.

---

## Question 1: Field Reliability

### Results
- **Total Open SQOs:** 125
- **CloseDate Population:** 100% (125/125)
- **Earliest_Anticipated_Start_Date__c Population:** 34.4% (43/125)
- **Both Fields Populated:** 34.4% (43/125)
- **Neither Field Populated:** 0% (0/125)

### Analysis
✅ **CloseDate is fully populated** - This is excellent for forecasting.  
⚠️ **Earliest_Anticipated_Start_Date__c is only 34.4% populated** - This field cannot be relied upon as a primary forecasting field.

### Key Insight
While `CloseDate` is always populated, we need to validate its accuracy (see Question 2).

---

## Question 2: Historical Accuracy

### Results
- **Total Joined Deals Analyzed:** 97
- **Deals with CloseDate:** 97 (100%)
- **Average Difference (CloseDate vs. advisor_join_date__c):** 19.54 days
- **Median Difference:** 0 days
- **Standard Deviation:** 39.28 days

### Distribution Analysis
- **Exact Match (0 days):** 50 deals (51.5%)
- **Within 7 days:** 68 deals (70.1%)
- **Within 30 days:** 73 deals (75.3%)
- **CloseDate Before Join Date:** 7 deals (7.2%)
- **CloseDate After Join Date:** 40 deals (41.2%)

### Analysis
⚠️ **CloseDate accuracy is mixed:**
- **Good News:** 51.5% of deals have exact matches, and 70% are within 7 days
- **Concern:** Average difference of 19.54 days with high variability (stddev: 39.28 days)
- **Issue:** 41% of deals have CloseDate set AFTER the actual join date, suggesting SGMs may be updating CloseDate retrospectively rather than proactively

### Key Insight
CloseDate is reasonably accurate for about half of deals, but the high variability (39-day standard deviation) makes it unreliable for precise forecasting. The fact that many CloseDates are set after the join date suggests SGMs are not maintaining this field proactively.

---

## Question 3: Cycle Time Baseline

### Results (Last 12 Months)
- **Total Deals Analyzed:** 59
- **Average Cycle Time (SQO → Join):** 81.97 days
- **Median Cycle Time:** 70 days
- **Standard Deviation:** 74.08 days

### Percentile Distribution
- **25th Percentile (P25):** 33 days
- **50th Percentile (Median):** 70 days
- **75th Percentile (P75):** 100 days
- **90th Percentile (P90):** 148 days

### Analysis
📊 **Cycle time shows significant variability:**
- Median of 70 days aligns with the previously known 77-day average
- High variability (74-day stddev) indicates deals can range from 33 days (fast) to 148+ days (slow)
- This variability supports using a calculated approach rather than relying on manually entered CloseDates

### Key Insight
The median cycle time of 70 days provides a good baseline for calculating projected close dates. However, the high variability suggests we should consider using percentiles or SGM-specific averages for more accurate forecasting.

---

## Question 4: Stage Velocity

### Results (Using Available Date Fields)

#### Discovery Stage (SQO → Qualification Call)
- **Deals with Data:** 46
- **Average Days:** -8.87 days ⚠️
- **Median Days:** 0 days
- **Note:** Negative values indicate Qualification_Call_Date__c often occurs before Date_Became_SQO__c, suggesting data quality issues or that qualification calls happen pre-SQO.

#### Sales Process Stage (Qualification Call → Signed)
- **Deals with Data:** 46
- **Average Days:** 60.96 days
- **Median Days:** 52 days
- **P25:** 27 days
- **P75:** 80 days

#### Negotiating Stage (Signed → Join)
- **Deals with Data:** 57
- **Average Days:** 26.56 days
- **Median Days:** 18 days
- **P25:** 7 days
- **P75:** 35 days

### Analysis
⚠️ **Stage-level data is limited:**
- We don't have explicit stage entry dates for Discovery, Sales Process, and Negotiating
- Qualification_Call_Date__c and Stage_Entered_Signed__c provide some proxy data
- Sales Process (52-day median) and Negotiating (18-day median) provide useful benchmarks

### Key Insight
While we can't precisely calculate time in each stage, the Sales Process (52 days) and Negotiating (18 days) segments provide useful validation that most of the cycle time occurs in the middle stages.

---

## Recommendations

### 🎯 Primary Recommendation: Use Calculated Projected_Close_Date

**Formula:**
```
Projected_Close_Date = Date_Became_SQO__c + Median_Cycle_Time - Days_Open_So_Far
```

**Or more sophisticated:**
```
Projected_Close_Date = CURRENT_DATE + (Median_Cycle_Time - Days_Open_Since_SQO)
```

**Rationale:**
1. **CloseDate is unreliable:** While 100% populated, only 51.5% are exact matches, and there's high variability (39-day stddev)
2. **CloseDate is often updated retrospectively:** 41% of CloseDates are set AFTER the join date
3. **Cycle time is stable:** Median of 70 days provides a reliable baseline
4. **Earliest_Anticipated_Start_Date__c is underpopulated:** Only 34.4% of deals have this field

### 📊 Secondary Recommendation: Hybrid Approach

Use a **weighted combination** of available fields:

1. **Primary:** Calculated Projected_Close_Date (based on cycle time)
2. **Secondary:** CloseDate (if within reasonable range of calculated date)
3. **Tertiary:** Earliest_Anticipated_Start_Date__c (if available and reasonable)

**Logic:**
```sql
Projected_Close_Date = 
  CASE
    -- If CloseDate is within 30 days of calculated date, use CloseDate
    WHEN CloseDate IS NOT NULL 
      AND ABS(DATE_DIFF(CloseDate, Calculated_Date, DAY)) <= 30
    THEN CloseDate
    
    -- If Earliest_Anticipated_Start_Date is within 30 days of calculated date, use it
    WHEN Earliest_Anticipated_Start_Date__c IS NOT NULL
      AND ABS(DATE_DIFF(Earliest_Anticipated_Start_Date__c, Calculated_Date, DAY)) <= 30
    THEN Earliest_Anticipated_Start_Date__c
    
    -- Otherwise, use calculated date
    ELSE Calculated_Date
  END
```

### 🔧 Implementation Suggestions

1. **SGM-Specific Cycle Times:** Calculate median cycle time per SGM for more accurate forecasting
2. **Stage-Based Adjustments:** For deals in "Negotiating" stage, use shorter cycle time (18-day median from Signed to Join)
3. **Stale Deal Handling:** For deals >120 days old, flag as "at risk" and use more conservative estimates
4. **Quarterly Bucketing:** 
   - **Current Quarter:** Deals with Projected_Close_Date in current quarter
   - **Next Quarter:** Deals with Projected_Close_Date in next quarter
   - **Beyond:** Deals with Projected_Close_Date > next quarter

### 📈 Forecasting Accuracy Improvements

1. **Monitor CloseDate Updates:** Track when CloseDate is updated relative to join date to identify SGMs who maintain this field proactively
2. **Validate Against Actuals:** Compare projected vs. actual close dates monthly to refine the model
3. **Consider Deal Size:** Larger deals may have longer cycle times - consider segmenting by AUM size

---

## Conclusion

**Answer to Key Questions:**

1. **Should we use raw CloseDate?** ❌ **No** - While 100% populated, accuracy is only 51.5% exact matches with high variability.

2. **Should we use advisor_join_date__c?** ❌ **No** - This is only available for closed deals, not useful for forecasting open deals.

3. **Should we use Earliest_Anticipated_Start_Date__c?** ⚠️ **Partially** - Only 34.4% populated, but can be used as a secondary validation field.

4. **Should we calculate Projected_Close_Date?** ✅ **Yes** - **RECOMMENDED APPROACH**
   - Use: `Projected_Close_Date = CURRENT_DATE + (70 - Days_Open_Since_SQO)` 
   - Or: `Projected_Close_Date = Date_Became_SQO__c + 70`
   - Consider SGM-specific medians for improved accuracy

**Final Recommendation:** Implement a calculated `Projected_Close_Date` based on historical cycle times (median: 70 days), with CloseDate and Earliest_Anticipated_Start_Date__c as validation/refinement fields when available and reasonable.

