# SGM Capacity Model: Dashboard Purpose, Logic, and User Guide

## 1. 🎯 Purpose: What Is This Dashboard?

This dashboard is a predictive sales planning tool designed to answer one critical question:

**"Does each Strategic Growth Manager (SGM) have enough pipeline right now to hit their quarterly target?"**

It moves beyond lagging indicators (like "what was our AUM last quarter?") and focuses on leading indicators (like "what is our realistic pipeline value today?").

The primary goal is to give sales leadership an objective, data-driven way to manage capacity, identify risk, and coach SGMs effectively. It pinpoints exactly who needs help and, most importantly, what kind of help they need (e.g., more opportunities, bigger deals, or better pipeline hygiene).

## 2. 💡 The Logic: How Does It Work?

The model is built on a series of logical steps that combine historical performance with the current pipeline.

### Concept 1: The Target & The Average

The model starts with a fixed goal: a **$36,750,000 quarterly target** for each SGM.

It then looks at each SGM's personal performance over the last 12 months to find their `avg_margin_aum_per_sqo`. This is their historical average deal size for a qualified opportunity.

### Concept 2: The "SQO Gap" (The Core Metric)

This is the model's most important calculation. It determines the number of opportunities an SGM needs.

**Logic:** `Required SQOs = Quarterly Target / SGM's Avg_AUM_per_SQO`

**Example:** If the target is $36.75M and an SGM's average SQO is $2.5M, they need 36.75 / 2.5 = 14.7, which rounds up to 15 SQOs in their pipeline.

The dashboard then calculates the `sqo_gap_count` by taking `Required SQOs - Current Pipeline SQOs`. A negative number here is the primary call to action.

### Concept 3: The Weighted Forecast (The "Realistic" Number)

This is the most sophisticated part of the model. It recognizes that a $1M deal in "Discovery" is not as valuable as a $1M deal in "Negotiating."

- **Step A:** A separate view (`vw_stage_to_joined_probability`) calculates the all-time historical probability of an opportunity in any given stage ever converting to "Joined".

- **Step B:** The main view multiplies every open SQO's `Margin_AUM__c` by its stage's probability.

- **Step C:** The `current_pipeline_sqo_weighted_margin_aum` is the sum of these probability-adjusted values. This provides a far more realistic forecast than a simple unweighted sum.

### Concept 4: Pipeline Health (The "Staleness" Factor)

A big pipeline isn't useful if it's full of old, dead deals.

The model automatically flags any SQO that has been open for more than **120 days** as "stale." This 120-day threshold is a deliberate, data-driven choice based on analysis of your historical sales cycle.

#### Why 120 Days for Staleness Threshold?

This number was chosen after analyzing the sales cycle time (from SQO to Joined) for all historical joined opportunities.

**Cycle Time Statistics:**
- Average: 77 days
- Median: 57 days
- 75th percentile: 97 days
- 90th percentile: 148 days
- 95th percentile: 214 days

**Rationale for 120 Days:**
- It's approximately 1.5x the average cycle time (77 days × 1.5 ≈ 116 days).
- This threshold flags ~17% of all deals, catching at-risk opportunities without over-flagging normal, healthy cycles.
- It sits comfortably between the 75th percentile (97 days) and the 90th percentile (148 days), correctly identifying deals that are "meaningfully longer than average" while still allowing for normal variation.

**Alternative thresholds were rejected:**
- 90 days was too aggressive, flagging over 26% of all deals.
- 150+ days was too conservative, missing many at-risk deals.

The `current_pipeline_sqo_stale_margin_aum` metric sums the value of these stale deals, and the **Stale % of Pipeline** calculated field shows what percentage of an SGM's pipeline is at risk.

### Concept 5: The "New SGM" Fallback

What about a new SGM with no 12-month history? The model smartly handles this.

If an SGM's personal `avg_margin_aum_per_sqo` is NULL, the logic automatically falls back to the overall company average. This ensures new hires are still included in the model with a reasonable baseline.

## 3. 📈 How to Use This Dashboard: A Manager's Workflow

This dashboard is designed for action. Here's how to use it.

### New: Analyzing the "Target vs. Actual" Bar Chart

This chart provides the fastest visual summary of an SGM's position. It compares the goal against the pipeline (optimistic and realistic) and actual results.

- **quarterly_target_margin_aum (Target):** This is the goal, the static $36,750,000 bar. It's the finish line.

