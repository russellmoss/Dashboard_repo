"""
LLM-Powered SGA Weekly Performance Report Generator

This script queries BigQuery views and generates a comprehensive weekly performance report
for SGA sales managers using an LLM to analyze SGA performance data and provide coaching insights.

Usage:
    python generate_sga_weekly_report.py [--output OUTPUT_FILE] [--llm-provider openai|anthropic|gemini]
    
Output:
    Generates a markdown report with:
    - QTD Leaderboard (who is winning, who is at zero)
    - The "Hot Sheet" (last 7 days production)
    - Calendar Watch (upcoming activity)
    - Coach's Corner (conversion diagnostics and trends)
    - Source Alerts (channel/source performance trends)
    - Pipeline Forecast (on-track assessment)
"""

import os
import json
import argparse
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from google.cloud import bigquery
from google.oauth2 import service_account
import pandas as pd

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
            self.model = "gpt-4o"
        
        elif self.provider == "anthropic":
            if not ANTHROPIC_AVAILABLE:
                raise ImportError("anthropic package not installed. Run: pip install anthropic")
            if not self.api_key:
                raise ValueError("Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable.")
            self.client = Anthropic(api_key=self.api_key)
            self.model = "claude-3-5-sonnet-20241022"
        
        elif self.provider == "gemini":
            if not GEMINI_AVAILABLE:
                raise ImportError("google-generativeai package not installed. Run: pip install google-generativeai")
            if not self.api_key:
                raise ValueError("Gemini API key not found. Set GEMINI_API_KEY or GOOGLE_API_KEY environment variable.")
            genai.configure(api_key=self.api_key)
            self.client = genai.GenerativeModel("gemini-2.5-pro")
            self.model = "gemini-2.5-pro"
        
        else:
            raise ValueError(f"Unsupported LLM provider: {provider}. Use 'openai', 'anthropic', or 'gemini'")
    
    def analyze_sga_data(self, qtd_leaderboard: List[Dict], activity_data: List[Dict],
                        conversion_trends: List[Dict], lost_reasons: List[Dict],
                        channel_source_data: List[Dict], initial_calls_last7: List[Dict],
                        initial_calls_next7: List[Dict], qual_calls_last7: List[Dict],
                        qual_calls_next7: List[Dict], contacting_activity: List[Dict],
                        team_conversion_rates: Dict, disposition_analysis: List[Dict],
                        current_date: str = None, current_quarter_start: str = None,
                        current_year: int = None) -> str:
        """Use LLM to analyze SGA performance data and generate insights"""
        
        # Prepare data summary for LLM
        data_summary = self._prepare_data_summary(qtd_leaderboard, activity_data,
                                                  conversion_trends, lost_reasons,
                                                  channel_source_data, initial_calls_last7,
                                                  initial_calls_next7, qual_calls_last7,
                                                  qual_calls_next7, contacting_activity,
                                                  team_conversion_rates, disposition_analysis,
                                                  current_date, current_quarter_start, current_year)
        
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
                temperature=0.3,
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
            retry_delay = 2
            
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
                    break
                except Exception as e:
                    error_str = str(e)
                    if "429" in error_str or "Resource has been exhausted" in error_str or "quota" in error_str.lower():
                        if attempt < max_retries - 1:
                            wait_time = retry_delay * (2 ** attempt)
                            print(f"API quota/rate limit hit. Retrying in {wait_time} seconds... (attempt {attempt + 1}/{max_retries})")
                            time.sleep(wait_time)
                            continue
                        else:
                            raise Exception(f"API quota exhausted after {max_retries} attempts. The prompt may be too large. Try reducing data volume or using a different LLM provider.")
                    else:
                        raise
        
        return analysis
    
    def _get_system_prompt(self) -> str:
        """System prompt that defines the LLM's role as a Sales Performance Coach"""
        return """You are an expert Sales Performance Coach analyzing weekly SGA (Sales Growth Associate) performance data.

Your goal is to identify who is winning, who is struggling, and provide specific coaching recommendations based on conversion trends and activity patterns.

## 🎯 YOUR ROLE

You are a **Sales Performance Coach** who:
- Identifies top performers and celebrates wins
- Flags struggling SGAs who need immediate attention
- Provides specific, actionable coaching based on conversion bottlenecks
- Highlights trends and patterns that indicate systemic issues or opportunities

## 📊 THE METRICS

- **Quarterly Goals:** SGA-specific goals (ranging from 9-12 SQOs per quarter). Default is 9 SQOs for SGAs not in the goal list. Each SGA's individual goal is provided in the data.
- **Ramp Period:** First 30 days of an SGA's tenure are excluded from "Lifetime" metrics
- **Key Conversion Stages:**
  - Contacted → MQL
  - MQL → SQL
  - SQL → SQO

## 📝 YOUR REPORT STRUCTURE

Generate a comprehensive weekly report using this structure:

### 1. QTD Leaderboard
- **IMPORTANT SEGMENTATION:** SGAs are segmented into two groups:
  - **Inbound SGAs:** Lauren George and Jacqueline Tully (field inbound leads - typically higher volume)
  - **Outbound SGAs:** All other SGAs (responsible for outbound prospecting - typically lower volume)
- **Who is leading the pack?** Rank SGAs by QTD SQOs WITHIN their respective groups (Inbound vs Outbound). Highlight top performers in each group. Always separate Inbound and Outbound rankings.
- **Who is at zero?** Identify SGAs with 0 QTD SQOs. Flag if they're new (ramp period) vs. struggling. Only compare SGAs within their group (Inbound vs Outbound).

### 2. The "Hot Sheet" (Last 7 Days)
- **Who put points on the board in the last 7 days?** List SGAs who generated SQOs in the trailing 7 days (including today).
- Highlight momentum: "SGA X generated 2 SQOs in the last 7 days, bringing QTD to 8 (80% of goal)."

### 3. Calendar Watch
- **Who has a loaded calendar next week?** **CRITICAL: You MUST list EVERY SINGLE SGA who has ANY upcoming calls (Initial Calls OR Qualification Calls) in the next 7 days.** Do NOT summarize or group - list each SGA individually with their exact call counts. Reference the "Initial Calls Detail - Next 7 Days" and "Qualification Calls Detail - Next 7 Days" tables to ensure you capture ALL calls. Include:
  - SGA name
  - Exact number of Initial Calls
  - Exact number of Qualification Calls
  - For Qualification Calls, include the advisor name and SGM name from the detail table
- **Who has an empty calendar (risk alert)?** SGAs with 0 upcoming calls. This is a critical flag - they need immediate coaching on activity generation.

### 4. Coach's Corner (Conversion Diagnostics)
This is your most valuable section. For each SGA, identify:
- **Specific bottlenecks:** e.g., "SGA X is excellent at booking calls (high Contacted→MQL) but losing them at SQL→SQO. Recommendation: Review SQL handoff notes and qualification criteria."
- **Divergent trends:** Compare Last 90 Days vs. Lifetime (Post-Ramp) conversion rates:
  - **Positive (Improving):** "SGA Y's MQL→SQL conversion improved 15% vs lifetime avg. They're getting better at qualification."
  - **Negative (Diminishing):** "SGA Z's SQL→SQO conversion dropped 10% vs lifetime avg. They may be accepting lower-quality SQLs or struggling with closing."
- **Team Comparison (CRITICAL):** ALWAYS compare each SGA's conversion rates to the team average (last 90 days). Flag if they are significantly above or below team average:
  - "SGA X's Contacted→MQL rate is 5.2% vs team average of 8.1% (-2.9pp). This suggests their outreach messaging or targeting needs improvement."
  - "SGA Y's SQL→SQO rate is 45% vs team average of 32% (+13pp). They're excelling at closing qualified leads."
- **DISPOSITION SENTIMENT ANALYSIS (MANDATORY FOR EVERY SGA):** This is CRITICAL for root cause diagnosis. For EVERY SGA with conversion issues, you MUST:
  1. **Calculate disposition percentages** for their Last 90 Days (both MQL and SQL losses)
  2. **Compare to team averages** - Calculate what % of team losses each disposition represents
  3. **Identify abnormal patterns** - Flag dispositions where the SGA's percentage is significantly different from team norms (e.g., 2x higher or lower)
  4. **Link to conversion issues** - Use disposition patterns to EXPLAIN WHY conversion rates are low:
     - **Example:** "Chris Morgan's MQL→SQL conversion is low (12.7% vs team 25.3%) because he has 40% 'AUM too Low' losses vs team average of 15%. This suggests he's either: (a) targeting the wrong segment, (b) not qualifying AUM early enough, or (c) accepting leads that don't meet ICP criteria."
     - **Example:** "Helen Kamens' SQL→SQO conversion is low (50% vs team 78.9%) because she has 30% 'No Response' losses vs team average of 10%. This suggests her follow-up cadence or handoff process needs improvement."
  5. **Provide specific coaching** based on disposition patterns:
     - High "No Response" → Review follow-up cadence, email templates, call scripts
     - High "AUM/Revenue too Low" → Review ICP targeting, qualification questions, lead source quality
     - High "Not Interested" → Review value proposition, initial call messaging
     - High "Competitor" → Review competitive positioning, differentiation messaging
     - High "Timing" → Review pipeline management, nurturing process
  6. **Compare to lifetime patterns** - If their 90-day disposition mix differs significantly from lifetime, flag it as a trend change that needs attention.
  
  **CRITICAL:** When you see a conversion rate problem, ALWAYS check the disposition analysis FIRST to identify the root cause. Don't just say "conversion is low" - explain WHY based on what dispositions are spiking.

### 5. Source Alerts
- Identify channel/source trends: "LinkedIn is trending down 15% vs yearly avg for SGA X."
- Flag if a previously strong source is weakening for specific SGAs.

### 6. Pipeline Forecast
- For each SGA, calculate: Based on QTD linear progression, are they on track to hit their individual quarterly goal?
- **Formula:** 
  - Calculate daily rate: `QTD SQOs / Days Elapsed in Quarter`
  - Calculate remaining days in quarter (excluding December 25-31 for holiday season)
  - **IMPORTANT:** Reduce December productivity by 33% to account for Christmas and New Year holidays
  - Projection = `QTD SQOs + (Daily Rate * Remaining Days in Quarter)`
  - For December days: Apply 33% reduction factor (multiply by 0.67)
- Flag if projection is < 80% of their goal (at risk) or < 60% of their goal (critical).

## 🎯 COACHING PRINCIPLES

1. **Be Specific:** Don't say "SGA needs to improve." Say "SGA X's SQL→SQO rate dropped 12% - review qualification criteria."

2. **Celebrate Wins:** Acknowledge top performers and positive trends.

3. **Flag Risks Early:** Empty calendars and declining conversion rates need immediate attention.

4. **Context Matters - CRITICAL RAMP PERIOD RULE:**
   - **On Ramp SGAs (CreatedDate within last 30 days):** These are NEW hires. Do NOT flag them for zero production or low performance. They are still learning. Only provide supportive, onboarding-focused coaching. Never say they have "zero production" as a critical issue - they're new!
   - **Post-Ramp SGAs (CreatedDate more than 30 days ago):** These are tenured reps. Flag zero production, declining trends, and performance issues as critical concerns.
   - **ALWAYS check the ramp_status field in the data before making performance judgments.** If ramp_status = "On Ramp", treat them as new hires, not underperformers.

5. **Actionable Recommendations:** Every diagnosis should include a specific coaching action.

**Tone:** Direct, supportive, data-driven. Use specific numbers. Avoid generic statements. Never criticize new hires for being new.

## 📋 APPENDIX: DATA SOURCES & METHODOLOGY

At the end of your report, include a comprehensive appendix that explains:

### Data Sources
- **Primary View:** `vw_funnel_lead_to_joined_v2` - Contains all lead-to-opportunity progression data, SQO dates, call dates, dispositions, and conversion flags
- **Conversion View:** `vw_sga_funnel` - Contains conversion progression flags (contacted_to_mql_progression, mql_to_sql_progression, sql_to_sqo_progression) and eligibility flags
- **User Data:** `SavvyGTMData.User` - Contains SGA creation dates for ramp period calculations

### Date Range Dimensions & Filters

1. **QTD (Quarter to Date):**
   - Start: First day of current quarter (calculated as: month = (current_month - 1) // 3 * 3 + 1, day = 1)
   - End: Current date (inclusive)
   - Used for: QTD SQO counts, quarterly goal progress

2. **Last 7 Days:**
   - Start: Current date - 7 days
   - End: Current date (inclusive, includes today)
   - When run on Sunday, this gives Monday-Sunday (8 days total: today + 7 days back)
   - Date Dimension: `Date_Became_SQO__c` for SQOs, `Initial_Call_Scheduled_Date__c` for initial calls, `Qualification_Call_Date__c` for qualification calls
   - Used for: Recent production, activity tracking

3. **Next 7 Days (Upcoming):**
   - Start: Current date + 1 day (tomorrow, excludes today)
   - End: Current date + 7 days (7 days total starting from tomorrow)
   - When run on Sunday, this gives next Monday-Sunday (7 days total: tomorrow + next 6 days)
   - Date Dimension: `Initial_Call_Scheduled_Date__c` for initial calls, `Qualification_Call_Date__c` for qualification calls
   - Used for: Calendar visibility, activity planning

4. **Last 90 Days (Trailing 90):**
   - Start: Current date - 90 days
   - End: Current date (inclusive)
   - Date Dimension: `FilterDate` (TIMESTAMP field)
   - Used for: Conversion rate trends, activity averages, disposition analysis
   - **Note:** For conversion rates, this is compared against "Lifetime (Post-Ramp)" which excludes the first 30 days after SGA creation

5. **Lifetime (Post-Ramp):**
   - Start: SGA CreatedDate + 30 days (excludes ramp period)
   - End: Current date (inclusive)
   - Date Dimension: `FilterDate` (TIMESTAMP field)
   - Used for: Baseline conversion rates, historical performance comparison

6. **Trailing 365 Days:**
   - Start: Current date - 365 days
   - End: Current date (inclusive)
   - Date Dimension: `FilterDate` (TIMESTAMP field)
   - Used for: Channel/source performance comparison (90d vs 365d)

### Key Calculations

1. **Conversion Rates:**
   - **Contacted → MQL:** `COUNT(DISTINCT contacted_to_mql_progression) / COUNT(DISTINCT eligible_for_contacted_conversions)`
   - **MQL → SQL:** `COUNT(DISTINCT mql_to_sql_progression) / COUNT(DISTINCT eligible_for_mql_conversions)`
   - **SQL → SQO:** `COUNT(DISTINCT sql_to_sqo_progression) / COUNT(DISTINCT eligible_for_sql_conversions)`
   - Source: `vw_sga_funnel` view with progression flags
   - Date filtering: Applied via `FilterDate` field

2. **Ramp Period Logic:**
   - SGAs are considered "On Ramp" if `days_since_creation <= 30`
   - Ramp period = First 30 days after SGA `CreatedDate` from `SavvyGTMData.User`
   - Lifetime metrics exclude this 30-day period: `WHERE FilterDate >= DATE_ADD(User.CreatedDate, INTERVAL 30 DAY)`

3. **SQO Deduplication:**
   - Uses `ROW_NUMBER() OVER (PARTITION BY Full_Opportunity_ID__c, SGA_Owner_Name__c ORDER BY Date_Became_SQO__c DESC)`
   - Ensures each opportunity is counted once per SGA, using the most recent SQO date

4. **Pipeline Forecast:**
   - Daily Rate = `QTD SQOs / Days Elapsed in Quarter`
   - Remaining Days = Total days in quarter - Days elapsed
   - **December Adjustment:** Days in December are multiplied by 0.67 (33% reduction) to account for holiday season
   - Projected SQOs = `QTD SQOs + (Daily Rate * Remaining Days)`
   - For December days: `(Daily Rate * 0.67 * December Days)`

5. **Contacting Activity:**
   - Metric: Count of records where `stage_entered_contacting__c` is not null
   - Average Weekly Contacts = `Total Contacts (Last 90 Days, Post-Ramp) / Weeks in Period`
   - Weeks in Period = `(Days in Period - Ramp Days) / 7`
   - Comparison: Last 7 Days contacts vs. Average Weekly Contacts

6. **Disposition Analysis:**
   - **Closed Lost MQLs:** `is_mql = 1 AND is_sql = 0 AND Disposition__c IS NOT NULL`
   - **Closed Lost SQLs:** `is_sql = 1 AND is_sqo = 0 AND Disposition__c IS NOT NULL AND StageName = 'Closed Lost'`
   - Grouped by `Disposition__c` for each SGA
   - Compared: Last 90 Days vs. Lifetime (Post-Ramp) vs. Team Aggregate (Last 90 Days)

7. **Team Aggregate Calculations:**
   - All team metrics aggregate data across all active SGAs (excluding: 'Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
   - Team conversion rates use the same formulas as individual SGAs but aggregate all eligible records
   - Team disposition analysis aggregates all closed lost MQLs/SQLs across the team

### Global Filters Applied
- `IsSGA__c = TRUE` AND `IsActive = TRUE` (from `SavvyGTMData.User`)
- `SGA_Owner_Name__c NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')`

### SGA Segmentation
- **Inbound SGAs:** Lauren George, Jacqueline Tully (handle inbound leads)
- **Outbound SGAs:** All other active SGAs (responsible for outbound prospecting)
- Rankings and comparisons are done within each segment

**Include this appendix at the end of your report to provide transparency on how all metrics are calculated.**
"""
    
    def _prepare_data_summary(self, qtd_leaderboard: List[Dict], activity_data: List[Dict],
                             conversion_trends: List[Dict], lost_reasons: List[Dict],
                             channel_source_data: List[Dict], initial_calls_last7: List[Dict],
                             initial_calls_next7: List[Dict], qual_calls_last7: List[Dict],
                             qual_calls_next7: List[Dict], contacting_activity: List[Dict],
                             team_conversion_rates: Dict, disposition_analysis: List[Dict],
                             current_date: str = None, current_quarter_start: str = None,
                             current_year: int = None) -> str:
        """Format the data for the LLM prompt"""
        
        summary = "# SGA Weekly Performance Data\n\n"
        
        # Add date context for forecast calculations
        if current_date and current_quarter_start and current_year:
            from datetime import datetime
            current_dt = datetime.strptime(current_date, '%Y-%m-%d').date() if isinstance(current_date, str) else current_date
            quarter_start_dt = datetime.strptime(current_quarter_start, '%Y-%m-%d').date() if isinstance(current_quarter_start, str) else current_quarter_start
            
            days_elapsed = (current_dt - quarter_start_dt).days + 1
            
            # Calculate quarter end
            quarter_num = (current_dt.month - 1) // 3
            if quarter_num == 0:  # Q1
                quarter_end_month = 3
            elif quarter_num == 1:  # Q2
                quarter_end_month = 6
            elif quarter_num == 2:  # Q3
                quarter_end_month = 9
            else:  # Q4
                quarter_end_month = 12
            
            from calendar import monthrange
            quarter_end = current_dt.replace(month=quarter_end_month, day=monthrange(current_year, quarter_end_month)[1])
            total_days_in_quarter = (quarter_end - quarter_start_dt).days + 1
            remaining_days = total_days_in_quarter - days_elapsed
            
            # Calculate December days in remaining period
            december_days = 0
            if quarter_end_month == 12:  # Q4
                if current_dt.month < 12:
                    # Current date is before December, all December days count
                    december_days = 31
                elif current_dt.month == 12:
                    # Current date is in December, only remaining December days count
                    december_end = min(quarter_end, current_dt.replace(month=12, day=31))
                    if current_dt <= december_end:
                        december_days = (december_end - current_dt).days
            
            summary += f"## Date Context for Forecast Calculations\n\n"
            summary += f"- **Current Date:** {current_date}\n"
            summary += f"- **Quarter Start:** {current_quarter_start}\n"
            summary += f"- **Quarter End:** {quarter_end.strftime('%Y-%m-%d')}\n"
            summary += f"- **Days Elapsed in Quarter:** {days_elapsed}\n"
            summary += f"- **Total Days in Quarter:** {total_days_in_quarter}\n"
            summary += f"- **Remaining Days in Quarter:** {remaining_days}\n"
            summary += f"- **December Days in Remaining Period:** {december_days} (will be reduced by 33% for holiday season)\n"
            summary += f"- **Non-December Days in Remaining Period:** {remaining_days - december_days}\n\n"
        
        # QTD Leaderboard
        summary += "## QTD Leaderboard & Last 7 Days Production\n\n"
        for sga in qtd_leaderboard:
            sga_name = sga.get('sga_name', 'Unknown')
            ramp_status = sga.get('ramp_status', 'Unknown')
            days_since_creation = sga.get('days_since_creation', 0)
            created_date = sga.get('sga_created_date', 'Unknown')
            sqo_goal = sga.get('sqo_goal', 9)
            pct_of_goal = sga.get('pct_of_goal', 0)
            sga_type = sga.get('sga_type', 'Outbound')
            summary += f"**{sga_name} ({sga_type}):**\n"
            summary += f"- Ramp Status: {ramp_status} (Created: {created_date}, {days_since_creation} days ago)\n"
            summary += f"- Quarterly Goal: {sqo_goal} SQOs\n"
            summary += f"- QTD SQOs: {sga.get('qtd_sqos', 0)} ({pct_of_goal:.1f}% of goal)\n"
            summary += f"- Last 7 Days SQOs: {sga.get('last_7_days_sqos', 0)}\n"
            sqo_list = sga.get('sqo_list', [])
            # Handle both list and array types from BigQuery
            if sqo_list is not None and len(sqo_list) > 0:
                # Convert to list if it's a pandas Series or array
                if hasattr(sqo_list, 'tolist'):
                    sqo_list = sqo_list.tolist()
                elif not isinstance(sqo_list, list):
                    sqo_list = list(sqo_list)
                # Create a table of all SQOs QTD
                summary += f"- **All SQOs QTD ({len(sqo_list)} total):**\n"
                summary += "  | Advisor Name | SQO Date | SGA Name |\n"
                summary += "  |--------------|----------|----------|\n"
                for sqo in sqo_list:
                    advisor = sqo.get('advisor_name', 'Unknown')
                    sqo_date = sqo.get('sqo_date', 'Unknown')
                    sga_name_sqo = sqo.get('sga_name', sga.get('sga_name', 'Unknown'))
                    summary += f"  | {advisor} | {sqo_date} | {sga_name_sqo} |\n"
            summary += "\n"
        
        # Activity Data - Summary Tables
        summary += "## Activity Summary (Trailing & Upcoming 7 Days)\n\n"
        
        # Table 1: Initial Calls Summary
        summary += "### Initial Calls Summary\n\n"
        summary += "| SGA Name | Last 7 Days | Next 7 Days |\n"
        summary += "|----------|-------------|-------------|\n"
        for sga in activity_data:
            summary += f"| {sga.get('sga_name', 'Unknown')} | {sga.get('trailing_initial_calls', 0)} | {sga.get('upcoming_initial_calls', 0)} |\n"
        summary += "\n"
        
        # Table 2: Initial Calls Detail (Last 7 Days)
        summary += "### Initial Calls Detail - Last 7 Days\n\n"
        summary += "| SGA Name | Advisor Name | Call Date |\n"
        summary += "|----------|-------------|-----------|\n"
        for call in initial_calls_last7:
            summary += f"| {call.get('sga_name', 'Unknown')} | {call.get('advisor_name', 'Unknown')} | {call.get('call_date', 'Unknown')} |\n"
        summary += "\n"
        
        # Table 3: Initial Calls Detail (Next 7 Days)
        summary += "### Initial Calls Detail - Next 7 Days\n\n"
        summary += "**COMPLETE LIST - Every initial call scheduled in the next 7 days (starting tomorrow):**\n\n"
        summary += "| SGA Name | Prospect Name | Initial Call Scheduled Date |\n"
        summary += "|----------|--------------|------------------------------|\n"
        for call in initial_calls_next7:
            summary += f"| {call.get('sga_name', 'Unknown')} | {call.get('prospect_name', 'Unknown')} | {call.get('call_date', 'Unknown')} |\n"
        summary += "\n"
        
        # Table 4: Qualification Calls Summary
        summary += "### Qualification Calls Summary\n\n"
        summary += "| SGA Name | Last 7 Days | Next 7 Days |\n"
        summary += "|----------|-------------|-------------|\n"
        for sga in activity_data:
            summary += f"| {sga.get('sga_name', 'Unknown')} | {sga.get('trailing_qual_calls', 0)} | {sga.get('upcoming_qual_calls', 0)} |\n"
        summary += "\n"
        
        # Table 5: Qualification Calls Detail (Last 7 Days)
        summary += "### Qualification Calls Detail - Last 7 Days\n\n"
        summary += "| SGA Name | Advisor Name | Call Date | SGM Name |\n"
        summary += "|----------|-------------|-----------|----------|\n"
        for call in qual_calls_last7:
            summary += f"| {call.get('sga_name', 'Unknown')} | {call.get('advisor_name', 'Unknown')} | {call.get('call_date', 'Unknown')} | {call.get('sgm_name', 'N/A')} |\n"
        summary += "\n"
        
        # Table 6: Qualification Calls Detail (Next 7 Days)
        summary += "### Qualification Calls Detail - Next 7 Days\n\n"
        summary += "**COMPLETE LIST - Every qualification call scheduled in the next 7 days (starting tomorrow):**\n\n"
        summary += "| SGA Name | Advisor Name | Call Date | SGM Name |\n"
        summary += "|----------|-------------|-----------|----------|\n"
        for call in qual_calls_next7:
            summary += f"| {call.get('sga_name', 'Unknown')} | {call.get('advisor_name', 'Unknown')} | {call.get('call_date', 'Unknown')} | {call.get('sgm_name', 'N/A')} |\n"
        summary += "\n"
        
        # Table 7: Contacting Activity (Last 90 Days Average vs Last 7 Days)
        summary += "## Contacting Activity Analysis (Last 90 Days Average vs Last 7 Days)\n\n"
        summary += "This table shows each SGA's average weekly contacts (people moved into 'contacting' stage) over the last 90 days (excluding first 30 days ramp period) compared to their last 7 days performance.\n\n"
        summary += "| SGA Name | Avg Weekly Contacts (90d) | Contacts Last 7 Days | Comparison |\n"
        summary += "|----------|---------------------------|---------------------|------------|\n"
        for sga in contacting_activity:
            sga_name = sga.get('sga_name', 'Unknown')
            avg_weekly = sga.get('avg_weekly_contacted_90d', 0)
            last_7d = sga.get('contacted_last_7d', 0)
            comparison = sga.get('comparison_status', 'N/A')
            summary += f"| {sga_name} | {avg_weekly:.1f} | {last_7d} | {comparison} |\n"
        summary += "\n"
        
        # Disposition Analysis
        summary += "## Disposition Analysis (Closed Lost MQLs & SQLs) - SENTIMENT ANALYSIS\n\n"
        summary += "This table shows the breakdown of disposition reasons for Closed Lost MQLs and SQLs for each SGA (Last 90 Days vs Lifetime Post-Ramp vs Team Aggregate).\n"
        summary += "**USE THIS DATA TO IDENTIFY ROOT CAUSES OF CONVERSION ISSUES BY COMPARING DISPOSITION PERCENTAGES TO TEAM AVERAGES.**\n\n"
        summary += "**Closed Lost MQLs:** is_mql = 1 AND is_sql = 0 AND disposition__c IS NOT NULL\n"
        summary += "**Closed Lost SQLs:** is_sql = 1 AND is_sqo = 0 AND disposition__c IS NOT NULL AND StageName = 'Closed Lost'\n\n"
        
        # Calculate team totals for percentage calculations (team data is the same for all SGAs, so use first one)
        team_mql_total = 0
        team_sql_total = 0
        if disposition_analysis and len(disposition_analysis) > 0:
            first_sga = disposition_analysis[0]
            team_mql_total = sum(first_sga.get('mql_dispositions_team', {}).values()) if first_sga.get('mql_dispositions_team') else 0
            team_sql_total = sum(first_sga.get('sql_dispositions_team', {}).values()) if first_sga.get('sql_dispositions_team') else 0
        
        for sga_disp in disposition_analysis:
            sga_name = sga_disp.get('sga_name', 'Unknown')
            summary += f"### {sga_name}\n\n"
            
            # MQL Dispositions
            mql_dispositions_90d = sga_disp.get('mql_dispositions_90d', {})
            mql_dispositions_lifetime = sga_disp.get('mql_dispositions_lifetime', {})
            mql_dispositions_team = sga_disp.get('mql_dispositions_team', {})
            
            # Calculate totals for percentages
            sga_mql_total_90d = sum(mql_dispositions_90d.values()) if mql_dispositions_90d else 0
            sga_mql_total_life = sum(mql_dispositions_lifetime.values()) if mql_dispositions_lifetime else 0
            
            summary += "**Closed Lost MQL Dispositions:**\n"
            summary += f"*Total MQL Losses (90d): {sga_mql_total_90d} | Lifetime: {sga_mql_total_life} | Team Total (90d): {team_mql_total}*\n\n"
            summary += "| Disposition | Last 90 Days | % of SGA | Lifetime | Team Avg | % of Team | Variance vs Team |\n"
            summary += "|-------------|--------------|----------|----------|----------|------------|------------------|\n"
            all_mql_disps = set(list(mql_dispositions_90d.keys()) + list(mql_dispositions_lifetime.keys()) + list(mql_dispositions_team.keys()))
            for disp in sorted(all_mql_disps):
                count_90d = mql_dispositions_90d.get(disp, 0)
                count_life = mql_dispositions_lifetime.get(disp, 0)
                count_team = mql_dispositions_team.get(disp, 0)
                
                # Calculate percentages
                pct_sga = (count_90d / sga_mql_total_90d * 100) if sga_mql_total_90d > 0 else 0
                pct_team = (count_team / team_mql_total * 100) if team_mql_total > 0 else 0
                variance = pct_sga - pct_team
                variance_str = f"{variance:+.1f}pp" if variance != 0 else "0.0pp"
                
                summary += f"| {disp} | {count_90d} | {pct_sga:.1f}% | {count_life} | {count_team} | {pct_team:.1f}% | {variance_str} |\n"
            
            # SQL Dispositions
            sql_dispositions_90d = sga_disp.get('sql_dispositions_90d', {})
            sql_dispositions_lifetime = sga_disp.get('sql_dispositions_lifetime', {})
            sql_dispositions_team = sga_disp.get('sql_dispositions_team', {})
            
            # Calculate totals for percentages
            sga_sql_total_90d = sum(sql_dispositions_90d.values()) if sql_dispositions_90d else 0
            sga_sql_total_life = sum(sql_dispositions_lifetime.values()) if sql_dispositions_lifetime else 0
            
            summary += "\n**Closed Lost SQL Dispositions:**\n"
            summary += f"*Total SQL Losses (90d): {sga_sql_total_90d} | Lifetime: {sga_sql_total_life} | Team Total (90d): {team_sql_total}*\n\n"
            summary += "| Disposition | Last 90 Days | % of SGA | Lifetime | Team Avg | % of Team | Variance vs Team |\n"
            summary += "|-------------|--------------|----------|----------|----------|------------|------------------|\n"
            all_sql_disps = set(list(sql_dispositions_90d.keys()) + list(sql_dispositions_lifetime.keys()) + list(sql_dispositions_team.keys()))
            for disp in sorted(all_sql_disps):
                count_90d = sql_dispositions_90d.get(disp, 0)
                count_life = sql_dispositions_lifetime.get(disp, 0)
                count_team = sql_dispositions_team.get(disp, 0)
                
                # Calculate percentages
                pct_sga = (count_90d / sga_sql_total_90d * 100) if sga_sql_total_90d > 0 else 0
                pct_team = (count_team / team_sql_total * 100) if team_sql_total > 0 else 0
                variance = pct_sga - pct_team
                variance_str = f"{variance:+.1f}pp" if variance != 0 else "0.0pp"
                
                summary += f"| {disp} | {count_90d} | {pct_sga:.1f}% | {count_life} | {count_team} | {pct_team:.1f}% | {variance_str} |\n"
            summary += "\n"
        
        # Conversion Trends - Create a table with team comparison
        summary += "## Conversion Rate Trends (Last 90 Days vs Lifetime Post-Ramp vs Team Average)\n\n"
        team_c_mql = team_conversion_rates.get('contacted_to_mql_90d', 0) * 100
        team_mql_sql = team_conversion_rates.get('mql_to_sql_90d', 0) * 100
        team_sql_sqo = team_conversion_rates.get('sql_to_sqo_90d', 0) * 100
        summary += f"**Team Averages (Last 90 Days):** Contacted→MQL: {team_c_mql:.1f}%, MQL→SQL: {team_mql_sql:.1f}%, SQL→SQO: {team_sql_sqo:.1f}%\n\n"
        summary += "| SGA Name | Contacted→MQL (90d) | vs Team | Contacted→MQL (Lifetime) | Trend | MQL→SQL (90d) | vs Team | MQL→SQL (Lifetime) | Trend | SQL→SQO (90d) | vs Team | SQL→SQO (Lifetime) | Trend |\n"
        summary += "|----------|---------------------|---------|-------------------------|-------|---------------|---------|-------------------|-------|----------------|---------|-------------------|-------|\n"
        for sga in conversion_trends:
            sga_name = sga.get('sga_name', 'Unknown')
            c_mql_90d = sga.get('contacted_to_mql_90d', 0) * 100
            c_mql_vs_team = c_mql_90d - team_c_mql
            c_mql_life = sga.get('contacted_to_mql_lifetime', 0) * 100
            c_mql_trend = sga.get('contacted_to_mql_trend', 'N/A')
            mql_sql_90d = sga.get('mql_to_sql_90d', 0) * 100
            mql_sql_vs_team = mql_sql_90d - team_mql_sql
            mql_sql_life = sga.get('mql_to_sql_lifetime', 0) * 100
            mql_sql_trend = sga.get('mql_to_sql_trend', 'N/A')
            sql_sqo_90d = sga.get('sql_to_sqo_90d', 0) * 100
            sql_sqo_vs_team = sql_sqo_90d - team_sql_sqo
            sql_sqo_life = sga.get('sql_to_sqo_lifetime', 0) * 100
            sql_sqo_trend = sga.get('sql_to_sqo_trend', 'N/A')
            summary += f"| {sga_name} | {c_mql_90d:.1f}% | {c_mql_vs_team:+.1f}pp | {c_mql_life:.1f}% | {c_mql_trend} | {mql_sql_90d:.1f}% | {mql_sql_vs_team:+.1f}pp | {mql_sql_life:.1f}% | {mql_sql_trend} | {sql_sqo_90d:.1f}% | {sql_sqo_vs_team:+.1f}pp | {sql_sqo_life:.1f}% | {sql_sqo_trend} |\n"
        summary += "\n"
        
        # Lost Reasons
        summary += "## Lost Reason Analysis (Last 90 Days)\n\n"
        for reason in lost_reasons:
            summary += f"**{reason.get('disposition', 'Unknown')}:** {reason.get('count', 0)} losses\n"
            sga_breakdown = reason.get('sga_breakdown', [])
            # Handle both list and array types from BigQuery
            if sga_breakdown is not None and len(sga_breakdown) > 0:
                # Convert to list if it's a pandas Series or array
                if hasattr(sga_breakdown, 'tolist'):
                    sga_breakdown = sga_breakdown.tolist()
                elif not isinstance(sga_breakdown, list):
                    sga_breakdown = list(sga_breakdown)
                sga_list = ', '.join([f"{sga.get('sga_name', 'Unknown')} ({sga.get('count', 0)})" for sga in sga_breakdown[:3]])
                summary += f"- Top SGAs: {sga_list}\n"
            summary += "\n"
        
        # Channel & Source Intelligence
        summary += "## Channel & Source Intelligence (Trailing 90 Days vs Trailing 365 Days)\n\n"
        for item in channel_source_data:
            summary += f"**{item.get('channel_grouping', 'Unknown')} / {item.get('original_source', 'Unknown')}:**\n"
            summary += f"- SQO Generation Rate (90d): {item.get('sqo_rate_90d', 0)*100:.2f}%\n"
            summary += f"- SQO Generation Rate (365d): {item.get('sqo_rate_365d', 0)*100:.2f}%\n"
            summary += f"- Change: {(item.get('sqo_rate_90d', 0) - item.get('sqo_rate_365d', 0))*100:+.2f} percentage points\n"
            summary += "\n"
        
        return summary
    
    def _create_analysis_prompt(self, data_summary: str) -> str:
        """Create the analysis prompt for the LLM"""
        return f"""Analyze the following SGA weekly performance data and generate a comprehensive coaching report.

{data_summary}

Please provide:
1. QTD Leaderboard (winners and zeros)
2. The "Hot Sheet" (last 7 days production)
3. Calendar Watch (upcoming activity risks)
   - **CRITICAL:** For "Who has a loaded calendar next week?", you MUST list EVERY SINGLE SGA who has ANY calls scheduled. Do NOT summarize - list each SGA individually with their exact counts. Use the "Initial Calls Detail - Next 7 Days" and "Qualification Calls Detail - Next 7 Days" tables to ensure you capture ALL calls. For qualification calls, include the advisor name and SGM name from the detail table.
4. Coach's Corner (conversion diagnostics with specific recommendations)
5. Source Alerts (channel/source trends)
6. Pipeline Forecast (on-track assessment for each SGA)

Be specific, data-driven, and actionable. Use the exact numbers provided. When listing upcoming calls, reference the detail tables to ensure completeness - do not rely solely on summary counts.
"""


