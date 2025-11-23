"""
PDF Text Extraction Module.

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
from typing import Optional

import PyPDF2
import pdfplumber
import fitz  # PyMuPDF

logger = logging.getLogger(__name__)


class PdfTextExtractor:
    """Handles PDF text extraction using multiple methods."""

    @staticmethod
    def extract_text_pypdf2(pdf_path: str) -> str:
        """
        Extract text using PyPDF2.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text or empty string if extraction fails
        """
        try:
            logger.info("Attempting text extraction with PyPDF2")
            with open(pdf_path, "rb") as file:
                reader = PyPDF2.PdfReader(file)
                text = ""
                for page_num, page in enumerate(reader.pages):
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"
                    logger.debug(
                        f"Page {page_num + 1}: Extracted {len(page_text)} characters"
                    )

                if text.strip():
                    logger.info(
                        f"PyPDF2 extraction successful: {len(text)} characters"
                    )
                    return text.strip()
                else:
                    logger.warning("PyPDF2 returned empty text")
                    return ""
        except Exception as e:
            logger.warning(f"PyPDF2 extraction failed: {e}")
            return ""

    @staticmethod
    def extract_text_pdfplumber(pdf_path: str) -> str:
        """
        Extract text using pdfplumber.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text or empty string if extraction fails
        """
        try:
            logger.info("Attempting text extraction with pdfplumber")
            with pdfplumber.open(pdf_path) as pdf:
                text = ""
                for page_num, page in enumerate(pdf.pages):
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"
                    logger.debug(
                        f"Page {page_num + 1}: Extracted {len(page_text or '')} "
                        "characters"
                    )

                if text.strip():
                    logger.info(
                        f"pdfplumber extraction successful: {len(text)} characters"
                    )
                    return text.strip()
                else:
                    logger.warning("pdfplumber returned empty text")
                    return ""
        except Exception as e:
            logger.warning(f"pdfplumber extraction failed: {e}")
            return ""

    @staticmethod
    def extract_text_pymupdf(pdf_path: str) -> str:
        """
        Extract text using PyMuPDF (fitz).

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text or empty string if extraction fails
        """
        try:
            logger.info("Attempting text extraction with PyMuPDF")
            doc = fitz.open(pdf_path)
            text = ""
            for page_num in range(len(doc)):
                page = doc.load_page(page_num)
                page_text = page.get_text()
                if page_text:
                    text += page_text + "\n"
                logger.debug(f"Page {page_num + 1}: Extracted {len(page_text)} characters")

            doc.close()

            if text.strip():
                logger.info(f"PyMuPDF extraction successful: {len(text)} characters")
                return text.strip()
            else:
                logger.warning("PyMuPDF returned empty text")
                return ""
        except Exception as e:
            logger.warning(f"PyMuPDF extraction failed: {e}")
            return ""

    @classmethod
    def extract_text(cls, pdf_path: str) -> Optional[str]:
        """
        Extract text from PDF using multiple methods.

        Tries PyMuPDF first (fastest and most reliable), then pdfplumber,
        then PyPDF2 as fallback.

        Args:
            pdf_path: Path to the PDF file

        Returns:
            Extracted text or None if all methods fail

        Raises:
            FileNotFoundError: If the PDF file does not exist
        """
        import os

        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF file not found: {pdf_path}")

        logger.info(f"Starting text extraction from: {pdf_path}")

        # Try PyMuPDF first (usually fastest and most reliable).
        text = cls.extract_text_pymupdf(pdf_path)
        if text:
            return text

        # Try pdfplumber as second option.
        text = cls.extract_text_pdfplumber(pdf_path)
        if text:
            return text

        # Try PyPDF2 as last resort.
        text = cls.extract_text_pypdf2(pdf_path)
        if text:
            return text

        logger.warning("All text extraction methods failed or returned empty text")
        return None
