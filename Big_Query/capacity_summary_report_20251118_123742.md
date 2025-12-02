# Capacity & Coverage Summary Report
Generated: 2025-11-18 12:37:42

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

Here is the comprehensive pipeline health analysis, structured as requested.

***

### **Pipeline Health Diagnostic: Executive Report**

### 1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY

This quarter's performance is a tale of two realities. On the surface, we are at 70.3% of our target, largely carried by two exceptional SGMs. However, a look under the hood reveals significant risks to our future performance. Our firm-wide Coverage Ratio of 1.77 appears healthy, but this number is dangerously inflated by stale, aging deals that are unlikely to close. The most critical issue is a collapse in our closing velocity: our **SQO-to-Joined conversion rate has plummeted from a 12-month average of 9.8% to just 4.4% in the last 90 days.** This means deals are entering the pipeline but are stalling out and dying before the finish line.

For the current quarter, **Bre McDaniel ($121.71M)** and **Corey Marcello ($36.90M)** have already exceeded their $36.75M targets, single-handedly driving our progress. GinaRose Galli is close at $30.8M (83.7% of target). While this is a success, our forward-looking pipeline is concerning. We have a massive firm-wide gap of 451 active SQOs needed to sustain future quarters. Two SGMs are officially "Under-Capacity" and mathematically starving for leads, while our physics-based forecast shows **$328.4M in revenue is tied to "Overdue" deals at high risk of slipping.**

**Critical Alerts for Immediate Attention:**
1.  **Closing Velocity Collapse:** The SQO→Joined rate has been cut by more than half (9.8% → 4.4%). This is our primary bottleneck and threatens all future revenue.
2.  **Massive Slip Risk:** $328.4M of our forecast is tied to deals older than our 70-day median cycle time. We are relying on hope, not physics. GinaRose Galli has **$0 in her "safe" current quarter forecast**, with 100% of her pipeline value in overdue deals.
3.  **Pipeline Starvation:** Jade Bingham (0.61 Coverage) and Bryan Belville (0.80 Coverage) do not have enough pipeline to hit future targets. They need immediate lead flow.
4.  **Pipeline Bloat:** GinaRose Galli has a dangerously high **39.1% stale pipeline**, artificially inflating her capacity and masking a real performance issue.

**Overall Assessment: At Risk.** While this quarter may be saved by top performers, the underlying health of our sales funnel is weak. The system is failing in the bottom half of the funnel (closing), and without immediate intervention to clean the pipeline and address stalled deals, we will face a significant revenue shortfall next quarter.

### 2. CAPACITY & COVERAGE ANALYSIS

*   **Current Quarter Readiness:** We have two SGMs who have already crossed the finish line this quarter: **Bre McDaniel (331% of target)** and **Corey Marcello (100.4% of target)**. GinaRose Galli is close at 83.7% of target. The remaining SGMs are significantly behind on *closed* business for the quarter.
*   **Next Quarter Readiness:** The firm-wide Coverage Ratio of 1.77 suggests we have enough total pipeline value to support future targets *in theory*. However, this is a misleading metric due to severe pipeline hygiene issues. Once stale deals are removed, our true capacity is much lower.
*   **Firm-Wide Capacity Gap:** While the model shows a surplus of $70.8M, this is not reality. The real issue is the distribution. Bre and Corey have massive surpluses, while others have significant gaps. The problem isn't total volume; it's concentration and quality.
*   **Coverage Status Breakdown:**
    *   **Sufficient (4 SGMs):** This group is led by Bre and Corey, whose massive pipelines skew the firm-wide average.
    *   **Under-Capacity (2 SGMs):** **Jade Bingham (0.61)** and **Bryan Belville (0.80)** are starving. They mathematically cannot hit future targets without an immediate injection of new, high-quality leads.
    *   **On Ramp (3 SGMs):** These SGAs are building their pipelines as expected.

### 3. SQO PIPELINE DIAGNOSIS

*   **Quantity Analysis:** We have a critical quantity problem. The firm-wide gap is **451 active SQOs**. We are simply not generating enough qualified opportunities to feed the entire team and ensure predictable revenue across the board.
*   **Quality Analysis:** Pipeline hygiene is a major concern. While the firm-wide stale rate is a manageable 6.5%, this average hides critical outliers.
    *   **GinaRose Galli has a 39.1% stale pipeline.** This is unacceptable. Deals like "Emily Hermeno" (740 days open) and "Tyler Brooks" (662 days open) are not real opportunities; they are CRM clutter that must be purged.
    *   **Corey Marcello's 11.4% stale rate** also requires attention.
