#!/usr/bin/env python3
"""
Script to extract all hadith content from the PDF and compare with JSON.
This will help identify any differences or improvements needed.
"""

import json
import re
import pdfplumber

def extract_all_pdf_content(pdf_path):
    """Extract all text from the PDF"""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            full_text = ""
            print(f"PDF has {len(pdf.pages)} pages")

            for page_num in range(len(pdf.pages)):
                page = pdf.pages[page_num]
                page_text = page.extract_text()
                if page_text:
                    full_text += f"\n--- Page {page_num + 1} ---\n"
                    full_text += page_text + "\n"

                    # Look for hadith markers
                    if "Hadith" in page_text and ("إِنَّمَا" in page_text or "Arabic" in page_text):
                        print(f"Found hadith content on page {page_num + 1}")

            return full_text
    except Exception as e:
        return f"Error extracting PDF: {str(e)}"

def find_hadith_sections(text):
    """Find individual hadith sections in the text"""
    # Look for patterns that indicate hadith beginnings
    hadith_patterns = [
        r"Hadith\s+(\d+)",
        r"(\d+)\.\s+",
        r"رضي الله عنه",
        r"صلى الله عليه وسلم"
    ]

    sections = []
    lines = text.split('\n')
    current_section = []
    in_hadith = False

    for line in lines:
        if any(re.search(pattern, line) for pattern in hadith_patterns):
            if current_section:
                sections.append('\n'.join(current_section))
            current_section = [line]
            in_hadith = True
        elif in_hadith:
            current_section.append(line)

    if current_section:
        sections.append('\n'.join(current_section))

    return sections

def load_existing_hadiths():
    """Load the existing hadiths.json file"""
    try:
        with open("./Nawawi/Resources/hadiths.json", 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading JSON: {str(e)}")
        return []

def main():
    pdf_path = "./Imam-Nawawis-40-Hadith-Text.pdf"

    print("Extracting all content from PDF...")
    pdf_text = extract_all_pdf_content(pdf_path)

    # Save the full text for analysis
    with open("./pdf_full_text.txt", 'w', encoding='utf-8') as f:
        f.write(pdf_text)
    print("Full PDF text saved to pdf_full_text.txt")

    print("Finding hadith sections...")
    hadith_sections = find_hadith_sections(pdf_text)
    print(f"Found {len(hadith_sections)} potential hadith sections")

    # Save hadith sections for analysis
    with open("./pdf_hadith_sections.txt", 'w', encoding='utf-8') as f:
        for i, section in enumerate(hadith_sections[:10]):  # First 10 sections
            f.write(f"\n--- Section {i+1} ---\n")
            f.write(section)
            f.write("\n\n")
    print("Hadith sections saved to pdf_hadith_sections.txt")

    # Compare with existing JSON
    print("Loading existing JSON data...")
    json_hadiths = load_existing_hadiths()
    print(f"JSON contains {len(json_hadiths)} hadiths")

    # Basic comparison
    print(f"\nComparison:")
    print(f"PDF sections found: {len(hadith_sections)}")
    print(f"JSON hadiths: {len(json_hadiths)}")

    if len(hadith_sections) > 0:
        print("\nFirst PDF section preview:")
        print(hadith_sections[0][:300] + "..." if len(hadith_sections[0]) > 300 else hadith_sections[0])

if __name__ == "__main__":
    main()