- **current_quarter_joined_margin_aum (Actual):** This is the realized AUM from advisors who have actually joined this quarter. This is the only bar that represents progress-to-date.

- **current_pipeline_sqo_margin_aum (Unweighted Pipeline - Actual Only):** This is the "Optimistic Forecast" using only actual Margin_AUM__c values. It's the full, face-value AUM of all open SQOs with Margin_AUM__c populated, assuming 100% will close. **Note:** This may undercount pipeline value since many SQOs don't have Margin_AUM__c yet.

- **current_pipeline_sqo_margin_aum_estimate (Unweighted Pipeline - With Estimates):** ⭐ **Recommended** This is the "Optimistic Forecast" including estimates. It includes opportunities without Margin_AUM__c by estimating from Underwritten_AUM__c or Amount.

- **current_pipeline_sqo_weighted_margin_aum (Weighted Pipeline - Actual Only):** This is the "Realistic Forecast" using only actual Margin_AUM__c values. It's the sum of each SQO's AUM (with Margin_AUM__c) multiplied by its historical probability of closing based on its current stage. **Note:** This may undercount pipeline value.

- **current_pipeline_sqo_weighted_margin_aum_estimate (Weighted Pipeline - With Estimates):** ⭐ **Recommended** This is the "Realistic Forecast" including estimates. It's the sum of each SQO's estimated AUM multiplied by its historical probability of closing. This provides the most complete and realistic view of pipeline capacity.

**How to Read This Chart:**

- **Actual vs. Target:** Compare the green bar (Actual) to the blue bar (Target) to see how far they've come.

- **Unweighted vs. Target:** Does the SGM claim to have enough? If this orange bar is below the target, they don't even have enough in their pipeline on paper.

- **Weighted vs. Target:** This is the most important comparison. Does the data support their claim? If this light-orange bar is below the target, they are statistically unlikely to hit their goal with their current pipeline.

- **Unweighted vs. Weighted:** A massive gap between these two orange bars means the SGM's pipeline is heavily skewed towards high-risk, early-stage deals (like 'Discovery').

### New: Understanding the "SGM Capacity Summary Table"

This is the central data grid for your analysis. It provides the specific numbers behind the charts and pinpoints the "why" for an SGM's status.

**Pipeline - Unweighted (current_pipeline_sqo_margin_aum):**
- **What it is:** The total, "happy ears" face-value of all open SQOs (actual Margin_AUM__c values only).
- **How it's calculated:** `SUM(Margin_AUM__c)` for all deals in the pipeline that have Margin_AUM__c populated.
- **How to use it:** This is the SGM's "best-case scenario" number, but it may undercount pipeline value since many SQOs don't have Margin_AUM__c populated yet.

**Pipeline - Unweighted Estimate (current_pipeline_sqo_margin_aum_estimate):** ⭐ **Recommended**
- **What it is:** The total estimated face-value of all open SQOs, including estimates for opportunities without Margin_AUM__c.
- **How it's calculated:** Uses actual `Margin_AUM__c` when available, otherwise estimates from `Underwritten_AUM__c / 3.125` or `Amount / 3.22` based on historical ratios.
- **How to use it:** This provides a more complete picture of pipeline capacity. Use this metric instead of the "actual only" version for capacity assessment, as it includes opportunities that haven't yet had Margin_AUM__c calculated.

**Pipeline - Weighted (current_pipeline_sqo_weighted_margin_aum):**
- **What it is:** The realistic, probability-adjusted forecast (actual Margin_AUM__c values only).
- **How it's calculated:** `SUM(Margin_AUM__c * probability_to_join)` for every SQO with Margin_AUM__c. The `probability_to_join` (from `vw_stage_to_joined_probability`) is based on all-time historical conversion rates for each specific sales stage.
- **How to use it:** This is a realistic forecast, but may undercount pipeline value since many SQOs don't have Margin_AUM__c populated yet.

**Pipeline - Weighted Estimate (current_pipeline_sqo_weighted_margin_aum_estimate):** ⭐ **Recommended**
- **What it is:** The realistic, probability-adjusted forecast including estimates for opportunities without Margin_AUM__c.
- **How it's calculated:** `SUM(estimated_margin_aum * probability_to_join)` for every SQO, using the same fallback logic as the unweighted estimate.
- **How to use it:** This is your most trustworthy forecast. If this number is less than the target, the SGM is at risk. This metric provides the most complete and realistic view of pipeline capacity.

