# Capacity & Coverage Summary Report
Generated: 2025-11-18 15:20:03

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

### **Pipeline Health & Sales Capacity Diagnostic**

**To:** Sales Leadership
**From:** Revenue Operations Partner
**Date:** October 26, 2023
**Subject:** Q4 Pipeline Diagnostic & Forward-Looking Risk Assessment

### 1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY

This quarter's performance is a tale of two extremes. We are on track to significantly exceed our firm-level target, but this success is dangerously concentrated in two top performers. **Bre McDaniel ($121.7M)** and **Corey Marcello ($36.9M)** have already surpassed their individual $36.75M targets, single-handedly pushing the firm to 70% of its quarterly goal. GinaRose Galli is also close at 84% of her target. While this quarter appears safe, this masks significant underlying risks that threaten future performance. Our forward-looking pipeline health is flashing red due to a severe lack of new opportunities and a troubling decline in our ability to close deals.

The firm-wide Coverage Ratio is a healthy 1.77, but this is misleadingly inflated by Bre and Corey's massive pipelines. The reality is that two SGMs are already "Under-Capacity" and mathematically starving for leads to hit future targets. More alarmingly, our total open pipeline has a **critical gap of 255 active SQOs** needed to sustain our targets long-term. This indicates a systemic, top-of-funnel weakness that will impact all SGMs in the coming quarters if not addressed immediately.

**Critical Alerts for Immediate Attention:**
1.  **Systemic SQO Shortage:** We have a firm-wide gap of 255 active SQOs. The majority of our SGMs do not have enough pipeline to hit future targets. This is not an individual performance issue; it is a systemic volume problem.
2.  **Plummeting Close Rate:** Our SQO→Joined conversion rate has collapsed from a 12-month average of 9.8% to just **4.4% in the last 90 days**. We are closing less than half of what we used to, indicating a severe bottleneck at the bottom of the funnel. This could be due to lead quality, SGM effectiveness, or market shifts.
3.  **Massive "Slip Risk":** Our velocity forecast shows **$328.4M in "Overdue" deals** that should have already closed based on a 70-day cycle. This represents significant revenue at risk of slipping and indicates poor pipeline velocity.
4.  **Pipeline Bloat & Hygiene Issues:** GinaRose Galli is carrying a pipeline where **39.1% is stale**, including deals over 700 days old. This inflates her capacity numbers and masks a severe lack of fresh opportunities, evidenced by a $0 next-quarter forecast.

**Overall Assessment: At Risk.** While this quarter's numbers will look strong on paper due to heroic individual efforts, the fundamental health of our sales funnel is weak. We are starving the top of the funnel for new leads and struggling to close what we have. Without immediate intervention to generate more SQOs and diagnose the closing issue, we are heading for a significant downturn next quarter.

### 2. CAPACITY & COVERAGE ANALYSIS

While our firm-wide coverage appears healthy, a closer look reveals significant risk concentrated in the middle and bottom of our roster.

*   **Current Quarter Readiness:** Two SGMs have already crossed the finish line this quarter.
    *   **Bre McDaniel:** Exceeded target by **$84.96M**.
    *   **Corey Marcello:** Exceeded target by **$0.15M**.
    *   **GinaRose Galli** is close, having achieved 84% of her target.

*   **Next Quarter Readiness:** The firm-wide Coverage Ratio of **1.77** suggests we have enough total pipeline value to support future targets. However, this is dangerously skewed. Bre and Corey's pipelines are so large they mask deficiencies across the rest of the team. The **$87.26M** expected next quarter is far below our **$330.8M** total target, signaling a major shortfall.

*   **Firm-Wide Capacity Gap:** We have a capacity *surplus* of **$70.8M**, but this is entirely due to our top performers. The real story is at the individual level.

*   **Coverage Status Breakdown:**
    *   **Sufficient (4 SGMs):** Healthy, but includes individuals with significant stale pipeline (Corey, GinaRose) that inflates their numbers.
    *   **Under-Capacity (2 SGMs):** **Jade Bingham (0.61)** and **Bryan Belville (0.80)** are mathematically starving for leads. They cannot hit future targets without immediate pipeline injection.
    *   **On Ramp (3 SGMs):** Ramping as expected.

### 3. SQO PIPELINE DIAGNOSIS

