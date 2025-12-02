# Capacity & Coverage Summary Report
Generated: 2025-11-21 12:14:08

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

Here is the comprehensive pipeline health diagnostic report.

***

### **TO:** Sales Leadership
### **FROM:** Revenue Operations Partner
### **DATE:** October 26, 2023
### **SUBJECT:** Q4 Pipeline Health Diagnostic & Action Plan

This report provides a "no-fluff" analysis of our current sales pipeline, highlighting immediate risks, opportunities, and a clear action plan to ensure we meet our targets for this quarter and the next.

---

### **1. EXECUTIVE DIAGNOSTIC (BLUF - Bottom Line Up Front)**

*   **Forecast Confidence:** **Medium**
    *   While overall capacity appears strong (2.28x coverage), this is misleading. Confidence is tempered by a significant **SQO→Joined conversion rate drop** (-5.2 pts), a massive **$337M in "Slip Risk"** from overdue deals, and a critical lead starvation issue for four SGMs. We have pockets of extreme health and extreme risk.

*   **The "Safe" List (Quarter Secured)**
| SGM | Status | Current Qtr Actuals | Expected EoQ | Why Safe |
| :--- | :--- | :--- | :--- | :--- |
| **Bre McDaniel** | Exceeded Target | $121.71M (331%) | $239.60M | Already 3x target. Massive enterprise pipeline. |
| **Corey Marcello** | Exceeded Target | $36.90M (100%) | $166.61M | Hit target with a robust pipeline to spare. |
| **Erin Pearson** | On Track | $19.84M (54%) | $70.01M | Strong capacity (1.64x) and forecast to double target. |
| **Bryan Belville** | On Track | $23.29M (63%) | $51.16M | Sufficient capacity (1.16x) and forecast to hit target. |

*   **The "Illusion" List (High Risk in Disguise)**
| SGM | Coverage Ratio | Risk Factor | Why Risky |
| :--- | :--- | :--- | :--- |
| **GinaRose Galli** | 1.13 (Sufficient) | **63.8% Stale Pipeline** | Her capacity is "fake pipeline." **$92.5M is overdue**, and her velocity forecast for this quarter is **$0.00**. She is not on track despite the coverage ratio. |
| **Tim Mackey** | 0.05 (On Ramp) | **75% Concentration Risk** | His entire pipeline hinges on a single $10.6M deal. This is a binary outcome; if it fails, he has nothing. |

*   **The "Emergency" List (Starving for Leads)**
| SGM | Coverage Ratio | Gap (M) | SQOs Needed | SQLs Needed | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Jade Bingham** | 0.75 | $19.86M | 25 | 41 | **🔴 CRITICAL** |
| **Lexi Harrison** | 0.17 | $32.64M | 38 | 38 | **🔴 CRITICAL** |
| **Tim Mackey** | 0.05 | $34.79M | 38 | 55 | **🔴 CRITICAL** |
| **Ariana Butler** | 0.20 | $35.12M | 38 | 48 | **🔴 CRITICAL** |

*   **Firm-Level Performance**
    The firm is on track to **exceed the target this quarter** (projected 188.7% attainment), driven by massive overperformance from Bre and Corey. However, **next quarter is at risk**, with four SGMs having a combined forecast gap of over $100M.

*   **Critical Alerts**
    1.  **Pipeline Bloat Crisis:** GinaRose Galli has **63.8% stale pipeline ($150M+)**, including deals over 700 days old. This requires immediate intervention.
    2.  **Lead Generation Emergency:** Four SGMs (Jade, Lexi, Tim, Ariana) are mathematically starving for leads. They need a combined **139 SQOs (182 SQLs)** routed to them immediately to have a chance this quarter.
    3.  **Conversion Funnel Leak:** The overall **SQO→Joined rate has dropped by 5.2 percentage points** (from 9.6% to 4.4%) in the last 90 days. This is a major threat to future quarters, indicating a potential decline in lead quality or deal execution.

---

### **2. CAPACITY & COVERAGE ANALYSIS**

