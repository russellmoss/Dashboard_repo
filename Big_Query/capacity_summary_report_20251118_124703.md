# Capacity & Coverage Summary Report
Generated: 2025-11-18 12:47:03

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

---

### **Pipeline Health Diagnostic: Executive Report**

### 1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY

This quarter's performance is a tale of two realities. On the surface, we are ahead of plan, largely due to the monumental success of Bre McDaniel, whose enterprise wins have single-handedly carried the firm's performance. However, beneath this success, critical leading indicators point to significant risk for next quarter. Our overall SQO→Joined conversion rate has been cut in half (from 9.8% to 4.4%), and we face a massive 451 active SQO gap in our total open pipeline. This indicates a severe top-of-funnel shortage that will starve the team in the coming months.

For the current quarter, performance is strong. We have achieved 70.3% of our firm-wide target, with a forecast to reach 165% by quarter-end. Two SGMs have already blown past their $36.75M target: **Bre McDaniel ($121.71M)** and **Corey Marcello ($36.90M)**. GinaRose Galli is also within striking distance at 83.8% of her goal. Firm-wide pipeline coverage appears healthy at 1.77, with four SGMs having sufficient pipeline for future targets. However, this aggregate number masks significant risk: two SGMs are "Under-Capacity" and mathematically starving for leads right now.

The core issue is sustainability. While this quarter's revenue is secure, our pipeline for next quarter is dangerously thin, with a forecast of only **$87.26M** against a **$330.8M** target. The dramatic drop in our closing conversion rate means we need more opportunities than ever to hit our goals, yet we have a significant SQO deficit. This combination of a leaky funnel bottom and an empty funnel top is a formula for a major miss next quarter if not addressed immediately.

**Critical Alerts:**
1.  **Next Quarter Revenue Cliff:** The forecast for next quarter ($87.26M) is only 26% of our target. This is the top priority.
2.  **Severe SQO Shortage:** We have a 451 active SQO gap in our total open pipeline. We are not creating enough future opportunities to sustain growth.
3.  **Funnel Bottleneck:** The SQO→Joined conversion rate has plummeted from 9.8% to 4.4%. Deals are dying before the finish line.
4.  **Critical Pipeline Bloat:** GinaRose Galli's pipeline is 39.1% stale, containing deals over 700 days old. This inflates her capacity and masks severe risk.
5.  **"Starving" SGMs:** Jade Bingham (0.61 coverage) and Bryan Belville (0.80 coverage) lack the necessary pipeline to hit future targets.

**Overall Assessment: Ahead of plan for the current quarter, but at high risk for the next.** Bre McDaniel's over-performance is masking foundational weaknesses in pipeline generation and conversion that require immediate intervention.

### 2. CAPACITY & COVERAGE ANALYSIS

While our firm-wide coverage ratio of 1.77 appears healthy, the distribution of that capacity is dangerously uneven. A handful of top performers are carrying the weight, while others are falling behind without enough pipeline to recover.

*   **Current Quarter Readiness:** Two SGMs have already crossed the finish line.
    *   **Exceeded Target:** Bre McDaniel ($121.71M) and Corey Marcello ($36.90M).
    *   **Close to Target:** GinaRose Galli ($30.78M, 84% of target).
*   **Next Quarter Readiness:** The outlook is poor. The total open pipeline capacity suggests we have enough value to cover future targets in theory, but the velocity and quarterly forecasts show that very little of it is projected to close next quarter ($87.26M). This indicates that value is either locked in very long-cycle deals or is stale and will never close. **GinaRose Galli has $0 forecasted for next quarter**, a critical red flag.
*   **Firm-Wide Capacity Gap:** We have a theoretical capacity surplus of $70.8M. However, this is misleading. Bre McDaniel and Corey Marcello alone account for a $174M surplus, while Jade Bingham and Bryan Belville have a combined $21.9M deficit. We don't have a capacity problem; we have a **distribution problem**.
*   **Coverage Status Breakdown:**
    *   **Sufficient (4):** Bre McDaniel, Corey Marcello, GinaRose Galli, Erin Pearson.
    *   **At Risk (0):** None.
    *   **Under-Capacity (2):** Jade Bingham, Bryan Belville.
    *   **On Ramp (3):** Tim Mackey, Lexi Harrison, Ariana Butler.

### 3. SQO PIPELINE DIAGNOSIS

Our analysis of the total open pipeline reveals a critical shortage of new opportunities, compounded by significant hygiene issues for key SGMs.

