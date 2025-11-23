"""
LLM Text Analysis Server for Pathology Reports.

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

import logging
import os
import tempfile
from datetime import datetime
from typing import Dict, Any

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from llm_prompts import create_analysis_prompt
from ollama_client import OllamaClient
from pdf_extractor import PdfTextExtractor
from ocr_service import OcrService
from unit_validator import UnitValidator

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Initialise FastAPI app
app = FastAPI(
    title="Pathology Report Analysis API",
    description="Complete pathology report analysis service. "
    "Accepts PDF files, performs text extraction (with OCR fallback), "
    "LLM analysis, unit validation, and returns structured data.",
    version="0.1.0",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialise services
ollama_client = OllamaClient(
    base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434"),
    model=os.getenv("OLLAMA_MODEL", "qwen3:8b"),
    timeout=int(os.getenv("OLLAMA_TIMEOUT", "900")),  # 900 seconds (15 minutes)
)
ocr_service = OcrService()
unit_validator = UnitValidator()


class TextAnalysisRequest(BaseModel):
    """Request model for text-based analysis."""

    text: str = Field(..., description="The pathology report text to analyse")
    report_name: str = Field(..., description="Name of the report")


class PathologyResponse(BaseModel):
    """Response model for pathology analysis."""

    report_name: str
    requested_date: str = ""
    collected_time: str = ""
    received_time: str = ""
    report_upload_date: str
    laboratory: str = ""
    tests: list[Dict[str, Any]] = []


@app.get("/")
async def root():
    """Root endpoint - health check."""
    return {
        "status": "healthy",
        "service": "Pathology Report Analysis API",
        "version": "0.1.0",
    }


@app.get("/health")
async def health_check():
    """
    Health check endpoint.

    Verifies that the API and Ollama server are accessible.
    """
    ollama_status = ollama_client.check_connection()

    return {
        "status": "healthy" if ollama_status else "degraded",
        "api": "operational",
        "ollama": "connected" if ollama_status else "disconnected",
        "timestamp": datetime.now().isoformat(),
    }


@app.post("/analyse/text", response_model=PathologyResponse)
async def analyse_text(request: TextAnalysisRequest):
    """
    Analyse pathology report text.

    This endpoint accepts pre-extracted text from a pathology report
    and uses an LLM to parse and structure the test results.

    Args:
        request: The text analysis request, containing
        - text: The extracted text from the pathology report
        - report_name: Name of the report file

    Returns:
        Structured pathology report data, including
        - report_name: Name of the report
        - requested_date: Date the tests were requested
        - collected_time: When the sample was collected
        - received_time: When the lab received the sample
        - report_upload_date: When the report was uploaded
        - laboratory: Name of the laboratory
        - tests: List of test results with values, units, and reference ranges

    Raises:
        HTTPException: If the analysis fails or text is empty
    """
    logger.info(f"Received text analysis request for report: {request.report_name}")

    try:
        result = await analyse_text_internal(request.text, request.report_name)
        return result
    except ValueError as e:
        logger.error(f"Text validation failed: {e}")
        raise HTTPException(
            status_code=400, detail=(f"Failed to analyse text: {str(e)}. ")
        )
    except Exception as e:
        logger.error(f"Failed to analyse text: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to analyse text: {str(e)}")


async def analyse_text_internal(
    report_text: str, report_name: str
) -> PathologyResponse:
    """
    Internal function to analyse pathology report text using LLM.

    Args:
        report_text: The text content of the pathology report
        report_name: Name of the report file

    Returns:
        Structured pathology report data

    Raises:
        Exception: If the analysis fails
    """
    if not report_text or not report_text.strip():
        raise ValueError("Report text is empty")

    # Log text length for debugging
    logger.info(f"Report text length: {len(report_text)} characters")

    # Truncate very long texts to avoid timeout
    MAX_TEXT_LENGTH = 50000  # ~50KB text, should be enough for most reports
    if len(report_text) > MAX_TEXT_LENGTH:
        logger.warning(
            f"Text too long ({len(report_text)} chars), "
            f"truncating to {MAX_TEXT_LENGTH}"
        )
        report_text = (
            report_text[:MAX_TEXT_LENGTH] + "\n\n[Text truncated due to length]"
        )

    # Create prompt for LLM
    prompt = create_analysis_prompt(report_text)

    # Send to Ollama
    logger.info("Sending request to Ollama for analysis")
    logger.info(f"Model: {ollama_client.model}, Timeout: {ollama_client.timeout}s")
    try:
        response = ollama_client.generate(
            prompt=prompt,
            temperature=0.1,  # Low temperature for more deterministic output
        )
        logger.info("Successfully received response from Ollama")
    except Exception as e:
        logger.error(f"Ollama request failed: {e}")
        logger.error(
            "This usually means: 1) Model is loading (first request), "
            "2) Text is too long, or 3) System is under load"
        )
        raise

    # Extract and parse JSON response
    try:
        parsed_data = ollama_client.extract_json_from_response(response)
        logger.info("Successfully parsed LLM response")
        logger.info(f"Parsed data keys: {list(parsed_data.keys())}")
        logger.info(
            f"Number of tests in parsed data: {len(parsed_data.get('tests', []))}"
        )
        if len(parsed_data.get("tests", [])) == 0:
            logger.warning("LLM returned 0 tests. This might indicate:")
            logger.warning("1. The report format is not recognized")
            logger.warning("2. The prompt needs adjustment")
            logger.warning("3. The model needs different parameters")
            logger.warning(
                f"Raw LLM response (first 500 chars): {response.get('response', '')[:500]}"
            )
    except Exception as e:
        logger.error(f"Failed to parse LLM response: {e}")
        raise

    # Add report metadata
    current_date = datetime.now()
    upload_date = current_date.strftime("%Y-%m-%d")

    # Construct response
    result = PathologyResponse(
        report_name=report_name,
        requested_date=parsed_data.get("requested_date", ""),
        collected_time=parsed_data.get("collected_time", ""),
        received_time=parsed_data.get("received_time", ""),
        report_upload_date=upload_date,
        laboratory=parsed_data.get("laboratory", ""),
        tests=parsed_data.get("tests", []),
    )

    # Validate and normalise units
    result.tests = unit_validator.validate_results(result.tests)

    logger.info(f"Successfully analysed report with {len(result.tests)} tests")
    return result


@app.post("/analyse/pdf", response_model=PathologyResponse)
async def analyse_pdf(file: UploadFile = File(...)):
    """
    Analyse a PDF pathology report.

    This endpoint accepts a PDF file and performs the complete analysis workflow:
    1. PDF text extraction (tries multiple methods)
    2. OCR fallback if text extraction returns empty results
    3. LLM analysis to structure the data
    4. Unit validation and normalisation

    Args:
        file: The PDF file to analyse

    Returns:
        Structured pathology report data, including
        - report_name: Name of the report
        - requested_date: Date the tests were requested
        - collected_time: When the sample was collected
        - received_time: When the lab received the sample
        - report_upload_date: When the report was uploaded
        - laboratory: Name of the laboratory
        - tests: List of test results with validated units

    Raises:
        HTTPException: If the analysis fails or file is invalid
    """
    logger.info(f"Received PDF file for analysis: {file.filename}")

    # Validate file type.
    if not file.filename.endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only PDF files are supported.",
        )

    # Save uploaded file to temporary location.
    temp_file = None
    try:
        # Create temporary files.
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp:
            temp_file = temp.name
            content = await file.read()
            temp.write(content)
            logger.info(f"Saved PDF to temporary file: {temp_file}")

        # Step 1: Try text extraction.
        logger.info("Step 1: Attempting PDF text extraction")
        text = PdfTextExtractor.extract_text(temp_file)

        # Step 2: If text extraction failed or returned empty, use OCR.
        if not text or len(text.strip()) < 50:
            logger.warning(
                "Text extraction returned empty or insufficient text. "
                "Falling back to OCR."
            )
            logger.info("Step 2: Performing OCR on PDF")
            text = ocr_service.extract_text_from_pdf(
                temp_file,
                dpi=300,  # High resolution for better accuracy.
                use_easyocr=False,  # Start with Tesseract, fallback to EasyOCR.
            )

            if not text:
                raise ValueError(
                    "Failed to extract text from PDF. "
                    "The document may be empty or contain unrecognisable content."
                )

        logger.info(f"Successfully extracted {len(text)} characters from PDF")

        # Step 3: Analyse with LLM.
        logger.info("Step 3: Analysing text with LLM")
        result = await analyse_text_internal(text, file.filename)

        return result

    except ValueError as e:
        logger.error(f"PDF validation failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to analyse PDF: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to analyse PDF: {str(e)}"
        )
    finally:
        # Clean up temporary files.
        if temp_file and os.path.exists(temp_file):
            try:
                os.unlink(temp_file)
                logger.info(f"Deleted temporary file: {temp_file}")
            except Exception as e:
                logger.warning(f"Failed to delete temporary file: {e}")


if __name__ == "__main__":
    import uvicorn

    # Run the server
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