*   **Current Quarter Readiness:** **2 of 9 SGMs (Bre McDaniel, Corey Marcello) have already exceeded their $36.75M target.** GinaRose ($30.8M), Bryan ($23.3M), and Erin ($19.8M) are close, but GinaRose's remaining pipeline is entirely stale.
*   **Next Quarter Readiness:** The pipeline for next quarter is a concern. While our total capacity of $519.3M seems high, the forecast shows four SGMs (Corey, Bryan, Erin, GinaRose) are already projected to miss their Q1 targets, with a combined gap of **$101.18M**. We are not building enough pipeline today to secure tomorrow.
*   **Firm-Wide Capacity Gap:** The firm has a capacity surplus of $188.5M, but this is dangerously concentrated with Bre and Corey. The core issue is distribution; we have the haves and the have-nots.
*   **Coverage Status Breakdown:**
    *   **Sufficient (5):** This number is misleading. GinaRose is included here but is high-risk.
    *   **Under-Capacity (1):** Jade Bingham is the sole SGM in this category and needs immediate help.
    *   **On Ramp (3):** Tim, Lexi, and Ariana are significantly behind where they should be in pipeline generation.

---

### **3. SQO PIPELINE DIAGNOSIS**

*   **Quantity Analysis:** We have a firm-wide active SQO gap of **288**. The pipeline is not being fed at the required rate. This is most acute for the four SGMs on the "Emergency" list, who collectively have a pipeline SQO gap of **166**.
*   **Quality Analysis:** Overall pipeline hygiene is decent at 8.3% stale. However, this average masks a critical problem: **GinaRose Galli's pipeline is 63.8% stale**, accounting for the majority of the firm's stale value. Her deals like *Emily Hermeno* (743 days) and *Matt Mai* (263 days) are clogging the forecast.
*   **Root Cause Analysis:**
    *   **SGA Perspective:** The data shows a significant drop in SQL volume from key outbound sources like "Provided Lead List" (8 SQLs this Q vs. 42 avg). This suggests a potential issue at the very top of the funnel for SGAs.
    *   **SGM Perspective:** The firm-wide SQO→Joined rate has halved. This points to a potential issue in SGM deal execution or a drop in the quality of SQOs being accepted. The high stale rate for specific SGMs (GinaRose, Corey) indicates a lack of pipeline management and qualification discipline.
    *   **Collaborative Factors:** The drop in both top-of-funnel volume and bottom-of-funnel conversion suggests a systemic issue. We need a joint SGA-SGM session to realign on lead quality definitions and review the handoff process.

---

### **3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)**

**CRITICAL CONTEXT:** The "Required SQOs" metric is directional guidance, not a precise target. It's based on a firm-wide average deal size of $11.35M, but this data is **highly volatile** (Coefficient of Variation: 48.8%). The actual range is $3.75M to $23.09M. This means an SGM closing larger deals needs fewer SQOs, while one closing smaller deals needs more.

| SGM | Required SQOs | Current Pipeline SQOs | SQO Gap | Pipeline % of Required | Interpretation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tim Mackey** | 50 | 2 | 48 | 4% | 🔴 **CRITICAL GAP** |
| **Ariana Butler** | 50 | 5 | 45 | 10% | 🔴 **CRITICAL GAP** |
| **Lexi Harrison** | 50 | 7 | 43 | 14% | 🔴 **CRITICAL GAP** |
| **GinaRose Galli** | 50 | 7 | 43 | 14% | 🔴 **CRITICAL GAP** |
| **Jade Bingham** | 50 | 13 | 37 | 26% | 🔴 **CRITICAL GAP** |
| **Bryan Belville** | 50 | 19 | 31 | 38% | ⚠️ **SIGNIFICANT GAP** |
| **Erin Pearson** | 50 | 19 | 31 | 38% | ⚠️ **SIGNIFICANT GAP** |
| **Corey Marcello** | 50 | 27 | 23 | 54% | 🟡 **MODERATE GAP** |
| **Bre McDaniel** | 13 | 26 | -13 | 200% | ✅ **EXCEEDING TARGET** |

**Analysis:**
*   The five SGMs with "Critical Gaps" are mathematically unable to hit future targets without immediate, high-volume lead flow. Their current pipeline SQO count is less than half of what's needed to stay on track.
*   Bre McDaniel's success highlights the model's limitation. Her enterprise focus means she needs fewer, larger deals, which she is successfully managing.

---

### **4. CONVERSION RATE ANALYSIS & TRENDS**

**METHODOLOGY NOTE:** SQO→Joined rates use a 90-day lookback for accuracy, reflecting the 77-day average sales cycle.

