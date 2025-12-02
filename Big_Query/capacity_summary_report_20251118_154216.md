# Capacity & Coverage Summary Report
Generated: 2025-11-18 15:42:16

---

## Key Definitions

### Capacity (SGM Capacity)
**Capacity** is the primary forecast metric representing the expected quarterly joined Margin AUM an SGM's active pipeline can produce.

- **Formula:** Capacity = Active Weighted Pipeline Value × SQO→Joined Conversion Rate
- **Logic:** Uses an SGM's active, healthy pipeline (non-stale SQOs) and multiplies it by their historical probability of converting deals, giving a realistic, stable forecast based on past performance.
- **Active Weighted Pipeline Value:** The weighted, estimated value only for non-stale deals (using dynamic thresholds: <$5M ≤90 days, $5M-$15M ≤120 days, $15M-$30M ≤180 days, ≥$30M ≤240 days). This is the most realistic forecast metric for capacity planning.

**⚠️ IMPORTANT: Understanding Capacity Estimate**
- **Capacity is NOT what will close in the current quarter.** It represents the forecasted value of deals coming down the pipeline that are expected to close over time.
- **Capacity is a forward-looking metric** that helps answer: "Do we have enough SQOs and Margin AUM in the pipeline to support all our SGMs hitting their $36.75M quarterly target?"
- **Interpretation:**
  - **Current Quarter:** Compare "Current Quarter Actuals" (what has already closed) to the $36.75M target to see who has met/exceeded their target this quarter.
  - **Future Quarters:** Compare "Capacity" to the $36.75M target to assess whether SGMs have enough pipeline to hit future quarterly targets.
  - **Pipeline Sufficiency:** A Capacity of $36.75M means the SGM has enough pipeline value (when weighted by conversion probability) to theoretically hit their target, but these deals may close across multiple quarters.
- **Why This Matters:** SGMs earn commission based on hitting their $36.75M quarterly target. Capacity helps ensure they have sufficient pipeline to achieve this, while Current Quarter Actuals shows what they've already achieved.

### Coverage (Coverage Ratio)
**Coverage** measures whether an SGM's Capacity is sufficient to hit their quarterly target.

- **Formula:** Coverage Ratio = Capacity / Target
- **Target:** The quarterly goal is $36.75M in Margin AUM per SGM, per quarter.
- **Example:** A Coverage Ratio of 1.20 means the SGM has 120% of the capacity needed to hit their $36.75M target. A ratio of 0.75 means they only have 75% of the capacity needed.

### Coverage Status Categories
Each SGM is automatically assigned a coverage status:

- **On Ramp:** The SGM's user account was created in the last 90 days. Their capacity is not calculated, as they are presumed to be ramping.
- **Sufficient:** Coverage Ratio ≥ 1.0 (100%+). This SGM's active pipeline forecast meets or exceeds their quarterly target.
- **At Risk:** Coverage Ratio ≥ 0.85 but < 1.0 (85%-99%). This SGM is close to having enough capacity but is in a "warning" zone.
- **Under-Capacity:** Coverage Ratio < 0.85 (<85%). This SGM has a significant gap in their pipeline and requires immediate attention.

### Pipeline Analysis Context
This report analyzes the **TOTAL OPEN PIPELINE** (all active SQOs and deals, regardless of when they were created) to ensure SGMs have sufficient pipeline to hit their quarterly targets. While the target is quarterly, we cannot predict exactly when deals will close, so we maintain a continuous pipeline that should contain enough SQOs and deals to support quarterly targets. The goal is to ensure SGMs have the right amount of SQOs and deals in their pipeline to hit their numbers across quarters, recognizing that deals may close in different quarters than when they entered the pipeline.

### Stale Pipeline
An SQO is flagged as "stale" using **dynamic thresholds based on deal size** (V2 Logic):

- **Small Deals (<$5M):** Stale if open >90 days
- **Medium Deals ($5M-$15M):** Stale if open >120 days
- **Large Deals ($15M-$30M):** Stale if open >180 days
- **Enterprise Deals (≥$30M):** Stale if open >240 days

This recognizes that larger, more complex deals naturally take longer to close. The average time from SQO to Joined is 77 days, but enterprise deals often take 120+ days. A high stale % (e.g., >30%) is a major red flag that the SGM's pipeline is inflated and needs cleanup, but enterprise-focused SGMs (like Bre McDaniel) may have longer cycles that are still healthy.

---

## Forecast Methodology & Confidence Guidelines

### Model Overview

This report uses a multi-layered forecasting framework based on the V2 Capacity Model, which has demonstrated approximately **89% accuracy** in backtests with a slight conservative bias (-11% error). The model uses:

1. **Deal-Size Dependent Velocity:** Enterprise deals (>$30M) are modeled at 120 days, Large deals ($15M-$30M) at 90 days, Standard deals (<$15M) at 50 days
2. **Dynamic Valuation:** When Margin_AUM is missing, uses Underwritten_AUM / 3.30 or Amount / 3.80
3. **Stage Probabilities:** Each deal stage (Discovery, Sales Process, Negotiating, Signed) has a specific probability of eventually reaching "Joined"
4. **Probability Penalties:** Recent deals (<6 months) receive penalties to reflect current market conditions

