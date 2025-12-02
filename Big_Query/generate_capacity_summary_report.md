# LLM-Powered Capacity Model Summary Report Generator

## Overview
This document describes how to generate automated, actionable summary reports for sales managers using the SGM Capacity Model views in BigQuery. The solution uses Large Language Models (LLMs) to analyze the data and generate comprehensive, actionable insights.

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Credentials

**Option A: Environment Variables (Recommended)**

**For Windows PowerShell:**
```powershell
$env:GOOGLE_CLOUD_PROJECT="savvy-gtm-analytics"
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account-key.json"
# For Gemini (recommended):
$env:GEMINI_API_KEY="AIzaSy-your-api-key-here"
# OR for OpenAI:
# $env:OPENAI_API_KEY="sk-your-api-key-here"
```

**For Linux/Mac (Bash):**
```bash
export GOOGLE_CLOUD_PROJECT="savvy-gtm-analytics"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
export OPENAI_API_KEY="sk-your-api-key-here"
```

**Note:** In PowerShell, environment variables set with `$env:` only last for the current session. To make them permanent, use:
```powershell
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-your-key-here", "User")
```

**Option B: Service Account File**
- Download your Google Cloud service account JSON key
- Place it in a secure location
- Reference it with `--credentials` flag or `GOOGLE_APPLICATION_CREDENTIALS` env var

### 3. Run the Report Generator

```bash
# Basic usage (uses defaults)
python generate_capacity_summary.py

# With custom output file
python generate_capacity_summary.py --output my_report.md

# Using Anthropic Claude instead of OpenAI
python generate_capacity_summary.py --llm-provider anthropic

# Custom project/dataset
python generate_capacity_summary.py --project-id my-project --dataset my_dataset
```

## What It Does

The script:
1. **Queries BigQuery** - Pulls data from three key views:
   - `vw_sgm_capacity_model_refined` - Firm-level and SGM-level metrics
   - `vw_sgm_open_sqos_detail` - Detailed opportunity data
   - Risk and pipeline health metrics

2. **Analyzes with LLM** - Sends structured data to an LLM (OpenAI GPT-4 or Anthropic Claude) with a specialized prompt that:
   - Understands sales capacity planning
   - Identifies risks and opportunities
   - Generates actionable recommendations
   - Provides specific questions managers should ask