*   **Overall Trends:**
    *   **SQL→SQO Rate (Good News):** Up +7.8 pts this quarter. The handoff from SGA to SGM is becoming more efficient.
    *   **SQO→Joined Rate (Bad News):** Down -5.2 pts (from 9.6% to 4.4%). This is a **major red flag**. We are qualifying deals that are not closing, indicating a potential lead quality or sales process issue.
*   **Channel Performance:**
    *   **Recruitment Firm:** SQO→Joined rate has plummeted from 10.0% to 0.0%.
    *   **Marketing / Re-Engagement:** SQO→Joined rate has halved from 11.5% to 5.6%.
*   **Diagnostic Insights:** The combination of a higher SQL→SQO rate and a lower SQO→Joined rate is classic "garbage in, garbage out." We are efficiently accepting more leads that are less likely to close. This points to a need for tighter qualification criteria at the SGA-to-SGM handoff. The issue is likely a combination of lead quality from certain sources and potentially less rigorous qualification by SGMs.

---

### **5. SGA PERFORMANCE ANALYSIS**

**CRITICAL SEGMENTATION:** Inbound (Lauren, Jacqueline) and Outbound SGAs are analyzed separately.

*   **Inbound SGAs (The Feeders):**
    *   **Top Performer:** **Lauren George** is a standout. Her SQL→SQO rate is up **+11.6 pts**, and she is the top volume producer with **21 SQOs**.
    *   **Volume Leader:** **Jacqueline Tully** remains a critical contributor with **13 SQOs**. While her conversion rate dipped slightly, her high volume is essential.
    *   **Inbound Health:** **Healthy.** Our inbound engine is performing well, with both SGAs delivering high volume.

*   **Outbound SGAs (The Hunters):**
    *   **Top Performers (Rate & Volume):**
        *   **Russell Armitage:** Excellent performance. SQL→SQO rate is up **+22.2 pts** with strong volume (**14 SQOs**).
        *   **Chris Morgan, Craig Suchodolski, Perry Kalmeta:** All show massive rate improvements (**+48.4, +23.2, +37.8 pts** respectively) and are becoming highly efficient.
    *   **Needing Coaching (Declining Rates & Low Volume):**
        *   **Ryan Crandall:** SQL→SQO rate is down **-16.7 pts** with only 3 SQOs. **Urgent coaching needed.**
        *   **Amy Waller:** SQL→SQO rate is down **-6.7 pts** with only 4 SQOs. **Urgent coaching needed.**

---

### **6. SGM-SPECIFIC RISK ASSESSMENT**

*   **Under-Capacity (Coverage < 0.85):**
    *   **Jade Bingham (0.75):** She is **$9.1M short on capacity** and has a **$19.86M forecast gap** for this quarter. She needs leads immediately.
*   **On Ramp (Severe Under-Capacity):**
    *   **Tim Mackey (0.05), Lexi Harrison (0.17), Ariana Butler (0.20):** These SGMs have negligible pipeline. They are effectively starting from zero and face massive capacity gaps ($34.8M, $30.4M, $29.2M respectively).
*   **Sufficient (But Risky):**
    *   **GinaRose Galli (1.13):** As noted, her "Sufficient" status is an illusion due to **63.8% stale pipeline**. Her forecast for the rest of the quarter is **$0**. She is at extreme risk of missing her number despite her on-paper capacity.

---

### **7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS**

1.  **Issue:** Critical lead starvation for 4 SGMs (Jade, Lexi, Tim, Ariana).
    *   **Root Cause:** Insufficient top-of-funnel lead generation and routing.
    *   **Impact:** **$122.4M in combined forecast gaps** for the current quarter. They cannot succeed without intervention.
    *   **Solution:** Immediately implement the routing plan from the "What-If Analysis" (Section 12). Prioritize all new SQLs to these four SGMs until their gaps are filled.

2.  **Issue:** GinaRose Galli's pipeline is 63.8% stale, creating "fake capacity."
    *   **Root Cause:** Lack of consistent pipeline management and failure to close/disqualify aged opportunities.
    *   **Impact:** Misleading forecast, wasted resources on dead deals, and a **$0 velocity forecast** for the current quarter.
    *   **Solution:** Mandate a pipeline review with GinaRose this week. Set a 14-day deadline to either advance or disqualify all deals older than 180 days.