Our analysis of the total open pipeline shows a critical shortage of opportunities, which is the root cause of our future risk.

*   **Quantity Analysis:** We are facing a severe volume deficit.
    *   **Firm-Wide SQO Gap (Active):** We need **255 more active SQOs** in our pipeline to ensure all SGMs can hit their targets consistently. We currently only have 105. This is our most critical long-term problem.

*   **Quality Analysis:** Pipeline hygiene is a major issue for specific reps.
    *   **Firm-Wide Stale %:** A respectable **6.2%**.
    *   **Individual Hygiene Issues:** **GinaRose Galli's pipeline is 39.1% stale**, containing deals over 700 days old. This severely inflates her capacity and masks an empty pipeline of fresh deals. **Corey Marcello (11.4% stale)** also needs a pipeline review.

*   **Root Cause Analysis:** The SQO gap is a shared responsibility.
    *   **SGA Perspective:** While some SGAs are performing well, overall SQL volume from key sources like "Provided Lead List" is down significantly. The SQL→SQO conversion rate is up (+7.7pp), suggesting SGAs are producing better-qualified leads, but not enough of them.
    *   **SGM Perspective:** The dramatic drop in the SQO→Joined rate (from 9.8% to 4.4%) points to a bottleneck in the SGM-owned part of the funnel. This could be due to SGMs struggling to convert, or it could be that the "higher quality" SQLs are not actually panning out over the full sales cycle. The truth is likely a combination of both.

### 3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)

**CRITICAL CONTEXT:** Our baseline requirement of **40 SQOs per quarter** is directional guidance, not a precise target. It is derived from highly volatile data. The average non-enterprise deal is $11.35M, but the standard deviation is a massive $5.55M (**48.8% coefficient of variation**). Deals range from $3.75M to $23.09M. This means an SGM closing smaller deals may need 56+ SQOs, while one closing larger deals may only need 24.

This analysis reveals that the majority of our team is operating well below the minimum pipeline threshold required for success, even in an optimistic scenario.

*   **Tim Mackey:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 2
    *   SQO Gap: 38
    *   Interpretation: 🔴 **CRITICAL GAP** - Needs 22 more SQOs just to reach the optimistic lower bound.

*   **Ariana Butler:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 5
    *   SQO Gap: 35
    *   Interpretation: 🔴 **CRITICAL GAP** - Needs 19 more SQOs to reach the lower bound.

*   **Lexi Harrison:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 5
    *   SQO Gap: 35
    *   Interpretation: 🔴 **CRITICAL GAP** - Needs 19 more SQOs to reach the lower bound.

*   **GinaRose Galli:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 8
    *   SQO Gap: 32
    *   Interpretation: ⚠️ **SIGNIFICANT GAP** - Needs 16 more SQOs to reach the lower bound. Her high stale % makes this gap even more severe.

*   **Jade Bingham:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 15
    *   SQO Gap: 25
    *   Interpretation: ⚠️ **SIGNIFICANT GAP** - Needs 9 more SQOs to reach the lower bound.

*   **Bryan Belville:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 16
    *   SQO Gap: 24
    *   Interpretation: ⚠️ **SIGNIFICANT GAP** - Needs 8 more SQOs to reach the lower bound.

*   **Erin Pearson:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 19
    *   SQO Gap: 21
    *   Interpretation: ⚠️ **SIGNIFICANT GAP** - Needs 5 more SQOs to reach the lower bound.

*   **Bre McDaniel (Enterprise Focus):**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 25
    *   SQO Gap: 15
    *   Interpretation: 🟡 **WITHIN RANGE** - Her pipeline meets the optimistic threshold. Given her focus on whale deals, this volume is likely sufficient.

*   **Corey Marcello:**
    *   Required SQOs: 40 (Range: 24-56)
    *   Current SQOs: 27
    *   SQO Gap: 13
    *   Interpretation: 🟡 **WITHIN RANGE** - His pipeline meets the optimistic threshold.

### 4. CONVERSION RATE ANALYSIS & TRENDS

Our conversion data reveals a critical failure at the bottom of the funnel.