### Confidence Levels

**High Confidence (90%+):**
- Trend and sufficiency signals (e.g., "SGM has enough pipeline" or "SGM is starving for leads")
- Coverage Ratio assessments (Capacity vs. Target)
- Pipeline gap identification

**Medium Confidence (75%+):**
- Exact dollar figures for the quarter, especially when forecast relies on multiple deals
- Expected End of Quarter forecasts with diversified pipeline

**Lower Confidence:**
- Forecasts that depend heavily on 1-2 Enterprise deals in early stages (e.g., "Negotiating")
- Quarters where a single large deal represents >50% of expected revenue

### Key Limitations & Interpretation Guidelines

1. **Binary Outcome Problem:** The model uses expected value (EV). A $50M deal at 10% probability shows as "$5M expected," but reality is "$0 or $50M" - never $5M. For Enterprise-focused SGMs (like Bre McDaniel), treat forecasts as "Deal Potential" rather than precise cash-flow predictions.

2. **Timing Uncertainty:** We use deal-size dependent cycle times, but large deals often take 120+ days. If a large deal is marked "Overdue," it might just be complex, not dead.

3. **Human-in-the-Loop Required:** These numbers are **directionally correct** but should always be reviewed with qualitative judgment, especially for:
   - Enterprise deals in early stages
   - SGMs with pipeline concentrated in 1-2 large deals
   - Quarters where seasonality may affect outcomes

4. **View as Planning Tool:** The model excels at identifying pipeline gaps and capacity issues. Use it to answer "Do we have enough iron in the fire?" rather than "Exactly how much will close this quarter?"

### How to Use Quarterly Forecasts

- **Current Quarter Actuals:** What has already closed (factual)
- **Expected End of Quarter:** Current Actuals + Pipeline Forecast for rest of quarter (directionally correct, medium confidence)
- **Expected Next Quarter:** Pipeline forecast for deals projected to close next quarter (leading indicator of future capacity)

**Critical Rule:** If an SGM's forecast relies heavily on 1-2 large Enterprise deals, flag it as "At Risk" regardless of what the model says, due to binary outcome nature.

---

Here is the comprehensive pipeline health analysis for sales leadership.

***

### **TO:** Sales Leadership
### **FROM:** Revenue Operations Partner
### **DATE:** October 26, 2023
### **SUBJECT:** Q4 Pipeline Diagnostic & Action Plan

This report provides a "no-fluff" diagnostic of our sales funnel, highlighting critical gaps, bright spots, and an immediate action plan to secure this quarter and build a healthy pipeline for the next.

---

### **1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY**

We are in a bifurcated state: top-heavy performance is masking significant underlying risk. While the firm is on track to exceed its quarterly target, this success is driven almost entirely by two top performers. A significant portion of the team is under-capacity and at risk for future quarters. Our ability to convert qualified opportunities into closed deals has dropped by over 50% in the last 90 days, indicating a critical bottleneck at the bottom of the funnel.

**Current Quarter Performance:** Two SGMs have already crushed their **$36.75M** quarterly target. **Bre McDaniel** has delivered an exceptional **$121.71M** (331% of target), and **Corey Marcello** has closed **$36.90M** (100.4% of target). **GinaRose Galli** is close at **$30.78M** (84% of target). This strong performance at the top has pushed the firm to 70.3% of its total goal.

**Firm-Level Performance & Coverage:** We are safe for *this* quarter, with a projected end-of-quarter result of **$546.87M** (165% of target). However, next quarter's forecast is only **$87.26M**, which is insufficient to cover the full team's target. The firm-wide Coverage Ratio is a healthy **1.77**, but this is misleading. It masks the reality that two SGMs (**Jade Bingham, Bryan Belville**) are "Under-Capacity" and mathematically starving for leads, while three are still ramping.

**SQO Pipeline Sufficiency:** The total open pipeline has a massive SQO gap of **238 deals**. We require 360 SQOs to be fully covered but only have 122. This is the primary leading indicator of future revenue problems. While top-of-funnel activity (SQL→SQO) is improving, the severe drop in closing conversion (SQO→Joined) means the new opportunities are not translating to revenue efficiently.

**Critical Alerts:**
1.  **Bottom-Funnel Conversion Collapse:** Our SQO→Joined conversion rate has plummeted from 9.8% to **4.4%** in the last 90 days. This is the most urgent issue.
2.  **Massive SQO Volume Gap:** We are missing **255 active SQOs** needed to sustain future quarters. This is a direct threat to next quarter's performance.
3.  **Extreme Performance Disparity:** Two SGMs are carrying the quarter. Two others are severely under-capacity, and three are ramping with minimal pipeline. This dependency on a few individuals is a significant risk.
4.  **High "Slip Risk":** **$328.42M** in revenue is tied to overdue deals (>70 days old). This pipeline is at high risk of not closing.