**Stale Pipeline (current_pipeline_sqo_stale_margin_aum):**
- **What it is:** The total AUM of all SQOs that have been open for more than 120 days from their `Date_Became_SQO__c` (actual Margin_AUM__c values only).
- **How it's calculated:** `SUM(Margin_AUM__c)` for all pipeline SQOs where `sqo_age_days > 120` and Margin_AUM__c is populated.
- **How to use it:** This is a key pipeline health risk metric, but may significantly undercount stale pipeline value since most SQOs don't have Margin_AUM__c populated.
- **Limitation**: Only captures stale SQOs with Margin_AUM__c, missing the majority of stale opportunities.

**Stale Pipeline Estimate (current_pipeline_sqo_stale_margin_aum_estimate):** ⭐ **Recommended**
- **What it is:** The total estimated AUM of all stale SQOs (older than 120 days from `Date_Became_SQO__c`), including estimates for opportunities without Margin_AUM__c.
- **How it's calculated:** 
  - Uses the same three-tier fallback logic as other estimate metrics:
    1. Actual `Margin_AUM__c` if available and > 0
    2. `Underwritten_AUM__c / 3.125` if Margin_AUM__c is missing
    3. `Amount / 3.22` if both Margin_AUM__c and Underwritten_AUM__c are missing
  - Formula: `SUM(estimated_margin_aum)` for SQOs where `sqo_age_days > 120`
- **How to use it:** 
  - **Primary use**: Calculate "Stale % of Pipeline" = `(stale_margin_aum_estimate / total_pipeline_margin_aum_estimate) * 100`
  - **Thresholds**: Red flag if > 30%, Yellow if 15-30%, Green if < 15%
  - **Why it matters**: A high "Stale Pipeline Estimate" number means a large part of the SGM's forecast is locked in old, at-risk deals that are unlikely to close. It's an indicator of poor pipeline hygiene.
  - **Action item**: SGMs with > 30% stale pipeline should review and either re-engage or close out these opportunities to make room for fresh pipeline
- **Example**: 
  - SGM has $12M total pipeline estimate, $5M stale pipeline estimate = 42% stale (RED FLAG)
  - This means nearly half their pipeline is at-risk and unlikely to convert
  - They should focus on cleaning up stale deals before adding new opportunities

**Why Use Estimate Metrics?**
- Only 15.45% of open SQOs have Margin_AUM__c populated, meaning the "actual only" metrics miss 84.55% of pipeline opportunities
- 100% of open SQOs have either Underwritten_AUM__c or Amount populated, allowing us to estimate their Margin AUM
- Historical analysis shows Underwritten_AUM__c is typically 3.125x Margin_AUM__c (median), and Amount is typically 3.22x Margin_AUM__c (median)
- Estimate accuracy: ±15-20% for Underwritten_AUM__c estimates, ±20-30% for Amount estimates
- Use estimate metrics for capacity planning to get a complete picture; use actual metrics for precision when Margin_AUM__c is available

**Required SQOs per quarter:**
- **What it is:** The number of qualified opportunities the model estimates an SGM needs in their pipeline to hit their target.
- **How it's calculated:**
  - First, the model finds the SGM's personal 12-month `avg_margin_aum_per_sqo` (their average deal size).
  - If the SGM is new (no history), it uses the company-wide average as a fallback.
  - It divides the $36,750,000 target by that average deal size (e.g., $36.75M Target / $2.5M Avg. Deal Size = 14.7).
  - It rounds this number up (`CEILING`) to the next whole number (15) to ensure capacity is met.
- **How to use it:** This is the SGM's quantity target. Compare this to their Current Pipeline SQOs to find their `sqo_gap_count`.

### Workflow 1: The Weekly Team Review (Top-Down)

1. **Check the Scorecards:** Start at the top. The scorecards give you the 30,000-foot view.
   - **"SGMs On Track":** This is an actuals metric. It shows who has already hit their quarterly goal with joined AUM.
   - **"SGMs with Sufficient SQOs":** This is a pipeline metric. It shows who has the right number of opportunities to hit the goal.

2. **Identify Top Gaps:** Look at the "SGM Capacity Summary Table".
   - Sort by `sqo_gap_count` (ascending). The SGMs at the top (e.g., -10, -8) have the largest quantity gap. They are your first priority for prospecting and lead generation.
   - **Sort by Stale % of Pipeline Estimate** (descending). Create a calculated field: `(current_pipeline_sqo_stale_margin_aum_estimate / current_pipeline_sqo_margin_aum_estimate) * 100`
   - Anyone with a high red percentage (e.g., >30%) has an unhealthy pipeline. Their forecast is inflated with stale, at-risk deals, and they need to clean their book of business before adding new opportunities.
   - **Why use estimate version**: The estimate version captures all stale SQOs, not just those with Margin_AUM__c, giving you a complete picture of pipeline health.