*   **Overall Trends:**
    *   **SQL→SQO Rate (Good News):** Increased from 69.9% to **77.6%** this quarter. This indicates better qualification at the handoff point.
    *   **SQO→Joined Rate (CRITICAL ALERT):** Collapsed from 9.8% (L12M) to **4.4% (Last 90 Days)**. This is a **55% relative drop** and the single biggest threat to our future revenue. We are generating better-qualified deals that are ultimately failing to close.

*   **Channel Performance:** Several key channels are underperforming at the final conversion stage.
    *   **Recruitment Firm:** SQO→Joined rate has dropped by **10.0 percentage points**.
    *   **Re-Engagement:** SQO→Joined rate has dropped by **6.2 percentage points**.
    *   **Marketing/Event:** SQO→Joined rate has dropped by **5.6 percentage points**.

*   **Diagnostic Insights:** The data suggests a disconnect. SGAs are successfully converting SQLs at a higher rate, but these SQOs are not converting to closed business for SGMs. This points to either:
    1.  A "false positive" on lead quality—they look good at handoff but lack true potential.
    2.  A degradation in SGM closing effectiveness or pipeline management.
    3.  A shift in the market making it harder to close deals.
    A collaborative review between SGAs and SGMs is required to diagnose this disconnect.

### 5. SGA PERFORMANCE ANALYSIS

**Inbound SGAs (Benchmark Group):**
Lauren and Jacqueline are the engine room of the pipeline, producing high volume.
*   **Top Performer:** **Lauren George** is a standout, producing **20 SQOs** with an improving SQL→SQO rate (+10.7pp). She is the model for high-volume, high-quality production.
*   **Strong Contributor:** **Jacqueline Tully** produced **13 SQOs**. While her SQL→SQO rate dipped slightly (-4.0pp), her high volume makes her a critical pipeline contributor.

**Outbound SGAs (Hunter Group):**
Performance is mixed, with clear stars and areas for coaching.
*   **Top Performers:**
    *   **Russell Armitage:** The top outbound producer with **13 SQOs** and a significantly improved SQL→SQO rate (+22.6pp). A true bright spot.
    *   **Craig Suchodolski & Perry Kalmeta:** Both show excellent rate improvements (+23.6pp and +37.8pp respectively) and are becoming highly efficient producers.
    *   **Chris Morgan:** Shows the most dramatic rate improvement (+53.6pp), turning his process around effectively.
*   **Volume Leader with Declining Rate:** **Eleni Stefanopoulos** produced a strong **10 SQOs**, but her conversion rates are declining across the board. She is a key contributor who needs coaching to improve efficiency.
*   **Urgent Coaching Needed:** **Helen Kamens** is struggling. Her SQL→SQO rate has plummeted by **40 percentage points** (from 40% to 0%). This requires immediate intervention.

### 6. SGM-SPECIFIC RISK ASSESSMENT

*   **Under-Capacity SGMs (High Risk):**
    *   **Jade Bingham (Coverage: 0.61):** Has a $14.4M capacity gap and only 15 SQOs. She has brought in $0 this quarter and is critically starved for leads.
    *   **Bryan Belville (Coverage: 0.80):** Has a $7.5M capacity gap. While he has closed $23.3M this quarter, his future pipeline is insufficient to sustain performance.

*   **On Ramp SGMs (Expected Status):**
    *   Tim Mackey, Lexi Harrison, and Ariana Butler are all new and building their pipelines as expected. Their low capacity is not yet a concern.

*   **Sufficient SGMs (Hidden Risks):**
    *   **GinaRose Galli (Coverage: 1.35):** Her "sufficient" status is a mirage built on a bloated, stale pipeline (39.1% stale). Her velocity forecast shows $0 for the current quarter and her quarterly forecast shows $0 for next quarter. **She is at high risk of crashing.**
    *   **Corey Marcello (Coverage: 2.92):** A top performer, but needs to address his 11.4% stale pipeline to maintain health.
    *   **Bre McDaniel (Coverage: 3.81):** Our top enterprise hunter. Her pipeline is healthy and progressing as expected for long-cycle deals.

### 7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS

1.  **Issue:** Critical, firm-wide shortage of active SQOs (255 gap).
    *   **Root Cause:** Insufficient top-of-funnel volume from key channels and inconsistent SGA production.
    *   **Impact:** Inability for the majority of SGMs to hit future quarterly targets, leading to a predictable revenue downturn.
    *   **Solution:** Launch a firm-wide "Pipeline Generation" sprint. Set aggressive but achievable weekly SQL & SQO targets for all SGAs. Protect time for outbound prospecting and run targeted campaigns on under-penetrated lead lists.