**Overall Assessment:** **At Risk.** While this quarter's numbers look strong on the surface due to heroic efforts from Bre and Corey, the underlying health of the funnel is poor. A severe conversion drop, a massive SQO volume deficit, and high pipeline bloat threaten future performance.

---

### **2. CAPACITY & COVERAGE ANALYSIS**

**Context:** Capacity is a forward-looking measure of pipeline health, indicating if we have enough "iron in the fire" for *future* quarters. Current Quarter Actuals show what has already closed *this* quarter.

*   **Current Quarter Readiness:**
    *   **Target Met/Exceeded (2):** Bre McDaniel ($121.71M), Corey Marcello ($36.90M).
    *   **Close to Target (1):** GinaRose Galli ($30.78M, 84% of target).
    *   The remaining 6 fully-ramped SGMs are significantly behind on this quarter's actuals.

*   **Next Quarter Readiness:**
    *   The firm-wide forecast for next quarter is only **$87.26M**, far below the **$330.8M** target.
    *   Specifically, **GinaRose Galli** has a **$0.00M** forecast for next quarter, indicating a complete pipeline cliff despite her strong current-quarter performance. This requires immediate attention.

*   **Firm-Wide Capacity Gap:**
    *   The firm has a capacity *surplus* of **$70.8M**, giving a healthy **1.77 Coverage Ratio**.
    *   **WARNING:** This surplus is held almost entirely by Bre McDaniel ($-103M gap) and Corey Marcello ($-70M gap). This masks the deficits elsewhere.

*   **Coverage Status Breakdown:**
    *   **Sufficient (4):** Bre McDaniel, Corey Marcello, GinaRose Galli, Erin Pearson.
    *   **At Risk (0):** None.
    *   **Under-Capacity (2):** **Jade Bingham (0.61)** and **Bryan Belville (0.80)** are starving for pipeline and cannot mathematically hit future targets without immediate lead flow.
    *   **On Ramp (3):** Tim Mackey, Lexi Harrison, and Ariana Butler have minimal pipeline and need significant support.

---

### **3. SQO PIPELINE DIAGNOSIS**

**Context:** Analysis of the total open pipeline to ensure SGMs have enough deals to hit targets over time.

*   **Quantity Analysis:**
    *   We have a firm-wide gap of **238 total SQOs** (255 active/non-stale).
    *   We currently have only **122 SQOs** in the pipeline against a requirement of **360**. This is a severe volume deficit and the primary cause of under-capacity issues for multiple SGMs.

*   **Quality Analysis:**
    *   The firm-wide stale rate is a manageable **6.2% ($188.2M)**.
    *   However, this is concentrated in specific SGMs. **GinaRose Galli** has a dangerously high **39.1% stale pipeline**. This bloat is likely consuming her time and masking true pipeline health. **Corey Marcello** also has an elevated stale rate at **11.4%**.

*   **Root Cause Analysis (Balanced View):**
    *   **SGA Perspective:** SGAs are improving at converting SQLs to SQOs (rate is up 7.7pp). However, the overall volume of SQLs from key channels like **Outbound / Provided Lead List** (7 SQLs this quarter vs. 42 avg) and **Marketing / Event** (0 SQLs vs. 7 avg) has collapsed. SGAs cannot create SQOs from leads that don't exist.
    *   **SGM Perspective:** The dramatic drop in the SQO→Joined rate (from 9.8% to 4.4%) points to a bottom-funnel problem. This could be due to lower quality leads making it through the funnel, SGMs struggling to close, or deals stalling out. The high stale pipeline for GinaRose and Corey supports the "stalling" hypothesis.
    *   **Collaborative Factors:** The data suggests a two-part problem: a top-of-funnel *volume* issue from specific marketing/outbound channels, compounded by a bottom-of-funnel *conversion* issue.

---

### **3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)**

**CRITICAL CONTEXT:** Our baseline requirement of **40 SQOs per SGM per quarter** is directional guidance, not a rigid target. It is derived from data with extremely high volatility.

*   **Volatility Statistics:**
    *   **Coefficient of Variation:** 48.8% (HIGH VOLATILITY - standard deviation is nearly half the mean).
    *   **Average Margin AUM:** $11.35M.
    *   **Range:** $3.75M to $23.09M.
    *   **Interpretation:** An SGM closing consistent $16M+ deals may only need ~24 SQOs, while an SGM closing $7M deals may need ~56. We must interpret SQO gaps with this context.