*   **Quantity Analysis:** The firm-wide SQO gap is the most alarming metric. We are short **451 active (non-stale) SQOs** needed to ensure all SGMs can hit future targets. This is a top-of-funnel crisis that will directly impact revenue in the coming quarters.
*   **Quality Analysis:**
    *   Firm-wide stale pipeline is a healthy 6.5%.
    *   However, this average masks severe individual issues. **GinaRose Galli's pipeline is 39.1% stale**, with deals open for 740 and 662 days. This is unacceptable and completely inflates her forecast. Corey Marcello also requires a cleanup at 11.4% stale.
    *   In contrast, **Erin Pearson has 0% stale pipeline**, a benchmark for the team.
*   **Root Cause Analysis:**
    *   **SGA/Marketing Perspective:** There is evidence of a lead volume issue. The "Provided Lead List" source, a historically high-volume channel, has produced only 7 SQLs this quarter compared to a quarterly average of 42. This directly impacts the SGA's ability to generate SQOs.
    *   **SGM Perspective:** The primary bottleneck is at the bottom of the funnel. The SQO→Joined rate has dropped by over 50%. This points to a breakdown in the sales process, deal qualification, or pipeline management post-handoff. The severe pipeline bloat for specific SGMs confirms a lack of disciplined pipeline management.
    *   **Collaborative Factors:** The sharp decline in closing rates suggests a potential misalignment. Either the quality of SQOs being passed has degraded, or the SGMs' ability to close what was previously considered a "good" lead has diminished.

### 4. CONVERSION RATE ANALYSIS & TRENDS

The data shows a clear and alarming trend: we are getting better at qualifying leads but significantly worse at closing them.

*   **Overall Trends:**
    *   **SQL→SQO Rate (Good News):** Increased from 69.9% to **77.6%**. The handoff from SGA to SGM is becoming more efficient.
    *   **SQO→Joined Rate (CRITICAL ALERT):** Plummeted from 9.8% (L12M) to **4.4%** (Last 90 Days). This 55% drop is the single biggest threat to our future revenue.
*   **Channel & Source Performance:** The decline is widespread.
    *   **Recruitment Firm:** SQO→Joined rate dropped from 10.0% to 0%.
    *   **Marketing / Re-Engagement:** Dropped from 12.5% to 6.2%.
    *   **LinkedIn (Self Sourced):** Dropped from 7.1% to 3.6%.
    *   **Bright Spot:** "Advisor Referral" is converting at an incredible **60%** (SQO→Joined). This is our highest quality source and should be a priority for investment.
*   **Diagnostic Insights:** This conversion collapse explains our future risk. We now require more than double the number of SQOs to generate the same revenue as last year. This makes the 451 SQO gap even more dangerous. The issue is not just about finding more leads; it's about understanding why qualified opportunities are stalling and dying in the SGM pipeline.

### 5. SGA PERFORMANCE ANALYSIS

The SGA team shows strong performance at the top of the funnel, particularly from the Inbound team, who are setting a high benchmark.

*   **Inbound SGAs (Lauren George & Jacqueline Tully):**
    *   **Benchmark Performance:** This team is the engine room. Lauren George (20 SQOs) and Jacqueline Tully (13 SQOs) are high-volume producers. Lauren's SQL→SQO rate has improved by over 10 percentage points, showing increased efficiency. Their consistent performance indicates that inbound lead quality from Marketing is strong.
*   **Outbound SGAs (Hunters):**
    *   **Top Performers:** **Russell Armitage** is the standout, leading with 13 SQOs and a massive 22.6 percentage point improvement in his SQL→SQO rate. Craig Suchodolski, Perry Kalmeta, and Chris Morgan also show excellent rate improvements and are models of efficiency.
    *   **Volume Leaders:** Russell Armitage (13) and Eleni Stefanopoulos (10) are driving the most outbound pipeline. While Eleni's conversion rates have declined, her high volume is critical and warrants coaching to improve efficiency.
    *   **Coaching Opportunities:** **Helen Kamens** needs immediate attention. Her SQL→SQO rate has fallen 40 points to 0%. Marisa Saucedo (4 SQLs, 0 SQOs) is also a red flag. These SGAs require urgent intervention to diagnose the breakdown in their process.

### 6. SGM-SPECIFIC RISK ASSESSMENT

