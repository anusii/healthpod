"""
PDF Parsing Utilities.

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

import pdfplumber
from PyPDF2 import PdfReader

# Configure logging
logger = logging.getLogger(__name__)


class PDFParser:
    """Utility class for extracting text from PDF files."""

    @staticmethod
    def extract_text_pdfplumber(pdf_path: str) -> str:
        """
        Extract text from a PDF file using pdfplumber.

        This method provides better text extraction for complex layouts.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text from all pages

        Raises:
            FileNotFoundError: If the PDF file does not exist
            Exception: For other PDF processing errors
        """
        try:
            text = ""
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"

            logger.info(
                f"Successfully extracted {len(text)} " "characters using pdfplumber"
            )
            return text

        except FileNotFoundError:
            logger.error(f"PDF file not found: {pdf_path}")
            raise
        except Exception as e:
            logger.error(f"Error extracting text with pdfplumber: {e}")
            raise

    @staticmethod
    def extract_text_pypdf2(pdf_path: str) -> str:
        """
        Extract text from a PDF file using PyPDF2.

        This is a fallback method for simpler PDFs.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text from all pages

        Raises:
            FileNotFoundError: If the PDF file does not exist
            Exception: For other PDF processing errors
        """
        try:
            text = ""
            reader = PdfReader(pdf_path)

            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"

            logger.info(
                f"Successfully extracted {len(text)} characters " "using PyPDF2"
            )
            return text

        except FileNotFoundError:
            logger.error(f"PDF file not found: {pdf_path}")
            raise
        except Exception as e:
            logger.error(f"Error extracting text with PyPDF2: {e}")
            raise

    @staticmethod
    def extract_text(pdf_path: str, method: str = "pdfplumber") -> str:
        """
        Extract text from a PDF file using the specified method.

        Args:
            pdf_path: Path to the PDF file
            method: Extraction method to use ("pdfplumber" or "pypdf2")

        Returns:
            Extracted text from all pages

        Raises:
            ValueError: If an invalid method is specified
            FileNotFoundError: If the PDF file does not exist
            Exception: For other PDF processing errors
        """
        if method == "pdfplumber":
            return PDFParser.extract_text_pdfplumber(pdf_path)
        elif method == "pypdf2":
            return PDFParser.extract_text_pypdf2(pdf_path)
        else:
            raise ValueError(f"Invalid extraction method: {method}")

    @staticmethod
    def extract_text_with_fallback(pdf_path: str) -> str:
        """
        Extract text from a PDF file with automatic fallback.

        Tries pdfplumber first, falls back to PyPDF2 if that fails.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text from all pages

        Raises:
            Exception: If both methods fail
        """
        try:
            return PDFParser.extract_text_pdfplumber(pdf_path)
        except Exception as e:
            logger.warning(f"pdfplumber failed, trying PyPDF2: {e}")
            try:
                return PDFParser.extract_text_pypdf2(pdf_path)
            except Exception as e2:
                logger.error(f"Both extraction methods failed: {e2}")
                raise