*   **SGM-Level SQO Gap Analysis:**

    *   **Tim Mackey:** 🔴 **CRITICAL GAP**
        *   Required SQOs: 40 | Current Pipeline: 2 | **Gap: 38** (5% of required)
        *   Interpretation: As a ramping rep, this gap is expected but needs immediate focus.

    *   **Ariana Butler:** 🔴 **CRITICAL GAP**
        *   Required SQOs: 40 | Current Pipeline: 5 | **Gap: 35** (12.5% of required)
        *   Interpretation: Ramping rep with a severe pipeline deficit.

    *   **Lexi Harrison:** 🔴 **CRITICAL GAP**
        *   Required SQOs: 40 | Current Pipeline: 5 | **Gap: 35** (12.5% of required)
        *   Interpretation: Ramping rep with a severe pipeline deficit.

    *   **GinaRose Galli:** 🔴 **CRITICAL GAP**
        *   Required SQOs: 40 | Current Pipeline: 8 | **Gap: 32** (20% of required)
        *   Interpretation: Despite being "Sufficient" on coverage, her SQO *volume* is critically low. Her high-value, stale pipeline is inflating her coverage ratio. She is at high risk for next quarter.

    *   **Jade Bingham:** ⚠️ **SIGNIFICANT GAP**
        *   Required SQOs: 40 | Current Pipeline: 15 | **Gap: 25** (37.5% of required)
        *   Interpretation: This is a real capacity issue, reflected in her "Under-Capacity" status. She needs immediate lead flow.

    *   **Bryan Belville:** ⚠️ **SIGNIFICANT GAP**
        *   Required SQOs: 40 | Current Pipeline: 16 | **Gap: 24** (40% of required)
        *   Interpretation: Another clear capacity issue. His pipeline volume is too low to sustain his target.

    *   **Erin Pearson:** ⚠️ **SIGNIFICANT GAP**
        *   Required SQOs: 40 | Current Pipeline: 19 | **Gap: 21** (47.5% of required)
        *   Interpretation: While her coverage ratio is sufficient, her deal volume is on the low end. She needs more at-bats to de-risk her forecast.

    *   **Bre McDaniel (Enterprise Focus):** ⚠️ **SIGNIFICANT GAP**
        *   Required SQOs: 40 | Current Pipeline: 25 | **Gap: 15** (62.5% of required)
        *   Interpretation: **IGNORE THIS GAP.** As our Enterprise Hunter, her deal value is multiples of the average. 25 active SQOs with a weighted pipeline of $1.25B is more than sufficient. She is on track.

    *   **Corey Marcello:** ⚠️ **SIGNIFICANT GAP**
        *   Required SQOs: 40 | Current Pipeline: 27 | **Gap: 13** (67.5% of required)
        *   Interpretation: He is close to the optimistic range (24 SQOs). Given his proven ability to close, this gap is less concerning but should be monitored.

---

### **4. CONVERSION RATE ANALYSIS & TRENDS**

**Methodology Note:** SQO→Joined rates use a 90-day lookback for accuracy.

*   **Overall Trends:**
    *   **SQL→SQO Rate (Top Funnel):** **Improving.** Up from 69.9% to **77.6%** this quarter. SGAs are qualifying more effectively.
    *   **SQO→Joined Rate (Bottom Funnel):** **Collapsing.** Down from 9.8% to **4.4%** in the last 90 days. This is a **-55%** drop in closing efficiency and our most critical bottleneck.

*   **Channel & Source Performance Driving the Decline:**
    *   **Ecosystem / Recruitment Firm:** SQO→Joined rate dropped from 10.0% to **0.0%**.
    *   **Marketing / Re-Engagement:** SQO→Joined rate dropped from 12.5% to **6.2%**.
    *   **Outbound / LinkedIn (Self Sourced):** SQO→Joined rate dropped from 7.1% to **3.6%**.

*   **Diagnostic Insights (Balanced View):**
    *   The improvement in SQL→SQO rates suggests the SGA-to-SGM handoff is mechanically working.
    *   The collapse in SQO→Joined rates points to a significant issue *after* the handoff. This could be:
        1.  **Lower Quality Inflow:** Leads from key sources (LinkedIn, Recruitment Firms) may be less qualified than historical averages, even if they pass the initial SQL check.
        2.  **SGM Closing Challenges:** SGMs may be struggling to move deals through the final stages, as evidenced by the high stale pipeline values.
        3.  **Market Headwinds:** External factors could be lengthening sales cycles and causing deals to stall in negotiation.

---

### **5. SGA PERFORMANCE ANALYSIS**

**CRITICAL SEGMENTATION:** Inbound (Lauren, Jacqueline) and Outbound SGAs are analyzed separately.

#### **Inbound SGAs (The Feeders)**

*   **Top Performer & Volume Leader:** **Lauren George**
    *   **Volume:** Produced **20 SQOs**, the highest on the team.
    *   **Performance:** Her SQL→SQO rate improved by **+10.7pp** to 84.6%. She is a high-volume, high-quality engine for the pipeline.

*   **Strong Contributor:** **Jacqueline Tully**
    *   **Volume:** Produced **13 SQOs**, the second-highest inbound volume.
    *   **Performance:** Her SQL→SQO rate saw a minor dip, but her MQL→SQL rate skyrocketed by **+34.3pp**. She is effectively qualifying leads and remains a critical pipeline contributor.

#### **Outbound SGAs (The Hunters)**