*   **Under-Capacity (Highest Risk):**
    *   **Jade Bingham:** Coverage ratio of 0.61 with a $14.4M capacity gap and $0 closed this quarter. She is mathematically unable to hit her number and needs immediate pipeline support.
    *   **Bryan Belville:** Coverage of 0.80 with a $7.5M gap. He is starving for new leads.
*   **Sufficient (With Caveats):**
    *   **GinaRose Galli:** While her coverage is 1.35, her pipeline is a liability. With 39.1% stale deals and a **$0 forecast for next quarter**, her "sufficient" status is an illusion. Her pipeline requires a mandatory, aggressive cleanup.
    *   **Corey Marcello:** Exceeded target and has a 2.92 coverage ratio. However, his 11.4% stale rate and $66M in "Overdue/Slip Risk" indicate a need for better pipeline management to secure that future revenue.
    *   **Bre McDaniel (Enterprise Hunter):** A massive success. Her 3.81 coverage and $121.7M in closed business are driving the firm's results. Her "overdue" deals (e.g., Sam Issermoyer at 196 days) are expected for enterprise cycles and should be viewed as complex, not dead.
*   **On Ramp (3 SGMs):** All are building pipeline as expected for their tenure.

### 7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS

1.  **Issue:** **Next Quarter Revenue Cliff & Severe SQO Gap.**
    *   **Root Cause:** A 55% drop in the SQO→Joined conversion rate combined with insufficient top-of-funnel lead generation.
    *   **Impact:** High probability of missing the firm-wide target next quarter.
    *   **Recommended Solution:**
        1.  Launch a cross-functional "deal rescue" task force (Sales, Marketing, RevOps) to diagnose why deals are stalling post-SQO.
        2.  Marketing to double down on high-converting lead sources like "Advisor Referral."
        3.  Implement a firm-wide "SQO Blitz" to close the 451 opportunity gap.

2.  **Issue:** **Critical Pipeline Bloat & Hygiene Failure.**
    *   **Root Cause:** Lack of disciplined pipeline management from specific SGMs, particularly GinaRose Galli (39.1% stale).
    *   **Impact:** Inaccurate forecasting, wasted SGM time on dead deals, and hidden pipeline risk. The $79.88M in "Overdue" deals for GinaRose is likely unrecoverable.
    *   **Recommended Solution:**
        1.  Mandatory pipeline review this week for any SGM with >10% stale pipeline (Galli, Marcello).
        2.  Implement a "close-lost or create action plan" policy for all deals aged over 120 days.

3.  **Issue:** **Uneven Capacity Distribution.**
    *   **Root Cause:** Top performers are over-supplied with pipeline while others (Jade Bingham, Bryan Belville) are starving.
    *   **Impact:** Two SGMs are set up to fail, dragging down overall team performance and morale.
    *   **Recommended Solution:**
        1.  Temporarily prioritize lead routing to Bingham and Belville.
        2.  Pair them with top-performing SGAs (Russell Armitage, Lauren George) to accelerate opportunity creation.

### 8. IMMEDIATE ACTION ITEMS

*   **This Week (Critical):**
    1.  **Mandatory Pipeline Review:** GinaRose Galli and Corey Marcello must conduct a full pipeline review with leadership to clean out all stale and dead deals.
    2.  **Intervention Plan:** Meet with Jade Bingham to build an emergency 30-day plan to generate immediate pipeline.
*   **This Month (High Priority):**
    1.  **Launch "Deal Rescue" Task Force:** Assemble leadership from Sales, Marketing, and RevOps to investigate and address the 55% drop in the SQO→Joined conversion rate.
    2.  **Prioritize Lead Flow:** Re-route a higher percentage of inbound and top-tier outbound leads to Jade Bingham and Bryan Belville.
*   **This Quarter (Strategic):**
    1.  **Revamp Pipeline Management Standards:** Institute clear, non-negotiable rules for deal stages and timelines.
    2.  **Re-evaluate Lead Sources:** Shift marketing and SGA focus towards sources with the highest SQO→Joined conversion rates, specifically "Advisor Referral."

### 9. VELOCITY-BASED FORECASTING ANALYSIS

Our physics-based forecast, which ignores unreliable manual close dates, confirms both the strength of this quarter and the danger of the next.