3. **Assess the Big Picture:** Look at the "Target vs Actual Chart". You can see at a glance who is all pipeline (orange bars) versus who is driving actuals (green bars).

### Workflow 2: The 1-on-1 SGM Coaching Session (Drill-Down)

This is the most powerful use of the dashboard.

1. **Filter the Dashboard:** Use the `sgm_name` filter at the top to select the SGM you're meeting with. The entire page will now focus just on them.

2. **Diagnose the Problem:** Look at their row in the "SGM Capacity Summary Table".
   - **If `sqo_gap_count` is high:** The conversation is about prospecting. "You need 8 more qualified opportunities to hit your number. Let's talk about your plan to get them."
   - **If Stale % of Pipeline Estimate is high:** The conversation is about pipeline hygiene. 
     - Calculate: `(current_pipeline_sqo_stale_margin_aum_estimate / current_pipeline_sqo_margin_aum_estimate) * 100`
     - Example: "42% of your pipeline ($5M out of $12M) is over 120 days old. This is inflating your forecast and hiding your real gap. Your active pipeline is only $7M, which may not be enough to hit your target."
     - Action: "Let's review your stale deals. We need to either re-engage them with a clear plan or close them out to make room for fresh opportunities."
   - **If `avg_margin_aum_per_sqo` is low:** The conversation is about deal quality. "Your average deal size is $1.5M, but the team average is $2.5M. You're working twice as hard. Let's review your qualification process to find larger opportunities."

3. **Drill into the Details:**
   - Click the SGM's name in the summary table to activate the cross-filtering.
   - Scroll down to the "Open SQOs Detail Table" at the bottom. This table now shows only that SGM's active deals.
   - **Use `estimated_margin_aum` column**: This field provides estimated Margin AUM for each opportunity using the same fallback logic as the aggregate metrics (Underwritten_AUM__c / 3.125 or Amount / 3.22). This gives you a complete view of each opportunity's potential value, even if Margin_AUM__c isn't populated yet.
   - Sort by `days_open_since_sqo` (descending). "Let's go through these top 5 oldest deals one by one. What is the real, actionable next step for each?" This cuts through excuses and forces a clear status update.
   - **Why `estimated_margin_aum` is in the detail table**: Since most SQOs don't have Margin_AUM__c populated (only 15.45%), the estimated field ensures you can see the full pipeline value at the opportunity level. This matches the aggregate estimate metrics in the summary view, allowing you to verify and drill down into the numbers.

## 4. ✅ Trust & Validation: How Much Can We Trust This?

The trustworthiness of this model is high, provided you understand its assumptions.

### Trust It Because:

- It's built on your company's actual, historical sales data, not generic industry benchmarks.
- The logic is transparent. The `vw_stage_to_joined_probability` view calculates real conversion rates from your own past performance.
- It is self-verifying. The "Open SQOs Detail Table" is your source of truth. If an SGM doubts their "Current Pipeline SQO Count" in the summary, you can filter for them and manually count the rows in the detail table. They will match.

### Caveats & Assumptions (What to Watch For):

- **GIGO (Garbage In, Garbage Out):** The model is 100% dependent on high-quality Salesforce data. If SGMs do not diligently update `StageName`, `Date_Became_SQO__c`, and `Margin_AUM__c`, the model's outputs will be inaccurate. This tool will naturally enforce better data hygiene.

- **The Past Predicts the Future:** The model assumes an SGM's future performance will resemble their 12-month-historical performance. If your market, product, or sales strategy changes dramatically, the `avg_margin_aum_per_sqo` will lag behind the new reality.

- **Hardcoded Target:** The $36,750,000 target is hardcoded in the SQL view. It is not in a separate table. If quarterly targets change, a data engineer must update the `vw_sgm_capacity_model_refined.sql` file and redeploy it.

- **"Stale" is a Guide, Not a Rule:** The 120-day stale flag is a powerful, data-driven guideline, but it's not infallible. A highly complex, $50M deal might be perfectly healthy at 130 days. Use it to start a conversation, not to automatically disqualify an opportunity.