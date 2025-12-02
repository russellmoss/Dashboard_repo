# Capacity & Coverage Summary Report
Generated: 2025-11-18 14:02:56

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

### **Pipeline Health Diagnostic: Executive Report**

**To:** Sales Leadership
**From:** Revenue Operations Partner
**Date:** October 26, 2023
**Subject:** Q4 Pipeline Analysis & Action Plan

### 1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY

This quarter's performance is a tale of two extremes. We are on track to significantly exceed our firm-level target, but this success is dangerously concentrated and masks critical weaknesses that threaten next quarter. **Bre McDaniel** and **Corey Marcello** have already surpassed their annual targets, with Bre closing $121.71M (331% of target) and Corey closing $36.90M (100.4% of target). Their exceptional performance is carrying the firm's current success. **GinaRose Galli** is also within striking distance at 83.8% of her goal. Firm-wide, we have achieved 70.3% of our quarterly goal, with forecasts predicting we will land well above target.

However, our overall pipeline health is concerning. The firm-wide Coverage Ratio of 1.77 is artificially inflated by Bre's massive enterprise deals. The reality is a bifurcated team: two top performers with massive capacity, and two SGMs—**Jade Bingham** and **Bryan Belville**—who are "Under-Capacity" and mathematically starving for leads. This concentration creates significant risk. If one of Bre's whale deals slips, our forecast evaporates.

The most critical operational issue is a severe bottleneck at the bottom of the funnel. While our SGAs are improving at generating qualified opportunities (SQL→SQO rate is up 7.7 points), our ability to close them has been cut in half. The **SQO→Joined conversion rate has plummeted from a 12-month average of 9.8% to just 4.4% in the last 90 days.** This indicates a systemic issue with closing velocity or deal qualification that is impacting the entire team.

**Critical Alerts for Immediate Attention:**
1.  **Massive Closing Bottleneck:** The SQO→Joined conversion rate has collapsed by over 50% (from 9.8% to 4.4%). This is the single biggest threat to future revenue.
2.  **"Starving" SGMs:** Jade Bingham (0.61 Coverage) and Bryan Belville (0.80 Coverage) lack the necessary pipeline to hit future targets. They need immediate lead flow.
3.  **Extreme Concentration Risk:** The firm's success hinges on Bre McDaniel's enterprise deals. Her pipeline accounts for over 41% of the firm's total weighted value.
4.  **Significant "Slip Risk":** Our velocity forecast identifies **$328.42M in overdue deals** that should have already closed. We are relying on aged pipeline to hit our numbers.
5.  **Severe Pipeline Bloat:** **GinaRose Galli's pipeline is 39.1% stale**, representing a major distraction and forecast inaccuracy.

**Overall Assessment:** **Ahead of Plan** for the current quarter due to heroic enterprise performance, but **At High Risk** for next quarter due to a systemic closing issue, poor pipeline distribution, and weak forward-looking pipeline.

### 2. CAPACITY & COVERAGE ANALYSIS

While the firm-wide coverage of 1.77 appears healthy, it masks an unhealthy distribution of pipeline. Capacity is a forward-looking metric; it tells us if we have enough iron in the fire for *future* quarters.

*   **Current Quarter Readiness:** We are in a strong position for this quarter.
    *   **Met/Exceeded Target ($36.75M):** Bre McDaniel ($121.71M) and Corey Marcello ($36.90M).
    *   **Close to Target:** GinaRose Galli ($30.78M, 83.8% of target).

*   **Next Quarter Readiness:** The outlook for next quarter is poor. The velocity-based forecast for next quarter is only **$76.39M**, and the deal-size dependent model forecasts **$87.26M**. Both are far below the firm's quarterly target of $330.8M, signaling a significant revenue cliff.

*   **Firm-Wide Capacity Gap:** The model shows a capacity surplus of $70.8M, but this is misleading. This surplus is held entirely by Bre and Corey. The rest of the team is either just sufficient or starving.

*   **Coverage Status Breakdown:**
    *   **Sufficient (4):** Bre McDaniel, Corey Marcello, GinaRose Galli, Erin Pearson. **Note:** GinaRose's status is at risk due to a 39.1% stale pipeline.
    *   **At Risk (0):** None.
    *   **Under-Capacity (2):** **Jade Bingham (0.61)** and **Bryan Belville (0.80)**. They do not have enough pipeline to hit future targets and need immediate support.
    *   **On Ramp (3):** Tim Mackey, Lexi Harrison, Ariana Butler. They are building pipeline as expected.