*   **Root Cause Analysis:** The primary bottleneck is not at the top of the funnel. The SQL→SQO conversion rate is improving (+7.7pp), indicating the SGA-to-SGM handoff is qualifying deals effectively. The system is breaking *after* the handoff. The dramatic drop in the SQO→Joined rate (from 9.8% to 4.4%) points to a breakdown in the SGM-led sales process, deal velocity, or an inability to close qualified opportunities.

### 4. CONVERSION RATE ANALYSIS & TRENDS

*   **Overall Trends:** This is the clearest signal of our problem.
    *   **Top of Funnel (SQL→SQO):** Healthy. Rate is up 7.7 percentage points this quarter. SGAs are qualifying leads well, and SGMs are accepting them.
    *   **Bottom of Funnel (SQO→Joined):** Critical Failure. The rate has collapsed from **9.8% to 4.4%** (90-day lookback). We are generating opportunities but failing to convert them into revenue at even half our historical rate.
*   **Channel Performance:** The conversion collapse is concentrated in key channels.
    *   **Marketing / Event:** SQO→Joined rate dropped from 5.6% to 0%.
    *   **Ecosystem / Recruitment Firm:** SQO→Joined rate dropped from 10.0% to 0%.
    *   These channels are now sending leads that do not close. This requires an urgent sync with Marketing and Partnerships.
*   **Diagnostic Insights:** The data points to a closing issue, not a lead generation issue. While SGAs are successfully converting leads to SQOs, the SGMs are struggling to move these deals across the finish line. This could be due to a shift in market conditions, a decline in deal management discipline, or lower-quality leads that only reveal their flaws late in the sales cycle.

### 5. SGA PERFORMANCE ANALYSIS

*   **Inbound SGAs (The Benchmark):**
    *   **Lauren George & Jacqueline Tully** are performing their roles effectively. They are high-volume producers, generating a combined **33 SQOs** this quarter. Lauren's SQL→SQO rate has improved by 10.7pp, showing strong qualification skills. As our inbound benchmark, their solid performance indicates that top-of-funnel lead quality from Marketing is likely not the primary issue.
*   **Outbound SGAs (The Hunters):**
    *   **Top Performers:**
        *   **Russell Armitage** is a standout, producing high volume (13 SQOs) while significantly improving his SQL→SQO rate by 22.6pp.
        *   **Craig Suchodolski, Perry Kalmeta, and Chris Morgan** are all showing excellent efficiency with perfect or near-perfect SQL→SQO rates and significant improvements over their L12M averages.
    *   **Volume Leaders:**
        *   **Eleni Stefanopoulos** is a key pipeline contributor with 10 SQOs. However, her conversion rates are declining across all stages, indicating a need for coaching on qualification quality over quantity.
    *   **Coaching Opportunities:**
        *   **Helen Kamens** needs urgent attention. Her SQL→SQO rate has fallen by 40pp to 0%. This suggests a severe disconnect in the quality of leads she is passing or a breakdown in the handoff process.

### 6. SGM-SPECIFIC RISK ASSESSMENT

*   **Under-Capacity (Immediate Intervention):**
    *   **Jade Bingham (Coverage: 0.61):** Starving for pipeline with a $14.4M capacity gap and $0 in actuals this quarter. She needs an immediate, dedicated flow of leads.
    *   **Bryan Belville (Coverage: 0.80):** At risk of starving with a $7.5M gap. While he has closed $23.3M this quarter, his future pipeline is insufficient.
*   **Sufficient but High Risk:**
    *   **GinaRose Galli (Coverage: 1.35):** Her capacity is a mirage built on a **39.1% stale pipeline**. Her velocity forecast shows **$0** expected to close this quarter based on normal cycle times. Her pipeline requires an immediate and aggressive cleanup.
*   **Enterprise Watch:**
    *   **Bre McDaniel (Coverage: 3.81):** Performing exactly as expected for an enterprise hunter. She has already delivered a massive $121.7M win. Her pipeline hygiene is excellent (1.6% stale), and her large, aging deals like "Victor Flores" (216 days) are progressing, not stalled. She is the model for enterprise success.

### 7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS

