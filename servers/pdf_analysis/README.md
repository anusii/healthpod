# Pathology Report Analysis Server

A comprehensive FastAPI-based server that handles complete pathology report 
analysis using locally-deployed Ollama with Qwen3:8b.

## Overview

This server provides complete PDF analysis workflow, including PDF processing, 
OCR, LLM analysis, and unit validation.

### Architecture

```
┌─────────────────────────────────┐
│       Flutter Client            │
│                                 │
│  • File selection/upload        │
│  • UI/UX handling               │
│  • Display results              │
└────────────┬────────────────────┘
             │ HTTP POST /analyse/pdf
             │ (sends PDF file)
             ↓
┌─────────────────────────────────┐
│      Python Analysis Server     │
│                                 │
│  1. PDF Text Extraction         │
│     • PyMuPDF (primary)         │
│     • pdfplumber (fallback)     │
│     • PyPDF2 (fallback)         │
│                                 │
│  2. OCR Fallback (if needed)    │
│     • Convert to high-res images│
│     • Tesseract OCR (primary)   │
│     • EasyOCR (fallback)        │
│                                 │
│  3. LLM Analysis                │
│     • Ollama + Qwen3:8b         │
│     • Structured data extraction│
│                                 │
│  4. Unit Validation             │
│     • Normalise units           │
│     • Validate test-unit pairs  │
│                                 │
│  • Returns structured JSON      │
└─────────────────────────────────┘
```

**Server Responsibilities**:
- ✅ Accept PDF file uploads via REST API
- ✅ Extract text from PDF (multiple methods)
- ✅ Perform OCR if text extraction fails
- ✅ Analyse text with LLM
- ✅ Validate and normalise measurement units
- ✅ Return structured JSON results

**Client Responsibilities**:
- ✅ Select and upload PDF files
- ✅ Display results and handle UI/UX

This design provides:
- ✅ Complete server-side processing
- ✅ Consistent PDF handling across platforms
- ✅ Better accuracy with multiple extraction methods
- ✅ Unit validation for data quality
- ✅ Simplified client implementation

## Prerequisites

### Server Requirements

The Python analysis server requires:
- **Python 3.8 or higher**
- **Ollama** (for running the LLM locally)
- **Tesseract OCR** (for optical character recognition)
- **Poppler** (for pdf2image, optional but recommended)

## Quick Start

### 1. Install System Dependencies

#### Install Ollama

```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh

# Windows or macOS alternative
# Download from https://ollama.com
```

#### Install Tesseract OCR

```bash
# macOS
brew install tesseract

# Ubuntu/Debian
sudo apt-get install tesseract-ocr

# Fedora/Red Hat
sudo dnf install tesseract

# Windows
# Download from https://github.com/UB-Mannheim/tesseract/wiki
```

#### Install Poppler (Optional, for pdf2image)

```bash
# macOS
brew install poppler

# Ubuntu/Debian
sudo apt-get install poppler-utils

# Fedora/Red Hat
sudo dnf install poppler-utils

# Windows
# Download from http://blog.alivate.com.au/poppler-windows/
```

### 2. Start Ollama Service

In a terminal window:

```bash
ollama serve
```

Keep this terminal window open.

### 3. Pull the Model

This step is only required on first run, or it can be done automatically via the installation script in step 4.

In a new terminal window:

```bash
ollama pull qwen3:8b
```

This will download approximately 4.5GB of model files. Please be patient.

### 4. Automated Installation

In the `servers/pdf_analysis` directory, run:

```bash
chmod +x setup.sh
./setup.sh
```

This script will:
- Verify Python, Ollama, and Tesseract installation
- Create a virtual environment
- Install all dependencies (PDF processing, OCR, LLM)
- Validate the installation

### 5. Start the Server

```bash
./run.sh
```

Upon success, you should see:

```
✓ Ollama is running
Starting FastAPI server on http://localhost:8000
```

### 6. Server API and Health Check

