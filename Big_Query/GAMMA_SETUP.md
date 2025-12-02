# Gamma.app PDF Generation Setup

## Overview

The script now supports generating beautiful PDFs from your markdown reports using Gamma.app's Generate API. This creates a professionally formatted PDF that preserves all your text content.

## How It Works

1. **Generate Markdown Report** - `generate_capacity_summary.py` creates the full markdown report
2. **Send to Gamma.app** - The markdown text is sent to Gamma.app's Generate API
3. **Gamma.app Creates PDF** - Gamma.app formats the text into a beautiful PDF/presentation
4. **Download/Share PDF** - You get a PDF URL that can be downloaded or shared

## Setup Requirements

### 1. Gamma.app Subscription

Gamma.app API requires one of these subscription levels:
- **Pro** ($10/month)
- **Ultra** ($20/month)
- **Teams** (custom pricing)
- **Business** (custom pricing)

Free accounts do **not** have API access.

### 2. Get Your API Key

1. Sign up/login to [Gamma.app](https://gamma.app)
2. Go to Account Settings → API
3. Click "Create API Key"
4. Copy the API key (starts with `gamma_` or similar)

### 3. Set Environment Variable

```bash
# On your local machine
export GAMMA_APP_API_KEY=your_api_key_here

# Or in Google Cloud Function
gcloud functions deploy generate_capacity_report \
  --set-env-vars GAMMA_APP_API_KEY=your_api_key_here
```

### 4. Test the Integration

```bash
# Generate report with PDF
python generate_capacity_summary.py --gamma --output report.md

# This will:
# 1. Generate markdown report → report.md
# 2. Send to Gamma.app → Generate PDF
# 3. Download PDF → report.pdf
```

## Usage

### Command Line

```bash
# Generate markdown + PDF
python generate_capacity_summary.py --gamma

# Generate markdown + PDF + Email
python generate_capacity_summary.py --gamma --email user@company.com
```

### From Looker Studio

1. User clicks button in Looker Studio
2. Checks "Generate PDF via Gamma.app" checkbox
3. Enters email address
4. Clicks "Generate & Send Report"
5. Receives email with:
   - Markdown attachment
   - **PDF download link** (if Gamma.app succeeded)

## What Gamma.app Does

Gamma.app's Generate API:
- Takes your markdown/text content
- Automatically formats it into a beautiful presentation/PDF
- Preserves all text content
- Applies professional styling
- Creates shareable PDF

**The PDF will contain:**
- All sections from your markdown report
- Properly formatted tables
- Headers and subheaders
- Bullet points and lists
- All text content preserved

## API Costs

Gamma.app uses a credit-based system:
- Each PDF generation consumes credits
- Check your Gamma.app dashboard for credit balance
- Credits are included with subscription, additional credits can be purchased

## Troubleshooting

### "API key not found"
- Set `GAMMA_APP_API_KEY` environment variable
- Or pass `api_key` parameter to `GammaAppClient()`

### "401 Unauthorized"
- Check API key is correct
- Verify key hasn't expired

### "403 Forbidden"
- Your subscription doesn't include API access
- Upgrade to Pro/Ultra/Teams/Business

### "402 Payment Required"
- Insufficient credits in your account
- Purchase more credits or wait for monthly reset

### "429 Rate Limit"
- Too many requests too quickly
- Wait a few minutes and try again

### PDF URL but can't download
- PDF URLs from Gamma.app may expire
- Download immediately after generation
- Or use the document URL to view online

## Alternative: Without Gamma.app

If you don't have Gamma.app subscription, you can:

1. **Use markdown-to-PDF tools:**
   ```bash
   # Install pandoc
   pip install pypandoc
   
   # Convert markdown to PDF
   pandoc report.md -o report.pdf
   ```

2. **Use other services:**
   - Marked (markdown to PDF)
   - WeasyPrint (HTML/CSS to PDF)
   - wkhtmltopdf

3. **Manual process:**
   - Generate markdown report
   - Copy to Gamma.app web interface
   - Manually create presentation

## Example Output

When you run with `--gamma`:

```
Report generated successfully!
================================================================================
Generating PDF via Gamma.app...
================================================================================
Calling Gamma.app API to generate pdf...
✅ Gamma.app PDF generated and saved: capacity_summary_report_20241215_143022.pdf
```

The PDF will be a beautifully formatted version of your markdown report, ready to share with stakeholders!

