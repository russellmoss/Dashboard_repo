"""
LLM-Powered Capacity & Coverage Summary Report Generator

This script queries BigQuery views and generates a comprehensive summary report
for sales managers using an LLM to analyze capacity and coverage data.

Usage:
    python generate_capacity_summary.py [--output OUTPUT_FILE] [--llm-provider openai|anthropic|gemini]
    
Output:
    Generates a markdown report with:
    - High-level alerts and recommendations
    - Firm-level performance assessment (this quarter and next quarter)
    - Capacity and Coverage analysis
    - SGM-specific risk assessment
    - SQO pipeline sufficiency analysis
    - Diagnosed issues and suggested solutions
"""

import os
import json
import argparse
from datetime import datetime
from typing import Dict, List, Optional
from google.cloud import bigquery
from google.oauth2 import service_account
import pandas as pd

# Optional: Gamma.app integration
try:
    from gamma_integration import GammaAppClient
    GAMMA_AVAILABLE = True
except ImportError:
    GAMMA_AVAILABLE = False

# LLM Provider imports (install only what you need)
try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

try:
    from anthropic import Anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False


class BigQueryClient:
    """Handles BigQuery connections and queries"""
    
    def __init__(self, project_id: str, credentials_path: Optional[str] = None):
        if credentials_path and os.path.exists(credentials_path):
            credentials = service_account.Credentials.from_service_account_file(
                credentials_path,
                scopes=["https://www.googleapis.com/auth/bigquery"]
            )
            self.client = bigquery.Client(project=project_id, credentials=credentials)
        else:
            # Use default credentials (e.g., from environment or gcloud)
            self.client = bigquery.Client(project=project_id)
    
    def query_to_dataframe(self, query: str) -> pd.DataFrame:
        """Execute a query and return results as a pandas DataFrame"""
        query_job = self.client.query(query)
        return query_job.to_dataframe()