```bash
curl http://localhost:8000/health
```

### Analyse PDF (Recommended)

```bash
curl -X POST "http://localhost:8000/analyse/pdf" \
  -F "file=@/path/to/pathology_report.pdf"
```

This endpoint automatically:
1. Extracts text from the PDF
2. Falls back to OCR if text extraction fails
3. Analyses with LLM
4. Validates and normalises units

### Analyse Text (Legacy)

```bash
curl -X POST "http://localhost:8000/analyse/text" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Pathology Report Content...",
    "report_name": "pathology_report.pdf"
  }'
```

Note: The text endpoint is still available for cases where text has already 
been extracted client-side.

## 7. Server Testing

### Automated Testing

```bash
cd servers/pdf_analysis
source venv/bin/activate
python test_server.py
```

### Testing with Sample PDFs

```bash
python test_server.py /path/to/sample.pdf
```

### Web Interface Testing

Open your browser and navigate to:

```
http://localhost:8000/docs
```

This will open the Swagger UI, allowing you to test the API directly in your browser.

## Output Format

The server returns JSON in the following format:

```json
{
  "report_name": "pathology_report.pdf",
  "requested_date": "2025-01-15",
  "collected_time": "2025-01-15T09:30:00",
  "received_time": "2025-01-15T10:15:00",
  "report_upload_date": "2025-01-16",
  "laboratory": "Some Pathology Laboratory",
  "tests": [
    {
      "test_name": "Sodium",
      "result": "140",
      "units": "mmol/l",
      "reference_interval": "135-145",
      "comment": "",
      "validation_metadata": {
        "test_name": {
          "original": "Na",
          "standardised": "Sodium",
          "was_changed": true
        },
        "unit": {
          "is_valid": true,
          "original": "mmol/L",
          "corrected": "mmol/L",
          "expected": "mmol/L",
          "was_corrected": false
        }
      }
    },
    {
      "test_name": "eGFR",
      "result": ">60",
      "units": "mL/min/1.73m²",
      "reference_interval": ">60",
      "comment": "",
      "validation_metadata": {
        "test_name": {
          "original": "eGFR mL/min/1.73m*2",
          "standardised": "eGFR",
          "was_changed": true
        },
        "unit": {
          "is_valid": false,
          "original": "mL/min/1.73m*2",
          "corrected": "mL/min/1.73m²",
          "expected": "mL/min/1.73m²",
          "was_corrected": true
        }
      }
    }
  ]
}
```

Each test result includes `validation_metadata` showing:
- **Test name standardisation**:
  - `original`: Original test name as extracted
  - `standardised`: Standardised test name
  - `was_changed`: Whether the name was modified
- **Unit validation and correction**:
  - `is_valid`: Whether the original unit was correct
  - `original`: Original unit as extracted
  - `corrected`: Corrected unit (automatically applied)
  - `expected`: Expected unit for this test
  - `was_corrected`: Whether the unit was automatically corrected

## Common Issues

### 1. Unable to Connect to Ollama Server

**Symptoms**: Server fails to start with "Cannot connect to Ollama" message

**Solution**:
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not running, start it
ollama serve
```

### 2. Model Not Found

**Symptoms**: Error message "model 'qwen3:8b' not found"

**Solution**:
```bash
ollama pull qwen3:8b
```

### 3. Flutter Application Cannot Connect to Server

**Symptoms**: Application displays "Cannot connect to LLM server"

**Solution**:
```bash
# Check if server is running
curl http://localhost:8000/health

