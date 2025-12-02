# Capacity & Coverage Summary Report
Generated: 2025-11-18 14:20:20

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

### **1. HIGH-LEVEL ALERTS & EXECUTIVE SUMMARY**

This report provides a diagnostic of our sales pipeline. For the **current quarter, we are ahead of plan**, largely due to exceptional performance from our enterprise and top-tier reps. However, a **critical pipeline generation gap puts next quarter at significant risk**. We are on track to achieve 165% of our firm-level target this quarter, but our forecast for next quarter is dangerously low, indicating we are not replenishing the funnel fast enough.

**Current quarter performance is strong.** Two SGMs have already exceeded their $36.75M target: **Bre McDaniel ($121.71M)** and **Corey Marcello ($36.90M)**. Their performance accounts for the majority of our current success. Firm-wide, we have achieved 70.3% of our quarterly goal, with a forecast model predicting we will end the quarter at $546.87M. While our overall pipeline coverage ratio is a healthy 1.77, this number is misleading. It is inflated by a few top performers, masking significant risk among the rest of the team. Two SGMs are "Under-Capacity" and mathematically starving for leads, while three new SGMs are still ramping with minimal pipeline.

The most critical issue is a **severe shortage of new opportunities (SQOs)**. We have a firm-wide gap of 381 active SQOs needed to sustain future performance. This is not a future problem; it is happening now. Our velocity-based forecast for next quarter is only $76.39M, and the deal-size adjusted forecast is $87.26M—both are a fraction of our $330.8M target. This confirms we are consuming pipeline faster than we are creating it.

**Critical Alerts for Immediate Attention:**
1.  **Next Quarter Crash Risk:** The forecast for next quarter is alarmingly low. Without immediate action to fill the top of the funnel, we will face a significant revenue shortfall.
2.  **Critical SQO Gap:** A firm-wide deficit of 381 active SQOs indicates a systemic lead generation issue. This is the root cause of the weak future forecast.
3.  **Lead Source Collapse:** Key lead sources like Marketing Events and Provided Lead Lists have seen a dramatic drop in both volume and conversion quality, directly contributing to the SQO gap.
4.  **Pipeline Bloat Masking Risk:** **GinaRose Galli** has a "Sufficient" coverage ratio but **39.1% of her pipeline is stale**. Her forecast is entirely dependent on reviving old, high-risk deals.

**Overall Assessment:** We are **ahead of plan for the current quarter** but **at high risk for the next**. Our current success is the result of closing deals generated in previous periods. The pipeline-building engine is sputtering, and we must address the top-of-funnel lead generation problem immediately to avoid a major downturn.

### **2. CAPACITY & COVERAGE ANALYSIS**

While the firm-wide coverage ratio of 1.77 appears healthy, it masks a polarized team performance. Capacity is a forward-looking measure of whether we have enough "iron in the fire" for future quarters. The current data shows a clear division between the "haves" and the "have-nots."

*   **Current Quarter Readiness:** Two SGMs have already crossed the finish line: **Bre McDaniel ($121.71M)** and **Corey Marcello ($36.90M)**. GinaRose Galli is close at $30.78M (84% of target). The team's success this quarter rests heavily on these individuals.
*   **Next Quarter Readiness:** The high firm-wide capacity is dangerously concentrated. Bre and Corey alone account for over half of the team's total capacity ($247.5M of $401.6M). The pipeline is not deep enough to support the entire team hitting their targets next quarter, as confirmed by the low next-quarter forecast of only $87.26M.
*   **Firm-Wide Capacity Gap:** The data shows a capacity surplus of $70.8M. This is misleading. The real story is in the distribution: 4 SGMs are sufficient, but 2 are under-capacity and 3 on-ramp SGMs have almost no pipeline to speak of. We don't have a total capacity problem; we have a distribution and replenishment problem.
*   **Coverage Status Breakdown:**
    *   **Sufficient (4):** Bre McDaniel, Corey Marcello, GinaRose Galli, Erin Pearson.
    *   **At Risk (0):** None.
    *   **Under-Capacity (2):** **Jade Bingham (0.61)** and **Bryan Belville (0.80)** are starving for leads right now.
    *   **On Ramp (3):** Tim Mackey, Lexi Harrison, and Ariana Butler are building from scratch and require significant support.