2.  **Issue:** SQO→Joined conversion rate has collapsed by over 50% (9.8% → 4.4%).
    *   **Root Cause:** Unknown. Potential causes include poor lead quality not caught at handoff, declining SGM effectiveness, or market headwinds.
    *   **Impact:** Wasted effort on deals that don't close, deflating forecasts, and putting revenue at risk.
    *   **Solution:** Mandate joint SGA-SGM deal review sessions for recently lost opportunities. The goal is to identify patterns: Are we losing on price? Are prospects not a good fit? Is our process failing? This will diagnose the root cause of the conversion drop.

3.  **Issue:** Severe pipeline bloat and hygiene issues, especially with GinaRose Galli (39.1% stale).
    *   **Root Cause:** Lack of consistent pipeline management and failure to close out dead opportunities.
    *   **Impact:** Inaccurate forecasting, wasted SGM time on zombie deals, and a false sense of security. GinaRose's $80M in overdue deals and $0 next-quarter forecast is a direct result.
    *   **Solution:** Implement a mandatory pipeline cleanup. All deals stale beyond their threshold must have a documented "Next Action Date" within 7 days or be moved to Closed-Lost. This applies immediately to GinaRose and Corey.

### 8. IMMEDIATE ACTION ITEMS

*   **This Week (Critical):**
    1.  **Mandatory Pipeline Review for GinaRose Galli & Corey Marcello:** Address their stale pipelines (39.1% and 11.4% respectively). All deals older than 180 days must have a clear action plan or be closed out.
    2.  **Intervention for "Under-Capacity" SGMs:** Leadership to meet with Jade Bingham and Bryan Belville to create a 30-day plan to inject new SQOs into their pipelines.
    3.  **Coaching Session for Helen Kamens:** Address the 40pp drop in her SQL→SQO conversion rate immediately.

*   **This Month (High Priority):**
    1.  **Launch "Pipeline Generation" Sprint:** Set clear weekly SQL/SQO targets for all SGAs to begin closing the 255 active SQO gap.
    2.  **Initiate Joint Lost-Deal Analysis:** Schedule the first SGA-SGM review session to diagnose the 50%+ drop in the SQO→Joined conversion rate.
    3.  **Clean Up Overdue Deals:** All SGMs with high "Slip Risk" (Bre, Corey, GinaRose) must review every overdue deal and update its status.

*   **This Quarter (Strategic):**
    1.  **Formalize Pipeline Hygiene Policy:** Stale deals without updates are automatically flagged for closure.
    2.  **Review Lead Source Performance:** Investigate why channels like Recruitment Firm and Marketing Events are seeing sharp declines in close rates. Reallocate resources to higher-performing channels if necessary.

### 9. VELOCITY-BASED FORECASTING ANALYSIS

This physics-based forecast provides a stark reality check against our more optimistic capacity models.

*   **Current Quarter Velocity Forecast:** The firm-wide "safe" forecast (deals <70 days old) is only **$191.3M**. This is significantly below our $330.8M target, indicating we are heavily reliant on aging deals to make our number.
    *   **Corey Marcello ($88.2M)** and **Bre McDaniel ($45.9M)** have the strongest current-quarter velocity.
    *   **GinaRose Galli has a $0 velocity forecast**, meaning she has no fresh deals expected to close. Her entire hope for the quarter rests on her overdue pipeline.

*   **Overdue / Slip Risk Analysis:**
    *   **CRITICAL ALERT:** We have **$328.4M in overdue deals** (>70 days old) that are at high risk of slipping. This is a massive amount of revenue hanging in the balance.
    *   **SGMs with High Slip Risk:**
        *   **Bre McDaniel:** $132.7M (Expected for enterprise deals, but still requires scrutiny).
        *   **GinaRose Galli:** $79.9M (RED STATUS - Her entire forecast is tied to overdue deals).
        *   **Corey Marcello:** $66.2M (RED STATUS - A significant portion of his forecast is at risk).

