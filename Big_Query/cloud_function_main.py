"""
Google Cloud Function entry point for generating capacity reports
This can be called from Google Apps Script or directly via HTTP
"""

import json
import os
from datetime import datetime
from generate_capacity_summary import CapacityReportGenerator


def generate_capacity_report(request):
    """
    Cloud Function HTTP endpoint
    
    Expected request body (JSON):
    {
        "llm_provider": "gemini",
        "project_id": "savvy-gtm-analytics",
        "dataset": "savvy_analytics",
        "email": "recipient@example.com"  # Optional
    }
    """
    try:
        # Parse request
        if request.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Max-Age': '3600'
            }
            return ('', 204, headers)
        
        request_json = request.get_json(silent=True) or {}
        
        project_id = request_json.get('project_id', os.getenv('GOOGLE_CLOUD_PROJECT', 'savvy-gtm-analytics'))
        dataset = request_json.get('dataset', 'savvy_analytics')
        llm_provider = request_json.get('llm_provider', 'gemini')
        email = request_json.get('email')
        
        # Generate report
        generator = CapacityReportGenerator(
            project_id=project_id,
            dataset=dataset,
            llm_provider=llm_provider
        )
        
        # Generate report (in memory, no file)
        # Pass None to generate_report to return string without saving to file
        report = generator.generate_report(output_file=None)
        
        # Optional: Generate PDF via Gamma.app if requested
        pdf_url = None
        pdf_path = None
        if request_json.get('generate_pdf', False):
            try:
                from gamma_integration import GammaAppClient
                gamma_client = GammaAppClient()
                title = f"Capacity Summary Report - {datetime.now().strftime('%Y-%m-%d')}"
                pdf_result = gamma_client.create_pdf_from_markdown(report, title=title)
                if pdf_result:
                    pdf_url = pdf_result
            except Exception as e:
                # Don't fail the whole request if PDF generation fails
                print(f"Warning: Gamma.app PDF generation failed: {e}")
        
        # Return response
        response_data = {
            'success': True,
            'markdown': report,
            'filename': f"capacity_summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md",
            'timestamp': datetime.now().isoformat(),
            'pdf_url': pdf_url  # Gamma.app PDF URL if generated
        }
        
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        }
        
        return (json.dumps(response_data), 200, headers)
        
    except Exception as e:
        error_response = {
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }
        
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        }
        
        return (json.dumps(error_response), 500, headers)


# For local testing
if __name__ == "__main__":
    from flask import Flask, request as flask_request
    
    app = Flask(__name__)
    
    @app.route('/', methods=['POST', 'OPTIONS'])
    def handler():
        class Request:
            method = flask_request.method
            def get_json(self, silent=True):
                return flask_request.get_json(silent=silent)
        
        return generate_capacity_report(Request())
    
    app.run(port=8080, debug=True)