### **3. SQO PIPELINE DIAGNOSIS**

The core issue facing the sales organization is a failure to replenish the pipeline with qualified opportunities.

*   **Quantity Analysis:** We have a **firm-wide gap of 381 active (non-stale) SQOs**. This is a massive deficit and the primary leading indicator of future revenue problems. We simply do not have enough raw material in the funnel.
*   **Quality Analysis:** The firm-wide stale rate of 6.5% is deceptively low. The problem is concentrated with specific individuals, indicating a pipeline management issue.
    *   **GinaRose Galli:** 39.1% stale pipeline. This is a critical hygiene issue that inflates her capacity and masks significant risk.
    *   **Corey Marcello:** 11.4% stale pipeline. While he is a top performer, this bloat needs to be addressed.
*   **Root Cause Analysis (Balanced View):**
    *   **SGA/Marketing Perspective:** There is a clear drop in lead volume and quality from key sources. "Marketing / Event" leads have vanished, and "Outbound / Provided Lead List" volume has plummeted from a quarterly average of 42 to just 7. This starves the SGAs of raw material.
    *   **SGM Perspective:** The firm-wide SQO-to-Joined conversion rate has dropped by 5.3 percentage points. While SGAs are converting SQLs to SQOs at a higher rate (+7.7pp), SGMs are struggling to close them. This points less to SGM skill and more to the quality of SQOs being passed. SGMs cannot close poor-quality opportunities.
    *   **Conclusion:** The primary breakdown is at the **top of the funnel**. A lack of high-quality leads from key marketing channels is forcing the team to work with lower-quality prospects, causing the drop in final conversion rates.

### **3a. REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)**

**CRITICAL CONTEXT: HIGH VOLATILITY IN DEAL SIZE**
The "Required SQOs" metric is directional guidance, not a precise target. It is based on a firm-wide average deal size of $11.35M, but this average is derived from a **highly volatile dataset**:
*   **Standard Deviation:** $5.55M
*   **Coefficient of Variation:** 48.8% (This is very high, meaning individual deal sizes vary significantly from the average).
*   **Range:** Deals range from $3.75M to $23.09M.
*   **Distribution:** The median deal size is only $10.01M.

**What This Means:** An SGM closing deals larger than the $11.35M average will need fewer SQOs than the model suggests. Conversely, an SGM with smaller deals will need more. This context is crucial for interpreting the gaps below.

**SGM-Level SQO Gap Analysis:**

*   **GinaRose Galli:**
    *   Required SQOs: 54.0
    *   Current SQOs: 8
    *   **SQO Gap: 46.0 (14.8% of Required)**
    *   **Interpretation: SIGNIFICANT GAP.** This is a major red flag. Her "Sufficient" capacity is built on a few large, aging deals, not a healthy flow of new opportunities.
*   **Jade Bingham:**
    *   Required SQOs: 54.0
    *   Current SQOs: 15
    *   **SQO Gap: 39.0 (27.8% of Required)**
    *   **Interpretation: SIGNIFICANT GAP.** This confirms her "Under-Capacity" status. She needs immediate pipeline support.
*   **Bryan Belville:**
    *   Required SQOs: 54.0
    *   Current SQOs: 16
    *   **SQO Gap: 38.0 (29.6% of Required)**
    *   **Interpretation: SIGNIFICANT GAP.** Also confirms his "Under-Capacity" status.
*   **Erin Pearson:**
    *   Required SQOs: 54.0
    *   Current SQOs: 19
    *   **SQO Gap: 35.0 (35.2% of Required)**
    *   **Interpretation: MODERATE GAP.** She has healthy capacity but needs to accelerate SQO generation to stay ahead.
*   **Bre McDaniel (Enterprise Focus):**
    *   Required SQOs: 54.0
    *   Current SQOs: 25
    *   **SQO Gap: 29.0 (46.3% of Required)**
    *   **Interpretation: METRIC NOT APPLICABLE.** Bre hunts whales. Her average deal size is far larger than the model's average, making this metric irrelevant. Her pipeline value is what matters.