| Issue                               | Root Cause                                                                                               | Impact                                                                                             | Recommended Solution                                                                                                                                                                                                                         | Owner                                   |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| **1. Closing Velocity Collapse**    | Deals are stalling in the bottom half of the funnel. SQO→Joined rate dropped from 9.8% to 4.4%.           | Future revenue is at high risk. Forecasts are unreliable.                                          | Institute mandatory weekly deal progression reviews for all deals open >70 days. Focus on identifying and executing next steps or closing out dead opportunities.                                                                               | Sales Leadership                        |
| **2. Severe Pipeline Bloat**        | Poor pipeline hygiene, particularly from GinaRose (39.1% stale) and Corey (11.4% stale).                 | Inflated capacity metrics, wasted SGM time on dead deals, and inaccurate forecasting.              | Mandate a "Close-or-Cut" deadline for all deals older than their stale threshold. SGMs must provide a documented action plan for progression or move the deal to Closed-Lost.                                                                    | RevOps & SGM Managers                   |
| **3. SGM Pipeline Starvation**      | Jade Bingham and Bryan Belville have insufficient pipeline (Coverage < 0.85).                            | These SGMs are mathematically set up to fail in future quarters, creating revenue gaps.            | Immediately re-route a higher share of qualified leads (SQOs) to Jade and Bryan. Partner with their SGAs to launch a targeted outbound campaign for their territories.                                                                        | Sales Leadership & SGA Management       |
| **4. Failing Lead Channels**        | Marketing/Event and Ecosystem/Recruitment Firm channels have a 0% SQO→Joined conversion rate.            | Wasted marketing spend and sales effort on channels that are not producing revenue.                | Schedule an urgent sync between Sales, Marketing, and Partnerships to diagnose the quality drop in these channels. Pause or re-evaluate spend until a solution is identified.                                                                 | Marketing, Partnerships, Sales Leadership |

### 8. IMMEDIATE ACTION ITEMS

*   **This Week (Critical):**
    1.  **GinaRose Galli & Corey Marcello:** SGM Managers to conduct a mandatory, deal-by-deal pipeline review focusing on all stale opportunities. Purge dead deals by EOW.
    2.  **Jade Bingham & Bryan Belville:** Leadership to implement a new lead routing rule to increase their SQO flow, effective immediately.
*   **This Month (High Priority):**
    1.  **All SGMs:** Complete the "Close-or-Cut" pipeline cleanup for all deals flagged as stale.
    2.  **Sales & Marketing Sync:** Hold a joint meeting to diagnose the 0% conversion rate from the Event and Recruitment Firm channels.
    3.  **SGA Coaching:** SGA Manager to implement a coaching plan for Helen Kamens focused on SQL qualification criteria.
*   **This Quarter (Strategic):**
    1.  **RevOps:** Refine the Coverage Ratio metric to exclude stale pipeline for a more accurate "True Coverage" score.
    2.  **Sales Enablement:** Launch a training module on late-stage deal management and velocity to address the SQO→Joined conversion drop.

### 9. VELOCITY-BASED FORECASTING ANALYSIS

*   **Current Quarter Velocity Forecast:** Our "safe" forecast, based on deals within the 70-day cycle time, is only **$191.3M**. This is dangerously low compared to our target. We are heavily dependent on closing old, at-risk deals to make our number.
*   **Overdue / Slip Risk Analysis:**
    *   A massive **$328.4M** of our pipeline value is in the "Overdue" category. This is revenue that should have already closed and is at extremely high risk of slipping to next quarter or being lost entirely.
    *   **CRITICAL ALERT (RED STATUS): GinaRose Galli has a $0 Current Quarter Velocity Forecast.** Her entire $79.9M overdue forecast is at risk, meaning she has no healthy, early-stage deals projected to close.
    *   **Bre McDaniel ($132.6M overdue)** and **Corey Marcello ($66.2M overdue)** also have significant slip risk, though Bre's is expected due to enterprise cycles.
*   **Next Quarter Pipeline Health:** The forecast for next quarter is only **$76.4M**. This is a major leading indicator of a future capacity crisis. The team is focused on closing old deals and is not building enough new pipeline to sustain future performance.
*   **Actionable Recommendations:** Leadership must shift focus from the inflated CRM forecast to this physics-based view. The $328.4M slip risk requires immediate triage. SGMs with high overdue pipelines (especially GinaRose) need mandatory reviews to accelerate or disqualify these deals. We must launch an initiative to build the anemic $76.4M pipeline for next quarter.

### 10. SUCCESSES & BRIGHT SPOTS

*   **Enterprise Execution:** **Bre McDaniel** is the star of the quarter, delivering a **$121.7M** win that has kept us on track. Her pipeline management is a model of enterprise discipline, with minimal stale deals despite long cycles.
*   **Consistent Performance:** **Corey Marcello** has already hit his quarterly number, demonstrating his reliability as a closer. His healthy "safe" forecast of $88.2M shows he is building new pipeline effectively.
*   **SGA Excellence:** The Inbound team (**Lauren George and Jacqueline Tully**) is a well-oiled machine, providing a steady stream of opportunities. In the Outbound team, **Russell Armitage** is a top performer in both volume and quality, while **Craig Suchodolski, Perry Kalmeta, and Chris Morgan** are showing remarkable improvements in efficiency.

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
