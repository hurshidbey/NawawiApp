#!/usr/bin/env python3
"""
Script to verify and potentially improve hadith content from the PDF source.
This script will help compare the PDF content with the existing JSON data.
"""

import json
import sys
import os

def load_existing_hadiths():
    """Load the existing hadiths.json file"""
    json_path = "./Nawawi/Resources/hadiths.json"
    if not os.path.exists(json_path):
        print(f"Error: Could not find {json_path}")
        return None

    with open(json_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def verify_hadith_structure(hadiths):
    """Verify the structure and completeness of hadith data"""
    issues = []

    for i, hadith in enumerate(hadiths):
        hadith_num = hadith.get('number', i+1)

        # Check required fields
        required_fields = ['number', 'arabicText', 'englishTranslation', 'narrator']
        for field in required_fields:
            if field not in hadith or not hadith[field]:
                issues.append(f"Hadith {hadith_num}: Missing or empty {field}")

        # Check if Arabic text looks reasonable (should contain Arabic characters)
        arabic_text = hadith.get('arabicText', '')
        if arabic_text and not any('\u0600' <= char <= '\u06FF' for char in arabic_text):
            issues.append(f"Hadith {hadith_num}: Arabic text appears to not contain Arabic characters")

        # Check for reasonable text lengths
        if len(hadith.get('arabicText', '')) < 10:
            issues.append(f"Hadith {hadith_num}: Arabic text seems too short")

        if len(hadith.get('englishTranslation', '')) < 10:
            issues.append(f"Hadith {hadith_num}: English translation seems too short")

    return issues

def main():
    print("Loading existing hadith data...")
    hadiths = load_existing_hadiths()

    if hadiths is None:
        return 1

    print(f"Found {len(hadiths)} hadiths in the JSON file")

    # Verify structure
    print("\nVerifying hadith structure...")
    issues = verify_hadith_structure(hadiths)

    if issues:
        print("Issues found:")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("✓ All hadiths appear to have proper structure and content")

    # Check for standard 40 + 2 additional hadiths
    if len(hadiths) == 42:
        print("✓ Found expected 42 hadiths (40 main + 2 additional)")
    elif len(hadiths) == 40:
        print("Found 40 hadiths (missing 2 commonly appended hadiths)")
    else:
        print(f"⚠ Unexpected number of hadiths: {len(hadiths)} (expected 40 or 42)")

    # Check hadith numbering
    numbers = [h.get('number', 0) for h in hadiths]
    expected_numbers = list(range(1, len(hadiths) + 1))
    if numbers != expected_numbers:
        print("⚠ Hadith numbering issues detected")
        missing = set(expected_numbers) - set(numbers)
        duplicates = set(numbers) - set(expected_numbers)
        if missing:
            print(f"  Missing numbers: {sorted(missing)}")
        if duplicates:
            print(f"  Unexpected numbers: {sorted(duplicates)}")
    else:
        print("✓ Hadith numbering is sequential and correct")

    return 0 if not issues else 1

if __name__ == "__main__":
    sys.exit(main())