class SGAWeeklyReportGenerator:
    """Main class that orchestrates SGA weekly report generation"""
    
    def __init__(self, project_id: str, dataset: str = "savvy_analytics",
                 credentials_path: Optional[str] = None, llm_provider: str = "gemini",
                 llm_api_key: Optional[str] = None):
        self.project_id = project_id
        self.dataset = dataset
        self.bq_client = BigQueryClient(project_id, credentials_path)
        self.llm_analyzer = LLMAnalyzer(provider=llm_provider, api_key=llm_api_key)
    
    def generate_report(self, output_file: Optional[str] = None) -> str:
        """Generate the complete SGA weekly performance report"""
        
        print("Querying BigQuery views...")
        
        # Calculate date ranges
        current_date = datetime.now().date()
        
        # Calculate current quarter start
        current_quarter = (current_date.month - 1) // 3
        current_quarter_start = current_date.replace(month=current_quarter * 3 + 1, day=1)
        current_year = current_date.year
        
        # SGA-specific quarterly goals (Q4 2025)
        sga_goals = {
            'Craig Suchodolski': 12,
            'Russell Armitage': 12,
            'Eleni Stefanopoulos': 12,
            'Chris Morgan': 12,
            'Marisa Saucedo': 11,
            'Lauren George': 10,
            'Perry Kalmeta': 10,
            'Ryan Crandall': 10,
            'Channing Guyer': 9
        }
        default_goal = 9
        
        # Last 7 days (trailing 7 days from today, inclusive of today)
        # When run on Sunday, this gives Monday-Sunday (8 days total: today + 7 days back)
        last_7_days_start = current_date - timedelta(days=7)  # 8 days total including today
        last_7_days_end = current_date
        
        # Next 7 days (upcoming 7 days starting from tomorrow, NOT including today)
        # When run on Sunday, this gives next Monday-Sunday (7 days total: tomorrow + next 6 days)
        upcoming_7_days_start = current_date + timedelta(days=1)  # Start from tomorrow
        upcoming_7_days_end = current_date + timedelta(days=7)  # 7 days total
        
        # Query A: QTD Leaderboard & Last 7 Days Production
        print("  Query A: QTD Leaderboard & Last 7 Days Production...")
        query_a = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name,
            u.Id AS sga_user_id,
            u.CreatedDate AS sga_created_date
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        SQO_Records AS (
          SELECT 
            f.Full_Opportunity_ID__c AS opp_id,
            f.SGA_Owner_Name__c AS sga_name,
            f.Opp_Name AS advisor_name,
            DATE(f.Date_Became_SQO__c) AS sqo_date,
            f.Date_Became_SQO__c AS sqo_timestamp,
            ROW_NUMBER() OVER (PARTITION BY f.Full_Opportunity_ID__c, f.SGA_Owner_Name__c ORDER BY f.Date_Became_SQO__c DESC) AS rn
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.Date_Became_SQO__c IS NOT NULL
            AND LOWER(f.SQO_raw) = 'yes'
            AND DATE(f.Date_Became_SQO__c) >= DATE('{current_quarter_start}')
        ),
        SQO_Records_Deduped AS (
          SELECT 
            opp_id,
            sga_name,
            advisor_name,
            sqo_date,
            sqo_timestamp
          FROM SQO_Records
          WHERE rn = 1
        ),
        SGA_Goals AS (
          SELECT sga_name, sqo_goal
          FROM UNNEST([
            STRUCT('Craig Suchodolski' AS sga_name, 12 AS sqo_goal),
            STRUCT('Russell Armitage' AS sga_name, 12 AS sqo_goal),
            STRUCT('Eleni Stefanopoulos' AS sga_name, 12 AS sqo_goal),
            STRUCT('Chris Morgan' AS sga_name, 12 AS sqo_goal),
            STRUCT('Marisa Saucedo' AS sga_name, 11 AS sqo_goal),
            STRUCT('Lauren George' AS sga_name, 10 AS sqo_goal),
            STRUCT('Perry Kalmeta' AS sga_name, 10 AS sqo_goal),
            STRUCT('Ryan Crandall' AS sga_name, 10 AS sqo_goal),
            STRUCT('Channing Guyer' AS sga_name, 9 AS sqo_goal)
          ])
        ),
        QTD_SQOs AS (
          SELECT
            a.sga_name,
            a.sga_created_date,
            DATE_DIFF(CURRENT_DATE(), DATE(a.sga_created_date), DAY) AS days_since_creation,
            CASE 
              WHEN DATE_DIFF(CURRENT_DATE(), DATE(a.sga_created_date), DAY) <= 30 THEN 'On Ramp'
              ELSE 'Post-Ramp'
            END AS ramp_status,
            CASE
              WHEN a.sga_name IN ('Lauren George', 'Jacqueline Tully') THEN 'Inbound'
              ELSE 'Outbound'
            END AS sga_type,
            COALESCE(g.sqo_goal, 9) AS sqo_goal,
            COUNT(DISTINCT CASE 
              WHEN s.sqo_date >= DATE('{current_quarter_start}') 
              THEN s.opp_id 
            END) AS qtd_sqos,
            COUNT(DISTINCT CASE 
              WHEN s.sqo_date >= DATE('{last_7_days_start}')
                AND s.sqo_date <= DATE('{last_7_days_end}')
              THEN s.opp_id 
            END) AS last_7_days_sqos
          FROM Active_SGAs a
          LEFT JOIN SQO_Records_Deduped s
            ON s.sga_name = a.sga_name
          LEFT JOIN SGA_Goals g
            ON a.sga_name = g.sga_name
          GROUP BY a.sga_name, a.sga_created_date, g.sqo_goal
        ),
        SQO_Details AS (
          SELECT
            s.sga_name,
            ARRAY_AGG(
              STRUCT(
                s.advisor_name AS advisor_name,
                FORMAT_DATE('%Y-%m-%d', s.sqo_date) AS sqo_date,
                s.sga_name AS sga_name
              )
              ORDER BY s.sqo_timestamp DESC
            ) AS sqo_list
          FROM SQO_Records_Deduped s
          GROUP BY s.sga_name
        )
        SELECT
          q.sga_name,
          q.qtd_sqos,
          q.last_7_days_sqos,
          q.sqo_goal,
          q.sga_type,
          ROUND((q.qtd_sqos / NULLIF(q.sqo_goal, 0)) * 100, 1) AS pct_of_goal,
          FORMAT_DATE('%Y-%m-%d', DATE(q.sga_created_date)) AS sga_created_date,
          q.days_since_creation,
          q.ramp_status,
          COALESCE(s.sqo_list, []) AS sqo_list
        FROM QTD_SQOs q
        LEFT JOIN SQO_Details s
          ON q.sga_name = s.sga_name
        ORDER BY q.sga_type, q.qtd_sqos DESC, q.last_7_days_sqos DESC, q.sga_name
        """
        
        qtd_leaderboard_df = self.bq_client.query_to_dataframe(query_a)
        qtd_leaderboard = qtd_leaderboard_df.to_dict('records')
        
        # Query B: Activity Summary (Trailing & Upcoming 7 Days)
        print("  Query B: Activity Summary (Trailing & Upcoming 7 Days)...")
        query_b = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        )
        SELECT
          a.sga_name,
          COUNT(DISTINCT CASE 
            WHEN DATE(f.Initial_Call_Scheduled_Date__c) >= DATE('{last_7_days_start}')
              AND DATE(f.Initial_Call_Scheduled_Date__c) <= DATE('{last_7_days_end}')
            THEN f.Full_prospect_id__c 
          END) AS trailing_initial_calls,
          COUNT(DISTINCT CASE 
            WHEN DATE(f.Qualification_Call_Date__c) >= DATE('{last_7_days_start}')
              AND DATE(f.Qualification_Call_Date__c) <= DATE('{last_7_days_end}')
            THEN f.Full_Opportunity_ID__c 
          END) AS trailing_qual_calls,
          COUNT(DISTINCT CASE 
            WHEN DATE(f.Initial_Call_Scheduled_Date__c) >= DATE('{upcoming_7_days_start}')
              AND DATE(f.Initial_Call_Scheduled_Date__c) <= DATE('{upcoming_7_days_end}')
            THEN f.Full_prospect_id__c 
          END) AS upcoming_initial_calls,
          COUNT(DISTINCT CASE 
            WHEN DATE(f.Qualification_Call_Date__c) >= DATE('{upcoming_7_days_start}')
              AND DATE(f.Qualification_Call_Date__c) <= DATE('{upcoming_7_days_end}')
            THEN f.Full_Opportunity_ID__c 
          END) AS upcoming_qual_calls
        FROM Active_SGAs a
        LEFT JOIN `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          ON f.SGA_Owner_Name__c = a.sga_name
        GROUP BY a.sga_name
        ORDER BY a.sga_name
        """
        
        activity_df = self.bq_client.query_to_dataframe(query_b)
        activity_data = activity_df.to_dict('records')
        
        # Query B1: Initial Calls Detail (Last 7 Days)
        print("  Query B1: Initial Calls Detail (Last 7 Days)...")
        query_b1 = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        )
        SELECT
          f.SGA_Owner_Name__c AS sga_name,
          f.Prospect_Name AS advisor_name,
          FORMAT_DATE('%Y-%m-%d', DATE(f.Initial_Call_Scheduled_Date__c)) AS call_date
        FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
        INNER JOIN Active_SGAs a
          ON f.SGA_Owner_Name__c = a.sga_name
        WHERE f.is_initial_call = 1
          AND DATE(f.Initial_Call_Scheduled_Date__c) >= DATE('{last_7_days_start}')
          AND DATE(f.Initial_Call_Scheduled_Date__c) <= DATE('{last_7_days_end}')
        ORDER BY f.SGA_Owner_Name__c, f.Initial_Call_Scheduled_Date__c
        """
        
        initial_calls_last7_df = self.bq_client.query_to_dataframe(query_b1)
        initial_calls_last7 = initial_calls_last7_df.to_dict('records')
        
        # Query B2: Initial Calls Detail (Next 7 Days)
        print("  Query B2: Initial Calls Detail (Next 7 Days)...")
        query_b2 = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        )
        SELECT
          f.SGA_Owner_Name__c AS sga_name,
          f.Prospect_Name AS prospect_name,
          FORMAT_DATE('%Y-%m-%d', DATE(f.Initial_Call_Scheduled_Date__c)) AS call_date
        FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
        INNER JOIN Active_SGAs a
          ON f.SGA_Owner_Name__c = a.sga_name
        WHERE f.is_initial_call = 1
          AND f.Initial_Call_Scheduled_Date__c IS NOT NULL
          AND DATE(f.Initial_Call_Scheduled_Date__c) >= DATE('{upcoming_7_days_start}')
          AND DATE(f.Initial_Call_Scheduled_Date__c) <= DATE('{upcoming_7_days_end}')
        ORDER BY f.SGA_Owner_Name__c, f.Initial_Call_Scheduled_Date__c
        """
        
        initial_calls_next7_df = self.bq_client.query_to_dataframe(query_b2)
        initial_calls_next7 = initial_calls_next7_df.to_dict('records')
        
        # Query B3: Qualification Calls Detail (Last 7 Days)
        print("  Query B3: Qualification Calls Detail (Last 7 Days)...")
        query_b3 = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        )
        SELECT
          f.SGA_Owner_Name__c AS sga_name,
          f.Opp_Name AS advisor_name,
          FORMAT_DATE('%Y-%m-%d', DATE(f.Qualification_Call_Date__c)) AS call_date,
          f.sgm_name AS sgm_name
        FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
        INNER JOIN Active_SGAs a
          ON f.SGA_Owner_Name__c = a.sga_name
        WHERE f.is_Qual_call = 1
          AND DATE(f.Qualification_Call_Date__c) >= DATE('{last_7_days_start}')
          AND DATE(f.Qualification_Call_Date__c) <= DATE('{last_7_days_end}')
        ORDER BY f.SGA_Owner_Name__c, f.Qualification_Call_Date__c
        """
        
        qual_calls_last7_df = self.bq_client.query_to_dataframe(query_b3)
        qual_calls_last7 = qual_calls_last7_df.to_dict('records')
        
        # Query B4: Qualification Calls Detail (Next 7 Days)
        print("  Query B4: Qualification Calls Detail (Next 7 Days)...")
        query_b4 = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        )
        SELECT
          f.SGA_Owner_Name__c AS sga_name,
          f.Opp_Name AS advisor_name,
          FORMAT_DATE('%Y-%m-%d', DATE(f.Qualification_Call_Date__c)) AS call_date,
          f.sgm_name AS sgm_name
        FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
        INNER JOIN Active_SGAs a
          ON f.SGA_Owner_Name__c = a.sga_name
        WHERE f.is_Qual_call = 1
          AND f.Qualification_Call_Date__c IS NOT NULL
          AND DATE(f.Qualification_Call_Date__c) >= DATE('{upcoming_7_days_start}')
          AND DATE(f.Qualification_Call_Date__c) <= DATE('{upcoming_7_days_end}')
        ORDER BY f.SGA_Owner_Name__c, f.Qualification_Call_Date__c
        """
        
        qual_calls_next7_df = self.bq_client.query_to_dataframe(query_b4)
        qual_calls_next7 = qual_calls_next7_df.to_dict('records')
        
        # Query C: Conversion Rate Trends
        print("  Query C: Conversion Rate Trends...")
        query_c = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name,
            u.CreatedDate AS sga_created_date
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        Conversion_Rates_90d AS (
          SELECT
            a.sga_name,
            -- Contacted→MQL: Filter by contacted_cohort_month (when they were contacted)
            SAFE_DIVIDE(
              SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.contacted_to_mql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_contacted_conversions ELSE 0 END), 0)
            ) AS contacted_to_mql_90d,
            -- MQL→SQL: Filter by mql_cohort_month (when they became MQL)
            SAFE_DIVIDE(
              SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.mql_to_sql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_mql_conversions ELSE 0 END), 0)
            ) AS mql_to_sql_90d,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            -- Note: For SQL→SQO, we need to use COUNT DISTINCT on opportunities, but vw_sga_funnel uses progression flags
            -- The progression flag approach is correct for vw_sga_funnel
            SAFE_DIVIDE(
              SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.sql_to_sqo_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_sql_conversions ELSE 0 END), 0)
            ) AS sql_to_sqo_90d
          FROM Active_SGAs a
          LEFT JOIN `{self.project_id}.{self.dataset}.vw_sga_funnel` f
            ON f.SGA_Owner_Name__c = a.sga_name
          GROUP BY a.sga_name
        ),
        Conversion_Rates_Lifetime AS (
          SELECT
            a.sga_name,
            -- Contacted→MQL: Filter by contacted_cohort_month (when they were contacted), excluding ramp period
            SAFE_DIVIDE(
              SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.contacted_to_mql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.eligible_for_contacted_conversions ELSE 0 END), 0)
            ) AS contacted_to_mql_lifetime,
            -- MQL→SQL: Filter by mql_cohort_month (when they became MQL), excluding ramp period
            SAFE_DIVIDE(
              SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.mql_to_sql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.eligible_for_mql_conversions ELSE 0 END), 0)
            ) AS mql_to_sql_lifetime,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL), excluding ramp period
            SAFE_DIVIDE(
              SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.sql_to_sqo_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), MONTH)
                THEN f.eligible_for_sql_conversions ELSE 0 END), 0)
            ) AS sql_to_sqo_lifetime
          FROM Active_SGAs a
          LEFT JOIN `{self.project_id}.{self.dataset}.vw_sga_funnel` f
            ON f.SGA_Owner_Name__c = a.sga_name
          GROUP BY a.sga_name, a.sga_created_date
        )
        SELECT
          c90.sga_name,
          COALESCE(c90.contacted_to_mql_90d, 0) AS contacted_to_mql_90d,
          COALESCE(cl.contacted_to_mql_lifetime, 0) AS contacted_to_mql_lifetime,
          CASE 
            WHEN c90.contacted_to_mql_90d > cl.contacted_to_mql_lifetime * 1.05 THEN 'Positive (Improving)'
            WHEN c90.contacted_to_mql_90d < cl.contacted_to_mql_lifetime * 0.95 THEN 'Negative (Diminishing)'
            ELSE 'Stable'
          END AS contacted_to_mql_trend,
          COALESCE(c90.mql_to_sql_90d, 0) AS mql_to_sql_90d,
          COALESCE(cl.mql_to_sql_lifetime, 0) AS mql_to_sql_lifetime,
          CASE 
            WHEN c90.mql_to_sql_90d > cl.mql_to_sql_lifetime * 1.05 THEN 'Positive (Improving)'
            WHEN c90.mql_to_sql_90d < cl.mql_to_sql_lifetime * 0.95 THEN 'Negative (Diminishing)'
            ELSE 'Stable'
          END AS mql_to_sql_trend,
          COALESCE(c90.sql_to_sqo_90d, 0) AS sql_to_sqo_90d,
          COALESCE(cl.sql_to_sqo_lifetime, 0) AS sql_to_sqo_lifetime,
          CASE 
            WHEN c90.sql_to_sqo_90d > cl.sql_to_sqo_lifetime * 1.05 THEN 'Positive (Improving)'
            WHEN c90.sql_to_sqo_90d < cl.sql_to_sqo_lifetime * 0.95 THEN 'Negative (Diminishing)'
            ELSE 'Stable'
          END AS sql_to_sqo_trend
        FROM Conversion_Rates_90d c90
        LEFT JOIN Conversion_Rates_Lifetime cl
          ON c90.sga_name = cl.sga_name
        ORDER BY c90.sga_name
        """
        
        conversion_trends_df = self.bq_client.query_to_dataframe(query_c)
        conversion_trends = conversion_trends_df.to_dict('records')
        
        # Query D: Lost Reason Analysis
        print("  Query D: Lost Reason Analysis...")
        query_d = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        Lost_Reasons AS (
          SELECT
            f.Disposition__c AS disposition,
            f.SGA_Owner_Name__c AS sga_name,
            COUNT(DISTINCT f.Full_prospect_id__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.Disposition__c IS NOT NULL
            AND (f.is_mql = 1 OR f.is_sql = 1)
            AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.Disposition__c, f.SGA_Owner_Name__c
        )
        SELECT
          disposition,
          SUM(count) AS total_count,
          ARRAY_AGG(
            STRUCT(sga_name, count)
            ORDER BY count DESC
            LIMIT 5
          ) AS sga_breakdown
        FROM Lost_Reasons
        GROUP BY disposition
        ORDER BY total_count DESC
        LIMIT 20
        """
        
        lost_reasons_df = self.bq_client.query_to_dataframe(query_d)
        lost_reasons = lost_reasons_df.to_dict('records')
        
        # Query E: Channel & Source Intelligence
        print("  Query E: Channel & Source Intelligence...")
        query_e = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        Channel_Source_90d AS (
          SELECT
            f.Channel_Grouping_Name AS channel_grouping,
            f.Original_source AS original_source,
            COUNT(DISTINCT CASE WHEN f.Date_Became_SQO__c IS NOT NULL 
              AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
              THEN f.Full_Opportunity_ID__c END) AS sqo_count_90d,
            COUNT(DISTINCT CASE WHEN f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
              THEN f.Full_prospect_id__c END) AS total_count_90d
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.Channel_Grouping_Name, f.Original_source
        ),
        Channel_Source_365d AS (
          SELECT
            f.Channel_Grouping_Name AS channel_grouping,
            f.Original_source AS original_source,
            COUNT(DISTINCT CASE WHEN f.Date_Became_SQO__c IS NOT NULL 
              AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
              THEN f.Full_Opportunity_ID__c END) AS sqo_count_365d,
            COUNT(DISTINCT CASE WHEN f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
              THEN f.Full_prospect_id__c END) AS total_count_365d
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
          GROUP BY f.Channel_Grouping_Name, f.Original_source
        )
        SELECT
          COALESCE(c90.channel_grouping, c365.channel_grouping) AS channel_grouping,
          COALESCE(c90.original_source, c365.original_source) AS original_source,
          SAFE_DIVIDE(c90.sqo_count_90d, NULLIF(c90.total_count_90d, 0)) AS sqo_rate_90d,
          SAFE_DIVIDE(c365.sqo_count_365d, NULLIF(c365.total_count_365d, 0)) AS sqo_rate_365d
        FROM Channel_Source_90d c90
        FULL OUTER JOIN Channel_Source_365d c365
          ON c90.channel_grouping = c365.channel_grouping
          AND c90.original_source = c365.original_source
        WHERE COALESCE(c90.total_count_90d, 0) >= 10  -- Minimum volume threshold
        ORDER BY ABS(SAFE_DIVIDE(c90.sqo_count_90d, NULLIF(c90.total_count_90d, 0)) - 
                     SAFE_DIVIDE(c365.sqo_count_365d, NULLIF(c365.total_count_365d, 0))) DESC
        LIMIT 30
        """
        
        channel_source_df = self.bq_client.query_to_dataframe(query_e)
        channel_source_data = channel_source_df.to_dict('records')
        
        # Query F: Contacting Activity (Last 90 Days Average vs Last 7 Days)
        print("  Query F: Contacting Activity Analysis...")
        query_f = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name,
            u.CreatedDate AS sga_created_date
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        Contacting_Events_90d AS (
          SELECT
            a.sga_name,
            a.sga_created_date,
            DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY) AS ramp_end_date,
            GREATEST(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)) AS period_start,
            CURRENT_DATE() AS period_end,
            COUNT(DISTINCT CASE 
              WHEN f.stage_entered_contacting__c IS NOT NULL
                AND DATE(f.stage_entered_contacting__c) >= GREATEST(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
                AND DATE(f.stage_entered_contacting__c) <= CURRENT_DATE()
              THEN f.Full_prospect_id__c 
            END) AS total_contacted_90d,
            -- Calculate number of weeks in the period (excluding ramp)
            GREATEST(1.0, 
              DATE_DIFF(
                CURRENT_DATE(),
                GREATEST(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY), DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)),
                DAY
              ) / 7.0
            ) AS weeks_in_period
          FROM Active_SGAs a
          LEFT JOIN `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
            ON f.SGA_Owner_Name__c = a.sga_name
          GROUP BY a.sga_name, a.sga_created_date
        ),
        Contacting_Events_Last7d AS (
          SELECT
            a.sga_name,
            COUNT(DISTINCT CASE 
              WHEN f.stage_entered_contacting__c IS NOT NULL
                AND DATE(f.stage_entered_contacting__c) >= DATE('{last_7_days_start}')
                AND DATE(f.stage_entered_contacting__c) <= DATE('{last_7_days_end}')
              THEN f.Full_prospect_id__c 
            END) AS contacted_last_7d
          FROM Active_SGAs a
          LEFT JOIN `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
            ON f.SGA_Owner_Name__c = a.sga_name
          GROUP BY a.sga_name
        )
        SELECT
          c90.sga_name,
          c90.total_contacted_90d,
          c90.weeks_in_period,
          ROUND(c90.total_contacted_90d / NULLIF(c90.weeks_in_period, 0), 1) AS avg_weekly_contacted_90d,
          COALESCE(c7.contacted_last_7d, 0) AS contacted_last_7d,
          CASE 
            WHEN COALESCE(c7.contacted_last_7d, 0) > ROUND(c90.total_contacted_90d / NULLIF(c90.weeks_in_period, 0), 1) THEN 'Above Average'
            WHEN COALESCE(c7.contacted_last_7d, 0) < ROUND(c90.total_contacted_90d / NULLIF(c90.weeks_in_period, 0), 1) THEN 'Below Average'
            ELSE 'At Average'
          END AS comparison_status
        FROM Contacting_Events_90d c90
        LEFT JOIN Contacting_Events_Last7d c7
          ON c90.sga_name = c7.sga_name
        ORDER BY c90.sga_name
        """
        
        contacting_activity_df = self.bq_client.query_to_dataframe(query_f)
        contacting_activity = contacting_activity_df.to_dict('records')
        
        # Query G: Team Aggregate Conversion Rates (Last 90 Days)
        print("  Query G: Team Aggregate Conversion Rates...")
        query_g = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        Team_Conversion_Rates AS (
          SELECT
            -- Contacted→MQL: Filter by contacted_cohort_month (when they were contacted)
            SAFE_DIVIDE(
              SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.contacted_to_mql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.contacted_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_contacted_conversions ELSE 0 END), 0)
            ) AS contacted_to_mql_90d,
            -- MQL→SQL: Filter by mql_cohort_month (when they became MQL)
            SAFE_DIVIDE(
              SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.mql_to_sql_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.mql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_mql_conversions ELSE 0 END), 0)
            ) AS mql_to_sql_90d,
            -- SQL→SQO: Filter by sql_cohort_month (when they became SQL)
            SAFE_DIVIDE(
              SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.sql_to_sqo_progression ELSE 0 END),
              NULLIF(SUM(CASE WHEN f.sql_cohort_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), MONTH)
                THEN f.eligible_for_sql_conversions ELSE 0 END), 0)
            ) AS sql_to_sqo_90d
          FROM `{self.project_id}.{self.dataset}.vw_sga_funnel` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
        )
        SELECT * FROM Team_Conversion_Rates
        """
        
        team_rates_df = self.bq_client.query_to_dataframe(query_g)
        team_conversion_rates = team_rates_df.iloc[0].to_dict() if len(team_rates_df) > 0 else {}
        
        # Query H: Disposition Analysis (Closed Lost MQLs & SQLs)
        print("  Query H: Disposition Analysis...")
        query_h = f"""
        WITH Active_SGAs AS (
          SELECT DISTINCT
            u.Name AS sga_name,
            u.CreatedDate AS sga_created_date
          FROM `{self.project_id}.SavvyGTMData.User` u
          WHERE u.IsSGA__c = TRUE 
            AND u.IsActive = TRUE
            AND u.Name NOT IN ('Savvy Marketing', 'Corey Marcello', 'Bryan Belville', 'Anett Diaz')
        ),
        -- Closed Lost MQLs: is_mql = 1 AND is_sql = 0 AND disposition__c IS NOT NULL
        MQL_Dispositions_90d AS (
          SELECT
            f.SGA_Owner_Name__c AS sga_name,
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_prospect_id__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_mql = 1
            AND f.is_sql = 0
            AND f.Disposition__c IS NOT NULL
            AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.SGA_Owner_Name__c, f.Disposition__c
        ),
        MQL_Dispositions_Lifetime AS (
          SELECT
            f.SGA_Owner_Name__c AS sga_name,
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_prospect_id__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_mql = 1
            AND f.is_sql = 0
            AND f.Disposition__c IS NOT NULL
            AND f.FilterDate >= TIMESTAMP(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY))
          GROUP BY f.SGA_Owner_Name__c, f.Disposition__c
        ),
        MQL_Dispositions_Team AS (
          SELECT
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_prospect_id__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_mql = 1
            AND f.is_sql = 0
            AND f.Disposition__c IS NOT NULL
            AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.Disposition__c
        ),
        -- Closed Lost SQLs: is_sql = 1 AND is_sqo = 0 AND disposition__c IS NOT NULL AND StageName = 'Closed Lost'
        SQL_Dispositions_90d AS (
          SELECT
            f.SGA_Owner_Name__c AS sga_name,
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_Opportunity_ID__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_sql = 1
            AND (f.is_sqo = 0 OR f.Date_Became_SQO__c IS NULL)
            AND f.Disposition__c IS NOT NULL
            AND f.StageName = 'Closed Lost'
            AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.SGA_Owner_Name__c, f.Disposition__c
        ),
        SQL_Dispositions_Lifetime AS (
          SELECT
            f.SGA_Owner_Name__c AS sga_name,
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_Opportunity_ID__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_sql = 1
            AND (f.is_sqo = 0 OR f.Date_Became_SQO__c IS NULL)
            AND f.Disposition__c IS NOT NULL
            AND f.StageName = 'Closed Lost'
            AND f.FilterDate >= TIMESTAMP(DATE_ADD(DATE(a.sga_created_date), INTERVAL 30 DAY))
          GROUP BY f.SGA_Owner_Name__c, f.Disposition__c
        ),
        SQL_Dispositions_Team AS (
          SELECT
            f.Disposition__c AS disposition,
            COUNT(DISTINCT f.Full_Opportunity_ID__c) AS count
          FROM `{self.project_id}.{self.dataset}.vw_funnel_lead_to_joined_v2` f
          INNER JOIN Active_SGAs a
            ON f.SGA_Owner_Name__c = a.sga_name
          WHERE f.is_sql = 1
            AND (f.is_sqo = 0 OR f.Date_Became_SQO__c IS NULL)
            AND f.Disposition__c IS NOT NULL
            AND f.StageName = 'Closed Lost'
            AND f.FilterDate >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
          GROUP BY f.Disposition__c
        ),
        Team_MQL_Dispositions AS (
          SELECT ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS mql_disps_team
          FROM MQL_Dispositions_Team
        ),
        Team_SQL_Dispositions AS (
          SELECT ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS sql_disps_team
          FROM SQL_Dispositions_Team
        ),
        SGA_MQL_90d_Agg AS (
          SELECT
            sga_name,
            ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS mql_disps_90d
          FROM MQL_Dispositions_90d
          GROUP BY sga_name
        ),
        SGA_MQL_Lifetime_Agg AS (
          SELECT
            sga_name,
            ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS mql_disps_lifetime
          FROM MQL_Dispositions_Lifetime
          GROUP BY sga_name
        ),
        SGA_SQL_90d_Agg AS (
          SELECT
            sga_name,
            ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS sql_disps_90d
          FROM SQL_Dispositions_90d
          GROUP BY sga_name
        ),
        SGA_SQL_Lifetime_Agg AS (
          SELECT
            sga_name,
            ARRAY_AGG(STRUCT(disposition, count) ORDER BY count DESC) AS sql_disps_lifetime
          FROM SQL_Dispositions_Lifetime
          GROUP BY sga_name
        )
        SELECT
          a.sga_name,
          COALESCE(m90.mql_disps_90d, []) AS mql_disps_90d,
          COALESCE(ml.mql_disps_lifetime, []) AS mql_disps_lifetime,
          COALESCE(s90.sql_disps_90d, []) AS sql_disps_90d,
          COALESCE(sl.sql_disps_lifetime, []) AS sql_disps_lifetime,
          t_mql.mql_disps_team,
          t_sql.sql_disps_team
        FROM Active_SGAs a
        LEFT JOIN SGA_MQL_90d_Agg m90 ON a.sga_name = m90.sga_name
        LEFT JOIN SGA_MQL_Lifetime_Agg ml ON a.sga_name = ml.sga_name
        LEFT JOIN SGA_SQL_90d_Agg s90 ON a.sga_name = s90.sga_name
        LEFT JOIN SGA_SQL_Lifetime_Agg sl ON a.sga_name = sl.sga_name
        CROSS JOIN Team_MQL_Dispositions t_mql
        CROSS JOIN Team_SQL_Dispositions t_sql
        ORDER BY a.sga_name
        """
        
        disposition_df = self.bq_client.query_to_dataframe(query_h)
        # Convert the arrays to dictionaries for easier processing
        disposition_analysis = []
        for row in disposition_df.to_dict('records'):
            sga_name = row.get('sga_name', 'Unknown')
            
            # Convert MQL dispositions arrays to dictionaries
            mql_disps_90d = {}
            if row.get('mql_disps_90d') is not None:
                if hasattr(row['mql_disps_90d'], 'tolist'):
                    mql_list = row['mql_disps_90d'].tolist()
                else:
                    mql_list = list(row['mql_disps_90d']) if isinstance(row['mql_disps_90d'], (list, tuple)) else []
                for item in mql_list:
                    if isinstance(item, dict):
                        mql_disps_90d[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            mql_disps_lifetime = {}
            if row.get('mql_disps_lifetime') is not None:
                if hasattr(row['mql_disps_lifetime'], 'tolist'):
                    mql_list = row['mql_disps_lifetime'].tolist()
                else:
                    mql_list = list(row['mql_disps_lifetime']) if isinstance(row['mql_disps_lifetime'], (list, tuple)) else []
                for item in mql_list:
                    if isinstance(item, dict):
                        mql_disps_lifetime[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            mql_disps_team = {}
            if row.get('mql_disps_team') is not None:
                if hasattr(row['mql_disps_team'], 'tolist'):
                    mql_list = row['mql_disps_team'].tolist()
                else:
                    mql_list = list(row['mql_disps_team']) if isinstance(row['mql_disps_team'], (list, tuple)) else []
                for item in mql_list:
                    if isinstance(item, dict):
                        mql_disps_team[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            # Convert SQL dispositions arrays to dictionaries
            sql_disps_90d = {}
            if row.get('sql_disps_90d') is not None:
                if hasattr(row['sql_disps_90d'], 'tolist'):
                    sql_list = row['sql_disps_90d'].tolist()
                else:
                    sql_list = list(row['sql_disps_90d']) if isinstance(row['sql_disps_90d'], (list, tuple)) else []
                for item in sql_list:
                    if isinstance(item, dict):
                        sql_disps_90d[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            sql_disps_lifetime = {}
            if row.get('sql_disps_lifetime') is not None:
                if hasattr(row['sql_disps_lifetime'], 'tolist'):
                    sql_list = row['sql_disps_lifetime'].tolist()
                else:
                    sql_list = list(row['sql_disps_lifetime']) if isinstance(row['sql_disps_lifetime'], (list, tuple)) else []
                for item in sql_list:
                    if isinstance(item, dict):
                        sql_disps_lifetime[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            sql_disps_team = {}
            if row.get('sql_disps_team') is not None:
                if hasattr(row['sql_disps_team'], 'tolist'):
                    sql_list = row['sql_disps_team'].tolist()
                else:
                    sql_list = list(row['sql_disps_team']) if isinstance(row['sql_disps_team'], (list, tuple)) else []
                for item in sql_list:
                    if isinstance(item, dict):
                        sql_disps_team[item.get('disposition', 'Unknown')] = item.get('count', 0)
            
            disposition_analysis.append({
                'sga_name': sga_name,
                'mql_dispositions_90d': mql_disps_90d,
                'mql_dispositions_lifetime': mql_disps_lifetime,
                'mql_dispositions_team': mql_disps_team,
                'sql_dispositions_90d': sql_disps_90d,
                'sql_dispositions_lifetime': sql_disps_lifetime,
                'sql_dispositions_team': sql_disps_team
            })
        
        print("Analyzing data with LLM...")
        
        # Generate report using LLM
        report = self.llm_analyzer.analyze_sga_data(
            qtd_leaderboard=qtd_leaderboard,
            activity_data=activity_data,
            conversion_trends=conversion_trends,
            lost_reasons=lost_reasons,
            channel_source_data=channel_source_data,
            initial_calls_last7=initial_calls_last7,
            initial_calls_next7=initial_calls_next7,
            qual_calls_last7=qual_calls_last7,
            qual_calls_next7=qual_calls_next7,
            contacting_activity=contacting_activity,
            team_conversion_rates=team_conversion_rates,
            disposition_analysis=disposition_analysis,
            current_date=str(current_date),
            current_quarter_start=str(current_quarter_start),
            current_year=current_year
        )
        
        # Add header
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        header = f"""# SGA Weekly Performance Report