3.  **Issue:** Firm-wide SQO→Joined conversion rate has dropped 52% (from 9.6% to 4.4%).
    *   **Root Cause:** Likely a combination of lower-quality leads being accepted into the pipeline and/or ineffective deal execution by SGMs.
    *   **Impact:** Threatens all future quarter attainment. Wasted effort on deals that won't close.
    *   **Solution:** Schedule a joint SGA-SGM meeting to review SQO criteria. Analyze wins/losses from the last 90 days to identify patterns in lead quality and sales process breakdowns.

---

### **8. IMMEDIATE ACTION ITEMS**

*   **This Week (Critical):**
    1.  **Re-route Leads:** Immediately divert all new SQLs to Jade Bingham, Lexi Harrison, Tim Mackey, and Ariana Butler per the routing plan.
    2.  **Mandatory Pipeline Review:** Schedule a mandatory 1:1 with GinaRose Galli to create a clean-up plan for her stale pipeline.
    3.  **Investigate Slip Risk:** Bre McDaniel and Corey Marcello must review their combined **$198M in overdue deals** and provide updated forecasts.

*   **This Month (High Priority):**
    1.  **Launch "Get Well" Plan:** Execute the full routing plan to fill the **139 SQO gap** for the four at-risk SGMs.
    2.  **Address Next-Quarter Gaps:** Begin routing leads to Corey, Bryan, Erin, and GinaRose to fill their projected Q1 gaps.
    3.  **SGA Coaching:** Implement targeted coaching for Ryan Crandall and Amy Waller to improve their conversion rates.

*   **This Quarter (Strategic):**
    1.  **Redefine SQO Criteria:** Host a workshop with top SGAs and SGMs to tighten the definition of a Sales Qualified Opportunity.
    2.  **Review Lead Sources:** Marketing and RevOps to analyze why channels like "Recruitment Firm" have seen a collapse in conversion and develop a plan to improve quality.

---

### **9. VELOCITY-BASED FORECASTING ANALYSIS**

This "physics-based" forecast uses a 70-day median cycle time, ignoring optimistic CRM close dates.

*   **Current Quarter Velocity Forecast:** The firm has a "safe" forecast of **$182.4M** for the rest of the quarter. However, this is heavily skewed by Corey ($85.9M) and Bre ($43.9M).
*   **Overdue / Slip Risk Analysis:**
    *   **CRITICAL ALERT:** We have **$337.3M in revenue at high risk of slipping**. These are deals older than 70 days that should have already closed.
    *   **High-Risk SGMs:**
        *   **Bre McDaniel:** $131.2M at risk. (Expected for enterprise, but requires active management).
        *   **GinaRose Galli:** $92.5M at risk. Her entire remaining pipeline is overdue.
        *   **Corey Marcello:** $66.7M at risk. Needs to clean up or accelerate these deals.
*   **Next Quarter Pipeline Health:** The next-quarter forecast of **$84.3M** is insufficient to cover the **$330.8M target** for the full team. This is a leading indicator of a weak Q1 start if we don't build pipeline now.

---

### **10. QUARTERLY FORECAST ANALYSIS**

This model uses deal-size dependent velocity for a more accurate forecast.

*   **Current Quarter Performance:**
    *   **Met/Exceeded:** Bre McDaniel ($121.7M), Corey Marcello ($36.9M).
    *   **On Track to Meet Target:** GinaRose ($72.2M), Erin ($70.0M), Bryan ($51.2M). **WARNING:** GinaRose's forecast is entirely dependent on closing her ancient, stale deals, making it highly unreliable.
    *   **At Risk of Missing Target:** Jade Bingham (exp. $16.9M), Lexi Harrison (exp. $4.1M), Tim Mackey (exp. $1.96M), Ariana Butler (exp. $1.6M).
*   **Next Quarter Pipeline Health:**
    *   **Weak Pipeline:** GinaRose ($0), Erin ($9.9M), Bryan ($14.6M), and Corey ($21.3M) are all projected to start next quarter with a significant pipeline deficit. This needs to be addressed now.
    *   **Strong Pipeline:** Bre McDaniel ($62.8M) is building a healthy pipeline for next quarter.

---

### **11. SUCCESSES & BRIGHT SPOTS**

