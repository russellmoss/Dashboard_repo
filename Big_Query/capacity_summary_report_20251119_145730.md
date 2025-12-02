# Capacity & Coverage Summary Report
Generated: 2025-11-19 14:57:30

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

Here is the comprehensive pipeline health diagnostic for sales leadership.

***

### **1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY**

**The Bottom Line:** We are on track to exceed our firm-level target *this quarter*, but this is a misleading indicator of health. Our success is dangerously concentrated, driven almost entirely by massive over-performance from Bre McDaniel and Corey Marcello, who have already hit their numbers. The rest of the team is struggling with a severe, firm-wide shortage of qualified opportunities (SQOs). Next quarter is at **high risk**. Our current pipeline velocity and volume are insufficient to sustain future targets.

**Funnel Bottleneck:** The primary bottleneck is at the **bottom of the funnel**. While our SGAs are converting leads to opportunities (SQL→SQO rate is up 7.2pp), our ability to close those opportunities is declining sharply (SQO→Joined rate is down 5.3pp in the last 90 days). This points to a potential issue in SGM deal progression, pipeline quality, or market headwinds affecting final-stage deals.

**Critical Alerts:**
1.  **Systemic SQO Starvation:** We have a firm-wide active SQO gap of 263 deals. Not a single SGM is meeting the minimum required SQO volume to ensure consistent future performance. This is a volume crisis, not an individual performance issue.
2.  **Plummeting Close Rate:** The 5.3 percentage point drop in our SQO→Joined conversion rate is the most alarming operational metric. It means we need significantly more pipeline just to achieve the same results as last year.
3.  **Concentrated Risk & Pipeline Bloat:** Two SGMs (Bre, Corey) account for the majority of our success and pipeline coverage. Furthermore, key reps like GinaRose Galli (37.6% stale) and Corey Marcello (11.4% stale) are carrying significant pipeline bloat, masking their true capacity and creating forecast risk.
4.  **Next Quarter Cliff:** Our velocity-based forecast for next quarter is only $80.88M, and the more detailed quarterly model shows that 6 of 9 SGMs have less than $13M forecasted for next quarter. This is a clear signal of an impending pipeline drought.

**Overall Assessment:** **At Risk.** While this quarter's numbers look strong on the surface, they are masking a systemic weakness in pipeline generation and conversion that will impact us severely next quarter if not addressed immediately.

### **2. CAPACITY & COVERAGE ANALYSIS**

**Context:** Capacity is a forward-looking measure of pipeline health, not a prediction of this quarter's revenue. It answers: "Do we have enough iron in the fire for future quarters?"

*   **Firm-Level Health Score:** The firm-wide Coverage Ratio is **2.37**, which appears exceptionally healthy. However, this is dangerously misleading. It is artificially inflated by Bre McDaniel (4.93) and Corey Marcello (4.13), whose massive pipelines mask deficiencies across the rest of the team.
*   **Current Quarter Readiness (Actuals):**
    *   **Target Exceeded:** 2 SGMs have already crossed the finish line.
        *   **Bre McDaniel:** $121.71M (331% of target)
        *   **Corey Marcello:** $36.90M (100% of target)
    *   **Close to Target:** GinaRose Galli is at 83.8% of her goal.