### 3. SQO PIPELINE DIAGNOSIS

We are analyzing the total open pipeline to ensure we have enough volume to sustain future quarters.

*   **Quantity Analysis:** We have a critical volume problem. There is a firm-wide gap of **381 active (non-stale) SQOs**. This massive deficit means we are not feeding the top of the SGM funnel with enough opportunities to create predictable revenue, forcing over-reliance on a few large deals.

*   **Quality Analysis:** Pipeline hygiene is a significant issue for specific reps.
    *   **GinaRose Galli:** 39.1% of her pipeline is stale. This is unacceptable and requires immediate cleanup.
    *   **Corey Marcello:** 11.4% stale pipeline. While performing well, this bloat needs to be addressed.
    *   The "Top Deals" list shows multiple high-value deals open for 200, 300, and even 700+ days. These are likely dead and are inflating our capacity forecast.

*   **Root Cause Analysis:** The data points to a bottom-of-funnel conversion problem, not a top-of-funnel generation problem.
    *   **SGA Perspective:** SGAs are improving. The SQL→SQO rate is up, meaning the handoff to SGMs is getting more efficient.
    *   **SGM Perspective:** The SQO→Joined rate has collapsed. This suggests SGMs are struggling to close the opportunities they accept, or the deals are stalling out in the sales process. This is the primary bottleneck in our funnel.

### 3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)

**CRITICAL CONTEXT:** The "Required SQOs" metric (54) is based on a historical average deal size of $11.35M, which is highly volatile. This metric should be used as directional guidance, not a rigid target, especially for enterprise-focused SGMs.

*   **Analysis:** According to this metric, **every single SGM has a significant SQO gap**.
    *   **Corey Marcello** has the smallest gap (needs 54, has 27).
    *   **Bre McDaniel** has a gap of 29 (needs 54, has 25). For her, this metric is irrelevant; she needs a handful of whales, not 54 standard deals.
    *   **Jade Bingham (Gap: 39)** and **Bryan Belville (Gap: 38)** have alarming gaps. As they do not primarily hunt enterprise deals, this volume-based metric is a valid and urgent indicator that they are starving for opportunities.

*   **Leadership Interpretation:** Ignore the SQO gap for Bre. For all other SGMs, treat these gaps as a serious leading indicator of future capacity issues. The team, excluding Bre, needs a significant increase in SQO volume.

### 4. CONVERSION RATE ANALYSIS & TRENDS

**METHODOLOGY NOTE:** SQO→Joined rates use a 90-day lookback to account for the 77-day average sales cycle.

*   **Overall Trends:**
    *   **SQL→SQO Rate (Top of Funnel):** IMPROVING. Up from 69.9% to **77.6%**. The handoff from SGA to SGM is getting stronger.
    *   **SQO→Joined Rate (Bottom of Funnel):** DECLINING SHARPLY. Down from 9.8% to **4.4%**. This is the core problem. We are failing to convert qualified pipeline into revenue at historical rates.

*   **Diagnostic Insights:** This is not an issue with one channel; it's a systemic closing problem. The SQO→Joined rate has dropped across our primary sources: Recruitment Firm (-10.0pp), Re-Engagement (-6.2pp), and LinkedIn (-3.5pp). This confirms the issue lies within the SGM-led sales process, not lead generation.

*   **Actionable Recommendation:** We must launch an immediate initiative to diagnose and fix our closing process. This should include deal reviews, win/loss analysis, and potential retraining on late-stage deal management.

### 5. SGA PERFORMANCE ANALYSIS

**SEGMENTATION:** Inbound SGAs (Lauren, Jacqueline) are analyzed separately from Outbound SGAs.

*   **Inbound SGAs (The Feeders):** The inbound engine is performing well and is not the cause of our pipeline issues.
    *   **Lauren George:** Top performer. High volume (**20 SQOs**) and an improving SQL→SQO rate (+10.7pp). She is a model of efficiency and volume.
    *   **Jacqueline Tully:** Strong performer. High volume (**13 SQOs**) makes her a critical contributor, despite a minor rate dip.

