"""
PDF Analysis Server.

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

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from llm_prompts import create_analysis_prompt
from ollama_client import OllamaClient
from pdf_parser import PDFParser

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Initialise FastAPI app
app = FastAPI(
    title="Pathology Report Analysis API",
    description="API for analysing pathology reports using LLM",
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

# Initialise Ollama client
ollama_client = OllamaClient(
    base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434"),
    model=os.getenv("OLLAMA_MODEL", "qwen3:8b"),
    timeout=int(os.getenv("OLLAMA_TIMEOUT", "900")),  # 900 seconds (15 minutes)
)


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


@app.post("/analyse/pdf", response_model=PathologyResponse)
async def analyse_pdf(file: UploadFile = File(..., description="PDF file to analyse")):
    """
    Analyse a pathology report PDF file.

    NOTE: This endpoint is deprecated. Flutter app now extracts text locally
    and uses the /analyse/text endpoint instead. This endpoint is kept for
    backward compatibility but is not actively used.

    Args:
        file: The PDF file to analyse

    Returns:
        Structured pathology report data

    Raises:
        HTTPException: If the file processing or analysis fails
    """
    logger.warning(f"PDF endpoint called (deprecated): {file.filename}")
    logger.info("Consider using /analyse/text endpoint - Flutter extracts text locally")

    # Validate file type
    if not file.filename.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="File must be a PDF")

    # Create a temporary file
    temp_file = None
    try:
        # Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name

        logger.info(f"Saved PDF to temporary file: {temp_file_path}")

        # Extract text from PDF
        try:
            report_text = PDFParser.extract_text_with_fallback(temp_file_path)
            logger.info(f"Extracted {len(report_text)} characters from PDF")
        except Exception as e:
            logger.error(f"Failed to extract text from PDF: {e}")
            raise HTTPException(
                status_code=500, detail=f"Failed to extract text from PDF: {str(e)}"
            )

        # Analyse text using LLM
        try:
            result = await analyse_text_internal(report_text, file.filename)
            return result
        except Exception as e:
            logger.error(f"Failed to analyse PDF content: {e}")
            raise HTTPException(
                status_code=500, detail=f"Failed to analyse PDF content: {str(e)}"
            )

    finally:
        # Clean up a temporary file
        if temp_file and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
                logger.info(f"Deleted temporary file: {temp_file_path}")
            except Exception as e:
                logger.warning(f"Failed to delete temporary file: {e}")


@app.post("/analyse/text", response_model=PathologyResponse)
async def analyse_text(request: TextAnalysisRequest):
    """
    Analyse pathology report text.

    This endpoint accepts pre-extracted text from a pathology report
    and uses an LLM to parse and structure the test results.

    Args:
        request: The text analysis request

    Returns:
        Structured pathology report data

    Raises:
        HTTPException: If the analysis fails
    """
    logger.info(f"Received text analysis request for report: {request.report_name}")

    try:
        result = await analyse_text_internal(request.text, request.report_name)
        return result
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

    logger.info(f"Successfully analysed report with {len(result.tests)} tests")
    return result


if __name__ == "__main__":
    import uvicorn

    # Run the server
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