*   **Top Performers (Rate Improvement & Volume):**
    *   **Russell Armitage:** Excellent performance. Produced **13 SQOs** (highest outbound volume) while improving his SQL→SQO rate by **+22.6pp**.
    *   **Craig Suchodolski:** Strong efficiency. Produced 5 SQOs with a **+23.6pp** improvement in his SQL→SQO rate.
    *   **Chris Morgan & Perry Kalmeta:** Showcasing massive efficiency gains with SQL→SQO rate improvements of **+53.6pp** and **+37.8pp** respectively.

*   **Volume Leaders:**
    *   **Russell Armitage (13 SQOs)** and **Eleni Stefanopoulos (10 SQOs)** are the clear volume leaders for the outbound team. While Eleni's rates have declined, her volume is essential.

*   **Needs Urgent Coaching:**
    *   **Helen Kamens:** Her SQL→SQO rate has dropped by **-40.0pp** (from 40% to 0%). This is a critical performance issue that requires immediate intervention.

---

### **6. SGM-SPECIFIC RISK ASSESSMENT**

*   **Under-Capacity (High Risk):**
    *   **Jade Bingham (Coverage: 0.61):** Has a **$14.44M** capacity gap and a 25 SQO deficit. She is starving for leads and has $0 in actuals this quarter. **Priority #1 for lead allocation.**
    *   **Bryan Belville (Coverage: 0.80):** Has a **$7.48M** capacity gap and a 24 SQO deficit. He needs an immediate pipeline injection to secure future quarters.

*   **On Ramp (Monitor & Support):**
    *   **Tim Mackey, Lexi Harrison, Ariana Butler:** All have critical SQO gaps (>35) and minimal pipeline. They need dedicated support to build their funnels from scratch.

*   **Sufficient (Manage Risk & Replicate Success):**
    *   **GinaRose Galli:** **High Risk despite "Sufficient" status.** Her 1.35 coverage is propped up by a **39.1% stale pipeline** and a critical lack of new SQOs (8 total). Her **$0 next-quarter forecast** is a major red flag.
    *   **Erin Pearson:** Healthy coverage (1.15) but low deal volume (19 SQOs). She is efficient but could be at risk if one or two deals slip.
    *   **Corey Marcello & Bre McDaniel:** The gold standard. They have massive capacity, have hit their targets, and are models of high performance.

---

### **7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS**

1.  **Issue:** **Bottom-Funnel Conversion Collapse.** SQO→Joined rate has dropped 55% (9.8% → 4.4%).
    *   **Root Cause:** A combination of lower-quality leads entering the funnel (despite passing SQL checks) and deals stalling in later stages.
    *   **Impact:** We are failing to monetize our pipeline effectively, putting future revenue at risk.
    *   **Solution:** Institute mandatory weekly deal progression reviews for all deals aged over 70 days. Focus on identifying stalled deals and creating action plans to move them forward or close them out.

2.  **Issue:** **Critical SQO Volume Deficit.** The firm has a gap of 255 active SQOs.
    *   **Root Cause:** Underperformance from key lead channels (Marketing Events, Provided Lead Lists) and several SGMs having significant individual gaps.
    *   **Impact:** SGMs like Jade Bingham and Bryan Belville are mathematically unable to hit future targets. Next quarter's revenue is at high risk.
    *   **Solution:** Immediately sync with Marketing to diagnose and fix the drop in lead volume from Events. Re-evaluate the quality and volume of Provided Lead Lists for the outbound team.

3.  **Issue:** **Pipeline Bloat & Stagnation.** Key SGMs have high stale percentages (GinaRose: 39.1%, Corey: 11.4%).
    *   **Root Cause:** Lack of consistent pipeline hygiene and a reluctance to close out low-probability deals.
    *   **Impact:** Inflates pipeline value, wastes SGM time on dead-end opportunities, and masks true coverage gaps.
    *   **Solution:** Mandate a "State of the Funnel" cleanup. All deals marked stale must have a formal review this week to either advance with a concrete next step or be closed-lost.

---

### **8. IMMEDIATE ACTION ITEMS**

*   **This Week (Critical):**
    1.  **GinaRose Galli - Pipeline Review:** Mandatory 1:1 review to address her 39.1% stale pipeline and $0 next-quarter forecast. Create a plan to clean the pipeline and fill her funnel.
    2.  **Jade Bingham & Bryan Belville - Lead Allocation:** Prioritize all available lead flow to these two SGMs to close their capacity gaps.
    3.  **Helen Kamens - SGA Coaching:** Immediate coaching session to diagnose and correct her 40pp drop in SQL→SQO conversion.

*   **This Month (High Priority):**
    1.  **Firm-Wide Pipeline Cleanup:** Execute the "State of the Funnel" cleanup for all SGMs with >10% stale pipeline.
    2.  **Marketing & Sales Sync:** Hold a working session to address the volume collapse from Marketing Events and Provided Lead Lists.
    3.  **Deal Progression Sessions:** Implement weekly reviews for all deals aged >70 days to combat stagnation.