*   **Outbound SGAs (The Hunters):** We have clear leaders and some who need coaching.
    *   **Top Performers:**
        *   **Russell Armitage:** Leading the pack with high volume (**13 SQOs**) and a massive +22.6pp improvement in his SQL→SQO rate.
        *   **Craig Suchodolski, Perry Kalmeta, Chris Morgan:** All show outstanding improvements in their conversion rates, demonstrating high-quality work.
    *   **Volume Leaders:** **Russell Armitage (13 SQOs)** and **Eleni Stefanopoulos (10 SQOs)** are driving the majority of outbound pipeline. Eleni's rates have declined, but her volume is essential.
    *   **Needs Coaching:**
        *   **Helen Kamens:** Urgent intervention needed. Her SQL→SQO rate has collapsed by 40 percentage points.

### 6. SGM-SPECIFIC RISK ASSESSMENT

*   **Under-Capacity (CRITICAL):**
    *   **Jade Bingham (Coverage: 0.61):** Has $0 in actuals this quarter and a $14.44M capacity gap. She is completely stalled and needs immediate, high-quality lead flow.
    *   **Bryan Belville (Coverage: 0.80):** Has a $7.48M capacity gap. While he has closed $23.29M, his future pipeline is insufficient.

*   **On Ramp:** Tim Mackey, Lexi Harrison, and Ariana Butler are new and building pipeline. Their low capacity is expected but must be monitored to ensure they ramp effectively.

*   **Sufficient (With Caveats):**
    *   **GinaRose Galli (Coverage: 1.35):** Her "Sufficient" status is misleading. With **39.1% of her pipeline stale** and **$0 forecasted for next quarter**, she is at high risk of a pipeline cliff.
    *   **Bre McDaniel & Corey Marcello:** They are the pillars of this quarter's performance. The key risk is the firm's over-reliance on them.

### 7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS

1.  **Issue:** Critical collapse in SQO-to-Joined conversion rate (from 9.8% to 4.4%).
    *   **Root Cause:** Widespread difficulty in late-stage deal execution by SGMs. Potential issues with negotiation, value proposition, or qualification depth.
    *   **Impact:** Lost revenue and wasted pipeline. A direct threat to all future quarterly attainment.
    *   **Solution:** Mandate weekly deal-level pipeline reviews focusing on "Next Steps" and "Stall Reasons." Implement a formal win/loss analysis program for all deals over $10M.

2.  **Issue:** Two SGMs (Jade Bingham, Bryan Belville) are critically under-capacity.
    *   **Root Cause:** Insufficient lead flow and pipeline generation.
    *   **Impact:** Guaranteed missed targets for these SGMs and a drag on firm-wide performance.
    *   **Solution:** Immediately prioritize all unassigned, high-quality leads to Jade and Bryan for the next 30 days. Partner them with a top-performing SGA.

3.  **Issue:** Severe pipeline bloat and poor hygiene, especially with GinaRose Galli (39.1% stale).
    *   **Root Cause:** Lack of accountability for updating and closing out old opportunities.
    *   **Impact:** Inaccurate forecasting, wasted SGM time on dead deals, and a false sense of security.
    *   **Solution:** Set a 7-day deadline for GinaRose and Corey to review every stale deal and either advance it with a concrete next step or close it out.

### 8. IMMEDIATE ACTION ITEMS

*   **This Week (Critical):**
    1.  **Triage Under-Capacity SGMs:** Leadership meeting with Jade Bingham and Bryan Belville to build a 30-day "get well" plan. Assign them top-tier SGA support immediately.
    2.  **Mandate Pipeline Cleanup:** GinaRose Galli and Corey Marcello must present a plan to clear their stale pipelines by the end of the week.
    3.  **Enterprise Deal Review:** Deep dive with Bre McDaniel on her top 3 deals to assess the real probability and timing, given the model's limitations with binary outcomes.

*   **This Month (High Priority):**
    1.  **Launch "Closing Initiative":** Begin weekly SGM-wide deal clinics focused on late-stage execution to address the SQO→Joined conversion drop.
    2.  **Address SQO Gap:** Run a 2-week "SQO Blitz" with SGAs and SGMs to generate net-new pipeline for the "starving" reps.

*   **This Quarter (Strategic):**
    1.  **Formalize Win/Loss Analysis:** Implement a structured process to understand why we are losing deals post-SQO.
    2.  **Review Lead Distribution Rules:** Ensure our process for assigning inbound leads promotes a more equitable distribution of pipeline capacity.

