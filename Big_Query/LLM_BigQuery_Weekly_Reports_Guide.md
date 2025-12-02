# LLM + BigQuery Weekly Automated Reports Guide

## Overview

This guide outlines multiple approaches to integrate Large Language Models (Claude, Gemini, etc.) with BigQuery to generate automated weekly reports answering questions like:
- "What SQOs moved the fastest last week?"
- "What SQOs seem like they may be at risk and need attention?"
- "What channels may be at risk of not reaching forecasted SQOs by the end of the quarter and at what stage in the funnel is it slowing down?"

---

## Approach Options

### Option 1: BigQuery MCP (Model Context Protocol) - **RECOMMENDED** ⭐

**Best for:** Direct integration with Claude/Gemini via Cursor, automated workflows

**How it works:**
- Uses BigQuery MCP server to connect LLMs directly to your BigQuery data
- LLM can query views, analyze data, and generate reports
- Can be automated via scheduled scripts or workflows

**Pros:**
- ✅ Native integration with Cursor/Claude
- ✅ No additional infrastructure needed
- ✅ Can query views directly
- ✅ Supports complex analytical queries
- ✅ Can use `mcp_bigquery_ask_data_insights` for natural language queries

**Cons:**
- ⚠️ Requires MCP server setup (if not already configured)
- ⚠️ Query costs scale with usage

**Setup:**
1. Configure BigQuery MCP server in Cursor
2. Use MCP tools to query views and generate reports
3. Create Python script to automate weekly runs

---

### Option 2: Vertex AI BigQuery Integration

**Best for:** Production-grade automation, scheduled reports

**How it works:**
- Uses Google Cloud Vertex AI (Gemini) with BigQuery integration
- Can create scheduled Cloud Functions or Cloud Run jobs
- Generates reports and sends via email/Slack

**Pros:**
- ✅ Native Google Cloud integration
- ✅ Built-in scheduling (Cloud Scheduler)
- ✅ Can send reports automatically
- ✅ Production-ready

**Cons:**
- ⚠️ Requires GCP setup and permissions
- ⚠️ More complex initial setup

---

### Option 3: Custom Python Script with LLM API

**Best for:** Full control, custom workflows

**How it works:**
- Python script queries BigQuery using `google-cloud-bigquery`
- Sends data + prompts to Claude/Gemini API
- Generates formatted reports (Markdown, HTML, PDF)

**Pros:**
- ✅ Full control over workflow
- ✅ Can integrate with any LLM provider
- ✅ Easy to customize output format
- ✅ Can add custom logic and filters

**Cons:**
- ⚠️ Requires maintaining Python code
- ⚠️ Need to manage API keys and costs

---

## Recommended Implementation: Option 1 (MCP) + Option 3 (Python Automation)

We'll combine MCP for interactive analysis with Python scripts for weekly automation.

---

## Implementation Plan

### Phase 1: Create Analysis Views for LLM Queries

First, let's create optimized views that make it easy for the LLM to answer common questions:

1. **SQO Velocity View** - Tracks how fast SQOs move through stages
2. **SQO Risk View** - Identifies SQOs that may be at risk
3. **Channel Forecast Risk View** - Shows channels at risk of missing forecasts

### Phase 2: Build Report Generation Script

Create a Python script that:
- Queries BigQuery views
- Uses LLM to analyze the data
- Generates formatted reports
- Can be scheduled weekly

### Phase 3: Set Up Automation

Configure weekly scheduling (Cloud Scheduler, cron, or GitHub Actions)

---

## Key BigQuery Views for LLM Analysis

Based on your existing setup, these views are most useful:

### For SQO Velocity Analysis:
- `vw_funnel_lead_to_joined_v2` - Base funnel data with stage dates
- `vw_production_forecast_v3_1` - Forecast vs actual comparisons

### For SQO Risk Analysis:
- `vw_actual_vs_forecast_by_source` - Actual vs forecast by channel/source
- Views with `days_since_last_modified` or similar staleness metrics

### For Channel Risk Analysis:
- `vw_production_forecast` - Forecast data with confidence intervals
- `vw_actual_vs_forecast_by_source` - Variance analysis

---

## Example Prompts for Weekly Reports

### Prompt 1: Fastest Moving SQOs
```
Analyze the data from vw_funnel_lead_to_joined_v2 for the last 7 days. 
Identify SQOs that moved through the funnel fastest (shortest time from SQL to SQO).
Report:
- Top 10 fastest SQOs with their velocity metrics
- Average velocity by channel/source
- Any patterns or anomalies
```

### Prompt 2: At-Risk SQOs
```
Using the funnel data, identify SQOs that may be at risk:
- SQLs that haven't converted to SQO in >30 days
- Opportunities with declining activity
- Channels with below-average conversion rates
Provide actionable recommendations.
```

### Prompt 3: Channel Forecast Risk
```
Analyze vw_production_forecast and vw_actual_vs_forecast_by_source for Q4 2025.
For each channel/source:
- Compare actual vs forecast SQOs (QTD)
- Identify channels at risk of missing quarterly targets
- Identify which funnel stage is the bottleneck (MQL→SQL, SQL→SQO)
- Calculate the gap and recommend actions
```

---

## Next Steps

1. **Create the analysis views** (Phase 1)
2. **Build the Python automation script** (Phase 2)
3. **Test with sample queries** (Phase 3)
4. **Set up weekly scheduling** (Phase 4)

Would you like me to:
1. Create the analysis views first?
2. Build the Python automation script?
3. Both?

Let me know which approach you prefer and I'll start implementing!