*   **Corey Marcello:**
    *   Required SQOs: 54.0
    *   Current SQOs: 27
    *   **SQO Gap: 27.0 (50.0% of Required)**
    *   **Interpretation: CLOSE TO TARGET.** As a top performer who has already hit his number, this gap is less concerning but serves as a reminder to keep the funnel full.

### **4. CONVERSION RATE ANALYSIS & TRENDS**

*Methodology Note: SQO→Joined rates use a 90-day lookback to account for the average 77-day sales cycle.*

*   **Overall Trends:** There is a clear bottleneck at the bottom of the funnel.
    *   **SQL→SQO Rate (Top of Funnel):** Improving by **+7.7pp**. SGAs are effectively qualifying and handing off leads.
    *   **SQO→Joined Rate (Bottom of Funnel):** Declining by **-5.3pp**. SGMs are struggling to convert the opportunities they receive.
*   **Channel & Source Diagnosis:** The decline is not random; it's tied to specific underperforming lead sources.
    *   **Marketing / Event:** Conversion has collapsed, and volume has dropped to zero. This channel is broken.
    *   **Outbound / Provided Lead List:** Volume has dropped 83% (from 42 to 7), and conversion rates are down. This source is underperforming significantly.
    *   **Ecosystem / Recruitment Firm:** The SQO→Joined rate has plummeted by **-10.0pp**. This was a strong channel that is now failing to convert.
*   **Diagnostic Insight:** The data tells a clear story: the quality of leads entering the funnel has decreased. SGAs are doing their job converting leads to opportunities, but the opportunities themselves are weaker, leading to the drop in the final close rate. This is a **lead quality problem originating from marketing and lead generation strategies**, not an SGM closing problem.

### **5. SGA PERFORMANCE ANALYSIS**

*CRITICAL: Inbound and Outbound SGAs are analyzed separately due to different roles and lead sources.*

**Inbound SGAs (Lauren George & Jacqueline Tully - The Benchmark)**
These two handle inbound leads and set the standard for performance. They are both performing well, indicating the handoff process is sound when lead quality is high.
*   **Top Performer & Volume Leader: Lauren George**
    *   **Volume:** 20 SQOs (highest on the team).
    *   **Performance:** Excellent SQL→SQO rate of 84.6%, an improvement of **+10.7pp**. She is a model of both volume and efficiency.
*   **Strong Contributor: Jacqueline Tully**
    *   **Volume:** 13 SQOs (high volume).
    *   **Performance:** Her SQL→SQO rate is high at 83.3%. While down slightly, her high volume makes her a critical pipeline contributor.

**Outbound SGAs (The Hunters)**
These SGAs must self-source and face a tougher environment.
*   **Top Performer & Volume Leader: Russell Armitage**
    *   **Volume:** 13 SQOs (highest among outbound).
    *   **Performance:** Outstanding SQL→SQO rate improvement of **+22.6pp**. He is delivering both quantity and quality.
*   **Other Bright Spots (High Efficiency):**
    *   **Chris Morgan (+53.6pp)**, **Perry Kalmeta (+37.8pp)**, and **Craig Suchodolski (+23.6pp)** have all shown massive improvements in their conversion efficiency. They are models for how to convert tough outbound leads.
*   **Volume Contributor Needing Coaching: Eleni Stefanopoulos**
    *   **Volume:** 10 SQOs (2nd highest outbound). Her volume is crucial.
    *   **Performance:** Her conversion rates are declining across the board. She needs coaching to improve the quality of her opportunities, but her high activity level is valuable.
*   **Urgent Coaching Needed: Helen Kamens**
    *   Her SQL→SQO rate has collapsed by **-40.0pp**. This is a critical performance issue that requires immediate intervention.

### **6. SGM-SPECIFIC RISK ASSESSMENT**

*   **Under-Capacity (High Risk):**
    *   **Jade Bingham:** Coverage ratio of 0.61. She is mathematically starving for leads and has a $14.44M capacity gap. She has brought in $0 this quarter.
    *   **Bryan Belville:** Coverage ratio of 0.80. He is also under-capacity with a $7.48M gap and needs immediate support.