3. **Generates Report** - Creates a comprehensive markdown report with:
   - Executive summary with firm-level status
   - Risk assessment by SGM (who's at risk and why)
   - Critical questions managers should ask
   - Top deals requiring immediate attention
   - Next quarter readiness assessment
   - Prioritized action items
   - Raw data tables for reference

## Report Structure

Each generated report includes:

### 1. Executive Summary
- Overall firm status: Are we on track for the quarter?
- Key metrics: Pipeline coverage, quarter progress, risk level
- Top-line assessment: At risk, on target, or ahead of plan

### 2. Risk Assessment by SGM
- Who is at highest risk and why (with specific numbers)
- Who is on track and performing well
- Key patterns or trends across the team

### 3. Critical Questions Managers Should Ask
- Specific questions for each high-risk SGM
- Questions about pipeline health and deal quality
- Questions about next quarter readiness

### 4. Top Deals Requiring Immediate Attention
- Which deals are most at risk and why
- Which deals are most valuable and need focus
- Recommendations for deal-level actions

### 5. Next Quarter Readiness Assessment
- How does the pipeline look for next quarter?
- What are the early warning signs?
- What actions should be taken now to prepare?

### 6. Action Items (Prioritized)
- Immediate actions (this week)
- Short-term actions (this month)
- Strategic actions (this quarter)

### 7. Appendix: Raw Data Summary
- Firm-level metrics table
- SGM risk assessment table (top 10)
- Top deals table (top 15)

## Key Data Sources

The script queries these BigQuery views:

1. **`vw_sgm_capacity_model_refined`** 
   - Aggregated metrics per SGM
   - Pipeline sufficiency indicators
   - Quarterly target status
   - Gap analysis

2. **`vw_sgm_open_sqos_detail`**
   - Detailed opportunity-level data
   - Staleness indicators
   - Days open since SQO
   - Estimated margin AUM

## LLM Provider Options

### Google Gemini (Default) ⭐ Recommended
- **Model**: Gemini 2.5 Pro
- **Pros**: Latest model, excellent for data analysis, integrates well with Google Cloud, cost-effective
- **Setup**: Set `GEMINI_API_KEY` or `GOOGLE_API_KEY` environment variable
- **Cost**: ~$0.005-0.015 per report (very cost-effective)
- **Best for**: BigQuery users, Google Cloud ecosystem

### OpenAI
- **Model**: GPT-4o (or GPT-4 Turbo)
- **Pros**: Fast, reliable, good at structured analysis
- **Setup**: Set `OPENAI_API_KEY` environment variable
- **Cost**: ~$0.01-0.03 per report (depending on data size)

### Anthropic Claude
- **Model**: Claude 3.5 Sonnet
- **Pros**: Excellent at nuanced analysis, longer context
- **Setup**: Set `ANTHROPIC_API_KEY` environment variable
- **Cost**: ~$0.015-0.045 per report

## Automation & Scheduling

### Option 1: Cron Job (Linux/Mac)
```bash
# Run every Monday at 9 AM
0 9 * * 1 cd /path/to/Big_Query && python generate_capacity_summary.py --output weekly_reports/capacity_report_$(date +\%Y\%m\%d).md
```

### Option 2: Windows Task Scheduler
- Create a task that runs `python generate_capacity_summary.py`
- Schedule weekly or daily

### Option 3: Google Cloud Functions / Cloud Run
- Deploy as a Cloud Function
- Trigger via Cloud Scheduler
- Can email reports automatically

### Option 4: GitHub Actions
```yaml
name: Weekly Capacity Report
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM
jobs:
  generate-report:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
      - run: pip install -r requirements.txt
      - run: python generate_capacity_summary.py
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

## Customization

### Adjusting LLM Prompts
Edit the `_create_analysis_prompt()` method in `generate_capacity_summary.py` to:
- Change report structure
- Add specific analysis requirements
- Focus on different metrics

### Adding More Data Sources
Modify the `generate_report()` method to:
- Query additional views
- Include more metrics
- Add custom analysis

### Changing Output Format
Modify the `_format_report()` method to:
- Generate HTML instead of Markdown
- Create PDF reports
- Send directly to Slack/Email

## Troubleshooting

### "BigQuery authentication failed"
- Ensure `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
- Verify service account has BigQuery read permissions
- Try: `gcloud auth application-default login`

### "LLM API key not found"
- Set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` environment variable
- Or pass API key directly in code (not recommended for production)

### "View not found"
- Verify the dataset name is correct (`--dataset` flag)
- Check that views exist in BigQuery
- Ensure service account has access to the dataset

### "Query timeout"
- Large datasets may take time
- Consider adding date filters to queries
- Increase BigQuery timeout settings

## Cost Estimation

**BigQuery**: ~$0.001-0.01 per report (depends on data scanned)
**LLM API**: ~$0.01-0.05 per report (depends on provider and data size)
**Total**: ~$0.02-0.06 per report

For weekly reports: ~$1-3 per month

## Best Practices

1. **Run Weekly**: Generate reports every Monday morning for weekly team reviews
2. **Review Before Sharing**: Always review LLM output for accuracy
3. **Track Trends**: Save reports with timestamps to track changes over time
4. **Customize Prompts**: Adjust LLM prompts based on your team's needs
5. **Monitor Costs**: Track API usage to avoid unexpected charges

## Example Output

The generated report will look like:

```markdown
# Capacity Model Summary Report
Generated: 2025-01-15 09:00:00

---

## Executive Summary

Based on the current pipeline analysis, the firm is **moderately at risk** for Q1 2025...

[Detailed LLM-generated analysis continues...]

---

## Appendix: Raw Data Summary
[Tables with actual numbers]
```

## Next Steps

1. **Test the script** with your BigQuery setup
2. **Review the first report** and adjust prompts if needed
3. **Set up automation** for weekly reports
4. **Share with managers** and gather feedback
5. **Iterate** based on what insights are most valuable

## Support

For issues or questions:
- Check BigQuery view definitions in `Views/` directory
- Review the main capacity model documentation: `SGM_Capacity_Model_Dashboard.md`
- Verify your service account permissions in Google Cloud Console