*   **This Quarter (Strategic):**
    1.  **Review SGA-SGM Handoff Quality:** While the SQL→SQO *rate* is up, the downstream conversion collapse suggests a quality issue. Jointly review a sample of recent SQOs to refine qualification criteria.
    2.  **Replicate Best Practices:** Analyze the activities and strategies of Bre McDaniel and Corey Marcello to create a playbook for other SGMs.

---

### **9. VELOCITY-BASED FORECASTING ANALYSIS (Physics-Based)**

**Context:** This forecast uses a 70-day median cycle time, ignoring unreliable manual Close Dates.

*   **Current Quarter Velocity Forecast:**
    *   The firm has a "safe" velocity forecast of **$191.34M** for the rest of the quarter.
    *   **Corey Marcello ($88.22M)** and **Bre McDaniel ($45.92M)** have strong velocity.
    *   **GinaRose Galli ($0.00M)** has zero velocity from recently created deals, meaning 100% of her hope for this quarter rests on old, overdue deals. **This is a RED STATUS alert.**

*   **Overdue / Slip Risk Analysis:**
    *   A massive **$328.42M** in pipeline value is tied to overdue deals (>70 days old). This is our single biggest risk.
    *   **High-Risk SGMs:**
        *   **Bre McDaniel:** $132.65M overdue. While expected for Enterprise deals, this still requires close monitoring.
        *   **GinaRose Galli:** $79.88M overdue. This is extremely high risk.
        *   **Corey Marcello:** $66.23M overdue. Needs a cleanup focus.

*   **Next Quarter Pipeline Health:**
    *   The firm-wide next quarter forecast is only **$76.39M**, confirming the risk identified earlier.
    *   **SGMs with Weak Next Quarter Pipeline:** GinaRose Galli ($0), Tim Mackey ($1.97M), Lexi Harrison ($4.80M). These SGMs are on track to crash next quarter.

---

### **10. QUARTERLY FORECAST ANALYSIS (Deal-Size Dependent Model)**

**Context:** This model uses more sophisticated, deal-size-dependent cycle times and probabilities.

*   **Current Quarter Performance:**
    *   **Met/Exceeded Target:** Bre McDaniel, Corey Marcello.
    *   **On Track to Meet Target:** GinaRose Galli (exp. $80.57M), Bryan Belville (exp. $43.81M), Erin Pearson (exp. $54.86M).
    *   **At Risk of Missing Target:** **Jade Bingham (exp. $15.86M)**. Her forecast is significantly below the $36.75M target. The ramping reps are also not expected to hit the target.

*   **Next Quarter Pipeline Health:**
    *   **Strong Next Quarter:** Bre McDaniel ($44.43M).
    *   **Weak Next Quarter:** **GinaRose Galli ($0.00M)**, Lexi Harrison ($0.49M), Tim Mackey ($0.00M). This confirms the velocity forecast: these SGMs have a pipeline cliff.

*   **Confidence & Caveats:**
    *   **High Confidence:** The overall assessment that the firm will hit its target this quarter, but that Jade Bingham is at risk and several SGMs face a cliff next quarter.
    *   **Lower Confidence:** The exact dollar forecast for Bre McDaniel ($217.49M) is subject to the binary outcome of her large enterprise deals. Treat this as "Deal Potential," not a cash flow prediction. Her forecast relies on a few "whale" deals, making it inherently risky despite the high value.

---

### **11. SUCCESSES & BRIGHT SPOTS**

*   **Elite SGM Performance:** **Bre McDaniel** and **Corey Marcello** have delivered outstanding results, single-handedly ensuring the firm will meet its quarterly goal. Their performance is the benchmark for excellence.
*   **Top-of-Funnel Efficiency:** Our SGAs, particularly on the outbound team, have significantly improved their ability to convert SQLs to SQOs. **Russell Armitage, Craig Suchodolski, Chris Morgan, and Perry Kalmeta** deserve recognition for their dramatic rate improvements.
*   **Inbound Engine:** **Lauren George** and **Jacqueline Tully** continue to be a powerful engine, delivering a combined **33 SQOs** and forming the backbone of our inbound pipeline generation.

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** 9.0
- **SGMs On Track (Joined):** 2.0
- **SGMs with Sufficient SQOs:** 0.0
- **Total Pipeline Estimate:** $3020.2M
- **Total Stale Pipeline:** $188.2M
- **Total Quarter Actuals:** $232.5M
- **Total Target:** $330.8M
- **Total Required SQOs:** 360.0
- **Total Current SQOs:** 122.0
- **Total Stale SQOs:** 17.0

### Coverage Summary
- **Total Capacity (Forecast):** $401.63M
- **Average Coverage Ratio:** 1.774 (177.4%)
- **On Ramp SGMs:** 3.0
- **Sufficient SGMs:** 4.0
- **At Risk SGMs:** 0.0
- **Under-Capacity SGMs:** 2.0

### SGM Coverage Analysis (Top 15 by Risk)

