"""
Test script for the PDF Analysis Server.

Copyright (C) 2025, Software Innovation Institute ANU

Licensed under the GNU General Public License, Version 3 (the "License");

License: https://opensource.org/license/gpl-3-0

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://opensource.org/license/gpl-3-0>.

Authors: Tony Chen
"""

import requests
import json
import sys


def test_health_check():
    """Test the health check endpoint."""
    print("\n=== Testing Health Check ===")
    try:
        response = requests.get("http://localhost:8000/health", timeout=5)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_text_analysis():
    """Test the text analysis endpoint."""
    print("\n=== Testing Text Analysis ===")
    
    # Sample pathology report text
    sample_text = """
    Example Pathology Laboratory
    123 Medical Street, Canberra ACT 2600
    
    Patient Report
    Collected: 15/01/2025 09:30
    Requested: 14/01/2025
    Received: 15/01/2025 10:15
    
    BIOCHEMISTRY
    
    Sodium          140      mmol/L    (135-145)
    Potassium       4.5   H  mmol/L    (3.5-5.0)
    Chloride        102      mmol/L    (95-105)
    Bicarbonate     25       mmol/L    (22-32)
    Urea            5.2      mmol/L    (2.5-7.0)
    Creatinine      85       µmol/L    (60-110)
    eGFR            >60      mL/min/1.73m²  (>60)
    
    Total Cholesterol  5.2      mmol/L    (<5.5)
    HDL Cholesterol    1.4      mmol/L    (>1.0)
    LDL Cholesterol    3.1      mmol/L    (<3.0)
    Triglycerides      1.5      mmol/L    (<2.0)
    """
    
    payload = {
        "text": sample_text,
        "report_name": "test_report.pdf"
    }
    
    try:
        response = requests.post(
            "http://localhost:8000/analyse/text",
            json=payload,
            timeout=60
        )
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Analysis successful!")
            print(f"Laboratory: {result.get('laboratory')}")
            print(f"Tests found: {len(result.get('tests', []))}")
            print("\nFirst few tests:")
            for test in result.get('tests', [])[:3]:
                print(f"  - {test.get('test_name')}: {test.get('result')} "
                      f"{test.get('units')}")
            
            print("\nFull response:")
            print(json.dumps(result, indent=2))
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_pdf_analysis(pdf_path=None):
    """Test the PDF analysis endpoint."""
    print("\n=== Testing PDF Analysis ===")
    
    if not pdf_path:
        print("⚠️  No PDF file provided, skipping PDF test")
        print("To test PDF analysis, run: python test_server.py "
              "/path/to/file.pdf")
        return True
    
    try:
        with open(pdf_path, 'rb') as f:
            files = {'file': (pdf_path, f, 'application/pdf')}
            response = requests.post(
                "http://localhost:8000/analyse/pdf",
                files=files,
                timeout=60
            )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("\n✅ Analysis successful!")
            print(f"Laboratory: {result.get('laboratory')}")
            print(f"Tests found: {len(result.get('tests', []))}")
            print("\nFull response:")
            print(json.dumps(result, indent=2))
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
            
    except FileNotFoundError:
        print(f"❌ Error: File not found: {pdf_path}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("PDF Analysis Server Test Suite")
    print("=" * 60)
    
    # Check if server is running
    try:
        requests.get("http://localhost:8000", timeout=2)
    except Exception:
        print("\n❌ Server is not running!")
        print("Please start the server first: python main.py")
        sys.exit(1)
    
    results = []
    
    # Run tests
    results.append(("Health Check", test_health_check()))
    results.append(("Text Analysis", test_text_analysis()))
    
    # Optional PDF test
    if len(sys.argv) > 1:
        pdf_path = sys.argv[1]
        results.append(("PDF Analysis", test_pdf_analysis(pdf_path)))
    else:
        test_pdf_analysis(None)
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{name}: {status}")
    
    print("\n")
    
    # Exit with appropriate code
    if all(r for _, r in results):
        print("✅ All tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
