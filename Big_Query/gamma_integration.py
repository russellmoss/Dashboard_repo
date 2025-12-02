"""
Gamma.app Integration Module
Handles converting markdown reports to Gamma.app presentations/PDFs

Gamma.app API Documentation: https://developers.gamma.app
Requires: Pro, Ultra, Teams, or Business subscription
"""

import os
import requests
import json
from typing import Optional, Dict, Tuple
from datetime import datetime


class GammaAppClient:
    """Client for interacting with Gamma.app Generate API"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("GAMMA_APP_API_KEY")
        self.base_url = "https://public-api.gamma.app/v1.0"
        
    def generate_pdf_from_text(self, text_content: str, title: str = "Capacity Summary Report", 
                               output_format: str = "pdf") -> Tuple[Optional[str], Optional[str]]:
        """
        Generate a PDF/presentation from text using Gamma.app's Generate API
        
        Args:
            text_content: The markdown/text content to convert
            title: Title for the document
            output_format: "pdf" or "presentation" (default: "pdf")
        
        Returns:
            Tuple of (document_url, pdf_url) if successful, (None, None) otherwise
        """
        if not self.api_key:
            print("Warning: Gamma.app API key not found. Skipping Gamma.app PDF generation.")
            print("Set GAMMA_APP_API_KEY environment variable or pass api_key parameter.")
            print("Note: Gamma.app API requires Pro/Ultra/Teams/Business subscription.")
            return None, None
        
        try:
            # Gamma.app Generate API endpoint
            url = f"{self.base_url}/generate"
            
            headers = {
                "X-API-KEY": self.api_key,
                "Content-Type": "application/json"
            }
            
            # Prepare the input text with title
            # Gamma.app works best with structured text, so we format it nicely
            formatted_text = f"{title}\n\n{text_content}"
            
            payload = {
                "inputText": formatted_text,
                "outputFormat": output_format,
                "title": title
            }
            
            print(f"Calling Gamma.app API to generate {output_format}...")
            response = requests.post(
                url,
                headers=headers,
                json=payload,
                timeout=120  # Longer timeout for PDF generation
            )
            
            if response.status_code == 200:
                result = response.json()
                
                # Gamma.app returns different fields depending on output format
                document_url = result.get("url") or result.get("documentUrl") or result.get("presentationUrl")
                pdf_url = result.get("pdfUrl") or result.get("downloadUrl")
                
                if document_url:
                    print(f"✅ Gamma.app {output_format} created successfully!")
                    print(f"   Document URL: {document_url}")
                    if pdf_url:
                        print(f"   PDF URL: {pdf_url}")
                    return document_url, pdf_url
                else:
                    print(f"Warning: Gamma.app response missing URL: {result}")
                    return None, None
            else:
                error_msg = response.text
                print(f"❌ Error creating Gamma.app {output_format}: {response.status_code}")
                print(f"   Response: {error_msg}")
                
                # Provide helpful error messages
                if response.status_code == 401:
                    print("   → Check that your API key is correct")
                elif response.status_code == 403:
                    print("   → Your subscription may not include API access (requires Pro/Ultra/Teams/Business)")
                elif response.status_code == 429:
                    print("   → Rate limit exceeded. Wait a moment and try again.")
                elif response.status_code == 402:
                    print("   → Insufficient credits. Check your Gamma.app account balance.")
                
                return None, None
                
        except requests.exceptions.Timeout:
            print("❌ Timeout connecting to Gamma.app API. The request took too long.")
            return None, None
        except requests.exceptions.RequestException as e:
            print(f"❌ Error connecting to Gamma.app API: {e}")
            return None, None
        except Exception as e:
            print(f"❌ Unexpected error with Gamma.app: {e}")
            import traceback
            traceback.print_exc()
            return None, None
    
    def download_pdf(self, pdf_url: str, output_path: str) -> bool:
        """
        Download PDF from Gamma.app URL
        
        Args:
            pdf_url: URL to the PDF
            output_path: Local path to save the PDF
        
        Returns:
            True if successful, False otherwise
        """
        try:
            print(f"Downloading PDF from Gamma.app...")
            response = requests.get(pdf_url, timeout=60)
            
            if response.status_code == 200:
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                print(f"✅ PDF downloaded successfully to: {output_path}")
                return True
            else:
                print(f"❌ Error downloading PDF: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Error downloading PDF: {e}")
            return False
    
    def create_presentation_from_markdown(self, markdown_content: str, title: str = "Capacity Summary Report") -> Optional[str]:
        """
        Create a Gamma.app presentation from markdown content (alias for generate_pdf_from_text)
        
        Returns the presentation URL if successful, None otherwise
        """
        # Convert markdown to plain text for Gamma.app (it handles formatting automatically)
        # Remove markdown syntax that might confuse Gamma.app
        text_content = self._clean_markdown_for_gamma(markdown_content)
        
        document_url, pdf_url = self.generate_pdf_from_text(text_content, title, output_format="presentation")
        return document_url
    
    def create_pdf_from_markdown(self, markdown_content: str, title: str = "Capacity Summary Report", 
                                 save_path: Optional[str] = None) -> Optional[str]:
        """
        Create a PDF from markdown content using Gamma.app
        
        Args:
            markdown_content: The markdown report content
            title: Title for the PDF
            save_path: Optional local path to save the PDF (if None, only returns URL)
        
        Returns:
            Path to saved PDF if save_path provided, or PDF URL otherwise
        """
        # Convert markdown to plain text for Gamma.app
        text_content = self._clean_markdown_for_gamma(markdown_content)
        
        document_url, pdf_url = self.generate_pdf_from_text(text_content, title, output_format="pdf")
        
        if pdf_url and save_path:
            # Download the PDF
            if self.download_pdf(pdf_url, save_path):
                return save_path
            else:
                return pdf_url  # Return URL if download failed
        elif pdf_url:
            return pdf_url
        elif document_url:
            # If only document URL is available, return that
            return document_url
        else:
            return None
    
    def _clean_markdown_for_gamma(self, markdown_content: str) -> str:
        """
        Clean markdown content for Gamma.app processing
        Gamma.app can handle some markdown, but we simplify it for better results
        """
        text = markdown_content
        
        # Keep structure but simplify formatting
        # Remove code blocks (Gamma.app doesn't need them)
        import re
        text = re.sub(r'```[\s\S]*?```', '', text)
        
        # Convert headers to plain text with emphasis
        text = re.sub(r'^### (.*)$', r'\1', text, flags=re.MULTILINE)
        text = re.sub(r'^## (.*)$', r'\n\1\n', text, flags=re.MULTILINE)
        text = re.sub(r'^# (.*)$', r'\n\1\n', text, flags=re.MULTILINE)
        
        # Keep bold/italic as-is (Gamma.app may handle these)
        # Remove inline code
        text = re.sub(r'`([^`]+)`', r'\1', text)
        
        # Clean up excessive whitespace
        text = re.sub(r'\n{3,}', '\n\n', text)
        
        return text.strip()
    
    def create_presentation_via_webhook(self, markdown_content: str, title: str = "Capacity Summary Report", 
                                        webhook_url: Optional[str] = None) -> Optional[str]:
        """
        Alternative: Use a webhook or automation service (like Zapier/Make.com) to create presentation
        This is a fallback if direct API doesn't work
        """
        webhook_url = webhook_url or os.getenv("GAMMA_WEBHOOK_URL")
        
        if not webhook_url:
            print("Warning: Gamma webhook URL not found. Skipping Gamma.app upload.")
            return None
        
        try:
            payload = {
                "title": title,
                "content": markdown_content,
                "timestamp": datetime.now().isoformat()
            }
            
            response = requests.post(webhook_url, json=payload, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                return result.get("url") or result.get("presentation_url")
            else:
                print(f"Error calling Gamma webhook: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            print(f"Error with Gamma webhook: {e}")
            return None