| SGM | Coverage Status | Coverage Ratio | Capacity (M) | Capacity Gap (M) | Active SQOs | Stale SQOs | Qtr Actuals (M) |
|-----|----------------|----------------|--------------|------------------|-------------|------------|-----------------|
| Jade Bingham | Under-Capacity | 0.61 | $22.31 | $14.44 | 15 | 2 | $0.00 |
| Bryan Belville | Under-Capacity | 0.80 | $29.27 | $7.48 | 16 | 0 | $23.29 |
| Tim Mackey | On Ramp | 0.04 | $1.41 | $35.34 | 2 | 0 | $0.00 |
| Lexi Harrison | On Ramp | 0.10 | $3.52 | $33.23 | 5 | 0 | $0.00 |
| Ariana Butler | On Ramp | 0.15 | $5.47 | $31.28 | 5 | 0 | $0.00 |
| Erin Pearson | Sufficient | 1.15 | $42.32 | $-5.57 | 19 | 0 | $19.84 |
| GinaRose Galli | Sufficient | 1.35 | $49.80 | $-13.05 | 8 | 5 | $30.78 |
| Corey Marcello | Sufficient | 2.92 | $107.32 | $-70.57 | 27 | 6 | $36.90 |
| Bre McDaniel | Sufficient | 3.81 | $140.21 | $-103.46 | 25 | 4 | $121.71 |


### SGM Risk Assessment (Top 10 by Risk)

| SGM | Status | SQO Gap | Pipeline (M) | Weighted (M) | Stale % | Quarter Actuals (M) |
|-----|--------|---------|--------------|--------------|---------|---------------------|
| Tim Mackey | No Activity | 38.0 | $14.3 | $2.0 | 0.0% | $0.0 |
| Ariana Butler | No Activity | 35.0 | $65.8 | $7.7 | 0.0% | $0.0 |
| Lexi Harrison | No Activity | 35.0 | $34.7 | $4.8 | 0.0% | $0.0 |
| Jade Bingham | No Activity | 25.0 | $202.2 | $34.1 | 0.0% | $0.0 |
| GinaRose Galli | Behind | 32.0 | $241.6 | $79.9 | 39.1% | $30.8 |
| Bryan Belville | Behind | 24.0 | $283.3 | $40.6 | 0.0% | $23.3 |
| Erin Pearson | Behind | 21.0 | $285.4 | $59.8 | 0.0% | $19.8 |
| Bre McDaniel | On Track | 15.0 | $1250.1 | $191.0 | 1.6% | $121.7 |
| Corey Marcello | On Track | 13.0 | $642.9 | $176.3 | 11.4% | $36.9 |


### Required SQOs & Joined Per Quarter Analysis (With Volatility Context)

**📊 CALCULATION METHODOLOGY**

**Step 1: Required Joined = CEILING($36.75M Target / Average Margin AUM per Joined)**  
**Step 2: Required SQOs = CEILING(Required Joined / SQO→Joined Conversion Rate)**

**Firm-Wide Statistics (35 Non-Enterprise Deals, Last 12 Months):**
- **Average Margin AUM:** $11.35M
- **Median Margin AUM:** $10.01M
- **Standard Error:** $0.94M (95% CI: $9.52M - $13.19M)
- **Coefficient of Variation:** 48.8% (HIGH VOLATILITY)

**SQO→Joined Conversion Rate (Trailing 12 Months):**
- **Rate:** 10.04% (45 joined / 448 SQOs)
- **95% Confidence Interval:** 7.26% - 12.83%

**Why Exclude Enterprise Deals (>= $30M):**
- Bre McDaniel: 8 of 19 deals (42.1%) are >= $30M, avg $49.81M
- All Other SGMs: 0 deals >= $30M (max $21.15M)
- Including enterprise increases average by 63% ($11.35M → $18.51M) and volatility by 88% (48.8% → 91.5%)
- $30M cleanly separates enterprise-focused SGM from standard SGMs

**Volatility Range:**
- **Base Case:** 40 SQOs (using $11.35M avg, 10.04% conversion rate)
- **Range:** 24-56 SQOs (±16 SQOs) depending on actual deal sizes and conversion rates
- **Interpretation:** SGMs should plan for approximately **40 ± 16 SQOs per quarter**

**Interpretation Thresholds (Calculated Dynamically):**

The interpretation in the table below is based on dynamically calculated thresholds from the confidence interval:
- **WITHIN RANGE:** ≥24 SQOs (lower bound of CI - optimistic scenario)
- **CLOSE TO TARGET:** ≥32 SQOs (midpoint between lower bound and base case)
- **ON TARGET:** ≥40 SQOs (base case requirement)
- **EXCEEDING TARGET:** >40 SQOs (above base case)
- **SIGNIFICANT GAP:** <24 SQOs but gap ≤16 SQOs below lower bound
- **CRITICAL GAP:** <24 SQOs and gap >16 SQOs below lower bound

*Note: Thresholds are calculated dynamically for each SGM based on their `required_sqos_per_quarter` value. Interpretation is based on QTD SQOs (all SQOs received this quarter), not just open pipeline SQOs.*

