/**
 * Google Apps Script for Looker Studio Integration
 * 
 * This script creates a web app that can be triggered from Looker Studio
 * to generate and email the capacity summary report.
 * 
 * Setup Instructions:
 * 1. Open Google Apps Script (script.google.com)
 * 2. Create a new project
 * 3. Paste this code
 * 4. Deploy as Web App (Execute as: Me, Access: Anyone with Google account)
 * 5. Copy the Web App URL
 * 6. In Looker Studio, add a Text/HTML element with a button that links to this URL
 */

// Configuration - Update these values
const CONFIG = {
  PROJECT_ID: 'savvy-gtm-analytics',
  DATASET: 'savvy_analytics',
  SCRIPT_URL: 'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec', // Update after deployment
  FROM_EMAIL: 'reports@yourcompany.com', // Update with your email
  FROM_NAME: 'Capacity Report Generator'
};

/**
 * Main function called when web app is accessed
 * Handles GET (form) and POST (API) requests
 */
function doGet(e) {
  return HtmlService.createHtmlOutputFromFile('Page')
    .setTitle('Capacity Report Generator')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * Handle POST requests (form submission)
 */
function doPost(e) {
  try {
    const email = e.parameter.email;
    const llmProvider = e.parameter.llm_provider || 'gemini';
    const generatePdf = e.parameter.generate_pdf === 'true' || e.parameter.generate_pdf === '1';
    
    if (!email) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: 'Email address is required'
      })).setMimeType(ContentService.MimeType.JSON);
    }
    
    // Generate the report
    const reportResult = generateReport(llmProvider, generatePdf);
    
    if (!reportResult.success) {
      return ContentService.createTextOutput(JSON.stringify(reportResult))
        .setMimeType(ContentService.MimeType.JSON);
    }
    
    // Send email (include PDF URL if generated)
    const emailResult = sendReportEmail(
      email, 
      reportResult.markdown, 
      reportResult.filename,
      reportResult.pdf_url
    );
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Report generated and sent successfully',
      email: email,
      filename: reportResult.filename,
      emailSent: emailResult.success,
      pdfUrl: reportResult.pdf_url || null
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Generate the capacity summary report
 * This calls a Cloud Function that runs the Python script
 */
function generateReport(llmProvider, generatePdf) {
  try {
    // Option 1: Call a Cloud Function that runs the Python script
    const cloudFunctionUrl = 'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/generate_capacity_report';
    
    const payload = {
      llm_provider: llmProvider,
      project_id: CONFIG.PROJECT_ID,
      dataset: CONFIG.DATASET,
      generate_pdf: generatePdf || false  // Request PDF generation if checkbox is checked
    };
    
    const options = {
      method: 'post',
      contentType: 'application/json',
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    };
    
    const response = UrlFetchApp.fetch(cloudFunctionUrl, options);
    const result = JSON.parse(response.getContentText());
    
    if (result.success) {
      return {
        success: true,
        markdown: result.markdown,
        filename: result.filename || `capacity_summary_${new Date().toISOString().split('T')[0]}.md`,
        pdf_url: result.pdf_url || null  // Gamma.app PDF URL if generated
      };
    } else {
      return {
        success: false,
        error: result.error || 'Failed to generate report'
      };
    }
    
  } catch (error) {
    // Fallback: Return error message
    return {
      success: false,
      error: `Error generating report: ${error.toString()}`
    };
  }
}

/**
 * Send the report via email
 */
function sendReportEmail(recipientEmail, markdownContent, filename, pdfUrl) {
  try {
    // Convert markdown to HTML for better email formatting
    const htmlContent = convertMarkdownToHtml(markdownContent);
    
    // Create email subject
    const subject = `Capacity Summary Report - ${new Date().toLocaleDateString()}`;
    
    // Add PDF link if available
    let pdfSection = '';
    if (pdfUrl) {
      pdfSection = `
        <div style="background: #e8f5e9; padding: 15px; border-radius: 4px; margin: 20px 0;">
          <h3 style="margin-top: 0; color: #2e7d32;">📄 PDF Version Available</h3>
          <p>A beautifully formatted PDF has been generated via Gamma.app:</p>
          <p><a href="${pdfUrl}" style="background: #1a73e8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">Download PDF Report</a></p>
        </div>
      `;
    }
    
    // Create email body
    const emailBody = `
      <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <h2>Capacity Summary Report</h2>
          <p>Please find attached the capacity summary report generated on ${new Date().toLocaleString()}.</p>
          ${pdfSection}
          <hr>
          ${htmlContent}
          <hr>
          <p style="color: #666; font-size: 12px;">
            This is an automated report. For questions, please contact the Revenue Operations team.
          </p>
        </body>
      </html>
    `;
    
    // Send email with attachment
    const blob = Utilities.newBlob(markdownContent, 'text/markdown', filename);
    
    MailApp.sendEmail({
      to: recipientEmail,
      subject: subject,
      htmlBody: emailBody,
      attachments: [blob],
      name: CONFIG.FROM_NAME
    });
    
    return { success: true };
    
  } catch (error) {
    return {
      success: false,
      error: error.toString()
    };
  }
}

/**
 * Simple markdown to HTML converter
 * For better results, consider using a library or Cloud Function
 */
function convertMarkdownToHtml(markdown) {
  let html = markdown;
  
  // Convert headers
  html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
  html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
  html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
  
  // Convert bold
  html = html.replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>');
  
  // Convert italic
  html = html.replace(/\*(.*?)\*/gim, '<em>$1</em>');
  
  // Convert lists
  html = html.replace(/^\- (.*$)/gim, '<li>$1</li>');
  html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');
  
  // Convert code blocks
  html = html.replace(/```([\s\S]*?)```/gim, '<pre><code>$1</code></pre>');
  
  // Convert inline code
  html = html.replace(/`([^`]+)`/gim, '<code>$1</code>');
  
  // Convert line breaks
  html = html.replace(/\n/g, '<br>');
  
  return html;
}