**Generated:** {timestamp}
**Quarterly Goals:** SGA-specific (9-12 SQOs per quarter, default: 9)
**Report Period:** QTD (Quarter to Date) + Last 7 Days Analysis

---

"""
        
        full_report = header + report
        
        # Save to file
        if output_file is None:
            timestamp_file = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"sga_weekly_report_{timestamp_file}.md"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(full_report)
        
        print(f"\nReport saved to: {output_file}")
        
        return full_report


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate LLM-powered SGA weekly performance report from BigQuery"
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
        "--api-key",
        type=str,
        default=None,
        help="API key for LLM provider (overrides environment variable)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output file path (default: sga_weekly_report_TIMESTAMP.md)"
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
        generator = SGAWeeklyReportGenerator(
            project_id=args.project_id,
            dataset=args.dataset,
            credentials_path=args.credentials,
            llm_provider=args.llm_provider,
            llm_api_key=args.api_key
        )
        
        report = generator.generate_report(output_file=args.output)
        
        print("\n" + "="*80)
        print("Report generated successfully!")
        print("="*80)
        
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
        msg['Subject'] = f"SGA Weekly Performance Report - {datetime.now().strftime('%Y-%m-%d')}"
        msg['From'] = smtp_user
        msg['To'] = recipient_email
        
        # Add HTML body
        html_body = f"""
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2>SGA Weekly Performance Report</h2>
            <p>Please find the SGA weekly performance report generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.</p>
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
        filename = f"sga_weekly_report_{timestamp}.md"
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