*   **Sufficient with Hidden Risk:**
    *   **GinaRose Galli:** Her 1.35 coverage ratio is a mirage. It is propped up by **$94.5M in stale pipeline (39.1%)**. Her two largest deals are 740 and 260 days old. She has a massive SQO gap and a $0 next-quarter forecast. She is at extremely high risk of missing future targets.
*   **Enterprise Watch (Healthy for Role):**
    *   **Bre McDaniel:** Her 3.81 coverage is strong. Her pipeline contains massive deals like Greg Blake ($178M) and Victor Flores ($166M) that are progressing within expected long cycles. Her performance is exactly what we expect from an enterprise hunter.
*   **On Ramp (Building):**
    *   Tim Mackey, Lexi Harrison, and Ariana Butler have negligible pipeline. Their ramp progress and activity levels must be closely monitored.

### **7. DIAGNOSED ISSUES & SUGGESTED SOLUTIONS**

1.  **Issue:** **Critical Shortfall in Pipeline Generation.** We have a firm-wide gap of 381 active SQOs.
    *   **Root Cause:** Collapse in lead volume and quality from key channels (Marketing Events, Provided Lead Lists).
    *   **Impact:** Next quarter's revenue is at high risk. Forecast is less than 30% of target.
    *   **Recommended Solution:** Immediate, mandatory sync between Sales and Marketing leadership to diagnose and repair broken lead channels. Re-evaluate budget and strategy for these sources.

2.  **Issue:** **Declining Bottom-of-Funnel Conversion.** The SQO→Joined rate has dropped 5.3pp.
    *   **Root Cause:** Poor lead quality being passed to SGMs. SGAs are hitting their numbers, but the underlying quality is low, making deals unclippable.
    *   **Impact:** Wasted SGM time, inaccurate forecasting, and lower morale.
    *   **Recommended Solution:** Host a joint SGA-SGM workshop to review and recalibrate SQL and SQO qualification criteria. Ensure both teams are aligned on what constitutes a "sales-ready" opportunity.

3.  **Issue:** **Significant Pipeline Bloat Masking Risk.**
    *   **Root Cause:** Poor pipeline hygiene, specifically from GinaRose Galli (39.1% stale) and Corey Marcello (11.4% stale).
    *   **Impact:** Inflated capacity metrics give a false sense of security. GinaRose's forecast is almost entirely dependent on reviving dead deals.
    *   **Recommended Solution:** Mandate a pipeline review and cleanup for any SGM with over 10% stale pipeline. Deals without meaningful next steps or engagement must be closed out.

### **8. IMMEDIATE ACTION ITEMS**

*   **This Week (Critical):**
    1.  **Schedule Marketing & Sales Leadership Sync:** Address the collapse of Event and Provided Lead List channels.
    2.  **Mandatory Pipeline Review:** For GinaRose Galli and Corey Marcello to clean up stale deals.
    3.  **Prioritize Lead Flow:** Allocate any available high-quality leads to Jade Bingham and Bryan Belville.
*   **This Month (High Priority):**
    1.  **Host SGA/SGM Alignment Workshop:** Re-define and agree upon SQO qualification criteria.
    2.  **SGA Coaching Intervention:** Provide targeted coaching for Helen Kamens on qualification and conversion.
*   **This Quarter (Strategic):**
    1.  **Develop Action Plan for Underperforming Channels:** Based on the leadership sync, create a formal plan to fix or replace broken lead sources.
    2.  **Implement Pipeline Health Dashboards:** Track stale rates and SQO gaps weekly to prevent future buildup.

### **9. VELOCITY-BASED FORECASTING ANALYSIS**

*This physics-based forecast uses a 70-day median cycle time, ignoring unreliable manual close dates.*