*   **Enterprise Excellence:** Bre McDaniel continues to demonstrate mastery of the enterprise sales cycle, having already tripled her quarterly target. Her pipeline is healthy and growing.
*   **Consistent High Performance:** Corey Marcello has already hit his number and maintains a massive pipeline, showing consistent execution.
*   **SGA Rising Stars:** The significant improvement in SQL→SQO conversion from outbound SGAs like **Russell Armitage, Chris Morgan, Craig Suchodolski, and Perry Kalmeta** is a huge win. Their increased efficiency is a model for the rest of the team.
*   **Inbound Engine is Strong:** Lauren George and Jacqueline Tully are reliably feeding the top of the funnel with high volume, providing a stable foundation for the SGMs.

---

### **12. WHAT-IF ANALYSIS: SQO & SQL ROUTING RECOMMENDATIONS**

This is our data-driven plan to close pipeline gaps.

*   **Priority 1: Current Quarter Gaps (Route SQLs Immediately)**
| SGM | Gap to Target | SQOs Needed | SQLs Needed |
| :--- | :--- | :--- | :--- |
| **Tim Mackey** | $34.79M | 38 | 55 |
| **Ariana Butler** | $35.12M | 38 | 48 |
| **Lexi Harrison** | $32.64M | 38 | 38 |
| **Jade Bingham** | $19.86M | 25 | 41 |
| **TOTAL** | **$122.41M** | **139** | **182** |

*   **Priority 2: Next Quarter Gaps (Begin Routing This Month)**
| SGM | Gap to Target | SQOs Needed | SQLs Needed |
| :--- | :--- | :--- | :--- |
| **GinaRose Galli** | $36.75M | 50 | 104 |
| **Erin Pearson** | $26.80M | 38 | 46 |
| **Bryan Belville** | $22.15M | 25 | 34 |
| **Corey Marcello** | $15.48M | 25 | 32 |
| **TOTAL** | **$101.18M** | **138** | **216** |

**Routing Strategy:**
1.  **Immediate Action:** All unassigned SQLs for the next 2-3 weeks must be routed to the "Priority 1" group.
2.  **Sustained Action:** Once Priority 1 SGMs show pipeline recovery, begin blending in routing to the "Priority 2" group to build their Q1 pipeline.
3.  **SGA Capacity:** This requires a total of **398 SQLs**. Leadership must confirm with SGA management if this volume is feasible and align top performers to support the highest-priority SGMs.

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** 9.0
- **SGMs On Track (Joined):** 2.0
- **SGMs with Sufficient SQOs:** 1.0
- **Total Pipeline Estimate:** $3077.2M
- **Total Stale Pipeline:** $256.4M
- **Total Quarter Actuals:** $232.5M
- **Total Target:** $330.8M
- **Total Required SQOs:** 413.0
- **Total Current SQOs:** 125.0
- **Total Stale SQOs:** 18.0

### Coverage Summary
- **Total Capacity (Forecast):** $519.28M
- **Average Coverage Ratio:** 2.283 (228.3%)
- **On Ramp SGMs:** 3.0
- **Sufficient SGMs:** 5.0
- **At Risk SGMs:** 0.0
- **Under-Capacity SGMs:** 1.0

### SGM Coverage Analysis (Top 15 by Risk)

| SGM | Coverage Status | Coverage Ratio | Capacity (M) | Capacity Gap (M) | Active SQOs | Stale SQOs | Qtr Actuals (M) |
|-----|----------------|----------------|--------------|------------------|-------------|------------|-----------------|
| Jade Bingham | Under-Capacity | 0.75 | $27.65 | $9.10 | 13 | 2 | $0.00 |
| Tim Mackey | On Ramp | 0.05 | $1.96 | $34.79 | 2 | 0 | $0.00 |
| Lexi Harrison | On Ramp | 0.17 | $6.39 | $30.36 | 7 | 1 | $0.00 |
| Ariana Butler | On Ramp | 0.20 | $7.52 | $29.23 | 5 | 0 | $0.00 |
| GinaRose Galli | Sufficient | 1.13 | $41.45 | $-4.70 | 7 | 5 | $30.78 |
| Bryan Belville | Sufficient | 1.16 | $42.48 | $-5.73 | 19 | 0 | $23.29 |
| Erin Pearson | Sufficient | 1.64 | $60.11 | $-23.36 | 19 | 0 | $19.84 |
| Corey Marcello | Sufficient | 4.11 | $150.98 | $-114.23 | 27 | 6 | $36.90 |
| Bre McDaniel | Sufficient | 4.92 | $180.74 | $-143.99 | 26 | 4 | $121.71 |


### SGM Risk Assessment (Top 10 by Risk)

