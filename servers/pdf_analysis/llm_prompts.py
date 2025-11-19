"""
LLM Prompt Templates for Pathology Report Analysis.

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

PATHOLOGY_ANALYSIS_PROMPT = """
Given the text from a pathology report, the following information will be 
extracted:

1. Report metadata:
   - Laboratory name
   - Requested date (format: YYYY-MM-DD)
   - Collection time (format: YYYY-MM-DDTHH:MM:SS)
   - Received time (format: YYYY-MM-DDTHH:MM:SS)

2. Test results:
   For each test, extract:
   - test_name: The name of the test
   - result: The numerical or textual result
   - units: The unit of measurement (e.g., mmol/L, g/L)
   - reference_interval: The normal reference range
   - comment: Any flags like "H" (high), "L" (low), or other notes

Return the results in the following JSON format:
{{
  "laboratory": "Laboratory name here",
  "requested_date": "YYYY-MM-DD",
  "collected_time": "YYYY-MM-DDTHH:MM:SS",
  "received_time": "YYYY-MM-DDTHH:MM:SS",
  "tests": [
    {{
      "test_name": "Test name",
      "result": "Result value",
      "units": "Unit of measurement",
      "reference_interval": "Normal range",
      "comment": "H/L or other notes"
    }}
  ]
}}

Important guidelines:
- Only extract actual test results, ignore headers, footers, and addresses
- If a value is not found, use an empty string ""
- Keep test names as they appear in the report
- Preserve any "H" or "L" flags in the comment field
- For reference intervals, keep the exact format from the report (e.g., 
"135-145", ">60", "<5.5")
- If a date/time is not in ISO format, convert it to ISO format

Here is the pathology report text to analyse:

{report_text}

Return ONLY the JSON object, with no additional text or explanation.
"""


def create_analysis_prompt(report_text: str) -> str:
    """
    Create the analysis prompt with the report text.
    
    Args:
        report_text: The extracted text from the pathology report
        
    Returns:
        The formatted prompt ready to send to the LLM
    """
    return PATHOLOGY_ANALYSIS_PROMPT.format(report_text=report_text)