# If not running, start it
cd servers/pdf_analysis
./run.sh
```

### 4. Request Timeout

**Symptoms**: Analysis takes too long, resulting in timeout errors

**Possible Causes**:
- First request requires model loading (30-60 seconds)
- Insufficient system resources
- PDF file too large

**Solutions**:
- The default timeout is set to 15 minutes (900 seconds), which should be sufficient for most reports
- Wait longer (subsequent requests will be much faster after the initial model loading)
- If still timing out, you can increase timeout settings further via the OLLAMA_TIMEOUT environment variable
- Use a smaller model (e.g., qwen3:4b)

### 5. Insufficient Memory

**Symptoms**: System slowdown or Ollama crashes

**Solutions**:
- Ensure at least 8GB of available RAM
- Close other large applications
- Use a smaller model

### 6. "Failed to extract text from PDF" Error

**Symptoms**: Error message "Failed to extract text from PDF"

**Cause**: All text extraction and OCR methods failed.

**Possible Reasons**:
- PDF is password-protected or encrypted
- PDF is corrupted
- PDF contains only unrecognisable images
- Tesseract is not installed or not in PATH

**Solution**:
```bash
# Verify Tesseract installation
tesseract --version

# If not installed, install it (see installation instructions above)

# For macOS
brew install tesseract

# For Ubuntu/Debian
sudo apt-get install tesseract-ocr
```

## Performance Notes

- **First Request**: 30-60 seconds (model loading)
- **Subsequent Requests**: 10-20 seconds
- **Memory Requirements**: Approximately 8GB RAM
- **Disc Space**: Approximately 4.5GB (model files)

## Debugging Tips

### Viewing Server Logs

The server outputs detailed logs to the terminal whilst running:

```
INFO:     Received PDF file: report.pdf
INFO:     Saved PDF to temporary file: /tmp/tmpXXXXXX.pdf
INFO:     Extracted 1234 characters from PDF
INFO:     Sending request to Ollama for analysis
INFO:     Successfully parsed LLM response
INFO:     Successfully analysed report with 12 tests
```

### Testing Ollama Connection

```bash
curl http://localhost:11434/api/tags
```

### Testing Server Connection

```bash
curl http://localhost:8000/health
```

### Checking Python Environment

```bash
cd servers/pdf_analysis
source venv/bin/activate
python -c "import fastapi, pdfplumber, pytesseract, easyocr; print('OK')"
```

### Checking Tesseract Installation

```bash
tesseract --version
```

## Custom Configuration

### Modifying Server Port

Edit the `main.py` file at the end:

```python
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,  # Modify this value
        reload=True,
    )
```

### Modifying Timeout Duration

Server-side timeout (default is 900 seconds / 15 minutes):

Set the `OLLAMA_TIMEOUT` environment variable before starting the server:

```bash
export OLLAMA_TIMEOUT=1200  # 20 minutes
./run.sh
```

Flutter client-side timeout:

```dart
final llmService = PathologyLLMService(
  baseUrl: 'http://localhost:8000',
  timeout: const Duration(seconds: 900),  // Should match or exceed server timeout
);

// Now simply upload the PDF file
final result = await llmService.analysePdf(pdfFile);
```

### Adjusting LLM Temperature Parameter

Edit the `analyse_text_internal` function in `main.py`:

```python
response = ollama_client.generate(
    prompt=prompt,
    temperature=0.1  # Lower for more deterministic, higher for more varied results
)
```

## Production Deployment Recommendations

1. **Use HTTPS**: Implement SSL/TLS in production environments
2. **Add Authentication**: Implement API keys or OAuth authentication
3. **Load Balancing**: Use nginx or cloud service load balancers
4. **Monitoring**: Add log aggregation and monitoring systems
5. **Backup Strategy**: Implement fallback mechanisms for LLM failures

## Getting Help

If you encounter issues:

1. Review the relevant log files
2. Run test scripts to validate configuration
3. Consult the detailed documentation
4. Verify all services are running properly

## Licence

Copyright (C) 2025, Software Innovation Institute ANU

Licensed under the GNU General Public License, Version 3 (the "License");

License: https://opensource.org/license/gpl-3-0

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://opensource.org/license/gpl-3-0>.

**Created**: 18 November 2025
**Author**: Tony Chen
**Project**: HealthPod
**Organisation**: Software Innovation Institute ANU