| SGM | Status | SQO Gap | Pipeline (M) | Weighted (M) | Stale % | Quarter Actuals (M) |
|-----|--------|---------|--------------|--------------|---------|---------------------|
| Tim Mackey | No Activity | 48.0 | $14.2 | $2.0 | 0.0% | $0.0 |
| Ariana Butler | No Activity | 45.0 | $65.5 | $7.5 | 0.0% | $0.0 |
| Lexi Harrison | No Activity | 43.0 | $52.3 | $6.9 | 11.3% | $0.0 |
| Jade Bingham | No Activity | 37.0 | $187.9 | $29.3 | 3.8% | $0.0 |
| GinaRose Galli | Behind | 43.0 | $234.9 | $92.5 | 63.8% | $30.8 |
| Bryan Belville | Behind | 31.0 | $323.9 | $42.5 | 0.0% | $23.3 |
| Erin Pearson | Behind | 31.0 | $284.7 | $60.1 | 0.0% | $19.8 |
| Corey Marcello | On Track | 23.0 | $640.7 | $174.3 | 11.4% | $36.9 |
| Bre McDaniel | On Track | -13.0 | $1273.1 | $189.0 | 1.6% | $121.7 |


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
| Tim Mackey | 4.0 | 50.0 | 2 | 48.0 | 4.0% | 2 | 🔴 CRITICAL |
| Ariana Butler | 4.0 | 50.0 | 5 | 45.0 | 10.0% | 5 | 🔴 CRITICAL |
| Lexi Harrison | 4.0 | 50.0 | 6 | 44.0 | 12.0% | 7 | 🔴 CRITICAL |
| Jade Bingham | 4.0 | 50.0 | 17 | 33.0 | 34.0% | 13 | 🔴 CRITICAL |
| GinaRose Galli | 4.0 | 50.0 | 0 | 50.0 | 0.0% | 7 | 🔴 CRITICAL |
| Bryan Belville | 4.0 | 50.0 | 17 | 33.0 | 34.0% | 19 | 🔴 CRITICAL |
| Erin Pearson | 4.0 | 50.0 | 18 | 32.0 | 36.0% | 19 | ⚠️ SIGNIFICANT |
| Corey Marcello | 4.0 | 50.0 | 18 | 32.0 | 36.0% | 27 | ⚠️ SIGNIFICANT |
| Bre McDaniel | 2.0 | 13.0 | 12 | 1.0 | 92.3% | 26 | 🟡 CLOSE |


### Top Deals Requiring Attention (Stale or High Value)

| Deal | SGM | Stage | Value (M) | Days Open | Stale |
|------|-----|-------|-----------|-----------|-------|
| Tony Parrish 2025 | GinaRose Galli | Negotiating | $61.5 | 242 | Yes |
| Matt Mai | GinaRose Galli | Negotiating | $45.0 | 263 | Yes |
| Emily Hermeno | GinaRose Galli | Sales Process | $37.9 | 743 | Yes |
| Debbie Huttner | Corey Marcello | Negotiating | $21.3 | 185 | Yes |
| Sam Issermoyer | Bre McDaniel | Sales Process | $20.1 | 199 | Yes |
| Derek Dall'Olmo | Corey Marcello | Sales Process | $13.7 | 149 | Yes |
| Aaron Clarke | Corey Marcello | Negotiating | $11.7 | 186 | Yes |
| David Matuszak | Corey Marcello | Negotiating | $10.1 | 367 | Yes |
| James Davis | Corey Marcello | Negotiating | $9.5 | 186 | Yes |
| Ryan Drews | Corey Marcello | Negotiating | $7.1 | 178 | Yes |
| Tyler Brooks | Lexi Harrison | Qualifying | $5.9 | 665 | Yes |
| Bryan Havighurst 2025 | GinaRose Galli | Negotiating | $5.4 | 254 | Yes |
| Erwin M Matthews, CPA/PFS | Jade Bingham | Sales Process | $4.3 | 162 | Yes |
| James Ling | Jade Bingham | Negotiating | $3.0 | 100 | Yes |
| Marcado 401k Team | GinaRose Galli | Negotiating | $0.0 | 105 | Yes |


### SGA Performance Summary (Top 15 by SQL→SQO Rate Change)