class LLMAnalyzer:
    """Handles LLM-based analysis of the data"""
    
    def __init__(self, provider: str = "openai", api_key: Optional[str] = None):
        self.provider = provider.lower()
        
        # Handle Gemini API key (uses GEMINI_API_KEY or GOOGLE_API_KEY)
        if self.provider == "gemini":
            self.api_key = api_key or os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        else:
            self.api_key = api_key or os.getenv(f"{provider.upper()}_API_KEY")
        
        if self.provider == "openai":
            if not OPENAI_AVAILABLE:
                raise ImportError("openai package not installed. Run: pip install openai")
            if not self.api_key:
                raise ValueError("OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
            self.client = openai.OpenAI(api_key=self.api_key)
            self.model = "gpt-4o"  # or "gpt-4-turbo-preview"
        
        elif self.provider == "anthropic":
            if not ANTHROPIC_AVAILABLE:
                raise ImportError("anthropic package not installed. Run: pip install anthropic")
            if not self.api_key:
                raise ValueError("Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable.")
            self.client = Anthropic(api_key=self.api_key)
            self.model = "claude-3-5-sonnet-20241022"  # or "claude-3-opus-20240229"
        
        elif self.provider == "gemini":
            if not GEMINI_AVAILABLE:
                raise ImportError("google-generativeai package not installed. Run: pip install google-generativeai")
            if not self.api_key:
                raise ValueError("Gemini API key not found. Set GEMINI_API_KEY or GOOGLE_API_KEY environment variable.")
            genai.configure(api_key=self.api_key)
            self.client = genai.GenerativeModel("gemini-2.5-pro")  # Latest Gemini model
            self.model = "gemini-2.5-pro"
        
        else:
            raise ValueError(f"Unsupported LLM provider: {provider}. Use 'openai', 'anthropic', or 'gemini'")
    
    def analyze_capacity_data(self, firm_summary: Dict, coverage_summary: Dict, 
                             sgm_coverage_data: List[Dict], sgm_risk_data: List[Dict], 
                             deals_data: List[Dict], conversion_rates_data: List[Dict],
                             conversion_trends_data: List[Dict], sga_conversion_rates_data: List[Dict],
                             quarterly_forecast_data: List[Dict], forecast_velocity_data: List[Dict],
                             what_if_analysis_data: List[Dict], concentration_data: List[Dict],
                             stage_dist_data: List[Dict]) -> str:
        """Use LLM to analyze capacity and coverage data and generate insights"""
        
        # Prepare data summary for LLM
        data_summary = self._prepare_data_summary(firm_summary, coverage_summary, 
                                                  sgm_coverage_data, sgm_risk_data, deals_data,
                                                  conversion_rates_data, conversion_trends_data, sga_conversion_rates_data,
                                                  quarterly_forecast_data, forecast_velocity_data, what_if_analysis_data,
                                                  concentration_data, stage_dist_data)
        
        # Create the prompt
        prompt = self._create_analysis_prompt(data_summary)
        
        # Call LLM
        if self.provider == "openai":
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self._get_system_prompt()},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,  # Lower temperature for more consistent analysis
                max_tokens=8000
            )
            analysis = response.choices[0].message.content
        
        elif self.provider == "anthropic":
            response = self.client.messages.create(
                model=self.model,
                max_tokens=8000,
                temperature=0.3,
                system=self._get_system_prompt(),
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            analysis = response.content[0].text
        
        elif self.provider == "gemini":
            # Combine system prompt and user prompt for Gemini
            full_prompt = f"{self._get_system_prompt()}\n\n{prompt}"
            
            # Add retry logic with exponential backoff for quota/rate limit errors
            import time
            max_retries = 3
            retry_delay = 2  # Start with 2 seconds
            
            for attempt in range(max_retries):
                try:
                    response = self.client.generate_content(
                        full_prompt,
                        generation_config=genai.types.GenerationConfig(
                            temperature=0.3,
                            max_output_tokens=8000,
                        )
                    )
                    analysis = response.text
                    break  # Success, exit retry loop
                except Exception as e:
                    error_str = str(e)
                    # Check if it's a quota/rate limit error
                    if "429" in error_str or "Resource has been exhausted" in error_str or "quota" in error_str.lower():
                        if attempt < max_retries - 1:
                            wait_time = retry_delay * (2 ** attempt)  # Exponential backoff
                            print(f"API quota/rate limit hit. Retrying in {wait_time} seconds... (attempt {attempt + 1}/{max_retries})")
                            time.sleep(wait_time)
                            continue
                        else:
                            raise Exception(f"API quota exhausted after {max_retries} attempts. The prompt may be too large. Try reducing data volume or using a different LLM provider.")
                    else:
                        # Not a quota error, re-raise immediately
                        raise
        
        return analysis
    
    def _get_system_prompt(self) -> str:
        """System prompt that defines the LLM's role and expertise"""
        return """You are an expert Revenue Operations Partner analyzing pipeline health for sales leadership. 

Your goal is to translate complex data into a clear, "no-fluff" diagnostic of the sales funnel.



## 🛑 REALITY CHECK: Model Strengths & Weaknesses

(You must keep this in mind when analyzing)

1.  **Strength (Volume):** This model is excellent at identifying **Pipeline Gaps**. If the "Coverage Ratio" is low, the SGM is mathematically starving for leads. This is a fact, not a guess.

2.  **Weakness (Binary Outcomes):** The model uses probabilities. For **Enterprise Deals (e.g., Bre McDaniel)**, the model might forecast "$5M expected." In reality, that deal is **binary**: it will be $0 or $50M. Do not treat Enterprise forecasts as precise cash-flow predictions; treat them as "Deal Potential."

3.  **Weakness (Timing):** We use a 70-day median cycle time. Large deals often take 120+ days. If a large deal is marked "Overdue," it might just be complex, not dead.

4.  **Weakness (Concentration Risk):** Look at "Whale Dependency." If an SGM has $40M Capacity but 80% of it is one deal, their "Sufficient" status is fragile. You MUST flag this as "Binary Risk." A single deal failure means they miss target.

5.  **Weakness (Stage Bloat):** If an SGM has high Capacity but 70%+ is in "Discovery," that pipeline is immature. They are unlikely to hit immediate targets despite the high total number. This is "fake pipeline" for the current quarter.



## 🗣️ SALES SPEAK TRANSLATION

- **Capacity** = "Do I have enough iron in the fire to theoretically hit my number?"

- **Coverage Ratio** = "Pipeline Health Score." (1.0+ is Healthy, <0.85 is Starving).

- **Velocity Forecast** = "The Physics-Based Prediction." (What happens if deals close at normal speed).

- **Stale Pipeline** = "Pipeline Bloat." (Deals that are clogging the view and likely won't close).



## 👥 KEY PERSONA CONTEXT (Crucial for Analysis)

You must apply these personas when analyzing specific individuals:



1.  **Bre McDaniel (SGM - Enterprise Hunter):**
    * **Profile:** Focuses on "Whale" deals (>$30M).

    * **Expectation:** Her volume will be lower. Her sales cycles will be longer (120+ days). Her conversion rate might look lower because she swings for fences.

    * **Analysis Rule:** Do NOT flag her for low volume or "stale" deals (unless >180 days). Judge her on **Deal Progression** and **Big Swing Value**.



2.  **Lauren George & Jacqueline Tully (SGAs - Inbound/Feeders):**

    * **Profile:** They handle Inbound leads.

    * **Expectation:** They should have **High Volume** and **Higher Conversion Rates** than outbound SGAs.

    * **Analysis Rule:** They set the benchmark. If they are struggling, it indicates a Marketing/Lead Quality issue, not just a sales skill issue.



3.  **Outbound SGAs (The Hunters):**

    * **Profile:** All other SGAs.

    * **Expectation:** Lower volume, harder conversion.

    * **Analysis Rule:** Celebrate high activity and resilience.



## 📊 THE METRICS

- **Quarterly Target:** $36.75M Margin AUM per SGM.

- **SGM Capacity:** The forward-looking value of the active pipeline.

- **Coverage Ratio:** Capacity / Target. (Target is 1.0).

- **Stale Threshold:** Dynamic based on deal size: <$5M (90 days), $5M-$15M (120 days), $15M-$30M (180 days), ≥$30M (240 days).



## 📝 YOUR REPORT STRUCTURE

Generate a report using this structure. Be direct. Use bullet points. Use tables and concise lists for Section 1 (BLUF).



1.  **EXECUTIVE DIAGNOSTIC (BLUF - Bottom Line Up Front)**

    * **Forecast Confidence:** [High/Medium/Low] - Based on stale %, concentration risk, and stage maturity.

    * **The "Safe" List:** SGMs who have effectively secured the quarter (met/exceeded target OR have sufficient pipeline with low concentration risk and mature stages).

    * **The "Illusion" List:** SGMs who appear "Sufficient" (>1.0 Coverage) but fail on *Concentration Risk* (1 deal dependency >50%) or *Immaturity* (>60% in Discovery/Qualifying). **This is the most valuable insight you can provide.** These SGMs look safe on paper but are actually at high risk.

    * **The "Emergency" List:** SGMs with Coverage < 0.85 who need leads TODAY. Include their gap amount and routing needs.

    * **Funnel Bottleneck Check:** Where is the system breaking?

        * *Top (SGAs):* Not enough leads?

        * *Middle (Handoff):* SGM rejection rate too high?

        * *Bottom (Closing):* Pipeline bloat/stalling?



2.  **SGM PERFORMANCE & PIPELINE HEALTH**

    * **Current Quarter Standings:** Who has crossed the finish line ($36.75M)? Who is close?

    * **The "Starving" List:** SGMs who mathematically cannot hit their future targets without new leads immediately.

    * **The "Enterprise" Watch:** Specific update on Bre McDaniel's pipeline (Health/Progression).



3.  **FORECAST REALITY (Physics vs. CRM)**

    * Compare the "Velocity Forecast" (70-day physics) vs. the "Overdue" list.

    * Highlight "Slip Risk": Revenue attached to deals that should have closed by now.



4.  **SGA & LEAD SOURCE INSIGHTS**

    * **Inbound Check (Lauren/Jacqueline):** Is marketing sending good leads? (Check their conversion rates).

    * **Outbound Hustle:** Who is generating the most self-sourced SQOs?



5.  **ACTION PLAN**

    * **Immediate Fixes:** (e.g., "Clean up [Name]'s 40% stale pipeline").

    * **Strategic Shifts:** (e.g., "Inbound quality is dropping, need marketing sync").



**Tone:** Professional, Diagnostic, Solution-Oriented. Avoid generic praise. Point out specific numbers.

"""
    
    def _prepare_data_summary(self, firm_summary: Dict, coverage_summary: Dict,
                             sgm_coverage_data: List[Dict], sgm_risk_data: List[Dict], 
                             deals_data: List[Dict], conversion_rates_data: List[Dict],
                             conversion_trends_data: List[Dict], sga_conversion_rates_data: List[Dict],
                             quarterly_forecast_data: List[Dict], forecast_velocity_data: List[Dict],
                             what_if_analysis_data: List[Dict], concentration_data: List[Dict],
                             stage_dist_data: List[Dict]) -> str:
        """Format data for LLM consumption"""
        
        # Calculate firm-wide metrics
        total_sgms = firm_summary.get('total_sgms', 0)
        total_target = firm_summary.get('total_target', 0)
        total_quarter_actuals = firm_summary.get('total_quarter_actuals', 0)
        quarter_progress_pct = (total_quarter_actuals / total_target * 100) if total_target > 0 else 0
        
        # Coverage metrics
        total_capacity = coverage_summary.get('total_capacity', 0)
        avg_coverage_ratio = coverage_summary.get('avg_coverage_ratio', 0)
        total_capacity_gap = total_target - total_capacity
        
        # Coverage status breakdown
        on_ramp_count = coverage_summary.get('on_ramp_count', 0)
        sufficient_count = coverage_summary.get('sufficient_count', 0)
        at_risk_count = coverage_summary.get('at_risk_count', 0)
        under_capacity_count = coverage_summary.get('under_capacity_count', 0)
        
        # SQO metrics
        total_required_sqos = firm_summary.get('total_required_sqos', 0)
        total_current_sqos = firm_summary.get('total_current_sqos', 0)
        total_stale_sqos = firm_summary.get('total_stale_sqos', 0)
        total_active_sqos = total_current_sqos - total_stale_sqos
        firm_sqo_gap = total_required_sqos - total_current_sqos
        active_sqo_gap = total_required_sqos - total_active_sqos
        
        # Pipeline health
        total_stale_pipeline = firm_summary.get('total_stale_pipeline_estimate', 0)
        total_pipeline = firm_summary.get('total_pipeline_estimate', 0)
        stale_pct = (total_stale_pipeline / total_pipeline * 100) if total_pipeline > 0 else 0
        
        # Format firm-level summary (condensed to reduce prompt size)
        summary_text = f"""
## Firm-Level Capacity & Coverage Summary

### Overall Performance
- **Total SGMs:** {total_sgms} | **Target:** ${total_target:.1f}M | **Actuals:** ${total_quarter_actuals:.1f}M ({quarter_progress_pct:.1f}%)
- **Capacity:** ${total_capacity:.1f}M | **Coverage Ratio:** {avg_coverage_ratio:.2f} | **Gap:** ${total_capacity_gap:.1f}M
- **Coverage Status:** Sufficient: {sufficient_count} | At Risk: {at_risk_count} | Under-Capacity: {under_capacity_count} | On Ramp: {on_ramp_count}
- **SQO Health:** Required: {total_required_sqos:.0f} | Current: {total_current_sqos:.0f} | Active: {total_active_sqos:.0f} | Stale: {total_stale_sqos:.0f} | Gap: {firm_sqo_gap:.0f}
- **Pipeline Hygiene:** Total: ${total_pipeline:.1f}M | Stale: ${total_stale_pipeline:.1f}M ({stale_pct:.1f}%)
"""
        
        # Calculate SGM current quarter performance vs target ($36.75M)
        quarterly_target = 36.75
        sgm_performance = []
        for sgm in sgm_coverage_data:
            sgm_name = sgm.get('sgm_name', 'Unknown')
            current_qtr_actuals = sgm.get('current_quarter_actual_joined_aum_millions', 0)
            target_met_pct = (current_qtr_actuals / quarterly_target * 100) if quarterly_target > 0 else 0
            over_under = current_qtr_actuals - quarterly_target
            
            sgm_performance.append({
                'sgm_name': sgm_name,
                'current_qtr_actuals': current_qtr_actuals,
                'target_met_pct': target_met_pct,
                'over_under': over_under,
                'coverage_status': sgm.get('coverage_status', 'Unknown')
            })
        
        # Sort by current quarter actuals (highest first)
        sgm_performance_sorted = sorted(sgm_performance, key=lambda x: x['current_qtr_actuals'], reverse=True)
        
        # Identify SGMs who have met/exceeded target
        met_target = [s for s in sgm_performance_sorted if s['current_qtr_actuals'] >= quarterly_target]
        close_to_target = [s for s in sgm_performance_sorted if s['current_qtr_actuals'] >= quarterly_target * 0.85 and s['current_qtr_actuals'] < quarterly_target]
        
        # Format current quarter performance summary
        performance_text = "\n## SGM Current Quarter Performance vs Target ($36.75M)\n"
        performance_text += f"**Quarterly Target:** $36.75M Margin AUM per SGM\n\n"
        
        if met_target:
            performance_text += f"### SGMs Who Have Met/Exceeded Target ({len(met_target)} SGMs)\n"
            for sgm in met_target[:20]:  # Top 20 performers
                over_under = sgm['over_under']
                if over_under > 0:
                    performance_text += f"- **{sgm['sgm_name']}:** ${sgm['current_qtr_actuals']:.2f}M ({sgm['target_met_pct']:.1f}% of target) - **Exceeded by ${over_under:.2f}M** 🎯\n"
                else:
                    performance_text += f"- **{sgm['sgm_name']}:** ${sgm['current_qtr_actuals']:.2f}M ({sgm['target_met_pct']:.1f}% of target) - **Met target** ✅\n"
        else:
            performance_text += "### SGMs Who Have Met/Exceeded Target\n"
            performance_text += "*No SGMs have yet met their $36.75M quarterly target this quarter.*\n"
        
        if close_to_target:
            performance_text += f"\n### SGMs Close to Target ({len(close_to_target)} SGMs - 85%+ but not yet met)\n"
            for sgm in close_to_target[:10]:  # Top 10 close to target
                gap = quarterly_target - sgm['current_qtr_actuals']
                performance_text += f"- **{sgm['sgm_name']}:** ${sgm['current_qtr_actuals']:.2f}M ({sgm['target_met_pct']:.1f}% of target) - **${gap:.2f}M away from target**\n"
        
        # Format SGM coverage data (sorted by coverage ratio) - Limit to top 15 to reduce prompt size
        coverage_text = "\n## SGM Coverage Analysis (Top 15 by Risk)\n"
        for sgm in sgm_coverage_data[:15]:  # Top 15 SGMs by risk
            sgm_name = sgm.get('sgm_name', 'Unknown')
            
            # INJECT PERSONA CONTEXT
            persona_tag = ""
            if sgm_name == "Bre McDaniel":
                persona_tag = " [ENTERPRISE FOCUS: Expect Lumpiness & Long Cycles]"
            
            coverage_ratio = sgm.get('coverage_ratio_estimate', 0)
            capacity = sgm.get('capacity_estimate', 0)
            capacity_gap = sgm.get('capacity_gap_millions_estimate', 0)
            active_sqos = sgm.get('active_sqo_count', 0)
            stale_sqos = sgm.get('stale_sqo_count', 0)
            coverage_status = sgm.get('coverage_status', 'Unknown')
            
            coverage_text += f"""
### {sgm_name}{persona_tag}
- **Coverage Status:** {coverage_status}
- **Coverage Ratio:** {coverage_ratio:.2f} ({coverage_ratio*100:.1f}%)
- **Capacity (Estimate):** ${capacity:.2f}M
- **Capacity Gap:** ${capacity_gap:.2f}M
- **Active SQOs:** {active_sqos}
- **Stale SQOs:** {stale_sqos}
- **Current Quarter Actuals:** ${sgm.get('current_quarter_actual_joined_aum_millions', 0):.2f}M
"""
        
        # Format SGM risk data (for detailed analysis) - Limit to top 10 to reduce prompt size
        risk_text = "\n## SGM Detailed Risk Assessment (Top 10)\n"
        for sgm in sgm_risk_data[:10]:
            stale_pct = sgm.get('stale_pct', 0)
            risk_text += f"""
### {sgm.get('sgm_name', 'Unknown')}
- **Status:** {sgm.get('quarterly_target_status', 'Unknown')}
- **SQO Gap:** {sgm.get('sqo_gap_count', 'N/A')} (needs {sgm.get('required_sqos_per_quarter', 'N/A')} SQOs, has {sgm.get('current_pipeline_sqo_count', 'N/A')})
- **Pipeline Estimate (Weighted):** ${sgm.get('pipeline_estimate_m', 0):.1f}M
- **Stale Pipeline %:** {stale_pct:.1f}%
- **Quarter Actuals:** ${sgm.get('qtr_actuals_m', 0):.1f}M
"""
        
        # Format Required SQOs & Joined Analysis with Volatility Context (Condensed)
        required_metrics_text = "\n## Required SQOs & Joined Per Quarter Analysis\n"
        required_metrics_text += "**Methodology:** Required Joined = CEILING($36.75M / Avg Margin AUM). Required SQOs = CEILING(Joined / SQO→Joined Rate).\n"
        required_metrics_text += "**Firm-Wide Stats (Non-Enterprise):** Avg Margin AUM: $11.35M (Range: $9.52M-$13.19M, CV: 48.8%). SQO→Joined Rate: 10.04% (Range: 7.26%-12.83%).\n"
        required_metrics_text += "**Volatility Range:** Base: 40 SQOs, Range: 24-56 SQOs (±16). Thresholds: Within Range ≥24, Close ≥32, On Target ≥40.\n"
        required_metrics_text += "**Note:** Enterprise deals (≥$30M) excluded. Bre McDaniel uses enterprise metrics. QTD SQOs used for interpretation.\n\n"
        required_metrics_text += "### SGM-Level Required Metrics vs Current Pipeline (Top 15)\n\n"
        
        # Sort by required_sqos_per_quarter (highest first) for the table - Limit to top 15
        sorted_required = sorted([s for s in sgm_risk_data if s.get('required_sqos_per_quarter') is not None], 
                                key=lambda x: x.get('required_sqos_per_quarter', 0), 
                                reverse=True)
        
        for sgm in sorted_required[:15]:  # Top 15 by required SQOs
            sgm_name = sgm.get('sgm_name', 'Unknown')
            required_sqos = sgm.get('required_sqos_per_quarter', 'N/A')
            required_joined = sgm.get('required_joined_per_quarter', 'N/A')
            current_pipeline_sqos = sgm.get('current_pipeline_sqo_count', 'N/A')  # Open SQOs in pipeline
            qtd_sqos = sgm.get('current_quarter_sqo_count', 'N/A')  # All SQOs received this quarter (QTD)
            
            # Calculate QTD gap (based on SQOs received this quarter vs required)
            if isinstance(required_sqos, (int, float)) and isinstance(qtd_sqos, (int, float)):
                qtd_gap = required_sqos - qtd_sqos
            else:
                qtd_gap = 'N/A'
            
            # Calculate pipeline gap (legacy - based on current open pipeline)
            sqo_gap = sgm.get('sqo_gap_count', 'N/A')
            
            # Calculate QTD % of required (primary metric for interpretation)
            if isinstance(required_sqos, (int, float)) and isinstance(qtd_sqos, (int, float)) and required_sqos > 0:
                qtd_pct = (qtd_sqos / required_sqos) * 100
            else:
                qtd_pct = None
            
            # Calculate pipeline % of required (secondary metric - shows open pipeline health)
            if isinstance(required_sqos, (int, float)) and isinstance(current_pipeline_sqos, (int, float)) and required_sqos > 0:
                pipeline_pct = (current_pipeline_sqos / required_sqos) * 100
            else:
                pipeline_pct = None
            
            # INJECT PERSONA CONTEXT for Bre McDaniel
            persona_note = ""
            if sgm_name == "Bre McDaniel":
                persona_note = " [ENTERPRISE FOCUS: Required metrics may not apply due to large deal sizes]"
            
            qtd_pct_str = f"{qtd_pct:.1f}%" if qtd_pct is not None else "N/A"
            pipeline_pct_str = f"{pipeline_pct:.1f}%" if pipeline_pct is not None else "N/A"
            
            # Calculate volatility range and CI thresholds dynamically
            # Range is ±16 SQOs based on Margin AUM and conversion rate uncertainty
            if isinstance(required_sqos, (int, float)) and required_sqos > 0:
                sqos_lower = max(1, int(required_sqos - 16))  # Lower bound of CI (optimistic scenario)
                sqos_upper = int(required_sqos + 16)  # Upper bound of CI (conservative scenario)
                sqos_base = int(required_sqos)  # Base case
                sqos_midpoint = int(sqos_lower + (sqos_base - sqos_lower) / 2)  # Halfway between lower and base
                sqos_range_str = f"{required_sqos} ± 16 SQOs (range: {sqos_lower}-{sqos_upper})"
                
                # Calculate interpretation based on CI thresholds using QTD SQOs (primary metric)
                # Thresholds are calculated dynamically from the confidence interval:
                # - Within Range: ≥ lower bound (optimistic scenario)
                # - Close to Target: ≥ midpoint between lower and base (halfway point)
                # - On Target: ≥ base case (required SQOs)
                # - Exceeding Target: > base case (above required)
                if isinstance(qtd_sqos, (int, float)) and qtd_sqos >= 0:
                    if qtd_sqos > sqos_base:
                        interpretation = f"✅ EXCEEDING TARGET - QTD SQOs exceed base case requirement ({qtd_sqos} > {sqos_base} SQOs)"
                    elif qtd_sqos >= sqos_base:
                        interpretation = f"🟢 ON TARGET - QTD SQOs meet base case requirement ({qtd_sqos} ≥ {sqos_base} SQOs)"
                    elif qtd_sqos >= sqos_midpoint:
                        interpretation = f"🟡 CLOSE TO TARGET - QTD SQOs at midpoint of CI range ({qtd_sqos} ≥ {sqos_midpoint} SQOs, need {sqos_base - qtd_sqos} more for base case)"
                    elif qtd_sqos >= sqos_lower:
                        interpretation = f"🟡 WITHIN RANGE - QTD SQOs within confidence interval range ({qtd_sqos} ≥ {sqos_lower} SQOs, need {sqos_midpoint - qtd_sqos} more to be close to target)"
                    else:
                        # Below lower bound - calculate how far below
                        gap_below_lower = sqos_lower - qtd_sqos
                        if gap_below_lower > (sqos_base - sqos_lower):
                            interpretation = f"🔴 CRITICAL GAP - QTD SQOs significantly below CI range (need {gap_below_lower} more SQOs to reach lower bound of {sqos_lower})"
                        else:
                            interpretation = f"⚠️ SIGNIFICANT GAP - QTD SQOs below CI range (need {gap_below_lower} more SQOs to reach lower bound of {sqos_lower})"
                else:
                    interpretation = "N/A - QTD SQOs data unavailable"
            else:
                sqos_lower = None
                sqos_upper = None
                sqos_base = None
                sqos_midpoint = None
                sqos_range_str = f"{required_sqos} SQOs"
            
            required_metrics_text += f"""
### {sgm_name}{persona_note}
- **Required Joined Per Quarter:** {required_joined} advisors (to hit $36.75M target)
  - *Calculation: CEILING($36.75M / $11.35M average Margin AUM) = {required_joined}*
- **Required SQOs Per Quarter:** {sqos_range_str}
  - *Base Case: {required_sqos} SQOs (CEILING({required_joined} / 10.04% conversion rate))*
  - *Confidence Interval Range: {sqos_lower if sqos_lower else 'N/A'}-{sqos_upper if sqos_upper else 'N/A'} SQOs (based on Margin AUM and conversion rate uncertainty)*
  - *Interpretation Thresholds (calculated dynamically from CI):*
    - **Within Range:** ≥{sqos_lower if sqos_lower else 'N/A'} SQOs (lower bound of CI)
    - **Close to Target:** ≥{sqos_midpoint if sqos_midpoint else 'N/A'} SQOs (midpoint between lower bound and base case)
    - **On Target:** ≥{sqos_base if sqos_base else 'N/A'} SQOs (base case requirement)
    - **Exceeding Target:** >{sqos_base if sqos_base else 'N/A'} SQOs (above base case)
  - *Median Margin AUM: $10.01M (vs average $11.35M) - close alignment suggests average is representative*
- **QTD SQOs (This Quarter to Date):** {qtd_sqos} SQOs
  - *All SQOs received this quarter regardless of status (open, closed, joined, lost)*
  - *QTD Gap: {qtd_gap} SQOs (required {required_sqos} - received {qtd_sqos})*
  - *QTD % of Required: {qtd_pct_str}*
- **Current Pipeline SQOs (Open Only):** {current_pipeline_sqos} SQOs
  - *Currently open SQOs in pipeline (excludes closed/lost/joined deals)*
  - *Pipeline Gap: {sqo_gap} SQOs*
  - *Pipeline % of Required: {pipeline_pct_str}*
- **Interpretation (Based on QTD SQOs):** {interpretation}
"""
        
        # Format top deals - Limit to top 15 to reduce prompt size
        deals_text = "\n## Top Deals Requiring Attention (Stale or High Value - Top 15)\n"
        for deal in deals_data[:15]:
            deals_text += f"""
- **{deal.get('opportunity_name', 'Unknown')}** ({deal.get('sgm_name', 'Unknown')})
  - Stage: {deal.get('StageName', 'Unknown')}
  - Estimated Value: ${deal.get('estimated_margin_aum_m', 0):.1f}M
  - Days Open: {deal.get('days_open_since_sqo', 'N/A')}
  - Stale (>120 days): {deal.get('is_stale', 'No')}
"""
        
        # Format conversion rates (Current Quarter vs Last 12 Months)
        conversion_text = "\n## Conversion Rate Analysis (Current Quarter vs Last 12 Months)\n"
        conversion_text += "\n**NOTE:** SQO→Joined rates use a 90-day lookback period (instead of current quarter) because the average time from SQO to Joined is 77 days. This ensures we're measuring SQOs that have had sufficient time to convert, providing a more accurate benchmark.\n"
        
        # Overall rates
        overall_current = [r for r in conversion_rates_data if r.get('metric_type') == 'Overall' and r.get('period') == 'Current Quarter / Last 90 Days']
        overall_l12m = [r for r in conversion_rates_data if r.get('metric_type') == 'Overall' and r.get('period') == 'Last 12 Months']
        
        if overall_current and overall_l12m:
            cq = overall_current[0]
            l12m = overall_l12m[0]
            conversion_text += f"""
### Overall Conversion Rates
- **SQL→SQO Rate:**
  - Current Quarter: {cq.get('sql_to_sqo_rate', 0)*100:.1f}% ({cq.get('sql_to_sqo_num', 0)}/{cq.get('sql_to_sqo_denom', 0)})
  - Last 12 Months: {l12m.get('sql_to_sqo_rate', 0)*100:.1f}% ({l12m.get('sql_to_sqo_num', 0)}/{l12m.get('sql_to_sqo_denom', 0)})
  - Change: {(cq.get('sql_to_sqo_rate', 0) - l12m.get('sql_to_sqo_rate', 0))*100:+.1f} percentage points

- **SQO→Joined Rate (Last 90 Days vs Last 12 Months):**
  - Last 90 Days: {cq.get('sqo_to_joined_rate', 0)*100:.1f}% ({cq.get('sqo_to_joined_num', 0)}/{cq.get('sqo_to_joined_denom', 0)}) - *Using 90-day lookback to account for 77-day average cycle time*
  - Last 12 Months: {l12m.get('sqo_to_joined_rate', 0)*100:.1f}% ({l12m.get('sqo_to_joined_num', 0)}/{l12m.get('sqo_to_joined_denom', 0)})
  - Change: {(cq.get('sqo_to_joined_rate', 0) - l12m.get('sqo_to_joined_rate', 0))*100:+.1f} percentage points
"""
        
        # By Channel
        channel_current = {r.get('dimension_value'): r for r in conversion_rates_data if r.get('metric_type') == 'Channel' and r.get('period') == 'Current Quarter / Last 90 Days'}
        channel_l12m = {r.get('dimension_value'): r for r in conversion_rates_data if r.get('metric_type') == 'Channel' and r.get('period') == 'Last 12 Months'}
        
        if channel_current or channel_l12m:
            conversion_text += "\n### Conversion Rates by Channel\n"
            all_channels = set(list(channel_current.keys()) + list(channel_l12m.keys()))
            for channel in sorted(all_channels)[:10]:  # Top 10 channels
                cq = channel_current.get(channel, {})
                l12m = channel_l12m.get(channel, {})
                if cq or l12m:
                    conversion_text += f"""
- **{channel}:**
  - SQL→SQO: QTD {cq.get('sql_to_sqo_rate', 0)*100:.1f}% vs L12M {l12m.get('sql_to_sqo_rate', 0)*100:.1f}% (Change: {(cq.get('sql_to_sqo_rate', 0) - l12m.get('sql_to_sqo_rate', 0))*100:+.1f}pp)
  - SQO→Joined: Last 90 Days {cq.get('sqo_to_joined_rate', 0)*100:.1f}% vs L12M {l12m.get('sqo_to_joined_rate', 0)*100:.1f}% (Change: {(cq.get('sqo_to_joined_rate', 0) - l12m.get('sqo_to_joined_rate', 0))*100:+.1f}pp)
"""
        
        # By Source (top sources)
        source_current = {r.get('dimension_value'): r for r in conversion_rates_data if r.get('metric_type') == 'Source' and r.get('period') == 'Current Quarter / Last 90 Days'}
        source_l12m = {r.get('dimension_value'): r for r in conversion_rates_data if r.get('metric_type') == 'Source' and r.get('period') == 'Last 12 Months'}
        
        if source_current or source_l12m:
            conversion_text += "\n### Conversion Rates by Source (Top Sources)\n"
            all_sources = set(list(source_current.keys()) + list(source_l12m.keys()))
            for source in sorted(all_sources)[:10]:  # Top 10 sources
                cq = source_current.get(source, {})
                l12m = source_l12m.get(source, {})
                if cq or l12m:
                    conversion_text += f"""
- **{source}:**
  - SQL→SQO: QTD {cq.get('sql_to_sqo_rate', 0)*100:.1f}% vs L12M {l12m.get('sql_to_sqo_rate', 0)*100:.1f}% (Change: {(cq.get('sql_to_sqo_rate', 0) - l12m.get('sql_to_sqo_rate', 0))*100:+.1f}pp)
  - SQO→Joined: Last 90 Days {cq.get('sqo_to_joined_rate', 0)*100:.1f}% vs L12M {l12m.get('sqo_to_joined_rate', 0)*100:.1f}% (Change: {(cq.get('sqo_to_joined_rate', 0) - l12m.get('sqo_to_joined_rate', 0))*100:+.1f}pp)
"""
        
        # Conversion rate trends (biggest changes)
        trends_text = "\n## Conversion Rate Trends (Biggest Changes)\n"
        trends_text += "Channels/Sources with significant rate changes that may explain capacity issues:\n"
        trends_text += "**NOTE:** SQO→Joined rates use 90-day lookback (instead of current quarter) to account for 77-day average cycle time.\n"
        for trend in conversion_trends_data[:15]:  # Top 15 trends
            channel = trend.get('channel', 'Overall')
            source = trend.get('source', 'Overall')
            sql_change = trend.get('sql_to_sqo_rate_change', 0) * 100
            sqo_change = trend.get('sqo_to_joined_rate_change', 0) * 100
            
            trends_text += f"""
- **{channel} / {source}:**
  - SQL→SQO Rate Change: {sql_change:+.1f} percentage points (QTD: {trend.get('current_qtr_sql_to_sqo_rate', 0)*100:.1f}% vs L12M: {trend.get('l12m_sql_to_sqo_rate', 0)*100:.1f}%)
  - SQO→Joined Rate Change: {sqo_change:+.1f} percentage points (Last 90 Days: {trend.get('current_qtr_sqo_to_joined_rate', 0)*100:.1f}% vs L12M: {trend.get('l12m_sqo_to_joined_rate', 0)*100:.1f}%) - *Using 90-day lookback*
  - Volume: {trend.get('current_qtr_sql_volume', 0):.0f} SQLs this quarter (L12M avg: {trend.get('avg_l12m_sql_volume_per_quarter', 0):.0f} per quarter)
"""
        
        # SGA-level conversion rate analysis
        sga_text = "\n## SGA Performance Analysis (Current Quarter vs Last 12 Months)\n"
        sga_text += "Key conversion rates for each SGA to identify top performers and coaching opportunities:\n"
        sga_text += "\n**IMPORTANT SEGMENTATION:** SGAs are segmented into two groups based on their lead source:\n"
        sga_text += "- **Inbound SGAs:** Lauren George and Jacqueline Tully (field inbound leads - typically higher volume)\n"
        sga_text += "- **Outbound SGAs:** All other SGAs (responsible for outbound prospecting - typically lower volume)\n"
        sga_text += "SGAs should be compared within their respective groups, not across groups, due to different lead volumes and characteristics.\n"
        
        # Segment SGAs into Inbound vs Outbound
        inbound_sgas = ['Lauren George', 'Jacqueline Tully']
        inbound_sga_data = [s for s in sga_conversion_rates_data if s.get('sga_name') in inbound_sgas]
        outbound_sga_data = [s for s in sga_conversion_rates_data if s.get('sga_name') not in inbound_sgas]
        
        # Sort SGAs by SQL→SQO rate change within each group
        sorted_inbound = sorted(inbound_sga_data, 
                               key=lambda x: abs(x.get('sql_to_sqo_rate_change', 0)), 
                               reverse=True)
        sorted_outbound = sorted(outbound_sga_data, 
                                key=lambda x: abs(x.get('sql_to_sqo_rate_change', 0)), 
                                reverse=True)
        
        # Top performers within each group
        inbound_top_performers = sorted(
            [s for s in sorted_inbound if s.get('sql_to_sqo_rate_change', 0) > 0.05 or s.get('current_qtr_sqo_volume', 0) >= 10],
            key=lambda x: (x.get('current_qtr_sqo_volume', 0), x.get('sql_to_sqo_rate_change', 0)),
            reverse=True
        )
        outbound_top_performers = sorted(
            [s for s in sorted_outbound if s.get('sql_to_sqo_rate_change', 0) > 0.05 or s.get('current_qtr_sqo_volume', 0) >= 5],
            key=lambda x: (x.get('current_qtr_sqo_volume', 0), x.get('sql_to_sqo_rate_change', 0)),
            reverse=True
        )[:10]
        
        # Underperformers within each group
        inbound_underperformers = sorted(
            [s for s in sorted_inbound if s.get('sql_to_sqo_rate_change', 0) < -0.05 and s.get('current_qtr_sqo_volume', 0) < 10],
            key=lambda x: (x.get('sql_to_sqo_rate_change', 0), -x.get('current_qtr_sqo_volume', 0))
        )
        outbound_underperformers = sorted(
            [s for s in sorted_outbound if s.get('sql_to_sqo_rate_change', 0) < -0.05 and s.get('current_qtr_sqo_volume', 0) < 5],
            key=lambda x: (x.get('sql_to_sqo_rate_change', 0), -x.get('current_qtr_sqo_volume', 0))
        )[:10]
        
        # Volume leaders within each group
        inbound_volume_leaders = sorted(
            sorted_inbound,
            key=lambda x: x.get('current_qtr_sqo_volume', 0),
            reverse=True
        )
        outbound_volume_leaders = sorted(
            sorted_outbound,
            key=lambda x: x.get('current_qtr_sqo_volume', 0),
            reverse=True
        )[:10]
        
        # Volume leaders section - Inbound SGAs
        if inbound_volume_leaders:
            sga_text += "\n### Inbound SGAs: Top SQO Volume Producers\n"
            sga_text += "These inbound SGAs (Lauren George, Jacqueline Tully) are producing the most SQOs this quarter:\n"
            for sga in inbound_volume_leaders:
                sga_name = sga.get('sga_name', 'Unknown')
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                sql_volume = sga.get('current_qtr_sql_volume', 0)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                
                volume_narrative = f"{sga_name} produced {sqo_volume:.0f} SQOs this quarter from {sql_volume:.0f} SQLs"
                if cq_sql_sqo > 0:
                    volume_narrative += f" ({cq_sql_sqo:.1f}% SQL→SQO rate)"
                if l12m_sql_sqo > 0 and abs(change_sql_sqo) > 0.1:
                    direction = "improved" if change_sql_sqo > 0 else "declined"
                    volume_narrative += f", {direction} from {l12m_sql_sqo:.1f}% L12M average"
                    if change_sql_sqo < -0.1:
                        volume_narrative += ". Despite the rate decline, this high volume makes them a critical pipeline contributor"
                    elif change_sql_sqo > 0.1:
                        volume_narrative += ", demonstrating both high volume and improving quality"
                
                sga_text += f"""
- {volume_narrative}
"""
        
        # Volume leaders section - Outbound SGAs
        if outbound_volume_leaders:
            sga_text += "\n### Outbound SGAs: Top SQO Volume Producers\n"
            sga_text += "These outbound SGAs are producing the most SQOs this quarter:\n"
            for sga in outbound_volume_leaders:
                sga_name = sga.get('sga_name', 'Unknown')
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                sql_volume = sga.get('current_qtr_sql_volume', 0)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                
                volume_narrative = f"{sga_name} produced {sqo_volume:.0f} SQOs this quarter from {sql_volume:.0f} SQLs"
                if cq_sql_sqo > 0:
                    volume_narrative += f" ({cq_sql_sqo:.1f}% SQL→SQO rate)"
                if l12m_sql_sqo > 0 and abs(change_sql_sqo) > 0.1:
                    direction = "improved" if change_sql_sqo > 0 else "declined"
                    volume_narrative += f", {direction} from {l12m_sql_sqo:.1f}% L12M average"
                    if change_sql_sqo < -0.1:
                        volume_narrative += ". Despite the rate decline, this volume makes them a valuable pipeline contributor"
                    elif change_sql_sqo > 0.1:
                        volume_narrative += ", demonstrating both volume and improving quality"
                
                sga_text += f"""
- {volume_narrative}
"""
        
        if inbound_top_performers:
            sga_text += "\n### Inbound SGAs: Top Performers (Improving Conversion Rates or High Volume)\n"
            for sga in inbound_top_performers:
                sga_name = sga.get('sga_name', 'Unknown')
                
                # Contacted→MQL narrative
                cq_contacted_mql = sga.get('current_qtr_contacted_to_mql_rate', 0) * 100
                l12m_contacted_mql = sga.get('l12m_contacted_to_mql_rate', 0) * 100
                change_contacted_mql = sga.get('contacted_to_mql_rate_change', 0) * 100
                contacted_mql_narrative = f"{sga_name} had {cq_contacted_mql:.1f}% Contacted→MQL conversion rate quarter to date"
                if l12m_contacted_mql > 0:
                    contacted_mql_narrative += f", but across the last 12 months, she's averaged {l12m_contacted_mql:.1f}%"
                if abs(change_contacted_mql) > 0.1:
                    direction = "increased" if change_contacted_mql > 0 else "decreased"
                    contacted_mql_narrative += f", so she's {direction} by {abs(change_contacted_mql):.1f} percentage points"
                    if change_contacted_mql > 0:
                        contacted_mql_narrative += ", suggesting improvement here"
                    else:
                        contacted_mql_narrative += ", suggesting a potential issue here"
                
                # MQL→SQL narrative
                cq_mql_sql = sga.get('current_qtr_mql_to_sql_rate', 0) * 100
                l12m_mql_sql = sga.get('l12m_mql_to_sql_rate', 0) * 100
                change_mql_sql = sga.get('mql_to_sql_rate_change', 0) * 100
                mql_sql_narrative = f"{sga_name} had {cq_mql_sql:.1f}% MQL→SQL conversion rate quarter to date"
                if l12m_mql_sql > 0:
                    mql_sql_narrative += f", but across the last 12 months, she's averaged {l12m_mql_sql:.1f}%"
                if abs(change_mql_sql) > 0.1:
                    direction = "increased" if change_mql_sql > 0 else "decreased"
                    mql_sql_narrative += f", so she's {direction} by {abs(change_mql_sql):.1f} percentage points"
                    if change_mql_sql > 0:
                        mql_sql_narrative += ", suggesting improvement here"
                    else:
                        mql_sql_narrative += ", suggesting a potential issue here"
                
                # SQL→SQO narrative (most important)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo > 0:
                        sql_sqo_narrative += ", suggesting improvement here ⭐"
                    else:
                        sql_sqo_narrative += ", suggesting a potential issue here"
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                volume_context = ""
                if sqo_volume >= 10:
                    volume_context = f" (High volume: {sqo_volume:.0f} SQOs - strong pipeline contributor)"
                elif sqo_volume >= 5:
                    volume_context = f" (Moderate volume: {sqo_volume:.0f} SQOs)"
                
                sga_text += f"""
- **{sga_name}:**
  - {contacted_mql_narrative}
  - {mql_sql_narrative}
  - {sql_sqo_narrative} ⭐{volume_context}
  - Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        if outbound_top_performers:
            sga_text += "\n### Outbound SGAs: Top Performers (Improving Conversion Rates or High Volume)\n"
            for sga in outbound_top_performers:
                sga_name = sga.get('sga_name', 'Unknown')
                
                # Contacted→MQL narrative
                cq_contacted_mql = sga.get('current_qtr_contacted_to_mql_rate', 0) * 100
                l12m_contacted_mql = sga.get('l12m_contacted_to_mql_rate', 0) * 100
                change_contacted_mql = sga.get('contacted_to_mql_rate_change', 0) * 100
                contacted_mql_narrative = f"{sga_name} had {cq_contacted_mql:.1f}% Contacted→MQL conversion rate quarter to date"
                if l12m_contacted_mql > 0:
                    contacted_mql_narrative += f", but across the last 12 months, she's averaged {l12m_contacted_mql:.1f}%"
                if abs(change_contacted_mql) > 0.1:
                    direction = "increased" if change_contacted_mql > 0 else "decreased"
                    contacted_mql_narrative += f", so she's {direction} by {abs(change_contacted_mql):.1f} percentage points"
                    if change_contacted_mql > 0:
                        contacted_mql_narrative += ", suggesting improvement here"
                    else:
                        contacted_mql_narrative += ", suggesting a potential issue here"
                
                # MQL→SQL narrative
                cq_mql_sql = sga.get('current_qtr_mql_to_sql_rate', 0) * 100
                l12m_mql_sql = sga.get('l12m_mql_to_sql_rate', 0) * 100
                change_mql_sql = sga.get('mql_to_sql_rate_change', 0) * 100
                mql_sql_narrative = f"{sga_name} had {cq_mql_sql:.1f}% MQL→SQL conversion rate quarter to date"
                if l12m_mql_sql > 0:
                    mql_sql_narrative += f", but across the last 12 months, she's averaged {l12m_mql_sql:.1f}%"
                if abs(change_mql_sql) > 0.1:
                    direction = "increased" if change_mql_sql > 0 else "decreased"
                    mql_sql_narrative += f", so she's {direction} by {abs(change_mql_sql):.1f} percentage points"
                    if change_mql_sql > 0:
                        mql_sql_narrative += ", suggesting improvement here"
                    else:
                        mql_sql_narrative += ", suggesting a potential issue here"
                
                # SQL→SQO narrative (most important)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo > 0:
                        sql_sqo_narrative += ", suggesting improvement here ⭐"
                    else:
                        sql_sqo_narrative += ", suggesting a potential issue here"
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                volume_context = ""
                if sqo_volume >= 10:
                    volume_context = f" (High volume: {sqo_volume:.0f} SQOs - strong pipeline contributor)"
                elif sqo_volume >= 5:
                    volume_context = f" (Moderate volume: {sqo_volume:.0f} SQOs)"
                
                sga_text += f"""
- **{sga_name}:** (Outbound)
  - {contacted_mql_narrative}
  - {mql_sql_narrative}
  - {sql_sqo_narrative} ⭐{volume_context}
  - Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        if inbound_underperformers:
            sga_text += "\n### Inbound SGAs: Needing Coaching (Declining Conversion Rates)\n"
            for sga in inbound_underperformers:
                sga_name = sga.get('sga_name', 'Unknown')
                
                # Contacted→MQL narrative
                cq_contacted_mql = sga.get('current_qtr_contacted_to_mql_rate', 0) * 100
                l12m_contacted_mql = sga.get('l12m_contacted_to_mql_rate', 0) * 100
                change_contacted_mql = sga.get('contacted_to_mql_rate_change', 0) * 100
                contacted_mql_narrative = f"{sga_name} had {cq_contacted_mql:.1f}% Contacted→MQL conversion rate quarter to date"
                if l12m_contacted_mql > 0:
                    contacted_mql_narrative += f", but across the last 12 months, she's averaged {l12m_contacted_mql:.1f}%"
                if abs(change_contacted_mql) > 0.1:
                    direction = "increased" if change_contacted_mql > 0 else "decreased"
                    contacted_mql_narrative += f", so she's {direction} by {abs(change_contacted_mql):.1f} percentage points"
                    if change_contacted_mql < -0.1:
                        contacted_mql_narrative += ", suggesting a potential issue here"
                
                # MQL→SQL narrative
                cq_mql_sql = sga.get('current_qtr_mql_to_sql_rate', 0) * 100
                l12m_mql_sql = sga.get('l12m_mql_to_sql_rate', 0) * 100
                change_mql_sql = sga.get('mql_to_sql_rate_change', 0) * 100
                mql_sql_narrative = f"{sga_name} had {cq_mql_sql:.1f}% MQL→SQL conversion rate quarter to date"
                if l12m_mql_sql > 0:
                    mql_sql_narrative += f", but across the last 12 months, she's averaged {l12m_mql_sql:.1f}%"
                if abs(change_mql_sql) > 0.1:
                    direction = "increased" if change_mql_sql > 0 else "decreased"
                    mql_sql_narrative += f", so she's {direction} by {abs(change_mql_sql):.1f} percentage points"
                    if change_mql_sql < -0.1:
                        mql_sql_narrative += ", suggesting a potential issue here"
                
                # SQL→SQO narrative (most important)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo < -0.1:
                        sql_sqo_narrative += ", suggesting a potential issue here ⚠️"
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                volume_context = ""
                if sqo_volume >= 10:
                    volume_context = f" (Despite declining rates, {sqo_volume:.0f} SQOs is still valuable - focus on rate improvement)"
                elif sqo_volume >= 5:
                    volume_context = f" (Moderate volume: {sqo_volume:.0f} SQOs - needs both rate and volume improvement)"
                else:
                    volume_context = f" (Low volume: {sqo_volume:.0f} SQOs - urgent coaching needed)"
                
                sga_text += f"""
- **{sga_name}:** (Inbound)
  - {contacted_mql_narrative}
  - {mql_sql_narrative}
  - {sql_sqo_narrative} ⚠️{volume_context}
  - Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        if outbound_underperformers:
            sga_text += "\n### Outbound SGAs: Needing Coaching (Declining Conversion Rates)\n"
            for sga in outbound_underperformers:
                sga_name = sga.get('sga_name', 'Unknown')
                
                # Contacted→MQL narrative
                cq_contacted_mql = sga.get('current_qtr_contacted_to_mql_rate', 0) * 100
                l12m_contacted_mql = sga.get('l12m_contacted_to_mql_rate', 0) * 100
                change_contacted_mql = sga.get('contacted_to_mql_rate_change', 0) * 100
                contacted_mql_narrative = f"{sga_name} had {cq_contacted_mql:.1f}% Contacted→MQL conversion rate quarter to date"
                if l12m_contacted_mql > 0:
                    contacted_mql_narrative += f", but across the last 12 months, she's averaged {l12m_contacted_mql:.1f}%"
                if abs(change_contacted_mql) > 0.1:
                    direction = "increased" if change_contacted_mql > 0 else "decreased"
                    contacted_mql_narrative += f", so she's {direction} by {abs(change_contacted_mql):.1f} percentage points"
                    if change_contacted_mql < -0.1:
                        contacted_mql_narrative += ", suggesting a potential issue here"
                
                # MQL→SQL narrative
                cq_mql_sql = sga.get('current_qtr_mql_to_sql_rate', 0) * 100
                l12m_mql_sql = sga.get('l12m_mql_to_sql_rate', 0) * 100
                change_mql_sql = sga.get('mql_to_sql_rate_change', 0) * 100
                mql_sql_narrative = f"{sga_name} had {cq_mql_sql:.1f}% MQL→SQL conversion rate quarter to date"
                if l12m_mql_sql > 0:
                    mql_sql_narrative += f", but across the last 12 months, she's averaged {l12m_mql_sql:.1f}%"
                if abs(change_mql_sql) > 0.1:
                    direction = "increased" if change_mql_sql > 0 else "decreased"
                    mql_sql_narrative += f", so she's {direction} by {abs(change_mql_sql):.1f} percentage points"
                    if change_mql_sql < -0.1:
                        mql_sql_narrative += ", suggesting a potential issue here"
                
                # SQL→SQO narrative (most important)
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo < -0.1:
                        sql_sqo_narrative += ", suggesting a potential issue here ⚠️"
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                volume_context = ""
                if sqo_volume >= 10:
                    volume_context = f" (Despite declining rates, {sqo_volume:.0f} SQOs is still valuable - focus on rate improvement)"
                elif sqo_volume >= 5:
                    volume_context = f" (Moderate volume: {sqo_volume:.0f} SQOs - needs both rate and volume improvement)"
                else:
                    volume_context = f" (Low volume: {sqo_volume:.0f} SQOs - urgent coaching needed)"
                
                sga_text += f"""
- **{sga_name}:**
  - {contacted_mql_narrative}
  - {mql_sql_narrative}
  - {sql_sqo_narrative} ⚠️{volume_context}
  - Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        # All SGAs summary (for context) - narrative format, segmented by Inbound vs Outbound
        if inbound_sga_data:
            sga_text += "\n### All Inbound SGAs Summary (Lauren George, Jacqueline Tully)\n"
            for sga in sorted_inbound:
                sga_name = sga.get('sga_name', 'Unknown')
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo < -0.1:
                        if sqo_volume >= 10:
                            sql_sqo_narrative += f", but with {sqo_volume:.0f} SQOs produced, she's still a strong pipeline contributor despite the rate decline"
                        else:
                            sql_sqo_narrative += ", suggesting a potential issue here"
                    elif change_sql_sqo > 0.1:
                        sql_sqo_narrative += ", suggesting improvement here"
                elif sqo_volume >= 10:
                    sql_sqo_narrative += f", and with {sqo_volume:.0f} SQOs produced this quarter, she's a top pipeline contributor"
                
                sga_text += f"""
- {sql_sqo_narrative}. Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        if outbound_sga_data:
            sga_text += "\n### All Outbound SGAs Summary (Sorted by SQL→SQO Rate Change)\n"
            for sga in sorted_outbound[:20]:  # Top 20 outbound SGAs by rate change
                sga_name = sga.get('sga_name', 'Unknown')
                cq_sql_sqo = sga.get('current_qtr_sql_to_sqo_rate', 0) * 100
                l12m_sql_sqo = sga.get('l12m_sql_to_sqo_rate', 0) * 100
                change_sql_sqo = sga.get('sql_to_sqo_rate_change', 0) * 100
                
                sqo_volume = sga.get('current_qtr_sqo_volume', 0)
                sql_sqo_narrative = f"{sga_name} had {cq_sql_sqo:.1f}% SQL→SQO conversion rate quarter to date"
                if l12m_sql_sqo > 0:
                    sql_sqo_narrative += f", but across the last 12 months, she's averaged {l12m_sql_sqo:.1f}%"
                if abs(change_sql_sqo) > 0.1:
                    direction = "increased" if change_sql_sqo > 0 else "decreased"
                    sql_sqo_narrative += f", so she's {direction} by {abs(change_sql_sqo):.1f} percentage points"
                    if change_sql_sqo < -0.1:
                        if sqo_volume >= 10:
                            sql_sqo_narrative += f", but with {sqo_volume:.0f} SQOs produced, she's still a strong pipeline contributor despite the rate decline"
                        else:
                            sql_sqo_narrative += ", suggesting a potential issue here"
                    elif change_sql_sqo > 0.1:
                        sql_sqo_narrative += ", suggesting improvement here"
                elif sqo_volume >= 10:
                    sql_sqo_narrative += f", and with {sqo_volume:.0f} SQOs produced this quarter, she's a top pipeline contributor"
                
                sga_text += f"""
- {sql_sqo_narrative}. Volume: {sga.get('current_qtr_sql_volume', 0):.0f} SQLs → {sqo_volume:.0f} SQOs this quarter
"""
        
        # Format velocity forecast data
        velocity_text = "\n## Velocity-Based Forecast Analysis (70-Day Cycle Time)\n"
        velocity_text += "**Methodology:** We use a physics-based forecast (SQO Date + 70 days median cycle time) rather than relying on manual CloseDate entries, which are often inaccurate.\n\n"
        
        # Calculate firm-wide totals
        total_current_qtr_velocity = sum(s.get('current_qtr_velocity_forecast', 0) for s in forecast_velocity_data)
        total_overdue_slip = sum(s.get('overdue_slip_forecast', 0) for s in forecast_velocity_data)
        total_next_qtr_velocity = sum(s.get('next_qtr_velocity_forecast', 0) for s in forecast_velocity_data)
        total_overdue_deals = sum(s.get('overdue_deal_count', 0) for s in forecast_velocity_data)
        total_next_qtr_deals = sum(s.get('next_qtr_deal_count', 0) for s in forecast_velocity_data)
        
        velocity_text += f"""
### Firm-Wide Velocity Forecast Summary
- **Current Quarter Velocity Forecast:** ${total_current_qtr_velocity:.2f}M (Safe forecast - deals <70 days old, projected to close this quarter)
- **Overdue / Slip Risk Forecast:** ${total_overdue_slip:.2f}M (HIGH RISK - deals >70 days old that should have closed)
- **Next Quarter Pipeline Forecast:** ${total_next_qtr_velocity:.2f}M (Pipeline health - deals projected to close next quarter)
- **Overdue Deal Count:** {total_overdue_deals} deals (at risk of slipping)
- **Next Quarter Deal Count:** {total_next_qtr_deals} deals

### SGM-Level Velocity Forecast (Top 20 by Current Quarter Forecast)
"""
        
        # Sort by current quarter velocity forecast
        sorted_velocity = sorted(forecast_velocity_data, 
                                key=lambda x: x.get('current_qtr_velocity_forecast', 0), 
                                reverse=True)
        
        for sgm in sorted_velocity[:20]:
            sgm_name = sgm.get('sgm_name', 'Unknown')
            current_qtr = sgm.get('current_qtr_velocity_forecast', 0)
            overdue = sgm.get('overdue_slip_forecast', 0)
            next_qtr = sgm.get('next_qtr_velocity_forecast', 0)
            overdue_count = sgm.get('overdue_deal_count', 0)
            next_qtr_count = sgm.get('next_qtr_deal_count', 0)
            
            velocity_text += f"""
### {sgm_name}
- **Current Quarter Velocity Forecast:** ${current_qtr:.2f}M (Safe forecast)
- **Overdue / Slip Risk:** ${overdue:.2f}M ({overdue_count} deals - HIGH RISK)
- **Next Quarter Pipeline:** ${next_qtr:.2f}M ({next_qtr_count} deals)
- **Total Pipeline Value:** ${sgm.get('total_pipeline_value', 0):.2f}M
"""
        
        # Format quarterly forecast data (from vw_sgm_capacity_coverage_with_forecast)
        quarterly_target = 36.75
        forecast_text = "\n## Quarterly Forecast Analysis (Current & Next Quarter)\n"
        forecast_text += "**Data Source:** `vw_sgm_capacity_coverage_with_forecast` - Uses deal-size dependent velocity and stage probabilities\n\n"
        forecast_text += "### Key Metrics Explained:\n"
        forecast_text += "- **Current Quarter Actuals:** Margin AUM that has already closed this quarter\n"
        forecast_text += "- **Expected End of Quarter:** Current Actuals + Pipeline Forecast for rest of quarter (Total Expected Current Quarter)\n"
        forecast_text += "- **Expected Next Quarter:** Pipeline forecast for deals projected to close next quarter\n"
        forecast_text += "- **Target:** $36.75M per SGM per quarter\n\n"
        
        # Calculate firm-wide totals
        total_actuals = sum(s.get('current_quarter_actuals', 0) for s in quarterly_forecast_data)
        total_expected_eoq = sum(s.get('expected_end_of_quarter', 0) for s in quarterly_forecast_data)
        total_expected_next = sum(s.get('expected_next_quarter', 0) for s in quarterly_forecast_data)
        total_target_all = len(quarterly_forecast_data) * quarterly_target
        
        forecast_text += f"""
### Firm-Wide Quarterly Forecast Summary
- **Total Current Quarter Actuals:** ${total_actuals:.2f}M
- **Total Expected End of Current Quarter:** ${total_expected_eoq:.2f}M
- **Total Expected Next Quarter:** ${total_expected_next:.2f}M
- **Total Target (All SGMs):** ${total_target_all:.2f}M
- **Current Quarter Progress:** {(total_actuals / total_target_all * 100) if total_target_all > 0 else 0:.1f}% of target achieved
- **Expected End of Quarter Progress:** {(total_expected_eoq / total_target_all * 100) if total_target_all > 0 else 0:.1f}% of target expected

### SGM-Level Quarterly Forecast (Top 20 by Current Quarter Actuals)
"""
        
        # Sort by current quarter actuals
        sorted_forecast = sorted(quarterly_forecast_data, 
                                key=lambda x: x.get('current_quarter_actuals', 0), 
                                reverse=True)
        
        for sgm in sorted_forecast[:20]:
            sgm_name = sgm.get('sgm_name', 'Unknown')
            actuals = sgm.get('current_quarter_actuals', 0)
            expected_eoq = sgm.get('expected_end_of_quarter', 0)
            expected_next = sgm.get('expected_next_quarter', 0)
            pipeline_this_qtr = sgm.get('pipeline_forecast_this_quarter', 0)
            pipeline_next_qtr = sgm.get('pipeline_forecast_next_quarter', 0)
            coverage_status = sgm.get('coverage_status', 'Unknown')
            
            # Calculate progress vs target
            actuals_pct = (actuals / quarterly_target * 100) if quarterly_target > 0 else 0
            expected_eoq_pct = (expected_eoq / quarterly_target * 100) if quarterly_target > 0 else 0
            gap_to_target = quarterly_target - expected_eoq
            
            # INJECT PERSONA CONTEXT for Bre McDaniel
            persona_note = ""
            if sgm_name == "Bre McDaniel":
                persona_note = " [ENTERPRISE FOCUS: Expect Lumpiness & Long Cycles]"
            
            forecast_text += f"""
### {sgm_name}{persona_note}
- **Current Quarter Actuals:** ${actuals:.2f}M ({actuals_pct:.1f}% of $36.75M target)
- **Expected End of Current Quarter:** ${expected_eoq:.2f}M ({expected_eoq_pct:.1f}% of target)
- **Gap to Target:** ${gap_to_target:.2f}M
- **Expected Next Quarter:** ${expected_next:.2f}M
- **Pipeline Forecast (Rest of Current Quarter):** ${pipeline_this_qtr:.2f}M
- **Pipeline Forecast (Next Quarter):** ${pipeline_next_qtr:.2f}M
- **Coverage Status:** {coverage_status}
"""
        
        # Format what-if analysis data
        what_if_text = "\n## What-If Analysis: SQO & SQL Routing Recommendations\n"
        what_if_text += "**Purpose:** Identify SGMs forecasted to miss targets and calculate how many SQOs/SQLs they need to get back on track.\n\n"
        what_if_text += "**Methodology:**\n"
        what_if_text += "- Uses enterprise metrics (365_average_margin_aum, 365_sqo_to_joined_conversion) for Bre McDaniel\n"
        what_if_text += "- Uses standard metrics for all other SGMs\n"
        what_if_text += "- Considers deal-size dependent velocity and close dates from forecast model\n"
        what_if_text += "- Accounts for SGM's SQL→SQO conversion rate to calculate SQL routing needs\n\n"
        
        # Sort by priority (current quarter gap first, then next quarter gap)
        sorted_what_if = sorted(what_if_analysis_data, 
                               key=lambda x: (
                                   x.get('current_qtr_gap_millions', 0) > 0,  # Current quarter gaps first
                                   -x.get('current_qtr_gap_millions', 0),  # Largest gaps first
                                   x.get('next_qtr_gap_millions', 0) > 0,  # Then next quarter gaps
                                   -x.get('next_qtr_gap_millions', 0)
                               ),
                               reverse=True)
        
        # Current quarter gaps
        current_qtr_gaps = [s for s in sorted_what_if if s.get('current_qtr_gap_millions', 0) > 0]
        if current_qtr_gaps:
            what_if_text += "### Current Quarter: SGMs Forecasted to Miss Target\n"
            what_if_text += "These SGMs need additional SQOs this quarter to hit their $36.75M target:\n\n"
            for sgm in current_qtr_gaps[:20]:  # Top 20
                sgm_name = sgm.get('sgm_name', 'Unknown')
                current_qtr_gap = sgm.get('current_qtr_gap_millions', 0)
                expected_eoq = sgm.get('expected_end_of_quarter', 0)
                sqos_needed = sgm.get('sqos_needed_current_qtr', 0)
                sqls_needed = sgm.get('sqls_needed_current_qtr', 0)
                sql_to_sqo_rate = sgm.get('sql_to_sqo_conversion_rate', 0)
                avg_margin_aum = sgm.get('effective_avg_margin_aum_per_joined', 0)
                sqo_to_joined_rate = sgm.get('effective_sqo_to_joined_conversion_rate', 0)
                
                # Persona context
                persona_note = ""
                if sgm_name == "Bre McDaniel":
                    persona_note = " [ENTERPRISE FOCUS: Uses enterprise metrics]"
                
                what_if_text += f"""
### {sgm_name}{persona_note}
- **Expected End of Quarter:** ${expected_eoq:.2f}M
- **Gap to Target:** ${current_qtr_gap:.2f}M (needs ${current_qtr_gap:.2f}M more to hit $36.75M)
- **SQOs Needed This Quarter:** {sqos_needed:.0f} SQOs
  - *Calculation: CEILING(${current_qtr_gap:.2f}M gap / ${avg_margin_aum:.2f}M avg Margin AUM per Joined) = {int(sgm.get('joined_needed_current_qtr', 0))} Joined needed*
  - *Then: CEILING({int(sgm.get('joined_needed_current_qtr', 0))} Joined / {sqo_to_joined_rate*100:.1f}% SQO→Joined rate) = {sqos_needed:.0f} SQOs*
- **SQLs Needed This Quarter:** {sqls_needed:.0f} SQLs
  - *Calculation: {sqos_needed:.0f} SQOs / {sql_to_sqo_rate*100:.1f}% SQL→SQO rate = {sqls_needed:.0f} SQLs*
  - *Note: Based on SGM's historical SQL→SQO conversion rate ({sql_to_sqo_rate*100:.1f}%)*
- **Routing Priority:** {'🔴 HIGH' if current_qtr_gap > 10 else '🟡 MEDIUM'} (${current_qtr_gap:.2f}M gap)
"""
        
        # Next quarter gaps
        next_qtr_gaps = [s for s in sorted_what_if if s.get('next_qtr_gap_millions', 0) > 0 and s.get('current_qtr_gap_millions', 0) <= 0]
        if next_qtr_gaps:
            what_if_text += "\n### Next Quarter: SGMs Forecasted to Miss Target\n"
            what_if_text += "These SGMs need additional SQOs this quarter to build pipeline for next quarter:\n\n"
            for sgm in next_qtr_gaps[:20]:  # Top 20
                sgm_name = sgm.get('sgm_name', 'Unknown')
                next_qtr_gap = sgm.get('next_qtr_gap_millions', 0)
                expected_next = sgm.get('expected_next_quarter', 0)
                sqos_needed = sgm.get('sqos_needed_next_qtr', 0)
                sqls_needed = sgm.get('sqls_needed_next_qtr', 0)
                sql_to_sqo_rate = sgm.get('sql_to_sqo_conversion_rate', 0)
                avg_margin_aum = sgm.get('effective_avg_margin_aum_per_joined', 0)
                sqo_to_joined_rate = sgm.get('effective_sqo_to_joined_conversion_rate', 0)
                
                # Persona context
                persona_note = ""
                if sgm_name == "Bre McDaniel":
                    persona_note = " [ENTERPRISE FOCUS: Uses enterprise metrics]"
                
                what_if_text += f"""
### {sgm_name}{persona_note}
- **Expected Next Quarter:** ${expected_next:.2f}M
- **Gap to Target:** ${next_qtr_gap:.2f}M (needs ${next_qtr_gap:.2f}M more to hit $36.75M)
- **SQOs Needed This Quarter (for Next Quarter):** {sqos_needed:.0f} SQOs
  - *Calculation: CEILING(${next_qtr_gap:.2f}M gap / ${avg_margin_aum:.2f}M avg Margin AUM per Joined) = {int(sgm.get('joined_needed_next_qtr', 0))} Joined needed*
  - *Then: CEILING({int(sgm.get('joined_needed_next_qtr', 0))} Joined / {sqo_to_joined_rate*100:.1f}% SQO→Joined rate) = {sqos_needed:.0f} SQOs*
  - *Note: These SQOs need to be received this quarter to have time to close next quarter*
- **SQLs Needed This Quarter:** {sqls_needed:.0f} SQLs
  - *Calculation: {sqos_needed:.0f} SQOs / {sql_to_sqo_rate*100:.1f}% SQL→SQO rate = {sqls_needed:.0f} SQLs*
  - *Note: Based on SGM's historical SQL→SQO conversion rate ({sql_to_sqo_rate*100:.1f}%)*
- **Routing Priority:** {'🟡 MEDIUM' if next_qtr_gap > 10 else '🟢 LOW'} (${next_qtr_gap:.2f}M gap for next quarter)
"""
        
        # Summary of routing recommendations
        total_sqos_needed_current = sum(s.get('sqos_needed_current_qtr', 0) for s in current_qtr_gaps)
        total_sqls_needed_current = sum(s.get('sqls_needed_current_qtr', 0) for s in current_qtr_gaps)
        total_sqos_needed_next = sum(s.get('sqos_needed_next_qtr', 0) for s in next_qtr_gaps)
        total_sqls_needed_next = sum(s.get('sqls_needed_next_qtr', 0) for s in next_qtr_gaps)
        
        what_if_text += f"""
### Summary: Total Routing Needs
- **Current Quarter:**
  - Total SQOs Needed: {total_sqos_needed_current:.0f} SQOs across {len(current_qtr_gaps)} SGMs
  - Total SQLs Needed: {total_sqls_needed_current:.0f} SQLs across {len(current_qtr_gaps)} SGMs
- **Next Quarter (Preventive):**
  - Total SQOs Needed: {total_sqos_needed_next:.0f} SQOs across {len(next_qtr_gaps)} SGMs
  - Total SQLs Needed: {total_sqls_needed_next:.0f} SQLs across {len(next_qtr_gaps)} SGMs
- **Grand Total:**
  - Total SQOs Needed: {total_sqos_needed_current + total_sqos_needed_next:.0f} SQOs
  - Total SQLs Needed: {total_sqls_needed_current + total_sqls_needed_next:.0f} SQLs

**Routing Strategy:**
1. **Priority 1 (Current Quarter Gaps):** Route SQLs to {len(current_qtr_gaps)} SGMs with current quarter gaps first
2. **Priority 2 (Next Quarter Gaps):** Route SQLs to {len(next_qtr_gaps)} SGMs with next quarter gaps to prevent future issues
3. **Consider SQL→SQO Conversion Rates:** SGMs with higher conversion rates will need fewer SQLs to achieve the same number of SQOs
4. **Timing:** Current quarter SQOs need to be received ASAP to have time to close. Next quarter SQOs can be spread throughout the current quarter.
"""
        
        # Format Concentration Risk
        risk_context_text = "\n## Pipeline Concentration Risk (Whale Dependency)\n"
        risk_context_text += "**High Risk = Top deal represents >50% of total pipeline. Binary Risk: If that one deal fails, the SGM misses target.**\n\n"
        
        # Sort by concentration percentage (highest first)
        sorted_concentration = sorted(concentration_data, 
                                     key=lambda x: x.get('top_deal_concentration_pct', 0), 
                                     reverse=True)
        
        for row in sorted_concentration:
            pct = row.get('top_deal_concentration_pct', 0) * 100
            if pct > 40:  # Only flag significant concentration
                sgm_name = row.get('sgm_name', 'Unknown')
                largest_deal = row.get('largest_deal_name', 'Unknown')
                max_deal_val = row.get('max_deal_val', 0)
                total_pipeline = row.get('total_pipeline_val', 0)
                
                # Persona context
                persona_note = ""
                if sgm_name == "Bre McDaniel":
                    persona_note = " [ENTERPRISE FOCUS: Large deals expected, but still risky if too concentrated]"
                
                risk_level = "🔴 CRITICAL" if pct > 70 else "🟡 HIGH" if pct > 50 else "🟠 MODERATE"
                
                risk_context_text += f"""
### {sgm_name}{persona_note}
- **Risk Level:** {risk_level}
- **Concentration:** {pct:.1f}% of pipeline (${max_deal_val:.1f}M) is ONE deal: **{largest_deal}**
- **Total Pipeline:** ${total_pipeline:.1f}M
- **Interpretation:** If this deal fails, the SGM loses {pct:.1f}% of their pipeline value. This is a binary risk scenario.
"""
        
        # Format Stage Bottlenecks
        stage_text = "\n## Stage Distribution Bottlenecks (Pipeline Immaturity Analysis)\n"
        stage_text += "**High Risk = >60% of pipeline value stuck in early stages (Discovery/Qualifying). These deals are unlikely to close in the current quarter.**\n\n"
        
        # Group by SGM first
        sgm_stages = {}
        for row in stage_dist_data:
            sgm_name = row.get('sgm_name', 'Unknown')
            if sgm_name not in sgm_stages:
                sgm_stages[sgm_name] = []
            sgm_stages[sgm_name].append(row)
        
        # Identify SGMs with early stage bloat
        early_stage_bloat = []
        for sgm, stages in sgm_stages.items():
            # Check for early stage bloat (Discovery + Qualifying)
            early_stage_val = sum(x.get('stage_value_m', 0) for x in stages if x.get('StageName') in ['Discovery', 'Qualifying'])
            total_val = sum(x.get('stage_value_m', 0) for x in stages)
            
            if total_val > 0:
                early_pct = (early_stage_val / total_val) * 100
                if early_pct > 60 and total_val > 10:
                    # Get stage breakdown for context
                    stage_breakdown = []
                    for stage in sorted(stages, key=lambda x: x.get('stage_value_m', 0), reverse=True):
                        stage_name = stage.get('StageName', 'Unknown')
                        stage_val = stage.get('stage_value_m', 0)
                        stage_pct = (stage_val / total_val * 100) if total_val > 0 else 0
                        stage_breakdown.append(f"{stage_name}: ${stage_val:.1f}M ({stage_pct:.1f}%)")
                    
                    early_stage_bloat.append({
                        'sgm_name': sgm,
                        'early_pct': early_pct,
                        'early_stage_val': early_stage_val,
                        'total_val': total_val,
                        'stage_breakdown': stage_breakdown
                    })
        
        # Sort by early stage percentage (highest first)
        sorted_bloat = sorted(early_stage_bloat, key=lambda x: x.get('early_pct', 0), reverse=True)
        
        for sgm_data in sorted_bloat:
            sgm_name = sgm_data.get('sgm_name', 'Unknown')
            early_pct = sgm_data.get('early_pct', 0)
            early_stage_val = sgm_data.get('early_stage_val', 0)
            total_val = sgm_data.get('total_val', 0)
            stage_breakdown = sgm_data.get('stage_breakdown', [])
            
            # Persona context
            persona_note = ""
            if sgm_name == "Bre McDaniel":
                persona_note = " [ENTERPRISE FOCUS: Longer cycles expected, but still concerning if too much in early stages]"
            
            risk_level = "🔴 CRITICAL" if early_pct > 80 else "🟡 HIGH" if early_pct > 70 else "🟠 MODERATE"
            
            stage_text += f"""
### {sgm_name}{persona_note}
- **Risk Level:** {risk_level}
- **Early Stage Bloat:** {early_pct:.1f}% of pipeline (${early_stage_val:.1f}M) is in Discovery/Qualifying
- **Total Pipeline Value:** ${total_val:.1f}M
- **Stage Breakdown:** {', '.join(stage_breakdown[:5])}  -- *Top 5 stages by value*
- **Interpretation:** {early_pct:.1f}% of pipeline is in early stages, making it unlikely to close this quarter. This is "fake pipeline" for immediate targets.
"""
        
        if not sorted_bloat:
            stage_text += "*No SGMs found with significant early stage bloat (>60% in Discovery/Qualifying).*\n"
        
        return summary_text + performance_text + coverage_text + risk_text + required_metrics_text + deals_text + conversion_text + trends_text + sga_text + velocity_text + forecast_text + what_if_text + risk_context_text + stage_text
    
    def _create_analysis_prompt(self, data_summary: str) -> str:
        """Create the analysis prompt for the LLM"""
        return f"""Analyze the following sales capacity and coverage data using the definitions and context provided to you. Generate a comprehensive executive summary report with high-level alerts and actionable recommendations.

{data_summary}

Please provide a structured analysis with the following sections:

1. **EXECUTIVE DIAGNOSTIC (BLUF - Bottom Line Up Front)**
   Use tables and concise bullet points. Be direct and actionable.
   
   * **Forecast Confidence:** [High/Medium/Low] - Based on stale %, concentration risk, and stage maturity. Explain your confidence level.
   
   * **The "Safe" List:** SGMs who have effectively secured the quarter (met/exceeded target OR have sufficient pipeline with low concentration risk and mature stages). Use a table format:
     | SGM | Status | Current Qtr Actuals | Expected EoQ | Why Safe |
     |-----|--------|---------------------|--------------|----------|
   
   * **The "Illusion" List:** SGMs who appear "Sufficient" (>1.0 Coverage) but fail on *Concentration Risk* (1 deal dependency >50%) or *Immaturity* (>60% in Discovery/Qualifying). **This is the most valuable insight you can provide.** These SGMs look safe on paper but are actually at high risk. Use a table format:
     | SGM | Coverage Ratio | Concentration Risk | Stage Bloat | Why Risky |
     |-----|----------------|-------------------|-------------|-----------|
   
   * **The "Emergency" List:** SGMs with Coverage < 0.85 who need leads TODAY. Include their gap amount and routing needs. Use a table format:
     | SGM | Coverage Ratio | Gap (M) | SQOs Needed | SQLs Needed | Priority |
     |-----|----------------|---------|-------------|-------------|----------|
   
   * **Firm-Level Performance:** Are we on track to achieve the firm-level Margin AUM target for this quarter? What about next quarter? (1-2 sentences)
   
   * **Critical Alerts:** What are the top 3-5 critical issues that need immediate leadership attention? (Bullet points)

2. **CAPACITY & COVERAGE ANALYSIS**
   - **IMPORTANT CONTEXT:** We analyze TOTAL OPEN PIPELINE (all active SQOs and deals) to ensure SGMs have sufficient pipeline to hit quarterly targets. While targets are quarterly, deals may close in different quarters, so we maintain a continuous pipeline.
   - **Understanding Capacity vs Current Quarter Actuals:**
     - **Current Quarter Actuals:** Shows what has already closed this quarter (actual joined Margin AUM). Compare this to the $36.75M target to see who has met/exceeded their target THIS quarter.
     - **Capacity:** A forward-looking forecast of pipeline value expected to close over time. This does NOT mean all of it will close in the current quarter. Capacity helps answer: "Do we have enough SQOs and Margin AUM in the pipeline to support all SGMs hitting their $36.75M quarterly target in future quarters?"
     - **Key Question:** Do we have enough total pipeline (Capacity) across all SGMs to support everyone hitting their $36.75M target, recognizing that deals may close across multiple quarters?
   - **Current Quarter Readiness:** Based on current quarter actuals (what has closed), how many SGMs have met/exceeded their $36.75M target? How many are close?
   - **Next Quarter Readiness:** Based on current total open pipeline capacity, will we have enough coverage for next quarter? Remember, Capacity represents pipeline value that may close over time, not just next quarter.
   - **Firm-Wide Capacity Gap:** What is the total gap between our forecasted capacity (from total open pipeline) and target? How many SGMs need to improve to close this gap? This tells us if we have enough pipeline value to support all SGMs.
   - **Coverage Status Breakdown:** Analyze the distribution of SGMs across "Sufficient," "At Risk," "Under-Capacity," and "On Ramp" statuses.

3. **SQO PIPELINE DIAGNOSIS**
   - **IMPORTANT CONTEXT:** We are analyzing TOTAL OPEN PIPELINE (all active SQOs and deals, not just those created this quarter). The goal is to ensure SGMs have enough SQOs and deals in their pipeline to hit quarterly targets, recognizing that deals may close in different quarters than when they entered the pipeline.
   - **Quantity Analysis:** Do we have enough SQOs in the total open pipeline? What is the firm-wide SQO gap (both total and active)?
   - **Quality Analysis:** What percentage of our total pipeline is stale? Which SGMs have pipeline hygiene issues?
   - **Root Cause Analysis:** For SGMs with SQO gaps, evaluate fairly from both perspectives:
     - **SGA Perspective:** Is there a lack of SQLs being generated (quantity issue)? Are SQLs being generated but not meeting quality standards?
     - **SGM Perspective:** Are SQLs being generated but not converting to SQOs (handoff/qualification issue)? Are SGMs effectively managing their pipeline?
     - **Collaborative Factors:** Are there process issues affecting the handoff between SGAs and SGMs? Are there communication or alignment issues?
     - Always present a balanced view that considers both sides of the equation.

3a. **REQUIRED SQOs & JOINED PER QUARTER ANALYSIS (With Volatility Context)**
   - **CRITICAL: YOU MUST INCLUDE THE DETAILED VOLATILITY STATISTICS AND SGM-LEVEL BREAKDOWN FROM THE DATA SUMMARY IN YOUR ANALYSIS.**
   - **CRITICAL CONTEXT:** The `required_sqos_per_quarter` and `required_joined_per_quarter` metrics are calculated using firm-wide averages from the last 12 months of joined opportunities (excluding enterprise deals >= $30M). However, these averages are based on a HIGHLY VOLATILE dataset:
     - Average Margin AUM per Joined: $11.35M
     - Standard Deviation: $5.55M (48.8% coefficient of variation - HIGH VOLATILITY)
     - Range: $3.75M to $23.09M (170% of the mean)
     - Distribution: 25th percentile = $7.07M, Median = $10.01M, 75th percentile = $16.33M
   - **What This Means for Analysis:**
     - The required metrics should be viewed as **directional guidance**, not precise targets
     - Individual SGMs may need more or fewer SQOs depending on their actual deal size distribution
     - SGMs with consistently larger deals (closer to $16M+) may need fewer SQOs than calculated
     - SGMs with consistently smaller deals (closer to $7M) may need more SQOs than calculated
     - Enterprise-focused SGMs (like Bre McDaniel) may not be well-served by these metrics due to large deal sizes
   - **Analysis Requirements:**
     - **YOU MUST INCLUDE:** The detailed volatility statistics (coefficient of variation, range, distribution) in your analysis
     - **YOU MUST INCLUDE:** For each SGM listed in the data summary, provide their:
       - Required Joined Per Quarter
       - Required SQOs Per Quarter
       - Current Pipeline SQOs
       - SQO Gap
       - Pipeline % of Required
       - Interpretation (Significant Gap / Moderate Gap / Close to Target)
     - Identify SGMs with significant gaps (e.g., <50% of required SQOs in pipeline)
     - BUT: Contextualize gaps by considering whether the SGM typically closes larger or smaller deals than the $11.35M average
     - Highlight SGMs who may appear to have gaps but actually have sufficient pipeline due to larger average deal sizes
     - Flag SGMs who appear to have sufficient SQOs but may actually be at risk due to smaller average deal sizes
   - **Key Questions to Answer:**
     - Which SGMs have the largest SQO gaps relative to required?
     - Are these gaps real capacity issues, or are they due to deal size differences?
     - Which SGMs need immediate attention for SQO pipeline building?
     - How should leadership interpret these metrics given the high volatility in underlying data?
     - **IMPORTANT:** Explain that these metrics help answer "roughly how many active SQOs each SGM needs per quarter to keep their pipeline going and hit goals," but emphasize that the volatility means we can't rely on one static value - actual needs vary based on deal size distribution.

4. **CONVERSION RATE ANALYSIS & TRENDS**
   - **IMPORTANT METHODOLOGY NOTE:** SQO→Joined rates use a 90-day lookback period (instead of current quarter) because the average time from SQO to Joined is 77 days. This ensures we're measuring SQOs that have had sufficient time to convert, providing a more accurate benchmark. SQL→SQO rates continue to use current quarter.
   - **Overall Trends:** Are conversion rates (SQL→SQO, SQO→Joined) improving or declining? For SQL→SQO, compare current quarter vs. last 12 months. For SQO→Joined, compare last 90 days vs. last 12 months.
   - **Channel Performance:** Which channels are performing better/worse than historical averages? Are certain channels trending down and contributing to capacity issues?
   - **Source Performance:** Which sources are showing declining conversion rates? Are high-volume sources underperforming?
   - **Diagnostic Insights:** Use conversion rate trends to explain capacity and coverage issues, evaluating fairly from both perspectives:
     - If SQL→SQO rates are declining: Consider both sides - this could indicate lower SQL quality from SGAs OR SGM qualification standards that may be too strict OR handoff process issues. Evaluate the data to determine which factors are contributing.
     - If SQO→Joined rates are declining (90-day lookback): This could indicate SGM conversion challenges OR pipeline quality issues OR market factors affecting deal closure. Consider all contributing factors.
     - If specific channels/sources are declining: This suggests channel-specific problems that need attention, which could affect both SGA lead generation and SGM conversion rates.
     - Always present a balanced, fair assessment that considers multiple perspectives rather than attributing issues to one role or the other.
   - **Actionable Recommendations:** Based on conversion rate trends, what specific actions should be taken to improve underperforming channels/sources?

5. **SGA PERFORMANCE ANALYSIS**
   - **IMPORTANT:** This section analyzes ONLY SGAs (Sales Development Associates), identified by `IsSGA__c = TRUE`. Do NOT confuse SGAs with SGMs (Strategic Growth Managers).
   - **CRITICAL SEGMENTATION:** SGAs are segmented into two groups that MUST be analyzed separately:
     - **Inbound SGAs:** Lauren George and Jacqueline Tully (field inbound leads - typically higher volume due to inbound lead flow)
     - **Outbound SGAs:** All other SGAs (responsible for outbound prospecting - typically lower volume as they must generate their own leads)
     - **DO NOT compare across groups:** Inbound and outbound SGAs have fundamentally different lead sources and volumes. Compare Lauren vs. Jacqueline, and compare outbound SGAs against each other, but never compare inbound to outbound.
   - **Top Performers (Within Each Group):** Which SGAs are "crushing it" with improving conversion rates AND/OR high SQO volume? Consider both metrics:
     - High conversion rates indicate quality and efficiency
     - High SQO volume indicates quantity and pipeline contribution
     - The best SGAs excel at both, but recognize that high volume producers (even with declining rates) are still valuable contributors
   - **Volume Leaders (Within Each Group):** Which SGAs are producing the most SQOs this quarter within their group? Even if their conversion rates are declining, high-volume SGAs are critical pipeline contributors.
   - **Underperformers (Within Each Group):** Which SGAs are showing declining conversion rates AND low volume within their group? These need the most urgent coaching.
   - **Key Metrics to Analyze:**
     - Contacted→MQL Rate: Measures SGA's ability to qualify leads and schedule calls
     - MQL→SQL Rate: Measures SGA's ability to convert qualified leads to SQLs
     - SQL→SQO Rate: Measures SGA-to-SGM handoff quality (most critical for capacity)
     - **SQO Volume:** The absolute number of SQOs produced this quarter (critical for understanding pipeline contribution)
   - **Balanced Assessment (Within Each Group):** When evaluating SGAs, consider:
     - An SGA with declining rates but high SQO volume (e.g., 15+ SQOs for inbound, 5+ SQOs for outbound) is still a strong contributor and may need rate improvement coaching, not urgent intervention
     - An SGA with perfect rates but very low volume (e.g., 1-2 SQOs) may need volume coaching
     - An SGA with both declining rates AND low volume needs urgent coaching
   - **Coaching Opportunities (Within Each Group):** For underperforming SGAs, identify:
     - Which specific conversion stage is the problem (Contacted→MQL, MQL→SQL, or SQL→SQO)?
     - Is it a volume issue (not enough leads/SQLs) or a quality issue (low conversion rates)?
     - What specific coaching actions should be taken for each underperforming SGA?
     - For high-volume SGAs with declining rates: Focus on rate improvement while recognizing their contribution
   - **Best Practices (Within Each Group):** What are top-performing SGAs doing differently within their group that we can replicate? Consider both high-rate and high-volume performers. Compare inbound SGAs to each other, and outbound SGAs to each other.

6. **SGM-SPECIFIC RISK ASSESSMENT** (prioritized by risk level)
   - **Under-Capacity SGMs:** Who has Coverage Ratio < 0.85? What is their specific gap? Why are they under-capacity (low pipeline value, high stale %, low conversion rate)?
   - **At-Risk SGMs:** Who has Coverage Ratio 0.85-0.99? What small boost do they need to become sufficient?
   - **On Ramp SGMs:** How many are ramping? Are they building pipeline appropriately?
   - **Sufficient SGMs:** Who is performing well? What can we learn from them?

7. **DIAGNOSED ISSUES & SUGGESTED SOLUTIONS**
   For each major issue identified, provide:
   - **Issue:** Clear description of the problem
   - **Root Cause:** Why is this happening?
   - **Impact:** What is the business impact (e.g., "$X million at risk")?
   - **Recommended Solution:** Specific, actionable steps to address the issue

8. **IMMEDIATE ACTION ITEMS** (prioritized by urgency)
   - **This Week (Critical):** What must be done immediately? (e.g., "Mandatory pipeline review for SGMs with >30% stale", "Address SQO gap for [specific SGMs]")
   - **This Month (High Priority):** What should be done in the next 30 days? (e.g., "Close firm-wide SQO gap of X deals", "Pipeline cleanup for [SGMs]")
   - **This Quarter (Strategic):** What strategic actions should be taken? (e.g., "Review SGA-to-SGM handoff process collaboratively", "Improve SQL quality standards through joint training", "Enhance pipeline management practices")

9. **VELOCITY-BASED FORECASTING ANALYSIS** (NEW - Physics-Based Forecasting)
   - **IMPORTANT:** This section uses a 70-day median cycle time (SQO → Join) to forecast when deals will close, rather than relying on unreliable manual CloseDate entries.
   - **Current Quarter Velocity Forecast:** 
     - What is the firm-wide "safe" forecast (Current Quarter Actuals + Current Quarter Velocity Forecast)?
     - Which SGMs have sufficient velocity forecast to hit their $36.75M target this quarter?
     - Which SGMs are relying too heavily on overdue deals to make their number?
   - **Overdue / Slip Risk Analysis:**
     - Which SGMs have high overdue forecast values? These are deals >70 days old that should have closed already.
     - **CRITICAL ALERT:** If an SGM's overdue forecast represents a large % of what they need to hit target, flag them as RED STATUS.
     - What is the total firm-wide overdue forecast? This represents revenue at high risk of slipping.
     - Which SGMs need immediate pipeline review due to high overdue deal counts?
   - **Next Quarter Pipeline Health:**
     - What is the firm-wide next quarter velocity forecast? Is it sufficient to support all SGMs hitting their targets next quarter?
     - Which SGMs have weak next quarter pipeline? These are at risk of crashing next quarter even if they hit this quarter.
     - **Leading Indicator:** Low next quarter pipeline is a warning sign that capacity issues are coming.
   - **Velocity vs. Capacity Comparison:**
     - How does the velocity forecast compare to the traditional capacity estimate?
     - Are there discrepancies that suggest pipeline quality issues or forecasting methodology differences?
   - **Actionable Recommendations:**
     - For SGMs with high overdue forecast: What specific actions should be taken to accelerate or clean up these deals?
     - For SGMs with low next quarter pipeline: What actions are needed to build pipeline for future quarters?
     - How should leadership use velocity forecasting to make better decisions about resource allocation and target setting?

10. **QUARTERLY FORECAST ANALYSIS** (Deal-Size Dependent Model)
   - **IMPORTANT CONTEXT:** This section uses data from `vw_sgm_capacity_coverage_with_forecast`, which applies deal-size dependent velocity (Enterprise deals take 120+ days, Standard deals take 50 days) and stage probabilities to forecast quarterly outcomes.
   - **Current Quarter Performance:**
     - For each SGM, analyze: How much have they achieved so far this quarter? What do we expect them to achieve by end of quarter?
     - Identify SGMs who have already met/exceeded their $36.75M target this quarter.
     - Identify SGMs who are on track to meet target (Expected End of Quarter is close to or above $36.75M).
     - Identify SGMs who are at risk of missing target (Expected End of Quarter is significantly below $36.75M).
   - **Next Quarter Pipeline Health:**
     - For each SGM, analyze: How much margin AUM do we expect to close next quarter from their current pipeline?
     - Which SGMs have strong next quarter pipeline (Expected Next Quarter is close to or above $36.75M)?
     - Which SGMs have weak next quarter pipeline (Expected Next Quarter is significantly below $36.75M)? These are at risk of crashing next quarter.
   - **Forecast Assumptions & Methodology:**
     - Explain the key assumptions: Deal-size dependent velocity, stage probabilities, dynamic stale thresholds.
     - Highlight that Enterprise deals (like Bre McDaniel's) are modeled with longer cycles (120+ days) and may show lumpiness.
     - Note that the model uses expected value (EV) calculations, so large binary deals may show as "$5M expected" when reality is "$0 or $50M".
   - **Confidence Levels & Interpretation:**
     - **High Confidence (90%+):** Trend and sufficiency signals (e.g., "SGM has enough pipeline" or "SGM is starving for leads").
     - **Medium Confidence (75%+):** Exact dollar figures for the quarter, especially when forecast relies on multiple deals.
     - **Lower Confidence:** Forecasts that depend heavily on 1-2 Enterprise deals in early stages (e.g., "Negotiating").
     - **Critical Caveat:** If an SGM's forecast relies heavily on 1-2 large Enterprise deals, flag it as "At Risk" regardless of what the model says, due to binary outcome nature.
   - **Actionable Insights:**
     - Which SGMs need immediate pipeline building to hit next quarter targets?
     - Which SGMs are over-reliant on large Enterprise deals that may not close?
     - What is the firm-wide expected end-of-quarter performance vs. target?

11. **SUCCESSES & BRIGHT SPOTS**
   - Which SGMs are performing exceptionally well? What makes them successful?
   - What patterns can we learn from high-performing SGMs?
   - Are there any positive trends we should highlight?

12. **WHAT-IF ANALYSIS: SQO & SQL ROUTING RECOMMENDATIONS** (NEW - Data-Driven Routing Strategy)
   - **CRITICAL:** This section provides actionable routing recommendations based on forecast gaps and conversion rates.
   - **Current Quarter Gaps:**
     - Which SGMs are forecasted to miss their $36.75M target this quarter?
     - For each SGM with a current quarter gap, analyze:
       - The exact gap amount (target - expected end of quarter)
       - How many SQOs they need this quarter to close the gap
       - How many SQLs need to be routed to them (based on their SQL→SQO conversion rate)
       - The urgency level (HIGH for gaps >$10M, MEDIUM for smaller gaps)
     - **Routing Priority:** SGMs with current quarter gaps should receive SQLs FIRST, as these deals need to close this quarter
   - **Next Quarter Gaps:**
     - Which SGMs are forecasted to miss their $36.75M target next quarter?
     - For each SGM with a next quarter gap, analyze:
       - The exact gap amount (target - expected next quarter)
       - How many SQOs they need this quarter (to have time to close next quarter)
       - How many SQLs need to be routed to them (based on their SQL→SQO conversion rate)
       - The urgency level (MEDIUM for gaps >$10M, LOW for smaller gaps)
     - **Routing Priority:** These SGMs need SQLs this quarter to build pipeline for next quarter
   - **Routing Strategy:**
     - **Priority 1:** Route SQLs to SGMs with current quarter gaps (highest urgency)
     - **Priority 2:** Route SQLs to SGMs with next quarter gaps (preventive action)
     - **Consider Conversion Rates:** SGMs with higher SQL→SQO conversion rates will need fewer SQLs to achieve the same number of SQOs
     - **Timing:** Current quarter SQOs need to be received ASAP. Next quarter SQOs can be spread throughout the current quarter
   - **Total Routing Needs:**
     - What is the total number of SQOs needed across all SGMs with gaps?
     - What is the total number of SQLs needed across all SGMs with gaps?
     - Is this feasible given current SGA production capacity?
   - **Enterprise vs Standard Considerations:**
     - Bre McDaniel uses enterprise metrics (larger average Margin AUM, potentially different conversion rates)
     - All other SGMs use standard metrics
     - Ensure routing recommendations account for these differences
   - **Actionable Recommendations:**
     - Provide a prioritized list of SGMs who should receive SQLs this week
     - Provide a prioritized list of SGMs who should receive SQLs this month
     - Recommend how to distribute SQLs across SGAs to meet these routing needs
     - Consider SGA capacity and conversion rates when making routing recommendations

Be specific, data-driven, and actionable. Use the actual numbers from the data to support your analysis. Focus on providing clear alerts, diagnoses, and concrete solutions that leadership can act on immediately.
"""


class CapacityReportGenerator:
    """Main class that orchestrates report generation"""
    
    def __init__(self, project_id: str, dataset: str = "savvy_analytics", 
                 credentials_path: Optional[str] = None, llm_provider: str = "openai"):
        self.project_id = project_id
        self.dataset = dataset
        self.bq_client = BigQueryClient(project_id, credentials_path)
        self.llm_analyzer = LLMAnalyzer(provider=llm_provider)
    
    def generate_report(self, output_file: Optional[str] = None) -> str:
        """Generate the complete capacity and coverage summary report"""
        
        print("Querying BigQuery views...")
        
        # Query 1: Firm-level summary from vw_sgm_capacity_model_refined
        firm_summary_query = f"""
        SELECT 
          COUNT(*) AS total_sgms,
          COUNT(CASE WHEN has_sufficient_sqos_in_pipeline = 'Yes' THEN 1 END) AS sgms_with_sufficient_sqos,
          COUNT(CASE WHEN quarterly_target_status = 'On Track' THEN 1 END) AS sgms_on_track,
          COUNT(CASE WHEN quarterly_target_status = 'Behind' THEN 1 END) AS sgms_behind,
          COUNT(CASE WHEN quarterly_target_status = 'No Activity' THEN 1 END) AS sgms_no_activity,
          ROUND(SUM(current_pipeline_sqo_margin_aum_estimate), 1) AS total_pipeline_estimate,
          ROUND(SUM(current_quarter_joined_margin_aum), 1) AS total_quarter_actuals,
          ROUND(SUM(quarterly_target_margin_aum), 1) AS total_target,
          ROUND(SUM(current_pipeline_sqo_stale_margin_aum_estimate), 1) AS total_stale_pipeline_estimate,
          ROUND(SUM(required_sqos_per_quarter), 0) AS total_required_sqos,
          ROUND(SUM(current_pipeline_sqo_count), 0) AS total_current_sqos,
          ROUND(SUM(current_pipeline_stale_sqo_count), 0) AS total_stale_sqos
        FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_model_refined`
        """
        
        # Query 2: Coverage summary from vw_sgm_capacity_coverage
        coverage_summary_query = f"""
        SELECT 
          COUNT(*) AS total_sgms,
          COUNT(CASE WHEN coverage_status = 'On Ramp' THEN 1 END) AS on_ramp_count,
          COUNT(CASE WHEN coverage_status = 'Sufficient' THEN 1 END) AS sufficient_count,
          COUNT(CASE WHEN coverage_status = 'At Risk' THEN 1 END) AS at_risk_count,
          COUNT(CASE WHEN coverage_status = 'Under-Capacity' THEN 1 END) AS under_capacity_count,
          ROUND(SUM(sgm_capacity_expected_joined_aum_millions_estimate), 2) AS total_capacity,
          ROUND(AVG(CASE WHEN coverage_status != 'On Ramp' THEN coverage_ratio_estimate END), 3) AS avg_coverage_ratio
        FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_coverage`
        WHERE IsActive = TRUE
        """
        
        # Query 3: SGM coverage data (for detailed analysis)
        sgm_coverage_query = f"""
        SELECT 
          sgm_name,
          coverage_status,
          ROUND(coverage_ratio_estimate, 3) AS coverage_ratio_estimate,
          ROUND(sgm_capacity_expected_joined_aum_millions_estimate, 2) AS capacity_estimate,
          ROUND(capacity_gap_millions_estimate, 2) AS capacity_gap_millions_estimate,
          active_sqo_count,
          stale_sqo_count,
          ROUND(current_quarter_actual_joined_aum_millions, 2) AS current_quarter_actual_joined_aum_millions
        FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_coverage`
        WHERE IsActive = TRUE
        ORDER BY 
          CASE coverage_status
            WHEN 'Under-Capacity' THEN 1
            WHEN 'At Risk' THEN 2
            WHEN 'On Ramp' THEN 3
            WHEN 'Sufficient' THEN 4
          END,
          coverage_ratio_estimate ASC
        """
        
        # Query 4: SGM risk assessment (detailed metrics)
        sgm_risk_query = f"""
        SELECT 
          sgm_name,
          required_sqos_per_quarter,
          required_joined_per_quarter,
          current_pipeline_sqo_count,
          current_quarter_sqo_count,
          sqo_gap_count,
          ROUND(current_pipeline_sqo_margin_aum_estimate, 1) AS pipeline_estimate_m,
          ROUND(current_pipeline_sqo_weighted_margin_aum_estimate, 1) AS weighted_pipeline_m,
          ROUND(current_pipeline_sqo_stale_margin_aum_estimate, 1) AS stale_pipeline_m,
          ROUND(CASE 
            WHEN current_pipeline_sqo_margin_aum_estimate > 0 
            THEN (current_pipeline_sqo_stale_margin_aum_estimate / current_pipeline_sqo_margin_aum_estimate) * 100
            ELSE 0
          END, 1) AS stale_pct,
          ROUND(current_quarter_joined_margin_aum, 1) AS qtr_actuals_m,
          ROUND(pipeline_margin_aum_pct_of_target, 1) AS pct_of_target,
          quarterly_target_status,
          has_sufficient_sqos_in_pipeline,
          has_sufficient_margin_aum_in_pipeline
        FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_model_refined`
        ORDER BY 
          CASE 
            WHEN quarterly_target_status = 'No Activity' THEN 1
            WHEN quarterly_target_status = 'Behind' THEN 2
            WHEN quarterly_target_status = 'On Track' THEN 3
          END,
          sqo_gap_count DESC NULLS LAST,
          stale_pct DESC
        """
        
        # Query 5: Top deals requiring attention
        deals_query = f"""
        SELECT 
          sgm_name,
          opportunity_name,
          StageName,
          ROUND(estimated_margin_aum, 1) AS estimated_margin_aum_m,
          days_open_since_sqo,
          is_stale
        FROM `{self.project_id}.{self.dataset}.vw_sgm_open_sqos_detail`
        WHERE is_stale = 'Yes' OR estimated_margin_aum > 20 OR days_open_since_sqo > 90
        ORDER BY 
          CASE WHEN is_stale = 'Yes' THEN 1 ELSE 2 END,
          estimated_margin_aum DESC
        LIMIT 30
        """
        
        # Query 5b: Concentration Risk (Whale Analysis)
        # Calculates dependency on the single largest open deal
        concentration_query = f"""
        WITH SGM_Totals AS (
            SELECT 
                sgm_name,
                SUM(estimated_margin_aum) as total_pipeline_val
            FROM `{self.project_id}.{self.dataset}.vw_sgm_open_sqos_detail`
            WHERE IsClosed = FALSE AND estimated_margin_aum > 0
            GROUP BY 1
        ),
        SGM_Max_Deal AS (
            SELECT 
                sgm_name,
                MAX(estimated_margin_aum) as max_deal_val,
                ARRAY_AGG(opportunity_name ORDER BY estimated_margin_aum DESC LIMIT 1)[OFFSET(0)] as largest_deal_name
            FROM `{self.project_id}.{self.dataset}.vw_sgm_open_sqos_detail`
            WHERE IsClosed = FALSE AND estimated_margin_aum > 0
              AND opportunity_name IS NOT NULL
            GROUP BY 1
        )
        SELECT 
            t.sgm_name,
            t.total_pipeline_val,
            m.max_deal_val,
            m.largest_deal_name,
            SAFE_DIVIDE(m.max_deal_val, t.total_pipeline_val) as top_deal_concentration_pct
        FROM SGM_Totals t
        JOIN SGM_Max_Deal m ON t.sgm_name = m.sgm_name
        WHERE t.total_pipeline_val > 5 -- Filter out empty pipelines
        ORDER BY top_deal_concentration_pct DESC
        """
        
        # Query 5c: Stage Distribution (Bottleneck Analysis)
        stage_dist_query = f"""
        SELECT 
            sgm_name,
            StageName,
            COUNT(*) as deal_count,
            SUM(estimated_margin_aum) as stage_value_m
        FROM `{self.project_id}.{self.dataset}.vw_sgm_open_sqos_detail`
        WHERE IsClosed = FALSE
        GROUP BY 1, 2
        ORDER BY sgm_name, stage_value_m DESC
        """
        
        # Query 6: Conversion rates - Current Quarter vs Last 12 Months
        # NOTE: For SQO→Joined, we use a 90-day lookback (instead of current quarter) because
        # the average time from SQO to Joined is 77 days. This ensures we're measuring SQOs
        # that have had sufficient time to convert, providing a more accurate benchmark.
        # IMPORTANT: We match vw_conversion_rates.sql logic:
        # - Join Opportunity to Lead to get Lead source (matching vw_conversion_rates FULL OUTER JOIN)
        # - Use COALESCE(o.LeadSource, l.LeadSource) for Original_source (matching vw_conversion_rates)
        # - Join Channel_Group_Mapping using that COALESCE value
        conversion_rates_query = f"""
        -- SQO→Joined rates using 90-day lookback (based on Date_Became_SQO__c)
        -- Matches vw_conversion_rates.sql logic for source attribution
        WITH SQO_Joined_90_Day AS (
          SELECT 
            'Overall' AS metric_type,
            'Overall' AS dimension_value,
            'Last 90 Days' AS period,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_denom,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND o.advisor_join_date__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_num
          FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
          WHERE o.recordtypeid = '012Dn000000mrO3IAI'
            AND LOWER(o.SQL__c) = 'yes'
        ),
        SQO_Joined_90_Day_Channel AS (
          SELECT 
            'Channel' AS metric_type,
            COALESCE(g.Channel_Grouping_Name, 'Other') AS dimension_value,
            'Last 90 Days' AS period,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_denom,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND o.advisor_join_date__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_num
          FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
          LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Lead` l
            ON l.ConvertedOpportunityId = o.Id
          LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
            ON COALESCE(o.LeadSource, l.LeadSource) = g.Original_Source_Salesforce
          WHERE o.recordtypeid = '012Dn000000mrO3IAI'
            AND LOWER(o.SQL__c) = 'yes'
          GROUP BY g.Channel_Grouping_Name
          HAVING COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) >= 5
        ),
        SQO_Joined_90_Day_Source AS (
          SELECT 
            'Source' AS metric_type,
            COALESCE(o.LeadSource, l.LeadSource, 'Unknown') AS dimension_value,
            'Last 90 Days' AS period,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_denom,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND o.advisor_join_date__c IS NOT NULL THEN o.Full_Opportunity_ID__c END) AS sqo_to_joined_num
          FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
          LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Lead` l
            ON l.ConvertedOpportunityId = o.Id
          WHERE o.recordtypeid = '012Dn000000mrO3IAI'
            AND LOWER(o.SQL__c) = 'yes'
            AND COALESCE(o.LeadSource, l.LeadSource) IS NOT NULL
          GROUP BY COALESCE(o.LeadSource, l.LeadSource, 'Unknown')
          HAVING COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) >= 5
        ),
        Current_Quarter_Overall AS (
          SELECT 
            'Overall' AS metric_type,
            'Overall' AS dimension_value,
            'Current Quarter' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined will come from 90-day lookback CTE
            NULL AS sqo_to_joined_denom,
            NULL AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
        ),
        Last_12_Months_Overall AS (
          SELECT 
            'Overall' AS metric_type,
            'Overall' AS dimension_value,
            'Last 12 Months' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined: Filter by sqo_cohort_month (when they became SQO)
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denom,
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
        ),
        Current_Quarter_Channel AS (
          SELECT 
            'Channel' AS metric_type,
            Channel_Grouping_Name AS dimension_value,
            'Current Quarter' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined will come from 90-day lookback CTE
            NULL AS sqo_to_joined_denom,
            NULL AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE Channel_Grouping_Name IS NOT NULL
          GROUP BY Channel_Grouping_Name
          HAVING SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) >= 5
        ),
        Last_12_Months_Channel AS (
          SELECT 
            'Channel' AS metric_type,
            Channel_Grouping_Name AS dimension_value,
            'Last 12 Months' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined: Filter by sqo_cohort_month (when they became SQO)
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denom,
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE Channel_Grouping_Name IS NOT NULL
          GROUP BY Channel_Grouping_Name
          HAVING SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) >= 5
        ),
        Current_Quarter_Source AS (
          SELECT 
            'Source' AS metric_type,
            Original_source AS dimension_value,
            'Current Quarter' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined will come from 90-day lookback CTE
            NULL AS sqo_to_joined_denom,
            NULL AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE Original_source IS NOT NULL
          GROUP BY Original_source
          HAVING SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_denominator ELSE 0 END) >= 5
        ),
        Last_12_Months_Source AS (
          SELECT 
            'Source' AS metric_type,
            Original_source AS dimension_value,
            'Last 12 Months' AS period,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_to_sqo_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_to_sqo_num,
            -- SQO→Joined: Filter by sqo_cohort_month (when they became SQO)
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_denominator ELSE 0 END) AS sqo_to_joined_denom,
            SUM(CASE WHEN sqo_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sqo_to_joined_numerator ELSE 0 END) AS sqo_to_joined_num
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE Original_source IS NOT NULL
          GROUP BY Original_source
          HAVING SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) >= 5
        ),
        -- Combine SQL→SQO (current quarter) with SQO→Joined (90-day lookback)
        Combined_Overall AS (
          SELECT 
            cq.metric_type,
            cq.dimension_value,
            'Current Quarter / Last 90 Days' AS period,
            cq.sql_to_sqo_denom,
            cq.sql_to_sqo_num,
            sqo90.sqo_to_joined_denom,
            sqo90.sqo_to_joined_num
          FROM Current_Quarter_Overall cq
          CROSS JOIN SQO_Joined_90_Day sqo90
        ),
        Combined_Channel AS (
          SELECT 
            COALESCE(cq.metric_type, sqo90.metric_type) AS metric_type,
            COALESCE(cq.dimension_value, sqo90.dimension_value) AS dimension_value,
            'Current Quarter / Last 90 Days' AS period,
            COALESCE(cq.sql_to_sqo_denom, 0) AS sql_to_sqo_denom,
            COALESCE(cq.sql_to_sqo_num, 0) AS sql_to_sqo_num,
            COALESCE(sqo90.sqo_to_joined_denom, 0) AS sqo_to_joined_denom,
            COALESCE(sqo90.sqo_to_joined_num, 0) AS sqo_to_joined_num
          FROM Current_Quarter_Channel cq
          FULL OUTER JOIN SQO_Joined_90_Day_Channel sqo90
            ON cq.dimension_value = sqo90.dimension_value
        ),
        Combined_Source AS (
          SELECT 
            COALESCE(cq.metric_type, sqo90.metric_type) AS metric_type,
            COALESCE(cq.dimension_value, sqo90.dimension_value) AS dimension_value,
            'Current Quarter / Last 90 Days' AS period,
            COALESCE(cq.sql_to_sqo_denom, 0) AS sql_to_sqo_denom,
            COALESCE(cq.sql_to_sqo_num, 0) AS sql_to_sqo_num,
            COALESCE(sqo90.sqo_to_joined_denom, 0) AS sqo_to_joined_denom,
            COALESCE(sqo90.sqo_to_joined_num, 0) AS sqo_to_joined_num
          FROM Current_Quarter_Source cq
          FULL OUTER JOIN SQO_Joined_90_Day_Source sqo90
            ON cq.dimension_value = sqo90.dimension_value
        )
        SELECT 
          metric_type,
          dimension_value,
          period,
          SAFE_DIVIDE(sql_to_sqo_num, sql_to_sqo_denom) AS sql_to_sqo_rate,
          SAFE_DIVIDE(sqo_to_joined_num, sqo_to_joined_denom) AS sqo_to_joined_rate,
          sql_to_sqo_denom,
          sql_to_sqo_num,
          sqo_to_joined_denom,
          sqo_to_joined_num
        FROM Combined_Overall
        
        UNION ALL
        
        SELECT 
          metric_type,
          dimension_value,
          period,
          SAFE_DIVIDE(sql_to_sqo_num, sql_to_sqo_denom) AS sql_to_sqo_rate,
          SAFE_DIVIDE(sqo_to_joined_num, sqo_to_joined_denom) AS sqo_to_joined_rate,
          sql_to_sqo_denom,
          sql_to_sqo_num,
          sqo_to_joined_denom,
          sqo_to_joined_num
        FROM Last_12_Months_Overall
        
        UNION ALL
        
        SELECT 
          metric_type,
          dimension_value,
          period,
          SAFE_DIVIDE(sql_to_sqo_num, sql_to_sqo_denom) AS sql_to_sqo_rate,
          SAFE_DIVIDE(sqo_to_joined_num, sqo_to_joined_denom) AS sqo_to_joined_rate,
          sql_to_sqo_denom,
          sql_to_sqo_num,
          sqo_to_joined_denom,
          sqo_to_joined_num
        FROM Combined_Channel
        
        UNION ALL
        
        SELECT 
          metric_type,
          dimension_value,
          period,
          SAFE_DIVIDE(sql_to_sqo_num, sql_to_sqo_denom) AS sql_to_sqo_rate,
          SAFE_DIVIDE(sqo_to_joined_num, sqo_to_joined_denom) AS sqo_to_joined_rate,
          sql_to_sqo_denom,
          sql_to_sqo_num,
          sqo_to_joined_denom,
          sqo_to_joined_num
        FROM Combined_Source
        """
        
        # Query 7: SGA-level conversion rates (Current Quarter vs Last 12 Months)
        # NOTE: This query uses progression-based conversion rates from vw_sga_funnel.sql
        # - Contacted→MQL: SUM(contacted_to_mql_progression) / SUM(eligible_for_contacted_conversions)
        # - MQL→SQL: SUM(mql_to_sql_progression) / SUM(eligible_for_mql_conversions)
        # - SQL→SQO: SUM(sql_to_sqo_progression) / SUM(eligible_for_sql_conversions)
        # IMPORTANT: Conversion rates must use EVENT-BASED COHORT MONTHS for accurate date attribution:
        # - Contacted→MQL: Filter by contacted_cohort_month (when they were contacted)
        # - MQL→SQL: Filter by mql_cohort_month (when they became MQL)
        # - SQL→SQO: Filter by sql_cohort_month (when they became SQL)
        # IMPORTANT: Volume metrics must use CONVERSION DATES (event dates) to match vw_conversion_volume_table.sql:
        # - Contacted volume: stage_entered_contacting__c
        # - MQL volume: mql_stage_entered_ts
        # - SQL volume: converted_date_raw
        # - SQO volume: Date_Became_SQO__c
        sga_conversion_rates_query = f"""
        WITH Current_Quarter_SGA AS (
          SELECT 
            SGA_Owner_Name__c,
            -- Conversion rate denominators and numerators (filtered by event-based cohort months)
            -- Contacted→MQL: Filter by contacted_cohort_month (when they were contacted)
            SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN eligible_for_contacted_conversions ELSE 0 END) AS contacted_denom,
            SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN contacted_to_mql_progression ELSE 0 END) AS contacted_to_mql_num,
            -- MQL→SQL: Filter by mql_cohort_month (when they became MQL)
            SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN eligible_for_mql_conversions ELSE 0 END) AS mql_denom,
            SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN mql_to_sql_progression ELSE 0 END) AS mql_to_sql_num,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN eligible_for_sql_conversions ELSE 0 END) AS sql_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN sql_to_sqo_progression ELSE 0 END) AS sql_to_sqo_num,
            -- Volume metrics (using conversion dates to match vw_conversion_volume_table.sql)
            -- Contacted volume: uses stage_entered_contacting__c (conversion date)
            COUNT(DISTINCT CASE 
              WHEN is_contacted = 1 
                AND unique_id IS NOT NULL 
                AND stage_entered_contacting__c IS NOT NULL
                AND DATE_TRUNC(DATE(stage_entered_contacting__c), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER)
                AND DATE(stage_entered_contacting__c) <= CURRENT_DATE()
              THEN unique_id 
            END) AS contacted_volume,
            -- MQL volume: uses mql_stage_entered_ts (conversion date)
            COUNT(DISTINCT CASE 
              WHEN is_mql = 1 
                AND unique_id IS NOT NULL 
                AND mql_stage_entered_ts IS NOT NULL
                AND DATE_TRUNC(DATE(mql_stage_entered_ts), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER)
                AND DATE(mql_stage_entered_ts) <= CURRENT_DATE()
              THEN unique_id 
            END) AS mql_volume,
            -- SQL volume: uses converted_date_raw (conversion date)
            COUNT(DISTINCT CASE 
              WHEN eligible_for_sql_conversions = 1 
                AND unique_id IS NOT NULL 
                AND converted_date_raw IS NOT NULL
                AND DATE_TRUNC(DATE(converted_date_raw), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER)
                AND DATE(converted_date_raw) <= CURRENT_DATE()
              THEN unique_id 
            END) AS sql_volume,
            -- SQO volume: uses Date_Became_SQO__c (conversion date)
            COUNT(DISTINCT CASE 
              WHEN eligible_for_sqo_conversions = 1 
                AND unique_id IS NOT NULL 
                AND Date_Became_SQO__c IS NOT NULL
                AND DATE_TRUNC(DATE(Date_Became_SQO__c), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER)
                AND DATE(Date_Became_SQO__c) <= CURRENT_DATE()
              THEN unique_id 
            END) AS sqo_volume
          FROM `{self.project_id}.{self.dataset}.vw_sga_funnel`
          WHERE SGA_Owner_Name__c IS NOT NULL
            AND (
              -- Include records where cohort months are in current quarter (for conversion rates)
              contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
              OR mql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
              OR sql_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
              -- OR conversion dates are in current quarter (for volume metrics)
              OR (stage_entered_contacting__c IS NOT NULL AND DATE_TRUNC(DATE(stage_entered_contacting__c), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) AND DATE(stage_entered_contacting__c) <= CURRENT_DATE())
              OR (mql_stage_entered_ts IS NOT NULL AND DATE_TRUNC(DATE(mql_stage_entered_ts), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) AND DATE(mql_stage_entered_ts) <= CURRENT_DATE())
              OR (converted_date_raw IS NOT NULL AND DATE_TRUNC(DATE(converted_date_raw), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) AND DATE(converted_date_raw) <= CURRENT_DATE())
              OR (Date_Became_SQO__c IS NOT NULL AND DATE_TRUNC(DATE(Date_Became_SQO__c), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) AND DATE(Date_Became_SQO__c) <= CURRENT_DATE())
            )
          GROUP BY SGA_Owner_Name__c
          HAVING SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN eligible_for_contacted_conversions ELSE 0 END) >= 5  -- Only SGAs with sufficient volume
        ),
        Last_12_Months_SGA AS (
          SELECT 
            SGA_Owner_Name__c,
            -- Conversion rate denominators and numerators (filtered by event-based cohort months)
            -- Contacted→MQL: Filter by contacted_cohort_month (when they were contacted)
            SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN eligible_for_contacted_conversions ELSE 0 END) AS contacted_denom,
            SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN contacted_to_mql_progression ELSE 0 END) AS contacted_to_mql_num,
            -- MQL→SQL: Filter by mql_cohort_month (when they became MQL)
            SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN eligible_for_mql_conversions ELSE 0 END) AS mql_denom,
            SUM(CASE WHEN mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN mql_to_sql_progression ELSE 0 END) AS mql_to_sql_num,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN eligible_for_sql_conversions ELSE 0 END) AS sql_denom,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_progression ELSE 0 END) AS sql_to_sqo_num,
            -- Volume metrics (using conversion dates to match vw_conversion_volume_table.sql)
            -- Contacted volume: uses stage_entered_contacting__c (conversion date)
            COUNT(DISTINCT CASE 
              WHEN is_contacted = 1 
                AND unique_id IS NOT NULL 
                AND stage_entered_contacting__c IS NOT NULL
                AND DATE(stage_entered_contacting__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
                AND DATE(stage_entered_contacting__c) <= CURRENT_DATE()
              THEN unique_id 
            END) AS contacted_volume,
            -- MQL volume: uses mql_stage_entered_ts (conversion date)
            COUNT(DISTINCT CASE 
              WHEN is_mql = 1 
                AND unique_id IS NOT NULL 
                AND mql_stage_entered_ts IS NOT NULL
                AND DATE(mql_stage_entered_ts) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
                AND DATE(mql_stage_entered_ts) <= CURRENT_DATE()
              THEN unique_id 
            END) AS mql_volume,
            -- SQL volume: uses converted_date_raw (conversion date)
            COUNT(DISTINCT CASE 
              WHEN eligible_for_sql_conversions = 1 
                AND unique_id IS NOT NULL 
                AND converted_date_raw IS NOT NULL
                AND DATE(converted_date_raw) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
                AND DATE(converted_date_raw) <= CURRENT_DATE()
              THEN unique_id 
            END) AS sql_volume,
            -- SQO volume: uses Date_Became_SQO__c (conversion date)
            COUNT(DISTINCT CASE 
              WHEN eligible_for_sqo_conversions = 1 
                AND unique_id IS NOT NULL 
                AND Date_Became_SQO__c IS NOT NULL
                AND DATE(Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
                AND DATE(Date_Became_SQO__c) <= CURRENT_DATE()
              THEN unique_id 
            END) AS sqo_volume
          FROM `{self.project_id}.{self.dataset}.vw_sga_funnel`
          WHERE SGA_Owner_Name__c IS NOT NULL
            AND (
              -- Include records where cohort months are in last 12 months (for conversion rates)
              contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
              OR mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
              OR sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
              -- OR conversion dates are in last 12 months (for volume metrics)
              OR (stage_entered_contacting__c IS NOT NULL AND DATE(stage_entered_contacting__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AND DATE(stage_entered_contacting__c) <= CURRENT_DATE())
              OR (mql_stage_entered_ts IS NOT NULL AND DATE(mql_stage_entered_ts) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AND DATE(mql_stage_entered_ts) <= CURRENT_DATE())
              OR (converted_date_raw IS NOT NULL AND DATE(converted_date_raw) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AND DATE(converted_date_raw) <= CURRENT_DATE())
              OR (Date_Became_SQO__c IS NOT NULL AND DATE(Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH) AND DATE(Date_Became_SQO__c) <= CURRENT_DATE())
            )
          GROUP BY SGA_Owner_Name__c
          HAVING SUM(CASE WHEN contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN eligible_for_contacted_conversions ELSE 0 END) >= 10  -- Only SGAs with sufficient volume over 12 months
        ),
        -- Verify that SGA_Owner_Name__c is actually an SGA (not an SGM)
        -- This is a safeguard to ensure we only include actual SGAs
        -- IMPORTANT: Exclude anyone who is an SGM (Is_SGM__c = TRUE), even if they also have IsSGA__c = TRUE
        -- This handles cases where data quality issues cause someone to be marked as both SGA and SGM
        Verified_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name,
            u.IsSGA__c,
            u.Is_SGM__c
          FROM `savvy-gtm-analytics.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE
            AND u.IsActive = TRUE
            AND (u.Is_SGM__c IS NULL OR u.Is_SGM__c = FALSE)  -- Explicitly exclude anyone with Is_SGM__c = TRUE
        ),
        -- Additional safeguard: Get list of all SGMs to explicitly exclude them
        Known_SGMs AS (
          SELECT DISTINCT
            u.Name AS sgm_name
          FROM `savvy-gtm-analytics.SavvyGTMData.User` u
          WHERE u.Is_SGM__c = TRUE
            AND u.IsActive = TRUE
        )
        SELECT 
          COALESCE(cq.SGA_Owner_Name__c, l12m.SGA_Owner_Name__c) AS sga_name,
          -- Current Quarter Rates
          SAFE_DIVIDE(COALESCE(cq.contacted_to_mql_num, 0), COALESCE(cq.contacted_denom, 1)) AS current_qtr_contacted_to_mql_rate,
          SAFE_DIVIDE(COALESCE(cq.mql_to_sql_num, 0), COALESCE(cq.mql_denom, 1)) AS current_qtr_mql_to_sql_rate,
          SAFE_DIVIDE(COALESCE(cq.sql_to_sqo_num, 0), COALESCE(cq.sql_denom, 1)) AS current_qtr_sql_to_sqo_rate,
          -- Last 12 Months Rates
          SAFE_DIVIDE(COALESCE(l12m.contacted_to_mql_num, 0), COALESCE(l12m.contacted_denom, 1)) AS l12m_contacted_to_mql_rate,
          SAFE_DIVIDE(COALESCE(l12m.mql_to_sql_num, 0), COALESCE(l12m.mql_denom, 1)) AS l12m_mql_to_sql_rate,
          SAFE_DIVIDE(COALESCE(l12m.sql_to_sqo_num, 0), COALESCE(l12m.sql_denom, 1)) AS l12m_sql_to_sqo_rate,
          -- Rate Changes
          SAFE_DIVIDE(COALESCE(cq.contacted_to_mql_num, 0), COALESCE(cq.contacted_denom, 1)) - SAFE_DIVIDE(COALESCE(l12m.contacted_to_mql_num, 0), COALESCE(l12m.contacted_denom, 1)) AS contacted_to_mql_rate_change,
          SAFE_DIVIDE(COALESCE(cq.mql_to_sql_num, 0), COALESCE(cq.mql_denom, 1)) - SAFE_DIVIDE(COALESCE(l12m.mql_to_sql_num, 0), COALESCE(l12m.mql_denom, 1)) AS mql_to_sql_rate_change,
          SAFE_DIVIDE(COALESCE(cq.sql_to_sqo_num, 0), COALESCE(cq.sql_denom, 1)) - SAFE_DIVIDE(COALESCE(l12m.sql_to_sqo_num, 0), COALESCE(l12m.sql_denom, 1)) AS sql_to_sqo_rate_change,
          -- Current Quarter Volumes
          COALESCE(cq.contacted_volume, 0) AS current_qtr_contacted_volume,
          COALESCE(cq.mql_volume, 0) AS current_qtr_mql_volume,
          COALESCE(cq.sql_volume, 0) AS current_qtr_sql_volume,
          COALESCE(cq.sqo_volume, 0) AS current_qtr_sqo_volume,
          -- Last 12 Months Volumes (average per quarter)
          COALESCE(l12m.contacted_volume, 0) / 4 AS avg_l12m_contacted_volume_per_quarter,
          COALESCE(l12m.mql_volume, 0) / 4 AS avg_l12m_mql_volume_per_quarter,
          COALESCE(l12m.sql_volume, 0) / 4 AS avg_l12m_sql_volume_per_quarter,
          COALESCE(l12m.sqo_volume, 0) / 4 AS avg_l12m_sqo_volume_per_quarter
          FROM Current_Quarter_SGA cq
          FULL OUTER JOIN Last_12_Months_SGA l12m
            ON cq.SGA_Owner_Name__c = l12m.SGA_Owner_Name__c
          INNER JOIN Verified_SGAs vs
            ON COALESCE(cq.SGA_Owner_Name__c, l12m.SGA_Owner_Name__c) = vs.sga_name
          LEFT JOIN Known_SGMs ks
            ON COALESCE(cq.SGA_Owner_Name__c, l12m.SGA_Owner_Name__c) = ks.sgm_name
          WHERE ks.sgm_name IS NULL  -- Explicitly exclude anyone who is an SGM
        ORDER BY 
          -- Sort by SQL→SQO rate change (biggest improvements/declines first)
          ABS(SAFE_DIVIDE(COALESCE(cq.sql_to_sqo_num, 0), COALESCE(cq.sql_denom, 1)) - SAFE_DIVIDE(COALESCE(l12m.sql_to_sqo_num, 0), COALESCE(l12m.sql_denom, 1))) DESC,
          -- Then by current quarter SQL volume (highest volume first)
          COALESCE(cq.sql_volume, 0) DESC
        LIMIT 30
        """
        
        # Query 8: Conversion rate trends (compare current quarter to 12-month average)
        # NOTE: SQO→Joined uses 90-day lookback (instead of current quarter) to account for 77-day average cycle time
        # IMPORTANT: Matches vw_conversion_rates.sql logic for source attribution
        conversion_trends_query = f"""
        WITH Current_Quarter_SQL_SQO AS (
          SELECT 
            Channel_Grouping_Name,
            Original_source,
            SAFE_DIVIDE(SUM(sql_to_sqo_numerator), SUM(sql_to_sqo_denominator)) AS current_qtr_sql_to_sqo_rate,
            SUM(sql_to_sqo_denominator) AS current_qtr_sql_volume
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE cohort_month >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
          GROUP BY Channel_Grouping_Name, Original_source
        ),
        SQO_Joined_90_Day_Trends AS (
          SELECT 
            COALESCE(g.Channel_Grouping_Name, 'Other') AS Channel_Grouping_Name,
            COALESCE(o.LeadSource, l.LeadSource, 'Unknown') AS Original_source,
            SAFE_DIVIDE(
              COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND o.advisor_join_date__c IS NOT NULL THEN o.Full_Opportunity_ID__c END),
              COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END)
            ) AS sqo_to_joined_90_day_rate,
            COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) AS sqo_90_day_volume
          FROM `savvy-gtm-analytics.SavvyGTMData.Opportunity` o
          LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Lead` l
            ON l.ConvertedOpportunityId = o.Id
          LEFT JOIN `savvy-gtm-analytics.SavvyGTMData.Channel_Group_Mapping` g
            ON COALESCE(o.LeadSource, l.LeadSource) = g.Original_Source_Salesforce
          WHERE o.recordtypeid = '012Dn000000mrO3IAI'
            AND LOWER(o.SQL__c) = 'yes'
          GROUP BY g.Channel_Grouping_Name, COALESCE(o.LeadSource, l.LeadSource, 'Unknown')
          HAVING COUNT(DISTINCT CASE WHEN o.Date_Became_SQO__c IS NOT NULL AND DATE(o.Date_Became_SQO__c) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN o.Full_Opportunity_ID__c END) >= 5
        ),
        Last_12_Month_Rates AS (
          SELECT 
            Channel_Grouping_Name,
            Original_source,
            SAFE_DIVIDE(SUM(sql_to_sqo_numerator), SUM(sql_to_sqo_denominator)) AS l12m_sql_to_sqo_rate,
            SAFE_DIVIDE(SUM(sqo_to_joined_numerator), SUM(sqo_to_joined_denominator)) AS l12m_sqo_to_joined_rate,
            SUM(sql_to_sqo_denominator) AS l12m_sql_volume,
            SUM(sqo_to_joined_denominator) AS l12m_sqo_volume
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE cohort_month >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
          GROUP BY Channel_Grouping_Name, Original_source
        )
        SELECT 
          COALESCE(cq.Channel_Grouping_Name, sqo90.Channel_Grouping_Name, l12m.Channel_Grouping_Name, 'Overall') AS channel,
          COALESCE(cq.Original_source, sqo90.Original_source, l12m.Original_source, 'Overall') AS source,
          COALESCE(cq.current_qtr_sql_to_sqo_rate, 0) AS current_qtr_sql_to_sqo_rate,
          COALESCE(l12m.l12m_sql_to_sqo_rate, 0) AS l12m_sql_to_sqo_rate,
          COALESCE(cq.current_qtr_sql_to_sqo_rate, 0) - COALESCE(l12m.l12m_sql_to_sqo_rate, 0) AS sql_to_sqo_rate_change,
          COALESCE(sqo90.sqo_to_joined_90_day_rate, 0) AS current_qtr_sqo_to_joined_rate,
          COALESCE(l12m.l12m_sqo_to_joined_rate, 0) AS l12m_sqo_to_joined_rate,
          COALESCE(sqo90.sqo_to_joined_90_day_rate, 0) - COALESCE(l12m.l12m_sqo_to_joined_rate, 0) AS sqo_to_joined_rate_change,
          COALESCE(cq.current_qtr_sql_volume, 0) AS current_qtr_sql_volume,
          COALESCE(l12m.l12m_sql_volume, 0) / 4 AS avg_l12m_sql_volume_per_quarter,
          COALESCE(sqo90.sqo_90_day_volume, 0) AS current_qtr_sqo_volume,
          COALESCE(l12m.l12m_sqo_volume, 0) / 4 AS avg_l12m_sqo_volume_per_quarter
        FROM Current_Quarter_SQL_SQO cq
        FULL OUTER JOIN SQO_Joined_90_Day_Trends sqo90
          ON COALESCE(cq.Channel_Grouping_Name, 'Other') = sqo90.Channel_Grouping_Name
          AND cq.Original_source = sqo90.Original_source
        FULL OUTER JOIN Last_12_Month_Rates l12m
          ON COALESCE(cq.Channel_Grouping_Name, sqo90.Channel_Grouping_Name, 'Other') = l12m.Channel_Grouping_Name
          AND COALESCE(cq.Original_source, sqo90.Original_source) = l12m.Original_source
        WHERE (COALESCE(cq.current_qtr_sql_volume, 0) >= 5 OR COALESCE(l12m.l12m_sql_volume, 0) >= 20)
        ORDER BY 
          ABS(COALESCE(cq.current_qtr_sql_to_sqo_rate, 0) - COALESCE(l12m.l12m_sql_to_sqo_rate, 0)) DESC,
          ABS(COALESCE(sqo90.sqo_to_joined_90_day_rate, 0) - COALESCE(l12m.l12m_sqo_to_joined_rate, 0)) DESC
        LIMIT 20
        """
        
        # Query 9: Quarterly Forecast Data (from vw_sgm_capacity_coverage_with_forecast)
        # Provides current quarter actuals, expected end-of-quarter forecast, and next quarter pipeline
        quarterly_forecast_query = f"""
        SELECT 
          sgm_name,
          ROUND(current_quarter_actual_joined_aum_millions, 2) AS current_quarter_actuals,
          ROUND(total_expected_current_quarter_margin_aum_millions, 2) AS expected_end_of_quarter,
          ROUND(total_expected_next_quarter_margin_aum_millions, 2) AS expected_next_quarter,
          ROUND(expected_to_join_this_quarter_margin_aum_millions, 2) AS pipeline_forecast_this_quarter,
          ROUND(expected_to_join_next_quarter_margin_aum_millions, 2) AS pipeline_forecast_next_quarter,
          coverage_status,
          ROUND(coverage_ratio_estimate, 3) AS coverage_ratio
        FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_coverage_with_forecast`
        WHERE IsActive = TRUE
        ORDER BY current_quarter_actuals DESC, expected_end_of_quarter DESC
        """
        
        # Query 10: What-If Analysis - SQO & SQL Routing Recommendations
        # Calculates how many SQOs and SQLs each SGM needs to hit their targets
        what_if_analysis_query = f"""
        WITH Quarterly_Forecast AS (
          SELECT 
            sgm_name,
            current_quarter_actual_joined_aum_millions AS current_quarter_actuals,
            total_expected_current_quarter_margin_aum_millions AS expected_end_of_quarter,
            total_expected_next_quarter_margin_aum_millions AS expected_next_quarter,
            expected_to_join_this_quarter_margin_aum_millions AS pipeline_forecast_this_quarter,
            expected_to_join_next_quarter_margin_aum_millions AS pipeline_forecast_next_quarter,
            coverage_status
          FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_coverage_with_forecast`
          WHERE IsActive = TRUE
        ),
        SGM_Metrics AS (
          SELECT 
            sgm_name,
            enterprise_365_average_margin_aum,
            enterprise_365_sqo_to_joined_conversion,
            standard_365_average_margin_aum,
            standard_365_sqo_to_joined_conversion,
            -- Use enterprise metrics for Bre McDaniel, standard for others
            CASE 
              WHEN sgm_name = 'Bre McDaniel' 
                AND enterprise_365_average_margin_aum > 0
              THEN enterprise_365_average_margin_aum
              WHEN sgm_name != 'Bre McDaniel'
                AND standard_365_average_margin_aum > 0
              THEN standard_365_average_margin_aum
              ELSE NULL
            END AS effective_avg_margin_aum_per_joined,
            CASE 
              WHEN sgm_name = 'Bre McDaniel' 
                AND enterprise_365_sqo_to_joined_conversion > 0
              THEN enterprise_365_sqo_to_joined_conversion
              WHEN sgm_name != 'Bre McDaniel'
                AND standard_365_sqo_to_joined_conversion > 0
              THEN standard_365_sqo_to_joined_conversion
              ELSE NULL
            END AS effective_sqo_to_joined_conversion_rate
          FROM `{self.project_id}.{self.dataset}.vw_sgm_capacity_model_refined`
          WHERE IsActive = TRUE
        ),
        SGM_SQL_To_SQO_Rates AS (
          SELECT 
            sgm_name,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) AS sql_denominator,
            SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END) AS sql_numerator,
            SAFE_DIVIDE(
              SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END),
              SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END)
            ) AS sql_to_sqo_conversion_rate
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE sgm_name IS NOT NULL
          GROUP BY sgm_name
          HAVING SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END) >= 5  -- Only SGMs with sufficient volume
        ),
        Firm_Wide_SQL_To_SQO_Rate AS (
          SELECT 
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SAFE_DIVIDE(
              SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_numerator ELSE 0 END),
              SUM(CASE WHEN sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH) THEN sql_to_sqo_denominator ELSE 0 END)
            ) AS firm_wide_sql_to_sqo_rate
          FROM `{self.project_id}.{self.dataset}.vw_conversion_rates`
          WHERE sgm_name IS NOT NULL
        )
        SELECT 
          qf.sgm_name,
          qf.current_quarter_actuals,
          qf.expected_end_of_quarter,
          qf.expected_next_quarter,
          qf.pipeline_forecast_this_quarter,
          qf.pipeline_forecast_next_quarter,
          qf.coverage_status,
          -- Target
          36.75 AS quarterly_target,
          -- Gaps
          GREATEST(0, 36.75 - qf.expected_end_of_quarter) AS current_qtr_gap_millions,
          GREATEST(0, 36.75 - qf.expected_next_quarter) AS next_qtr_gap_millions,
          -- Effective metrics
          COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) AS effective_avg_margin_aum_per_joined,
          COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10) AS effective_sqo_to_joined_conversion_rate,
          -- SQL→SQO conversion rate (use individual if available, otherwise firm-wide)
          COALESCE(sr.sql_to_sqo_conversion_rate, fw.firm_wide_sql_to_sqo_rate, 0.15) AS sql_to_sqo_conversion_rate,
          -- Current Quarter Calculations
          -- Step 1: How many Joined advisors needed to close the gap?
          CASE 
            WHEN 36.75 - qf.expected_end_of_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
            THEN CEILING((36.75 - qf.expected_end_of_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
            ELSE 0
          END AS joined_needed_current_qtr,
          -- Step 2: How many SQOs needed to get those Joined advisors?
          CASE 
            WHEN 36.75 - qf.expected_end_of_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
              AND COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10) > 0
            THEN CEILING(
              CEILING((36.75 - qf.expected_end_of_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
              / COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10)
            )
            ELSE 0
          END AS sqos_needed_current_qtr,
          -- Step 3: How many SQLs needed to get those SQOs?
          CASE 
            WHEN 36.75 - qf.expected_end_of_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
              AND COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10) > 0
              AND COALESCE(sr.sql_to_sqo_conversion_rate, fw.firm_wide_sql_to_sqo_rate, 0.15) > 0
            THEN CEILING(
              CEILING(
                CEILING((36.75 - qf.expected_end_of_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
                / COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10)
              )
              / COALESCE(sr.sql_to_sqo_conversion_rate, fw.firm_wide_sql_to_sqo_rate, 0.15)
            )
            ELSE 0
          END AS sqls_needed_current_qtr,
          -- Next Quarter Calculations
          -- Step 1: How many Joined advisors needed to close the gap?
          CASE 
            WHEN 36.75 - qf.expected_next_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
            THEN CEILING((36.75 - qf.expected_next_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
            ELSE 0
          END AS joined_needed_next_qtr,
          -- Step 2: How many SQOs needed to get those Joined advisors?
          CASE 
            WHEN 36.75 - qf.expected_next_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
              AND COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10) > 0
            THEN CEILING(
              CEILING((36.75 - qf.expected_next_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
              / COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10)
            )
            ELSE 0
          END AS sqos_needed_next_qtr,
          -- Step 3: How many SQLs needed to get those SQOs?
          CASE 
            WHEN 36.75 - qf.expected_next_quarter > 0 
              AND COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35) > 0
              AND COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10) > 0
              AND COALESCE(sr.sql_to_sqo_conversion_rate, fw.firm_wide_sql_to_sqo_rate, 0.15) > 0
            THEN CEILING(
              CEILING(
                CEILING((36.75 - qf.expected_next_quarter) / COALESCE(sm.effective_avg_margin_aum_per_joined, 11.35))
                / COALESCE(sm.effective_sqo_to_joined_conversion_rate, 0.10)
              )
              / COALESCE(sr.sql_to_sqo_conversion_rate, fw.firm_wide_sql_to_sqo_rate, 0.15)
            )
            ELSE 0
          END AS sqls_needed_next_qtr
        FROM Quarterly_Forecast qf
        LEFT JOIN SGM_Metrics sm
          ON qf.sgm_name = sm.sgm_name
        LEFT JOIN SGM_SQL_To_SQO_Rates sr
          ON qf.sgm_name = sr.sgm_name
        CROSS JOIN Firm_Wide_SQL_To_SQO_Rate fw
        WHERE qf.expected_end_of_quarter < 36.75 OR qf.expected_next_quarter < 36.75  -- Only SGMs with gaps
        ORDER BY 
          (36.75 - qf.expected_end_of_quarter) DESC,  -- Current quarter gaps first
          (36.75 - qf.expected_next_quarter) DESC     -- Then next quarter gaps
        """
        
        # Query 11: Velocity-Based Forecast (Current vs Next Quarter)
        # Uses the 70-day median cycle time logic established in the Feasibility Study
        forecast_velocity_query = f"""
        WITH Forecast_Data AS (
          SELECT
            o.sgm_name,
            o.Full_Opportunity_ID__c,
            o.estimated_margin_aum,
            o.StageName,
            o.Date_Became_SQO__c,
            o.days_open_since_sqo,
            -- Calculate Projected Date: SQO Date + 70 Days (Median Cycle)
            DATE_ADD(DATE(o.Date_Became_SQO__c), INTERVAL 70 DAY) AS projected_close_date,
            -- Calculate Deal Age
            o.days_open_since_sqo AS deal_age_days
          FROM `{self.project_id}.{self.dataset}.vw_sgm_open_sqos_detail` o
          WHERE o.Date_Became_SQO__c IS NOT NULL
        ),
        Stage_Probabilities AS (
          SELECT 
            StageName,
            probability_to_join
          FROM `{self.project_id}.{self.dataset}.vw_stage_to_joined_probability`
        )
        SELECT
          sgm_name,
          -- 1. Current Quarter Forecast (Standard Velocity)
          -- Deals that naturally land in this quarter based on 70-day cycle
          ROUND(SUM(CASE 
            WHEN DATE_TRUNC(projected_close_date, QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) 
            AND deal_age_days <= 70 
            THEN estimated_margin_aum * COALESCE(sp.probability_to_join, 0.5)
            ELSE 0 
          END), 2) AS current_qtr_velocity_forecast,
          -- 2. The "Slip" Risk (Overdue Deals)
          -- Deals older than 70 days. They theoretically "should" have closed. 
          -- We count them as Current Quarter potential, but HIGH RISK.
          ROUND(SUM(CASE 
            WHEN deal_age_days > 70 
            THEN estimated_margin_aum * COALESCE(sp.probability_to_join, 0.5)
            ELSE 0 
          END), 2) AS overdue_slip_forecast,
          -- 3. Next Quarter Forecast (Pipeline Health)
          -- Deals that naturally land next quarter
          ROUND(SUM(CASE 
            WHEN DATE_TRUNC(projected_close_date, QUARTER) = DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 1 QUARTER) 
            THEN estimated_margin_aum * COALESCE(sp.probability_to_join, 0.5)
            ELSE 0 
          END), 2) AS next_qtr_velocity_forecast,
          -- Counts for Context
          COUNT(DISTINCT CASE WHEN deal_age_days > 70 THEN Full_Opportunity_ID__c END) AS overdue_deal_count,
          COUNT(DISTINCT CASE 
            WHEN DATE_TRUNC(projected_close_date, QUARTER) = DATE_ADD(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 1 QUARTER) 
            THEN Full_Opportunity_ID__c 
          END) AS next_qtr_deal_count,
          -- Total pipeline value for context
          ROUND(SUM(estimated_margin_aum), 2) AS total_pipeline_value
        FROM Forecast_Data fd
        LEFT JOIN Stage_Probabilities sp
          ON fd.StageName = sp.StageName
        WHERE sgm_name IS NOT NULL
        GROUP BY sgm_name
        ORDER BY current_qtr_velocity_forecast DESC
        """
        
        # Execute queries
        firm_summary_df = self.bq_client.query_to_dataframe(firm_summary_query)
        coverage_summary_df = self.bq_client.query_to_dataframe(coverage_summary_query)
        sgm_coverage_df = self.bq_client.query_to_dataframe(sgm_coverage_query)
        sgm_risk_df = self.bq_client.query_to_dataframe(sgm_risk_query)
        deals_df = self.bq_client.query_to_dataframe(deals_query)
        concentration_df = self.bq_client.query_to_dataframe(concentration_query)
        stage_dist_df = self.bq_client.query_to_dataframe(stage_dist_query)
        conversion_rates_df = self.bq_client.query_to_dataframe(conversion_rates_query)
        conversion_trends_df = self.bq_client.query_to_dataframe(conversion_trends_query)
        sga_conversion_rates_df = self.bq_client.query_to_dataframe(sga_conversion_rates_query)
        quarterly_forecast_df = self.bq_client.query_to_dataframe(quarterly_forecast_query)
        forecast_velocity_df = self.bq_client.query_to_dataframe(forecast_velocity_query)
        what_if_analysis_df = self.bq_client.query_to_dataframe(what_if_analysis_query)
        
        # Convert to dictionaries
        firm_summary = firm_summary_df.iloc[0].to_dict() if len(firm_summary_df) > 0 else {}
        coverage_summary = coverage_summary_df.iloc[0].to_dict() if len(coverage_summary_df) > 0 else {}
        sgm_coverage_data = sgm_coverage_df.to_dict('records')
        sgm_risk_data = sgm_risk_df.to_dict('records')
        deals_data = deals_df.to_dict('records')
        concentration_data = concentration_df.to_dict('records')
        stage_dist_data = stage_dist_df.to_dict('records')
        conversion_rates_data = conversion_rates_df.to_dict('records')
        conversion_trends_data = conversion_trends_df.to_dict('records')
        sga_conversion_rates_data = sga_conversion_rates_df.to_dict('records')
        quarterly_forecast_data = quarterly_forecast_df.to_dict('records')
        forecast_velocity_data = forecast_velocity_df.to_dict('records')
        what_if_analysis_data = what_if_analysis_df.to_dict('records')
        
        print(f"Retrieved data: {len(firm_summary_df)} firm summary rows, {len(coverage_summary_df)} coverage summary rows, {len(sgm_coverage_df)} SGM coverage rows, {len(sgm_risk_df)} SGM risk rows, {len(deals_df)} deal rows, {len(concentration_df)} concentration risk rows, {len(stage_dist_df)} stage distribution rows, {len(conversion_rates_df)} conversion rate rows, {len(conversion_trends_df)} trend rows, {len(sga_conversion_rates_df)} SGA conversion rate rows, {len(quarterly_forecast_df)} quarterly forecast rows, {len(forecast_velocity_df)} velocity forecast rows, {len(what_if_analysis_df)} what-if analysis rows")
        print("Analyzing data with LLM (using capacity & coverage framework with conversion rate analysis, velocity forecasting, what-if routing recommendations, concentration risk, and stage bottlenecks)...")
        
        # Generate LLM analysis
        llm_analysis = self.llm_analyzer.analyze_capacity_data(
            firm_summary, coverage_summary, sgm_coverage_data, sgm_risk_data, deals_data,
            conversion_rates_data, conversion_trends_data, sga_conversion_rates_data, 
            quarterly_forecast_data, forecast_velocity_data, what_if_analysis_data,
            concentration_data, stage_dist_data
        )
        
        # Generate full report
        report = self._format_report(firm_summary, coverage_summary, sgm_coverage_data, 
                                    sgm_risk_data, deals_data, conversion_rates_data, 
                                    conversion_trends_data, sga_conversion_rates_data, 
                                    quarterly_forecast_data, forecast_velocity_data, 
                                    what_if_analysis_data, llm_analysis)
        
        # Save to file (if output_file is provided and not None)
        if output_file is not None:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"Report saved to: {output_file}")
        elif output_file is None:
            # No file output requested (e.g., Cloud Function usage)
            # Report is returned as string
            print("Report generated (returned as string, not saved to file)")
        
        return report
    
    def _format_report(self, firm_summary: Dict, coverage_summary: Dict,
                      sgm_coverage_data: List[Dict], sgm_risk_data: List[Dict], 
                      deals_data: List[Dict], conversion_rates_data: List[Dict],
                      conversion_trends_data: List[Dict], sga_conversion_rates_data: List[Dict],
                      quarterly_forecast_data: List[Dict], forecast_velocity_data: List[Dict],
                      what_if_analysis_data: List[Dict], llm_analysis: str) -> str:
        """Format the complete report with LLM analysis and raw data"""
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        report = f"""# Capacity & Coverage Summary Report
Generated: {timestamp}

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

{llm_analysis}

---

## Appendix: Raw Data Summary

### Firm-Level Metrics
- **Total SGMs:** {firm_summary.get('total_sgms', 'N/A')}
- **SGMs On Track (Joined):** {firm_summary.get('sgms_on_track', 'N/A')}
- **SGMs with Sufficient SQOs:** {firm_summary.get('sgms_with_sufficient_sqos', 'N/A')}
- **Total Pipeline Estimate:** ${firm_summary.get('total_pipeline_estimate', 0):.1f}M
- **Total Stale Pipeline:** ${firm_summary.get('total_stale_pipeline_estimate', 0):.1f}M
- **Total Quarter Actuals:** ${firm_summary.get('total_quarter_actuals', 0):.1f}M
- **Total Target:** ${firm_summary.get('total_target', 0):.1f}M
- **Total Required SQOs:** {firm_summary.get('total_required_sqos', 'N/A')}
- **Total Current SQOs:** {firm_summary.get('total_current_sqos', 'N/A')}
- **Total Stale SQOs:** {firm_summary.get('total_stale_sqos', 'N/A')}

### Coverage Summary
- **Total Capacity (Forecast):** ${coverage_summary.get('total_capacity', 0):.2f}M
- **Average Coverage Ratio:** {coverage_summary.get('avg_coverage_ratio', 0):.3f} ({coverage_summary.get('avg_coverage_ratio', 0)*100:.1f}%)
- **On Ramp SGMs:** {coverage_summary.get('on_ramp_count', 'N/A')}
- **Sufficient SGMs:** {coverage_summary.get('sufficient_count', 'N/A')}
- **At Risk SGMs:** {coverage_summary.get('at_risk_count', 'N/A')}
- **Under-Capacity SGMs:** {coverage_summary.get('under_capacity_count', 'N/A')}

### SGM Coverage Analysis (Top 15 by Risk)

| SGM | Coverage Status | Coverage Ratio | Capacity (M) | Capacity Gap (M) | Active SQOs | Stale SQOs | Qtr Actuals (M) |
|-----|----------------|----------------|--------------|------------------|-------------|------------|-----------------|
"""
        
        # Add top 15 SGMs to table
        for sgm in sgm_coverage_data[:15]:
            report += f"| {sgm.get('sgm_name', 'N/A')} | {sgm.get('coverage_status', 'N/A')} | {sgm.get('coverage_ratio_estimate', 0):.2f} | ${sgm.get('capacity_estimate', 0):.2f} | ${sgm.get('capacity_gap_millions_estimate', 0):.2f} | {sgm.get('active_sqo_count', 'N/A')} | {sgm.get('stale_sqo_count', 'N/A')} | ${sgm.get('current_quarter_actual_joined_aum_millions', 0):.2f} |\n"
        
        report += f"""

### SGM Risk Assessment (Top 10 by Risk)

| SGM | Status | SQO Gap | Pipeline (M) | Weighted (M) | Stale % | Quarter Actuals (M) |
|-----|--------|---------|--------------|--------------|---------|---------------------|
"""
        
        # Add top 10 SGMs to table
        for sgm in sgm_risk_data[:10]:
            report += f"| {sgm.get('sgm_name', 'N/A')} | {sgm.get('quarterly_target_status', 'N/A')} | {sgm.get('sqo_gap_count', 'N/A')} | ${sgm.get('pipeline_estimate_m', 0):.1f} | ${sgm.get('weighted_pipeline_m', 0):.1f} | {sgm.get('stale_pct', 0):.1f}% | ${sgm.get('qtr_actuals_m', 0):.1f} |\n"
        
        # Add Required SQOs & Joined Per Quarter Analysis with Volatility Context
        report += f"""

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
"""
        
        # Sort by required_sqos_per_quarter (highest first) for the table
        sorted_required = sorted([s for s in sgm_risk_data if s.get('required_sqos_per_quarter') is not None], 
                                key=lambda x: x.get('required_sqos_per_quarter', 0), 
                                reverse=True)
        
        # Add SGMs to table
        for sgm in sorted_required[:20]:  # Top 20 by required SQOs
            sgm_name = sgm.get('sgm_name', 'N/A')
            required_sqos = sgm.get('required_sqos_per_quarter', 'N/A')
            required_joined = sgm.get('required_joined_per_quarter', 'N/A')
            qtd_sqos = sgm.get('current_quarter_sqo_count', 'N/A')  # QTD SQOs (all SQOs this quarter)
            current_pipeline_sqos = sgm.get('current_pipeline_sqo_count', 'N/A')  # Open pipeline SQOs
            
            # Calculate QTD gap and percentage
            if isinstance(required_sqos, (int, float)) and isinstance(qtd_sqos, (int, float)):
                qtd_gap = required_sqos - qtd_sqos
            else:
                qtd_gap = 'N/A'
            
            qtd_pct = None
            if isinstance(required_sqos, (int, float)) and isinstance(qtd_sqos, (int, float)) and required_sqos > 0:
                qtd_pct = (qtd_sqos / required_sqos) * 100
                qtd_pct_str = f"{qtd_pct:.1f}%"
            else:
                qtd_pct_str = "N/A"
            
            # Calculate interpretation based on CI thresholds using QTD SQOs (primary metric)
            # Calculate CI thresholds dynamically
            if isinstance(required_sqos, (int, float)) and required_sqos > 0 and isinstance(qtd_sqos, (int, float)) and qtd_sqos >= 0:
                sqos_lower = max(1, int(required_sqos - 16))  # Lower bound of CI
                sqos_base = int(required_sqos)  # Base case
                sqos_midpoint = int(sqos_lower + (sqos_base - sqos_lower) / 2)  # Halfway between lower and base
                
                if qtd_sqos > sqos_base:
                    interpretation = "✅ EXCEEDING"
                elif qtd_sqos >= sqos_base:
                    interpretation = "🟢 ON TARGET"
                elif qtd_sqos >= sqos_midpoint:
                    interpretation = "🟡 CLOSE"
                elif qtd_sqos >= sqos_lower:
                    interpretation = "🟡 WITHIN RANGE"
                else:
                    gap_below_lower = sqos_lower - qtd_sqos
                    if gap_below_lower > (sqos_base - sqos_lower):
                        interpretation = "🔴 CRITICAL"
                    else:
                        interpretation = "⚠️ SIGNIFICANT"
            elif isinstance(qtd_gap, (int, float)):
                # Fallback to gap-based logic if CI calculation not possible
                if qtd_gap > 30:
                    interpretation = "🔴 CRITICAL"
                elif qtd_gap > 20:
                    interpretation = "⚠️ SIGNIFICANT"
                elif qtd_gap > 10:
                    interpretation = "⚠️ MODERATE"
                elif qtd_gap > 0:
                    interpretation = "🟡 GAP"
                else:
                    interpretation = "✅ SUFFICIENT"
            else:
                interpretation = "N/A"
            
            report += f"| {sgm_name} | {required_joined} | {required_sqos} | {qtd_sqos} | {qtd_gap} | {qtd_pct_str} | {current_pipeline_sqos} | {interpretation} |\n"
        
        report += f"""

### Top Deals Requiring Attention (Stale or High Value)

| Deal | SGM | Stage | Value (M) | Days Open | Stale |
|------|-----|-------|-----------|-----------|-------|
"""
        
        # Add top deals to table
        for deal in deals_data[:15]:
            report += f"| {deal.get('opportunity_name', 'N/A')} | {deal.get('sgm_name', 'N/A')} | {deal.get('StageName', 'N/A')} | ${deal.get('estimated_margin_aum_m', 0):.1f} | {deal.get('days_open_since_sqo', 'N/A')} | {deal.get('is_stale', 'No')} |\n"
        
        report += f"""

### SGA Performance Summary (Top 15 by SQL→SQO Rate Change)

| SGA | Contacted→MQL (QTD) | MQL→SQL (QTD) | SQL→SQO (QTD) | SQL→SQO Change | SQL Volume | SQO Volume |
|-----|---------------------|---------------|---------------|----------------|------------|------------|
"""

        # Sort SGAs by SQL→SQO rate change for the table
        sorted_sgas_table = sorted(sga_conversion_rates_data, 
                                  key=lambda x: abs(x.get('sql_to_sqo_rate_change', 0)), 
                                  reverse=True)
        
        # Add top 15 SGAs to table
        for sga in sorted_sgas_table[:15]:
            report += f"| {sga.get('sga_name', 'N/A')} | {sga.get('current_qtr_contacted_to_mql_rate', 0)*100:.1f}% | {sga.get('current_qtr_mql_to_sql_rate', 0)*100:.1f}% | {sga.get('current_qtr_sql_to_sqo_rate', 0)*100:.1f}% | {sga.get('sql_to_sqo_rate_change', 0)*100:+.1f}pp | {sga.get('current_qtr_sql_volume', 0):.0f} | {sga.get('current_qtr_sqo_volume', 0):.0f} |\n"
        
        # Add What-If Analysis table
        report += f"""

### What-If Analysis: SQO & SQL Routing Recommendations

**Purpose:** Identify SGMs forecasted to miss targets and calculate routing needs to get them back on track.

| SGM | Current Qtr Gap (M) | SQOs Needed (CQ) | SQLs Needed (CQ) | Next Qtr Gap (M) | SQOs Needed (NQ) | SQLs Needed (NQ) | Priority |
|-----|---------------------|------------------|------------------|------------------|------------------|------------------|----------|
"""
        
        # Sort what-if data by priority
        sorted_what_if_table = sorted(what_if_analysis_data, 
                                     key=lambda x: (
                                         x.get('current_qtr_gap_millions', 0) > 0,  # Current quarter gaps first
                                         -x.get('current_qtr_gap_millions', 0),  # Largest gaps first
                                         x.get('next_qtr_gap_millions', 0) > 0,  # Then next quarter gaps
                                         -x.get('next_qtr_gap_millions', 0)
                                     ),
                                     reverse=True)
        
        # Add what-if data to table
        for sgm in sorted_what_if_table[:30]:  # Top 30 SGMs with gaps
            sgm_name = sgm.get('sgm_name', 'N/A')
            current_qtr_gap = sgm.get('current_qtr_gap_millions', 0)
            sqos_needed_cq = sgm.get('sqos_needed_current_qtr', 0)
            sqls_needed_cq = sgm.get('sqls_needed_current_qtr', 0)
            next_qtr_gap = sgm.get('next_qtr_gap_millions', 0)
            sqos_needed_nq = sgm.get('sqos_needed_next_qtr', 0)
            sqls_needed_nq = sgm.get('sqls_needed_next_qtr', 0)
            
            # Determine priority
            if current_qtr_gap > 10:
                priority = "🔴 HIGH"
            elif current_qtr_gap > 0:
                priority = "🟡 MEDIUM"
            elif next_qtr_gap > 10:
                priority = "🟡 MEDIUM"
            elif next_qtr_gap > 0:
                priority = "🟢 LOW"
            else:
                priority = "N/A"
            
            report += f"| {sgm_name} | ${current_qtr_gap:.2f} | {sqos_needed_cq:.0f} | {sqls_needed_cq:.0f} | ${next_qtr_gap:.2f} | {sqos_needed_nq:.0f} | {sqls_needed_nq:.0f} | {priority} |\n"
        
        # Calculate totals
        total_sqos_needed_current = sum(s.get('sqos_needed_current_qtr', 0) for s in sorted_what_if_table)
        total_sqls_needed_current = sum(s.get('sqls_needed_current_qtr', 0) for s in sorted_what_if_table)
        total_sqos_needed_next = sum(s.get('sqos_needed_next_qtr', 0) for s in sorted_what_if_table)
        total_sqls_needed_next = sum(s.get('sqls_needed_next_qtr', 0) for s in sorted_what_if_table)
        
        report += f"""
| **TOTAL** | - | **{total_sqos_needed_current:.0f}** | **{total_sqls_needed_current:.0f}** | - | **{total_sqos_needed_next:.0f}** | **{total_sqls_needed_next:.0f}** | - |
| **GRAND TOTAL** | - | **{total_sqos_needed_current + total_sqos_needed_next:.0f} SQOs** | **{total_sqls_needed_current + total_sqls_needed_next:.0f} SQLs** | - | - | - | - |

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
"""
        
        report += f"""

---

*Report generated using LLM analysis of BigQuery capacity and coverage views.*
*Data sources: `{self.project_id}.{self.dataset}.vw_sgm_capacity_model_refined`, `vw_sgm_capacity_coverage`, `vw_sgm_open_sqos_detail`, `vw_conversion_rates`, `vw_sga_funnel`, and `vw_sgm_capacity_coverage_with_forecast`*
"""
        
        return report


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate LLM-powered capacity summary report from BigQuery"
    )
    parser.add_argument(
        "--project-id",
        type=str,
        default=os.getenv("GOOGLE_CLOUD_PROJECT", "savvy-gtm-analytics"),
        help="BigQuery project ID"
    )
    parser.add_argument(
        "--dataset",
        type=str,
        default="savvy_analytics",
        help="BigQuery dataset name"
    )
    parser.add_argument(
        "--credentials",
        type=str,
        default=None,
        help="Path to Google Cloud service account credentials JSON file"
    )
    parser.add_argument(
        "--llm-provider",
        type=str,
        choices=["openai", "anthropic", "gemini"],
        default="gemini",
        help="LLM provider to use (default: gemini)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output file path (default: capacity_summary_report_TIMESTAMP.md)"
    )
    parser.add_argument(
        "--gamma",
        action="store_true",
        help="Generate PDF via Gamma.app after generation (requires GAMMA_APP_API_KEY and Pro/Ultra/Teams/Business subscription)"
    )
    parser.add_argument(
        "--email",
        type=str,
        default=None,
        help="Email address to send report to (requires SMTP configuration)"
    )
    parser.add_argument(
        "--smtp-server",
        type=str,
        default=os.getenv("SMTP_SERVER", "smtp.gmail.com"),
        help="SMTP server for email sending"
    )
    parser.add_argument(
        "--smtp-port",
        type=int,
        default=int(os.getenv("SMTP_PORT", "587")),
        help="SMTP port (default: 587)"
    )
    parser.add_argument(
        "--smtp-user",
        type=str,
        default=os.getenv("SMTP_USER"),
        help="SMTP username (or set SMTP_USER env var)"
    )
    parser.add_argument(
        "--smtp-password",
        type=str,
        default=os.getenv("SMTP_PASSWORD"),
        help="SMTP password (or set SMTP_PASSWORD env var)"
    )
    
    args = parser.parse_args()
    
    try:
        generator = CapacityReportGenerator(
            project_id=args.project_id,
            dataset=args.dataset,
            credentials_path=args.credentials,
            llm_provider=args.llm_provider
        )
        
        report = generator.generate_report(output_file=args.output)
        
        print("\n" + "="*80)
        print("Report generated successfully!")
        print("="*80)
        
        # Optional: Generate PDF via Gamma.app
        if args.gamma and GAMMA_AVAILABLE:
            print("\n" + "="*80)
            print("Generating PDF via Gamma.app...")
            print("="*80)
            
            gamma_client = GammaAppClient()
            title = f"Capacity Summary Report - {datetime.now().strftime('%Y-%m-%d')}"
            
            # Generate PDF from the markdown report
            pdf_path = None
            if args.output:
                # Save PDF next to the markdown file
                pdf_path = args.output.replace('.md', '.pdf')
            else:
                # Default PDF filename
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                pdf_path = f"capacity_summary_report_{timestamp}.pdf"
            
            pdf_result = gamma_client.create_pdf_from_markdown(
                report,
                title=title,
                save_path=pdf_path
            )
            
            if pdf_result:
                if os.path.exists(pdf_result):
                    print(f"✅ Gamma.app PDF generated and saved: {pdf_result}")
                else:
                    print(f"✅ Gamma.app PDF generated: {pdf_result}")
                    print("   (PDF URL - you can download it manually)")
            else:
                print("⚠️  Gamma.app PDF generation failed.")
                print("   Check API key, subscription level, and credits.")
                print("   Note: Gamma.app API requires Pro/Ultra/Teams/Business subscription.")
        
        # Optional: Send email
        if args.email:
            print(f"\nSending email to {args.email}...")
            try:
                send_email_report(
                    report,
                    args.email,
                    args.smtp_server,
                    args.smtp_port,
                    args.smtp_user,
                    args.smtp_password
                )
                print("✅ Email sent successfully!")
            except Exception as e:
                print(f"❌ Error sending email: {e}")
                print("   Make sure SMTP credentials are configured correctly.")
        
    except Exception as e:
        print(f"Error generating report: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


def send_email_report(markdown_content: str, recipient_email: str, smtp_server: str, 
                     smtp_port: int, smtp_user: str, smtp_password: str) -> None:
    """Send the markdown report via email"""
    try:
        import smtplib
        from email.mime.multipart import MIMEMultipart
        from email.mime.text import MIMEText
        from email.mime.base import MIMEBase
        from email import encoders
        
        # Try to convert markdown to HTML
        try:
            import markdown
            html_content = markdown.markdown(markdown_content, extensions=['tables', 'fenced_code'])
        except ImportError:
            # Fallback: simple HTML conversion
            html_content = markdown_content.replace('\n', '<br>\n')
            html_content = html_content.replace('**', '<strong>').replace('**', '</strong>')
        
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"Capacity Summary Report - {datetime.now().strftime('%Y-%m-%d')}"
        msg['From'] = smtp_user
        msg['To'] = recipient_email
        
        # Add HTML body
        html_body = f"""
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2>Capacity Summary Report</h2>
            <p>Please find the capacity summary report generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.</p>
            <hr>
            {html_content}
            <hr>
            <p style="color: #666; font-size: 12px;">
              This is an automated report. The markdown file is also attached.
            </p>
          </body>
        </html>
        """
        msg.attach(MIMEText(html_body, 'html'))
        
        # Attach markdown file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"capacity_summary_report_{timestamp}.md"
        attachment = MIMEBase('application', 'octet-stream')
        attachment.set_payload(markdown_content.encode('utf-8'))
        encoders.encode_base64(attachment)
        attachment.add_header('Content-Disposition', f'attachment; filename= {filename}')
        msg.attach(attachment)
        
        # Send email
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_password)
            server.send_message(msg)
            
    except ImportError:
        raise Exception("Email sending requires smtplib (built-in) and optionally markdown library")
    except Exception as e:
        raise Exception(f"Failed to send email: {str(e)}")


if __name__ == "__main__":
    exit(main())