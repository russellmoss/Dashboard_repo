# Capacity Report Automation Setup Guide

This guide explains how to set up the complete automation flow: Generate Report → Gamma.app → Email, triggered from Looker Studio.

## Architecture Overview

```
Looker Studio (Button) 
    ↓
Google Apps Script (Web App)
    ↓
Google Cloud Function (Python Script)
    ↓
BigQuery → LLM Analysis → Markdown Report
    ↓
Email (Gmail API) + Optional: Gamma.app
```

## Setup Steps

### 1. Deploy Google Cloud Function

1. **Create Cloud Function:**
   ```bash
   gcloud functions deploy generate_capacity_report \
     --runtime python311 \
     --trigger-http \
     --allow-unauthenticated \
     --entry-point generate_capacity_report \
     --source . \
     --set-env-vars GOOGLE_CLOUD_PROJECT=savvy-gtm-analytics
   ```

2. **Set Environment Variables:**
   - `GEMINI_API_KEY` (or `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`)
   - `GOOGLE_CLOUD_PROJECT=savvy-gtm-analytics`

3. **Note the Function URL:**
   - Copy the trigger URL (e.g., `https://us-central1-savvy-gtm-analytics.cloudfunctions.net/generate_capacity_report`)

### 2. Set Up Google Apps Script

1. **Open Google Apps Script:**
   - Go to [script.google.com](https://script.google.com)
   - Create a new project

2. **Add Files:**
   - Copy `looker_studio_trigger.gs` → `Code.gs`
   - Create new HTML file: `Page` → Copy content from `Page.html`

3. **Update Configuration:**
   - In `Code.gs`, update `CONFIG` object:
     - `PROJECT_ID`: Your BigQuery project ID
     - `DATASET`: Your dataset name
     - `FROM_EMAIL`: Your sender email
   - Update `cloudFunctionUrl` with your Cloud Function URL

4. **Deploy as Web App:**
   - Click "Deploy" → "New deployment"
   - Type: Web app
   - Execute as: Me
   - Who has access: Anyone with Google account (or specific users)
   - Click "Deploy"
   - Copy the Web App URL

### 3. Add to Looker Studio

**Option A: Embedded HTML (Recommended)**

1. In Looker Studio, add a **Text/HTML** element
2. Use this HTML:
   ```html
   <iframe 
     src="YOUR_APPS_SCRIPT_WEB_APP_URL" 
     width="100%" 
     height="400px" 
     frameborder="0">
   </iframe>
   ```

**Option B: Button Link**

1. Add a **Text** element
2. Create a button:
   ```html
   <a href="YOUR_APPS_SCRIPT_WEB_APP_URL" target="_blank">
     <button style="background: #1a73e8; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer;">
       Generate Capacity Report
     </button>
   </a>
   ```

**Option C: Community Visualization (Advanced)**

1. Create a custom visualization that calls the Apps Script URL
2. Requires JavaScript development

### 4. Optional: Gamma.app Integration

**If Gamma.app has an API:**

1. Get your Gamma.app API key
2. Set environment variable: `GAMMA_APP_API_KEY`
3. Update `gamma_integration.py` with correct API endpoints
4. Use `--gamma` flag when generating reports

**If Gamma.app doesn't have an API:**

1. Use a webhook service (Zapier, Make.com, n8n)
2. Set up webhook to create Gamma presentation from markdown
3. Update `GAMMA_WEBHOOK_URL` environment variable

### 5. Email Configuration

**For SMTP (Gmail):**

1. Enable "Less secure app access" or use App Password
2. Set environment variables:
   ```bash
   export SMTP_SERVER=smtp.gmail.com
   export SMTP_PORT=587
   export SMTP_USER=your-email@gmail.com
   export SMTP_PASSWORD=your-app-password
   ```

**For Gmail API (Recommended):**

1. Enable Gmail API in Google Cloud Console
2. Create OAuth 2.0 credentials
3. Update Apps Script to use Gmail API instead of SMTP

### 6. Testing

1. **Test Cloud Function:**
   ```bash
   curl -X POST https://YOUR_FUNCTION_URL \
     -H "Content-Type: application/json" \
     -d '{"llm_provider": "gemini", "email": "test@example.com"}'
   ```

2. **Test Apps Script:**
   - Open the Web App URL in a browser
   - Enter an email address
   - Click "Generate & Send Report"
   - Check email inbox

3. **Test from Looker Studio:**
   - Open your Looker Studio dashboard
   - Click the button/link
   - Verify report is generated and emailed

## Troubleshooting

### Cloud Function Errors

- **Check logs:** `gcloud functions logs read generate_capacity_report`
- **Verify permissions:** Function needs BigQuery access
- **Check API keys:** LLM provider API keys must be set

### Apps Script Errors

- **Check execution transcript:** View → Execution transcript
- **Verify Cloud Function URL:** Must be correct and accessible
- **Check email permissions:** Apps Script needs Gmail send permission

### Looker Studio Issues

- **Iframe blocked:** Use Option B (button link) instead
- **CORS errors:** Ensure Cloud Function allows CORS
- **Authentication:** May need to sign in to Google account

## Security Considerations

1. **API Keys:** Never commit API keys to version control
2. **Access Control:** Limit who can access the Apps Script web app
3. **Email Validation:** Validate email addresses before sending
4. **Rate Limiting:** Consider adding rate limiting to prevent abuse
5. **Audit Logging:** Log all report generations for compliance

## Alternative: Direct Looker Studio Integration

If you want to skip Apps Script, you can:

1. Create a Looker Studio Community Visualization
2. Have it call the Cloud Function directly
3. Handle email sending in the Cloud Function

This requires more JavaScript development but removes the Apps Script layer.

## Cost Considerations

- **Cloud Function:** ~$0.40 per million invocations
- **BigQuery:** Pay per query (varies by data size)
- **LLM API:** Varies by provider (Gemini is free tier, OpenAI/Anthropic are paid)
- **Apps Script:** Free (within quotas)
- **Gmail API:** Free (within quotas)

## Next Steps

1. Deploy Cloud Function
2. Set up Apps Script
3. Add to Looker Studio
4. Test end-to-end
5. Share with team!

For questions or issues, check the logs and error messages for specific guidance.