| SGA | Contacted→MQL (QTD) | MQL→SQL (QTD) | SQL→SQO (QTD) | SQL→SQO Change | SQL Volume | SQO Volume |
|-----|---------------------|---------------|---------------|----------------|------------|------------|
| Chris Morgan | 3.3% | 11.1% | 100.0% | +48.4pp | 5 | 6 |
| Perry Kalmeta | 3.3% | 21.4% | 100.0% | +37.8pp | 4 | 4 |
| Craig Suchodolski | 1.5% | 26.9% | 100.0% | +23.2pp | 5 | 6 |
| Russell Armitage | 8.6% | 40.0% | 84.6% | +22.2pp | 18 | 14 |
| Ryan Crandall | 4.9% | 9.8% | 50.0% | -16.7pp | 4 | 3 |
| Lauren George | 4.0% | 42.1% | 85.7% | +11.6pp | 17 | 21 |
| Amy Waller | 6.3% | 26.3% | 60.0% | -6.7pp | 6 | 4 |
| Eleni Stefanopoulos | 3.5% | 11.8% | 75.0% | -5.2pp | 6 | 11 |
| Jacqueline Tully | 53.8% | 73.7% | 83.3% | -4.0pp | 15 | 13 |
| Helen Kamens | 3.6% | 9.7% | 50.0% | +0.0pp | 4 | 4 |
| Marisa Saucedo | 3.7% | 11.1% | 0.0% | +0.0pp | 4 | 0 |
| Channing Guyer | 3.1% | 15.4% | 100.0% | +0.0pp | 3 | 5 |
| Anett Diaz | 1.4% | 0.0% | nan% | +nanpp | 0 | 1 |


### What-If Analysis: SQO & SQL Routing Recommendations

**Purpose:** Identify SGMs forecasted to miss targets and calculate routing needs to get them back on track.

| SGM | Current Qtr Gap (M) | SQOs Needed (CQ) | SQLs Needed (CQ) | Next Qtr Gap (M) | SQOs Needed (NQ) | SQLs Needed (NQ) | Priority |
|-----|---------------------|------------------|------------------|------------------|------------------|------------------|----------|
| Jade Bingham | $19.86 | 25 | 41 | $25.98 | 38 | 62 | 🔴 HIGH |
| Lexi Harrison | $32.64 | 38 | 38 | $34.47 | 38 | 38 | 🔴 HIGH |
| Tim Mackey | $34.79 | 38 | 55 | $36.75 | 50 | 72 | 🔴 HIGH |
| Ariana Butler | $35.12 | 38 | 48 | $30.86 | 38 | 48 | 🔴 HIGH |
| Corey Marcello | $0.00 | 0 | 0 | $15.48 | 25 | 32 | 🟡 MEDIUM |
| Bryan Belville | $0.00 | 0 | 0 | $22.15 | 25 | 34 | 🟡 MEDIUM |
| Erin Pearson | $0.00 | 0 | 0 | $26.80 | 38 | 46 | 🟡 MEDIUM |
| GinaRose Galli | $0.00 | 0 | 0 | $36.75 | 50 | 104 | 🟡 MEDIUM |

| **TOTAL** | - | **139** | **182** | - | **302** | **436** | - |
| **GRAND TOTAL** | - | **441 SQOs** | **618 SQLs** | - | - | - | - |

**Legend:**
- **CQ** = Current Quarter
- **NQ** = Next Quarter
- **Priority:** 🔴 HIGH (current quarter gap >$10M), 🟡 MEDIUM (current quarter gap <$10M or next quarter gap >$10M), 🟢 LOW (next quarter gap <$10M)

**Calculation Methodology:**
1. **Gap Calculation:** Target ($36.75M) - Expected End of Quarter/Next Quarter
2. **Joined Needed:** CEILING(Gap / Average Margin AUM per Joined)
3. **SQOs Needed:** CEILING(Joined Needed / SQO→Joined Conversion Rate)
4. **SQLs Needed:** CEILING(SQOs Needed / SQL→SQO Conversion Rate)

**Note:** Uses enterprise metrics (365_average_margin_aum, 365_sqo_to_joined_conversion) for Bre McDaniel, standard metrics for all other SGMs.


---

*Report generated using LLM analysis of BigQuery capacity and coverage views.*
*Data sources: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`, `vw_sgm_capacity_coverage`, `vw_sgm_open_sqos_detail`, `vw_conversion_rates`, `vw_sga_funnel`, and `vw_sgm_capacity_coverage_with_forecast`*