*   **Current Quarter Velocity Forecast:** The firm is projected to bring in **$191.34M** from deals currently in the pipeline, in addition to the $232.5M already closed. This provides a strong "safe" forecast of **$423.84M** for the quarter, well above target.
*   **Overdue / Slip Risk Analysis:** This is a major red flag. There is **$328.42M in revenue attached to overdue deals** (>70 days old). This represents significant risk and pipeline clog.
    *   **CRITICAL ALERT - GinaRose Galli:** Has **$79.88M in overdue deals** and **$0.00 in her current quarter velocity forecast**. She is 100% dependent on closing old, stalled deals to hit her number. This is an unsustainable and high-risk position.
    *   **Bre McDaniel:** Has $132.65M overdue. Per her enterprise role, this is expected and should be monitored for progression, not flagged as a failure.
    *   **

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


### Required SQOs & Joined Per Quarter Analysis (With Volatility Context)

**⚠️ IMPORTANT: Understanding Volatility in Required Metrics**

The `required_sqos_per_quarter` and `required_joined_per_quarter` calculations are based on firm-wide averages from the last 12 months of joined opportunities (excluding enterprise deals >= $30M). However, these averages are derived from a highly volatile dataset:

**Volatility Analysis (Based on 35 valid joined opportunities, last 12 months):**
- **Average Margin AUM per Joined:** $11.35M
- **Standard Deviation:** $5.55M (48.8% coefficient of variation - HIGH VOLATILITY)
- **Range:** $3.75M to $23.09M (170% of the mean)
- **Distribution:** 25th percentile = $7.07M, Median = $10.01M, 75th percentile = $16.33M

**What This Means:**
- The average Margin AUM of $11.35M is based on deals ranging from $3.75M to $23.09M
- A coefficient of variation of 48.8% indicates **significant volatility** - the standard deviation is nearly half the mean
- This means the `required_sqos_per_quarter` and `required_joined_per_quarter` calculations should be viewed as **directional guidance**, not precise targets
- Individual SGMs may need more or fewer SQOs depending on the actual Margin AUM of their deals
- SGMs with consistently larger deals (closer to $16M+) may need fewer SQOs than the calculated requirement
- SGMs with consistently smaller deals (closer to $7M) may need more SQOs than the calculated requirement

**How to Use These Metrics:**
- **View as a baseline:** The required metrics provide a starting point for capacity planning
- **Consider deal size:** SGMs should assess whether their typical deal size aligns with the $11.35M average
- **Monitor trends:** Track whether actual joined Margin AUM per deal is trending up or down
- **Use for gap analysis:** Compare current pipeline SQOs to required SQOs to identify capacity gaps, but recognize that actual needs may vary based on deal size distribution
- **Key Question:** These metrics help answer "roughly how many active SQOs each SGM needs per quarter to keep their pipeline going and hit goals," but the volatility means we can't rely on one static value - actual needs vary based on deal size distribution.

| SGM | Required Joined | Required SQOs | Current Pipeline SQOs | SQO Gap | Pipeline % of Required | Interpretation |
|-----|----------------|----------------|----------------------|---------|----------------------|----------------|
| Tim Mackey | 4.0 | 54.0 | 2 | 52.0 | 3.7% | ✅ CLOSE TO TARGET |
| Ariana Butler | 4.0 | 54.0 | 5 | 49.0 | 9.3% | ✅ CLOSE TO TARGET |
| Lexi Harrison | 4.0 | 54.0 | 5 | 49.0 | 9.3% | ✅ CLOSE TO TARGET |
| Jade Bingham | 4.0 | 54.0 | 15 | 39.0 | 27.8% | ✅ CLOSE TO TARGET |
| GinaRose Galli | 4.0 | 54.0 | 8 | 46.0 | 14.8% | ✅ CLOSE TO TARGET |
| Bryan Belville | 4.0 | 54.0 | 16 | 38.0 | 29.6% | ✅ CLOSE TO TARGET |
| Erin Pearson | 4.0 | 54.0 | 19 | 35.0 | 35.2% | ✅ CLOSE TO TARGET |
| Bre McDaniel | 4.0 | 54.0 | 25 | 29.0 | 46.3% | ✅ CLOSE TO TARGET |
| Corey Marcello | 4.0 | 54.0 | 27 | 27.0 | 50.0% | ✅ CLOSE TO TARGET |


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