*   **Next Quarter Pipeline Health:**
    *   The firm-wide next-quarter forecast is only **$76.4M**. This is a leading indicator that we are not building enough pipeline today to support our targets tomorrow. This confirms the risk identified in the SQO gap analysis.
    *   **GinaRose has a $0 next-quarter pipeline**, signaling an imminent performance cliff.

### 10. QUARTERLY FORECAST ANALYSIS

This model, which accounts for deal size and stage probability, provides our most likely financial outcome.

*   **Current Quarter Performance:** The firm is expected to end the quarter at **$546.9M (165% of target)**, driven almost entirely by Bre and Corey.
    *   **On Track to Exceed:** Bre McDaniel (exp. $217M), Corey Marcello (exp. $128M), GinaRose Galli (exp. $80M), Bryan Belville (exp. $43M), Erin Pearson (exp. $54M).
    *   **At Risk of Missing Target:** **Jade Bingham (exp. $15.9M)**, **Lexi Harrison (exp. $3.0M)**, **Tim Mackey (exp. $1.4M)**, and **Ariana Butler (exp. $1.2M)** are all projected to fall significantly short.

*   **Next Quarter Pipeline Health:** The forecast for next quarter is dangerously low at **$87.3M firm-wide**.
    *   **Bre McDaniel ($44.4M)** is the only SGM with a healthy next-quarter forecast that is above the individual target.
    *   **CRITICAL ALERT:** **GinaRose Galli and Tim Mackey have a $0 forecast for next quarter.** They have no pipeline projected to close, indicating they will crash without immediate intervention.

*   **Confidence & Interpretation:**
    *   **High Confidence:** The directional signals are clear. Bre and Corey will have massive quarters. Jade, Lexi, Tim, and Ariana will miss their targets. GinaRose's pipeline is empty for next quarter.
    *   **Lower Confidence:** The exact dollar amount for Bre McDaniel is subject to the binary outcome of her large enterprise deals. Her $217M forecast should be treated as "Deal Potential," not guaranteed cash flow.

### 11. SUCCESSES & BRIGHT SPOTS

Amidst the challenges, there are clear pockets of excellence we must recognize and replicate.

*   **Enterprise Dominance:** **Bre McDaniel** is executing her "Whale Hunter" role perfectly, having already closed $121.7M. Her success validates our enterprise strategy.
*   **Consistent High Performance:** **Corey Marcello** continues to be a model of consistency, hitting his number and maintaining a deep pipeline.
*   **Inbound Engine:** **Lauren George (20 SQOs)** is a high-volume, high-quality machine, setting the standard for inbound lead conversion.
*   **Outbound Star:** **Russell Armitage (13 SQOs)** has emerged as the top outbound SGA, demonstrating significant improvement in both volume and efficiency. His process should be studied and replicated across the outbound team.

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

*Note: Thresholds are calculated dynamically for each SGM based on their `required_sqos_per_quarter` value.*

| SGM | Required Joined | Required SQOs | Current Pipeline SQOs | SQO Gap | Pipeline % of Required | Interpretation |
|-----|----------------|----------------|----------------------|---------|----------------------|----------------|
| Tim Mackey | 4.0 | 40.0 | 2 | 38.0 | 5.0% | 🔴 CRITICAL |
| Ariana Butler | 4.0 | 40.0 | 5 | 35.0 | 12.5% | 🔴 CRITICAL |
| Lexi Harrison | 4.0 | 40.0 | 5 | 35.0 | 12.5% | 🔴 CRITICAL |
| Jade Bingham | 4.0 | 40.0 | 15 | 25.0 | 37.5% | ⚠️ SIGNIFICANT |
| GinaRose Galli | 4.0 | 40.0 | 8 | 32.0 | 20.0% | ⚠️ SIGNIFICANT |
| Bryan Belville | 4.0 | 40.0 | 16 | 24.0 | 40.0% | ⚠️ SIGNIFICANT |
| Erin Pearson | 4.0 | 40.0 | 19 | 21.0 | 47.5% | ⚠️ SIGNIFICANT |
| Bre McDaniel | 4.0 | 40.0 | 25 | 15.0 | 62.5% | 🟡 WITHIN RANGE |
| Corey Marcello | 4.0 | 40.0 | 27 | 13.0 | 67.5% | 🟡 WITHIN RANGE |


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