*   **Current Quarter Velocity Forecast:** The "safe" forecast for this quarter is **$423.8M** ($232.5M Actuals + $191.3M Velocity Forecast), well above the $330.8M target.
*   **Overdue / Slip Risk Analysis:** There is a staggering **$328.42M** in revenue attached to 43 deals that are past the 70-day median close time.
    *   **CRITICAL ALERT:** GinaRose Galli has **$79.88M** at slip risk. Combined with her 39% stale rate, this portion of her forecast should be considered highly unreliable.
    *   Corey Marcello ($66.23M) also has significant slip risk that requires immediate attention.
    *   Bre McDaniel's $132.65M in overdue deals is less concerning due to the 120+ day cycle time for her enterprise pursuits.
*   **Next Quarter Pipeline Health:** The velocity forecast for next quarter is only **$76.39M**. This is a clear leading indicator that we are not building enough pipeline to support future targets. **GinaRose Galli has $0 in her next quarter velocity forecast**, confirming she is on track for a pipeline cliff.

### 10. QUARTERLY FORECAST ANALYSIS

This model, which uses deal-size dependent velocity, paints a similar picture: a strong current quarter finish followed by a weak start to the next.

*   **Current Quarter Performance:** We are expected to end the quarter at **$546.87M** (165% of target). Bre, Corey, GinaRose, Bryan, and Erin are all projected to meet or exceed their individual targets. Jade Bingham is the only tenured SGM forecast to miss significantly.
*   **Next Quarter Pipeline Health:** The forecast of **$87.26M** is a major red flag.
    *   **Strong Pipeline:** Bre McDaniel ($44.43M) is well-positioned.
    *   **Weak Pipeline:** Corey Marcello ($15.6M), Bryan Belville ($8.7M), and Erin Pearson ($7.3M) have weak pipelines for next quarter.
    *   **CRITICAL ALERT:** **GinaRose Galli has a $0 forecast for next quarter.** She has no active pipeline projected to close. This is an emergency.
*   **Confidence & Interpretation:** The firm's EOD forecast of $546.87M is heavily dependent on Bre McDaniel's large, binary enterprise deals. GinaRose's forecast of $80.57M should be viewed with extreme skepticism due to her pipeline's poor health. The low next-quarter forecast of $87.26M is a high-confidence signal of impending trouble.

### 11. SUCCESSES & BRIGHT SPOTS

*   **Enterprise Dominance (Bre McDaniel):** Bre's performance is exceptional. Her $121.71M in actuals has secured the firm's quarter. She is the model of a successful "Whale Hunter."
*   **Consistent High Performer (Corey Marcello):** Corey has already hit his number and maintains a massive pipeline, demonstrating his ability to consistently close deals.
*   **The Benchmark for Hygiene (Erin Pearson):** Erin is on track to hit her number, has sufficient capacity, and maintains a 0% stale pipeline. She is the model for effective pipeline management.
*   **Inbound Engine (Lauren George & Jacqueline Tully):** As a team, they are the primary drivers of new opportunities, delivering high volume and proving the effectiveness of our inbound marketing strategy.
*   **Outbound Leader (Russell Armitage):** Russell is the top-performing outbound SGA, delivering both high volume (13 SQOs) and significantly improved conversion rates. He sets the standard for the outbound team.

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** 9.0
- **SGMs On Track (Joined):** 2.0
- **SGMs with Sufficient SQOs:** 1.0
- **Total Pipeline Estimate:** $3020.2M
- **Total Stale Pipeline:** $195.8M
- **Total Quarter Actuals:** $232.5M
- **Total Target:** $330.8M
- **Total Required SQOs:** 556.0
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
| Jade Bingham | No Activity | 145.0 | $202.2 | $34.1 | 3.8% | $0.0 |
| Tim Mackey | No Activity | 48.0 | $14.3 | $2.0 | 0.0% | $0.0 |
| Ariana Butler | No Activity | 45.0 | $65.8 | $7.7 | 0.0% | $0.0 |
| Lexi Harrison | No Activity | 45.0 | $34.7 | $4.8 | 0.0% | $0.0 |
| Erin Pearson | Behind | 89.0 | $285.4 | $59.8 | 0.0% | $19.8 |
| Bryan Belville | Behind | 43.0 | $283.3 | $40.6 | 0.0% | $23.3 |
| GinaRose Galli | Behind | 11.0 | $241.6 | $79.9 | 39.1% | $30.8 |
| Corey Marcello | On Track | 20.0 | $642.9 | $176.3 | 11.4% | $36.9 |
| Bre McDaniel | On Track | -12.0 | $1250.1 | $191.0 | 1.6% | $121.7 |


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