### 9. VELOCITY-BASED FORECASTING ANALYSIS

This "physics-based" forecast ignores optimistic CRM close dates and uses a 70-day median cycle time.

*   **Current Quarter Velocity Forecast:** The "safe" forecast (deals <70 days old) is only **$191.34M**. This is significantly below our $330.8M target.

*   **Overdue / Slip Risk Analysis:** We are heavily dependent on aging deals. There is **$328.42M in overdue pipeline** that should have closed already.
    *   **RED STATUS:** **Bre McDaniel ($132.65M overdue)** and **GinaRose Galli ($79.88M overdue)** have the highest risk. For Bre, this is somewhat expected due to long enterprise cycles. For GinaRose, combined with her stale pipeline, this is a critical warning that her forecast is unreliable.

*   **Next Quarter Pipeline Health:** **CRITICAL WARNING.** The pipeline for next quarter is only **$76.39M**. This is a clear signal of a major revenue shortfall next quarter if we don't build new pipeline immediately. **GinaRose has $0 forecasted for next quarter.**

### 10. QUARTERLY FORECAST ANALYSIS (Deal-Size Dependent Model)

This model is more sophisticated, accounting for longer enterprise deal cycles.

*   **Current Quarter Performance:** This model is more optimistic, projecting the firm will end the quarter at **$546.87M (165.3% of target)**. This is heavily weighted by Bre's large deals.
    *   **At Risk of Missing Target:** **Jade Bingham** is forecasted to end the quarter at $15.86M, missing her target by over $20M. This is a high-confidence forecast.

*   **Next Quarter Pipeline Health:** This model confirms the velocity forecast's warning. It projects only **$87.26M** for next quarter. The agreement between both models gives this weak forecast high confidence.
    *   **At Risk of Crashing:** **GinaRose Galli** has a **$0.00 forecast** for next quarter, indicating a complete lack of early-stage pipeline.

*   **Confidence & Interpretation:** The high-level E-o-Q number ($546M) is at risk due to its reliance on Bre's binary deals. However, the signals are clear and high-confidence: **Jade will miss her number this quarter, and the firm faces a major pipeline gap for next quarter.**

### 11. SUCCESSES & BRIGHT SPOTS

*   **SGM Rock Stars:** **Bre McDaniel** and **Corey Marcello** are having phenomenal years. Their ability to land significant deals is the primary driver of our current over-performance.

*   **SGA Top Performers:**
    *   **Lauren George (Inbound):** A model of consistency and volume, producing 20 SQOs with improving efficiency.
    *   **Russell Armitage (Outbound):** A true hunter, leading the outbound team in volume (13 SQOs) while dramatically improving his conversion rate.

*   **Process Improvement:** The firm-wide improvement in the **SQL→SQO conversion rate (+7.7pp)** shows that the alignment and handoff process between our SGAs and SGMs is getting stronger. We are getting better at the top of the funnel. Now we must fix the bottom.

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** 9.0
- **SGMs On Track (Joined):** 2.0
- **SGMs with Sufficient SQOs:** 0.0
- **Total Pipeline Estimate:** $3020.2M
- **Total Stale Pipeline:** $195.8M
- **Total Quarter Actuals:** $232.5M
- **Total Target:** $330.8M
- **Total Required SQOs:** 486.0
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
| Tim Mackey | No Activity | 52.0 | $14.3 | $2.0 | 0.0% | $0.0 |
| Ariana Butler | No Activity | 49.0 | $65.8 | $7.7 | 0.0% | $0.0 |
| Lexi Harrison | No Activity | 49.0 | $34.7 | $4.8 | 0.0% | $0.0 |
| Jade Bingham | No Activity | 39.0 | $202.2 | $34.1 | 3.8% | $0.0 |
| GinaRose Galli | Behind | 46.0 | $241.6 | $79.9 | 39.1% | $30.8 |
| Bryan Belville | Behind | 38.0 | $283.3 | $40.6 | 0.0% | $23.3 |
| Erin Pearson | Behind | 35.0 | $285.4 | $59.8 | 0.0% | $19.8 |
| Bre McDaniel | On Track | 29.0 | $1250.1 | $191.0 | 1.6% | $121.7 |
| Corey Marcello | On Track | 27.0 | $642.9 | $176.3 | 11.4% | $36.9 |


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