*   **Next Quarter Readiness (Capacity):** The outlook is poor. While five SGMs are technically "Sufficient," this capacity is threatened by low SQO volume and significant stale pipeline. The team is not structured for repeatable success next quarter.
*   **Coverage Status Breakdown:**
    *   **Sufficient (5):** Bre, Corey, Erin, GinaRose, Bryan. (Warning: GinaRose and Corey's capacity is bloated).
    *   **At Risk (0):** None.
    *   **Under-Capacity (1):** **Jade Bingham (0.81)** is mathematically starving for leads and cannot hit future targets without immediate pipeline injection.
    *   **On Ramp (3):** Tim, Lexi, and Ariana are building their pipelines as expected.

### **3. SQO PIPELINE DIAGNOSIS**

**Context:** We are analyzing the total open pipeline to ensure SGMs have enough opportunities to hit targets over time.

*   **Quantity Analysis (The Core Problem):** We have a critical volume shortage.
    *   **Firm-Wide SQO Gap (Total):** 246
    *   **Firm-Wide SQO Gap (Active Only):** **263**. This is the number that matters. We are missing 263 non-stale deals needed to fuel the engine for future quarters.
*   **Quality Analysis (Pipeline Hygiene):**
    *   **Firm-Wide Stale %:** 6.5%. This is healthy overall.
    *   **Hygiene Issues:** The problem is concentrated with specific reps who require immediate intervention.
        *   **GinaRose Galli:** **37.6% stale pipeline.** Unacceptable. This pipeline is bloated with dead deals, creating false confidence and wasting time.
        *   **Corey Marcello:** **11.4% stale pipeline.** Needs attention.
        *   **Lexi Harrison:** **11.3% stale pipeline.** Concerning for a ramping rep; bad habits are forming early.
*   **Root Cause Analysis:** The data suggests the SQO gap is not primarily an SGA sourcing issue. The SQL→SQO conversion rate is up, indicating SGAs are successfully creating qualified handoffs. The breakdown appears to be happening *after* the handoff, with deals stalling and a low overall SQO→Joined conversion rate. This points toward SGM pipeline management, deal progression challenges, or a mismatch in qualification criteria not caught at the handoff.

### **3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)**

**CRITICAL CONTEXT:** Our model suggests a baseline requirement of **41 SQOs per quarter** per SGM. However, this is based on highly volatile data (Coefficient of Variation: 48.8%). The actual requirement for an SGM to hit their target could be as low as 25 SQOs (if they close larger deals) or as high as 57 (if they close smaller deals). **Therefore, 41 is a directional guide, not a rigid target.**

**The bottom line is that not a single SGM has received enough SQOs this quarter to be within the acceptable volatility range.** This is a systemic lead flow and pipeline generation failure.

| SGM | QTD SQOs Received | Required SQOs (Base) | QTD Gap | % of Required | Interpretation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **GinaRose Galli** | 0 | 41 | 41 | 0% | 🔴 **CRITICAL GAP** |
| **Tim Mackey** | 2 | 41 | 39 | 5% | 🔴 **CRITICAL GAP** |
| **Ariana Butler** | 5 | 41 | 36 | 12% | 🔴 **CRITICAL GAP** |
| **Lexi Harrison** | 6 | 41 | 35 | 15% | 🔴 **CRITICAL GAP** |
| **Bre McDaniel** | 11 | 41 | 30 | 27% | ⚠️ **SIGNIFICANT GAP** |
| **Bryan Belville** | 15 | 41 | 26 | 37% | ⚠️ **SIGNIFICANT GAP** |
| **Jade Bingham** | 16 | 41 | 25 | 39% | ⚠️ **SIGNIFICANT GAP** |
| **Erin Pearson** | 18 | 41 | 23 | 44% | ⚠️ **SIGNIFICANT GAP** |
| **Corey Marcello** | 18 | 41 | 23 | 44% | ⚠️ **SIGNIFICANT GAP** |

**Interpretation:**
*   The four SGMs in "Critical Gap" are on a path to failure in future quarters without immediate, massive lead injection.
*   Even top performers like Bre and Corey are operating on dangerously low new deal volume. Bre's enterprise focus means she needs fewer "at-bats," but 11 SQOs is still too low to ensure a consistent pipeline of large opportunities.

### **4. CONVERSION RATE ANALYSIS & TRENDS**

**Methodology Note:** SQO→Joined rates use a 90-day lookback for accuracy, reflecting the average 77-day sales cycle.

*   **Overall Trends (The Funnel Bottleneck):**
    *   **SQL→SQO Rate (Top of Funnel):** **UP 7.2pp** (77.1% QTD vs 69.9% L12M). This is a bright spot. The handoff from SGA to SGM is getting more efficient.
    *   **SQO→Joined Rate (Bottom of Funnel):** **DOWN 5.3pp** (4.3% last 90 days vs 9.7% L12M). **This is the primary operational failure.** We are struggling to convert qualified pipeline into revenue.
*   **Channel Performance:**
    *   **Marketing-sourced leads** have a particularly low SQO→Joined rate of **2.2%**. This channel is not producing deals that close.
    *   **Recruitment Firm** leads have seen their SQO→Joined rate drop by **10.0pp**.
*   **Diagnostic Insights:** The problem is not lead generation; it's deal conversion. The drop in SQO→Joined rates directly impacts capacity and explains why SGMs feel pressure despite a healthy-looking firm-wide coverage ratio. We need to investigate *why* deals are stalling post-SQO. This could be due to SGM skill gaps in closing, lower quality pipeline that only becomes apparent in later stages, or changing market conditions.

### **5. SGA PERFORMANCE ANALYSIS**

**Context:** Inbound SGAs (Lauren, Jacqueline) are benchmarked separately from Outbound SGAs due to different lead sources.

*   **Inbound SGAs (The Benchmark):** **Performing Well.**
    *   **Lauren George:** A top performer. High volume (21 SQOs) and a significantly improved SQL→SQO rate (+11.6pp).
    *   **Jacqueline Tully:** Strong contributor. High volume (13 SQOs) despite a minor dip in conversion rate.
    *   **Conclusion:** Inbound lead flow and qualification are healthy. They are not the source of the problem.
*   **Outbound SGAs (The Hunters):**
    *   **Top Performers (Crushing It):**
        *   **Russell Armitage:** High volume (13 SQOs) and a massive +22.6pp improvement in SQL→SQO rate. Excellent performance.
        *   **Craig Suchodolski, Perry Kalmeta, Chris Morgan:** All show significant improvements in their SQL→SQO conversion rates, demonstrating high-quality work.
    *   **Volume Leaders:** Russell Armitage (13 SQOs) and Eleni Stefanopoulos (10 SQOs) are the key pipeline drivers for the outbound team.
    *   **Needs Coaching:**
        *   **Amy Waller:** Declining conversion rate and low volume (4 SQOs). Needs immediate attention.
        *   **Marisa Saucedo:** Produced 0 SQOs from 4 SQLs. This is a red flag.
*   **Overall Assessment:** The SGA team, particularly at the critical SQL→SQO handoff stage, is performing effectively. The systemic pipeline issues are not originating from this team.

### **6. SGM-SPECIFIC RISK ASSESSMENT**

*   **Under-Capacity:**
    *   **Jade Bingham (Coverage: 0.81):** Mathematically starving for pipeline. She has a 25 SQO gap and has received only 16 SQOs this quarter. She needs immediate lead flow to have a chance in future quarters.
*   **On Ramp:**
    *   **Tim, Lexi, Ariana:** All have critical SQO gaps (>35 each). While expected during ramp, we must ensure they are getting enough "at-bats" to build their pipeline and skills. Lexi's 11.3% stale rate is a concern to address now.
*   **Sufficient (With Caveats):**
    *   **GinaRose Galli (Coverage: 1.61):** Her capacity is a mirage. With **37.6% stale pipeline** and **0 new SQOs this quarter**, her pipeline is actively decaying. She is at high risk despite her "Sufficient" status.
    *   **Corey Marcello (Coverage: 4.13):** Has already hit his number, but his **11.4% stale rate** and a 23 SQO gap indicate he is not building sufficiently for the future.
    *   **Bre McDaniel (Enterprise Focus):** Her model is different. While her SQO volume is low, her pipeline value is immense ($1.25B). The key is **deal progression**. Her stale rate is low (1.6%), which is positive. The focus for Bre is converting one of her massive deals, not volume.

### **7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS**

| Issue | Root Cause | Impact | Recommended Solution |
| :--- | :--- | :--- | :--- |
| **1. Systemic SQO Volume Crisis** | Insufficient lead generation at the top of the funnel to meet the required 41±16 SQO/quarter baseline for all SGMs. | **High risk of missing future quarterly targets.** Creates a boom/bust cycle reliant on heroics. | **Immediate "All Hands on Deck" SQO Generation Sprint.** Focus all available SGA resources on high-intent channels. Launch targeted outbound campaigns. Implement a SPIF for self-sourced SGM opportunities. |
| **2. Plummeting SQO→Joined Conversion Rate** | Deals are stalling or being lost in the final stages. Potential causes: SGM closing skills, poor qualification not caught early, or market shifts. | **Wasted pipeline and inefficient use of SGM time.** Directly reduces revenue capacity. | **Conduct a "Loss Analysis" workshop.** Review all deals lost in the last 90 days post-SQO. Identify patterns and implement targeted SGM training on late-stage deal management and negotiation. |
| **3. Critical Pipeline Bloat** | Poor pipeline hygiene, allowing dead deals to remain in the forecast (esp. GinaRose, Corey). | **Inaccurate forecasting and wasted SGM focus.** Masks true pipeline health and capacity gaps. | **Mandate pipeline hygiene reviews.** SGMs with >10% stale pipeline (GinaRose, Corey, Lexi) must conduct a deal-by-deal review with leadership this week to either advance or close out stale opportunities. |

### **8. IMMEDIATE ACTION ITEMS**

*   **This Week (Critical):**
    1.  **Mandatory Pipeline Review:** Schedule 1:1s with **GinaRose Galli**, **Corey Marcello**, and **Lexi Harrison** to address their stale pipeline. Deals must be advanced with a clear next step or closed out by EOW.
    2.  **Triage for Jade Bingham:** Develop an immediate action plan to get at least 10 new SQOs into Jade's pipeline.
*   **This Month (High Priority):**
    1.  **Launch "SQO Generation Sprint":** Focus marketing and the entire SGA team on closing the 263 active SQO gap.
    2.  **Conduct Loss Analysis Workshop:** Analyze deals lost post-SQO in the last 90 days to understand why the conversion rate has dropped.
*   **This Quarter (Strategic):**
    1.  **Review SGM Closing Process:** Implement targeted training based on findings from the loss analysis.
    2.  **Re-evaluate Lead Sources:** Investigate why Marketing and Recruitment Firm leads have such low final conversion rates. Re-allocate budget to higher-performing sources like Advisor Referrals.

### **9. VELOCITY-BASED FORECASTING ANALYSIS**

**Context:** This forecast uses a 70-day median cycle time, providing a physics-based view of when deals *should* close, ignoring optimistic CRM close dates.

*   **Current Quarter Forecast:**
    *   The firm has a "safe" velocity forecast of **$187.79M** for the remainder of the quarter. Combined with the $232.5M already closed, we are in a strong position for this quarter.
    *   However, SGMs like **GinaRose ($0 forecast)** and the **On Ramp reps ($0 forecast)** have no deals projected to close based on normal velocity. They are entirely dependent on aging, overdue deals.
*   **Overdue / Slip Risk Analysis:**
    *   **Total Slip Risk:** **$337.51M**. This is an enormous amount of revenue tied to deals that are older than our median sales cycle.
    *   **🔴 RED STATUS:** **GinaRose Galli.** Her entire hope of hitting her number rests on **$92.69M** in overdue deals, combined with a 37.6% stale rate. This forecast is pure risk.
    *   **🟡 YELLOW STATUS:** **Bre McDaniel ($132.05M overdue)** and **Corey Marcello ($65.79M overdue)**.
        *   For Bre, this is less alarming due to the long cycles of enterprise deals. We must monitor progression, not just age.
        *   For Corey, this is a concern for future quarters, as it indicates a slowing pipeline.
*   **Next Quarter Pipeline Health:**
    *   The velocity forecast for next quarter is only **$80.88M**. For a team with a $330.8M target, this is a **five-alarm fire**. It confirms that our pipeline generation is not keeping pace and we are heading for a major shortfall.

### **10. QUARTERLY FORECAST ANALYSIS**

**Context:** This model uses deal-size dependent velocity and stage probabilities for a more nuanced forecast.

*   **Current Quarter Performance:**
    *   **On Track to Exceed Target:** Bre, Corey, GinaRose, Bryan, and Erin are all expected to finish the quarter above their $36.75M target.
    *   **At Risk of Missing Target:** **Jade Bingham** is only forecasted to hit **$18.91M (51.5% of target)**. This aligns with her under-capacity status. The on-ramp reps are forecasted to miss, as expected.
*   **Next Quarter Pipeline Health (The Warning Signal):**
    *   The forecast confirms the velocity model's warning. The pipeline for next quarter is dangerously thin for most of the team.
    *   **Weak Pipeline:** Tim ($0), Lexi ($2.29M), Ariana ($5.99M), Erin ($10.22M), Jade ($10.98M), and Bryan ($12.35M) all have forecasts that are a fraction of their quarterly target.
    *   **Over-Reliance:** The firm's entire next-quarter forecast of $143.97M is heavily dependent on Bre McDaniel ($62.47M). If her large deals slip, the entire firm will miss.
*   **Actionable Insights:** The forecast is clear: we are sacrificing future success for this quarter's results. We must immediately shift focus to building a sustainable pipeline for every SGM, not just relying on our top two performers.

### **11. SUCCESSES & BRIGHT SPOTS**

*   **Elite Performance:** **Bre McDaniel** and **Corey Marcello** have had exceptional quarters, single-handedly putting the firm in a position to exceed its target. Their performance demonstrates what is possible.
*   **SGA Execution:** The overall improvement in the **SQL→SQO conversion rate (+7.2pp)** is a significant win. It shows better alignment and efficiency between the SGA and SGM teams at the critical handoff point.
*   **Outbound Stars:** **Russell Armitage** stands out among the outbound SGAs for delivering both high volume (13 SQOs) and dramatically improved quality (+22.6pp conversion). He provides a model for success in a difficult role.
*   **High-Converting Source:** The **Advisor Referral** source, with a 50% SQO→Joined rate, is our most potent channel. Every effort should be made to increase volume from this source.

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** 9.0
- **SGMs On Track (Joined):** 2.0
- **SGMs with Sufficient SQOs:** 0.0
- **Total Pipeline Estimate:** $3029.1M
- **Total Stale Pipeline:** $195.4M
- **Total Quarter Actuals:** $232.5M
- **Total Target:** $330.8M
- **Total Required SQOs:** 369.0
- **Total Current SQOs:** 123.0
- **Total Stale SQOs:** 17.0

### Coverage Summary
- **Total Capacity (Forecast):** $538.93M
- **Average Coverage Ratio:** 2.372 (237.2%)
- **On Ramp SGMs:** 3.0
- **Sufficient SGMs:** 5.0
- **At Risk SGMs:** 0.0
- **Under-Capacity SGMs:** 1.0

### SGM Coverage Analysis (Top 15 by Risk)

| SGM | Coverage Status | Coverage Ratio | Capacity (M) | Capacity Gap (M) | Active SQOs | Stale SQOs | Qtr Actuals (M) |
|-----|----------------|----------------|--------------|------------------|-------------|------------|-----------------|
| Jade Bingham | Under-Capacity | 0.81 | $29.89 | $6.86 | 14 | 2 | $0.00 |
| Tim Mackey | On Ramp | 0.05 | $1.96 | $34.79 | 2 | 0 | $0.00 |
| Lexi Harrison | On Ramp | 0.17 | $6.42 | $30.33 | 7 | 1 | $0.00 |
| Ariana Butler | On Ramp | 0.21 | $7.62 | $29.13 | 5 | 0 | $0.00 |
| Bryan Belville | Sufficient | 1.10 | $40.38 | $-3.63 | 17 | 0 | $23.29 |
| GinaRose Galli | Sufficient | 1.61 | $59.35 | $-22.60 | 7 | 4 | $30.78 |
| Erin Pearson | Sufficient | 1.65 | $60.46 | $-23.71 | 19 | 0 | $19.84 |
| Corey Marcello | Sufficient | 4.13 | $151.77 | $-115.02 | 27 | 6 | $36.90 |
| Bre McDaniel | Sufficient | 4.93 | $181.07 | $-144.32 | 25 | 4 | $121.71 |


### SGM Risk Assessment (Top 10 by Risk)

| SGM | Status | SQO Gap | Pipeline (M) | Weighted (M) | Stale % | Quarter Actuals (M) |
|-----|--------|---------|--------------|--------------|---------|---------------------|
| Tim Mackey | No Activity | 39.0 | $14.3 | $2.0 | 0.0% | $0.0 |
| Ariana Butler | No Activity | 36.0 | $65.8 | $7.6 | 0.0% | $0.0 |
| Lexi Harrison | No Activity | 34.0 | $52.5 | $6.9 | 11.3% | $0.0 |
| Jade Bingham | No Activity | 27.0 | $194.0 | $31.5 | 3.7% | $0.0 |
| GinaRose Galli | Behind | 34.0 | $235.7 | $92.7 | 37.6% | $30.8 |
| Bryan Belville | Behind | 24.0 | $288.5 | $40.4 | 0.0% | $23.3 |
| Erin Pearson | Behind | 22.0 | $285.4 | $60.5 | 0.0% | $19.8 |
| Bre McDaniel | On Track | 16.0 | $1250.1 | $189.4 | 1.6% | $121.7 |
| Corey Marcello | On Track | 14.0 | $642.9 | $175.2 | 11.4% | $36.9 |


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
| Tim Mackey | 4.0 | 41.0 | 2 | 39.0 | 4.9% | 2 | 🔴 CRITICAL |
| Ariana Butler | 4.0 | 41.0 | 5 | 36.0 | 12.2% | 5 | 🔴 CRITICAL |
| Lexi Harrison | 4.0 | 41.0 | 6 | 35.0 | 14.6% | 7 | 🔴 CRITICAL |
| Jade Bingham | 4.0 | 41.0 | 16 | 25.0 | 39.0% | 14 | ⚠️ SIGNIFICANT |
| GinaRose Galli | 4.0 | 41.0 | 0 | 41.0 | 0.0% | 7 | 🔴 CRITICAL |
| Bryan Belville | 4.0 | 41.0 | 15 | 26.0 | 36.6% | 17 | ⚠️ SIGNIFICANT |
| Erin Pearson | 4.0 | 41.0 | 18 | 23.0 | 43.9% | 19 | ⚠️ SIGNIFICANT |
| Bre McDaniel | 4.0 | 41.0 | 11 | 30.0 | 26.8% | 25 | ⚠️ SIGNIFICANT |
| Corey Marcello | 4.0 | 41.0 | 18 | 23.0 | 43.9% | 27 | ⚠️ SIGNIFICANT |


### Top Deals Requiring Attention (Stale or High Value)

| Deal | SGM | Stage | Value (M) | Days Open | Stale |
|------|-----|-------|-----------|-----------|-------|
| Matt Mai | GinaRose Galli | Negotiating | $45.0 | 261 | Yes |
| Emily Hermeno | GinaRose Galli | Sales Process | $38.0 | 741 | Yes |
| Debbie Huttner | Corey Marcello | Negotiating | $21.4 | 183 | Yes |
| Sam Issermoyer | Bre McDaniel | Sales Process | $20.2 | 197 | Yes |
| Derek Dall'Olmo | Corey Marcello | Sales Process | $13.8 | 147 | Yes |
| Aaron Clarke | Corey Marcello | Negotiating | $11.7 | 184 | Yes |
| David Matuszak | Corey Marcello | Negotiating | $10.1 | 365 | Yes |
| James Davis | Corey Marcello | Negotiating | $9.5 | 184 | Yes |
| Ryan Drews | Corey Marcello | Negotiating | $7.1 | 176 | Yes |
| Tyler Brooks | Lexi Harrison | Qualifying | $5.9 | 663 | Yes |
| Bryan Havighurst 2025 | GinaRose Galli | Negotiating | $5.5 | 252 | Yes |
| Erwin M Matthews, CPA/PFS | Jade Bingham | Sales Process | $4.3 | 160 | Yes |
| James Ling | Jade Bingham | Negotiating | $3.0 | 98 | Yes |
| Marcado 401k Team | GinaRose Galli | Negotiating | $0.0 | 103 | Yes |
| Clint Seefeldt (Ed Wildermuth team) | Bre McDaniel | Discovery | $0.0 | 147 | Yes |


### SGA Performance Summary (Top 15 by SQL→SQO Rate Change)

| SGA | Contacted→MQL (QTD) | MQL→SQL (QTD) | SQL→SQO (QTD) | SQL→SQO Change | SQL Volume | SQO Volume |
|-----|---------------------|---------------|---------------|----------------|------------|------------|
| Chris Morgan | 3.0% | 6.7% | 100.0% | +53.6pp | 2 | 3 |
| Perry Kalmeta | 2.3% | 30.0% | 100.0% | +37.8pp | 4 | 4 |
| Craig Suchodolski | 1.4% | 28.6% | 100.0% | +23.6pp | 4 | 5 |
| Russell Armitage | 9.5% | 40.0% | 84.6% | +22.6pp | 17 | 13 |
| Eleni Stefanopoulos | 3.6% | 10.0% | 66.7% | -13.3pp | 5 | 10 |
| Lauren George | 4.4% | 41.7% | 85.7% | +11.6pp | 17 | 21 |
| Amy Waller | 5.8% | 30.3% | 60.0% | -6.7pp | 6 | 4 |
| Jacqueline Tully | 77.8% | 73.7% | 83.3% | -4.0pp | 15 | 13 |
| Ryan Crandall | 4.6% | 10.4% | 75.0% | +0.0pp | 6 | 5 |
| Helen Kamens | 3.2% | 12.0% | 50.0% | +0.0pp | 4 | 4 |
| Marisa Saucedo | 3.8% | 11.4% | 0.0% | +0.0pp | 4 | 0 |
| Channing Guyer | 3.2% | 16.7% | 100.0% | +0.0pp | 3 | 5 |
| Anett Diaz | 1.4% | 0.0% | nan% | +nanpp | 0 | 1 |


---

*Report generated using LLM analysis of BigQuery capacity and coverage views.*
*Data sources: `savvy-gtm-analytics.savvy_analytics.vw_sgm_capacity_model_refined`, `vw_sgm_capacity_coverage`, `vw_sgm_open_sqos_detail`, `vw_conversion_rates`, and `vw_sga_funnel`*