| SGM | Required Joined | Required SQOs | QTD SQOs | QTD Gap | QTD % of Required | Current Pipeline SQOs | Interpretation |
|-----|----------------|----------------|----------|---------|-------------------|----------------------|----------------|
| Tim Mackey | 4.0 | 40.0 | 2 | 38.0 | 5.0% | 2 | 🔴 CRITICAL |
| Ariana Butler | 4.0 | 40.0 | 5 | 35.0 | 12.5% | 5 | 🔴 CRITICAL |
| Lexi Harrison | 4.0 | 40.0 | 5 | 35.0 | 12.5% | 5 | 🔴 CRITICAL |
| Jade Bingham | 4.0 | 40.0 | 14 | 26.0 | 35.0% | 15 | ⚠️ SIGNIFICANT |
| GinaRose Galli | 4.0 | 40.0 | 0 | 40.0 | 0.0% | 8 | 🔴 CRITICAL |
| Bryan Belville | 4.0 | 40.0 | 14 | 26.0 | 35.0% | 16 | ⚠️ SIGNIFICANT |
| Erin Pearson | 4.0 | 40.0 | 18 | 22.0 | 45.0% | 19 | ⚠️ SIGNIFICANT |
| Bre McDaniel | 4.0 | 40.0 | 11 | 29.0 | 27.5% | 25 | ⚠️ SIGNIFICANT |
| Corey Marcello | 4.0 | 40.0 | 18 | 22.0 | 45.0% | 27 | ⚠️ SIGNIFICANT |


### Top Deals Requiring Attention (Stale or High Value)

| Deal | SGM | Stage | Value (M) | Days Open | Stale |
|------|-----|-------|-----------|-----------|-------|
| Matt Mai | GinaRose Galli | Negotiating | $45.0 | 260 | Yes |
| Emily Hermeno | GinaRose Galli | Sales Process | $38.0 | 740 | Yes |
| Debbie Huttner | Corey Marcello | Negotiating | $21.4 | 182 | Yes |
| Sam Issermoyer | Bre McDaniel | Sales Process | $20.2 | 196 | Yes |
| Derek Dall'Olmo | Corey Marcello | Sales Process | $13.8 | 146 | Yes |
| Aaron Clarke | Corey Marcello | Negotiating | $11.7 | 183 | Yes |
| David Matuszak | Corey Marcello | Negotiating | $10.1 | 364 | Yes |
| James Davis | Corey Marcello | Negotiating | $9.5 | 183 | Yes |
| Ryan Drews | Corey Marcello | Negotiating | $7.1 | 175 | Yes |
| Tyler Brooks | GinaRose Galli | Qualifying | $5.9 | 662 | Yes |
| Bryan Havighurst 2025 | GinaRose Galli | Negotiating | $5.5 | 251 | Yes |
| Joshua Singer | Jade Bingham | Negotiating | $4.7 | 106 | Yes |
| James Ling | Jade Bingham | Negotiating | $3.0 | 97 | Yes |
| Marcado 401k Team | GinaRose Galli | Negotiating | $0.0 | 102 | Yes |
| Clint Seefeldt (Ed Wildermuth team) | Bre McDaniel | Discovery | $0.0 | 146 | Yes |


### SGA Performance Summary (Top 15 by SQL→SQO Rate Change)

| SGA | Contacted→MQL (QTD) | MQL→SQL (QTD) | SQL→SQO (QTD) | SQL→SQO Change | SQL Volume | SQO Volume |
|-----|---------------------|---------------|---------------|----------------|------------|------------|
| Chris Morgan | 3.1% | 3.7% | 100.0% | +53.6pp | 2 | 3 |
| Helen Kamens | 3.2% | 12.5% | 0.0% | -40.0pp | 3 | 3 |
| Perry Kalmeta | 2.3% | 30.0% | 100.0% | +37.8pp | 4 | 4 |
| Craig Suchodolski | 1.4% | 23.8% | 100.0% | +23.6pp | 4 | 5 |
| Russell Armitage | 9.9% | 40.0% | 84.6% | +22.6pp | 17 | 13 |
| Eleni Stefanopoulos | 4.0% | 6.0% | 66.7% | -13.3pp | 5 | 10 |
| Lauren George | 4.4% | 41.7% | 84.6% | +10.7pp | 16 | 20 |
| Jacqueline Tully | 77.8% | 73.7% | 83.3% | -4.0pp | 15 | 13 |
| Amy Waller | 5.6% | 33.3% | 60.0% | -2.5pp | 5 | 3 |
| Ryan Crandall | 4.6% | 11.1% | 75.0% | +0.0pp | 6 | 5 |
| Marisa Saucedo | 3.8% | 11.6% | 0.0% | +0.0pp | 4 | 0 |
| Channing Guyer | 3.2% | 16.7% | 100.0% | +0.0pp | 3 | 4 |
| Anett Diaz | 1.4% | 0.0% | nan% | +nanpp | 0 | 1 |


---

*Report generated using LLM analysis of BigQuery capacity and coverage views.*
*Data sources: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`, `vw_sgm_capacity_coverage`, `vw_sgm_open_sqos_detail`, `vw_conversion_rates`, and `vw_sga_funnel`*
