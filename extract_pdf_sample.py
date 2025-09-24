#!/usr/bin/env python3
"""
Script to extract and compare a small sample from the PDF with existing data.
This will help us validate if the PDF contains different or improved content.
"""

try:
    import PyPDF2
    print("PyPDF2 found")
except ImportError:
    print("PyPDF2 not found, trying pdfplumber...")
    try:
        import pdfplumber
        print("pdfplumber found")
    except ImportError:
        print("Neither PyPDF2 nor pdfplumber found. Please install one:")
        print("pip install PyPDF2")
        print("or")
        print("pip install pdfplumber")
        exit(1)

import json
import re

def extract_first_hadith_from_pdf(pdf_path):
    """Extract the first hadith from the PDF to compare with JSON"""
    try:
        # Try pdfplumber first as it's generally better for text extraction
        try:
            import pdfplumber
            with pdfplumber.open(pdf_path) as pdf:
                text = ""
                # Extract text from more pages to find actual hadith content
                for page_num in range(min(10, len(pdf.pages))):
                    page = pdf.pages[page_num]
                    page_text = page.extract_text()
                    if page_text:
                        text += f"\n--- Page {page_num + 1} ---\n"
                        text += page_text + "\n"

                        # Look for the first hadith pattern
                        if "إِنَّمَا الْأَعْمَالُ" in page_text or "Actions are judged" in page_text:
                            print(f"Found first hadith content on page {page_num + 1}")
                            break

                return text
        except ImportError:
            pass

        # Fallback to PyPDF2
        import PyPDF2
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            text = ""
            # Extract text from first few pages
            for page_num in range(min(3, len(pdf_reader.pages))):
                page = pdf_reader.pages[page_num]
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
            return text[:2000]  # Return first 2000 characters

    except Exception as e:
        return f"Error extracting PDF: {str(e)}"

def load_existing_first_hadith():
    """Load the first hadith from the JSON file"""
    try:
        with open("./Nawawi/Resources/hadiths.json", 'r', encoding='utf-8') as f:
            hadiths = json.load(f)
            return hadiths[0] if hadiths else None
    except Exception as e:
        return f"Error loading JSON: {str(e)}"

def main():
    pdf_path = "./Imam-Nawawis-40-Hadith-Text.pdf"

    print("Attempting to extract sample text from PDF...")
    pdf_text = extract_first_hadith_from_pdf(pdf_path)

    print("PDF Text Sample:")
    print("=" * 50)
    print(pdf_text)
    print("=" * 50)

    print("\nExisting JSON First Hadith:")
    json_hadith = load_existing_first_hadith()
    if isinstance(json_hadith, dict):
        print(f"Number: {json_hadith.get('number')}")
        print(f"Arabic: {json_hadith.get('arabicText', '')[:100]}...")
        print(f"English: {json_hadith.get('englishTranslation', '')[:100]}...")
        print(f"Narrator: {json_hadith.get('narrator')}")
    else:
        print(json_hadith)

if __name__ == "__main__":
    main()