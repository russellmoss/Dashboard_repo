# Quick Start: Looker Studio → Report → Email Automation

## Overview

This automation allows you to:
1. Click a button in Looker Studio
2. Generate a capacity summary report
3. Automatically email it to specified recipients
4. Optionally upload to Gamma.app for presentation

## Quick Setup (3 Steps)

### Step 1: Deploy Cloud Function

```bash
# Install dependencies
pip install -r requirements.txt

# Deploy to Google Cloud Functions
gcloud functions deploy generate_capacity_report \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point generate_capacity_report \
  --source . \
  --set-env-vars GEMINI_API_KEY=your_key_here,GOOGLE_CLOUD_PROJECT=savvy-gtm-analytics \
  --timeout 540s \
  --memory 2GB
```

**Copy the Function URL** (e.g., `https://us-central1-savvy-gtm-analytics.cloudfunctions.net/generate_capacity_report`)

### Step 2: Set Up Google Apps Script

1. Go to [script.google.com](https://script.google.com)
2. Create new project
3. Copy `looker_studio_trigger.gs` → paste as `Code.gs`
4. Create HTML file named `Page` → copy content from `Page.html`
5. **Update these in Code.gs:**
   - Line 10: `cloudFunctionUrl` → Your Cloud Function URL from Step 1
   - Line 6-9: Update `CONFIG` with your project details
6. Deploy → New deployment → Web app
   - Execute as: Me
   - Access: Anyone with Google account
7. **Copy the Web App URL**

### Step 3: Add to Looker Studio

**Option A: Embedded Form (Recommended)**

1. In Looker Studio, add a **Text/HTML** element
2. Paste this HTML (replace `YOUR_WEB_APP_URL`):

```html
<iframe 
  src="YOUR_WEB_APP_URL" 
  width="100%" 
  height="450px" 
  frameborder="0"
  style="border-radius: 8px;">
</iframe>
```

**Option B: Button Link**

1. Add a **Text** element
2. Use this HTML:

```html
<a href="YOUR_WEB_APP_URL" target="_blank">
  <button style="
    background: #1a73e8; 
    color: white; 
    padding: 12px 24px; 
    border: none; 
    border-radius: 4px; 
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;">
    📊 Generate Capacity Report
  </button>
</a>
```

## Testing

1. Open your Looker Studio dashboard
2. Click the button or open the form
3. Enter your email address
4. Click "Generate & Send Report"
5. Check your email inbox!

## Optional: Gamma.app Integration

If you want to upload to Gamma.app:

1. Get Gamma.app API key (or set up webhook)
2. Set environment variable: `GAMMA_APP_API_KEY`
3. Update `gamma_integration.py` with correct API endpoints
4. Reports will automatically upload to Gamma.app

## Troubleshooting

**"Function not found" error:**
- Check Cloud Function URL is correct
- Verify function is deployed and public

**"Email not sent" error:**
- Check Apps Script execution transcript
- Verify Gmail permissions are granted

**"Report generation failed":**
- Check Cloud Function logs: `gcloud functions logs read generate_capacity_report`
- Verify BigQuery permissions
- Check LLM API keys are set

## Advanced: Direct Email from Python Script

You can also run the script directly with email:

```bash
python generate_capacity_summary.py \
  --email recipient@company.com \
  --smtp-server smtp.gmail.com \
  --smtp-port 587 \
  --smtp-user your-email@gmail.com \
  --smtp-password your-app-password
```

## Security Notes

- Never commit API keys to version control
- Use Google Cloud Secret Manager for production
- Limit Apps Script access to authorized users
- Consider adding rate limiting

For detailed setup instructions, see `SETUP_INSTRUCTIONS.md`.
