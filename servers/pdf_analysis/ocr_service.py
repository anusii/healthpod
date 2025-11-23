"""
OCR Service Module for PDF Image Extraction.

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
from typing import List, Optional

import easyocr
import fitz
import pytesseract
from PIL import Image
from pdf2image import convert_from_path

logger = logging.getLogger(__name__)


class OcrService:
    """Handles OCR operations for PDF documents."""

    def __init__(self):
        """Initialise OCR service with EasyOCR reader."""
        self._easyocr_reader = None

    @property
    def easyocr_reader(self):
        """Lazy initialisation of EasyOCR reader."""
        if self._easyocr_reader is None:
            logger.info("Initialising EasyOCR reader (this may take a moment)...")
            self._easyocr_reader = easyocr.Reader(["en"], gpu=False)
            logger.info("EasyOCR reader initialised successfully")
        return self._easyocr_reader

    def pdf_to_images_pymupdf(
        self, pdf_path: str, dpi: int = 300
    ) -> List[Image.Image]:
        """
        Convert PDF pages to high-resolution images using PyMuPDF.

        Args:
            pdf_path: Path to the PDF file
            dpi: Resolution for image conversion (default: 300 for high quality)

        Returns:
            List of PIL Images, one per page
        """
        try:
            logger.info(f"Converting PDF to images with PyMuPDF at {dpi} DPI")
            doc = fitz.open(pdf_path)
            images = []

            # Calculate zoom factor for desired DPI (72 DPI is default).
            zoom = dpi / 72
            matrix = fitz.Matrix(zoom, zoom)

            for page_num in range(len(doc)):
                logger.debug(f"Converting page {page_num + 1}/{len(doc)}")
                page = doc.load_page(page_num)

                # Render page to pixmap.
                pix = page.get_pixmap(matrix=matrix)

                # Convert pixmap to PIL Image.
                img_data = pix.tobytes("png")
                img = Image.open(tempfile.NamedTemporaryFile(suffix=".png", delete=False))
                img.save(img.name)
                img = Image.open(tempfile.NamedTemporaryFile(suffix=".png", delete=False))

                # More efficient approach.
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                images.append(img)

            doc.close()
            logger.info(f"Successfully converted {len(images)} pages to images")
            return images

        except Exception as e:
            logger.error(f"PyMuPDF image conversion failed: {e}")
            return []

    def pdf_to_images_pdf2image(
        self, pdf_path: str, dpi: int = 300
    ) -> List[Image.Image]:
        """
        Convert PDF pages to high-resolution images using pdf2image.

        Args:
            pdf_path: Path to the PDF file
            dpi: Resolution for image conversion (default: 300 for high quality)

        Returns:
            List of PIL Images, one per page
        """
        try:
            logger.info(f"Converting PDF to images with pdf2image at {dpi} DPI")
            images = convert_from_path(pdf_path, dpi=dpi)
            logger.info(f"Successfully converted {len(images)} pages to images")
            return images
        except Exception as e:
            logger.error(f"pdf2image conversion failed: {e}")
            return []

    def pdf_to_images(self, pdf_path: str, dpi: int = 300) -> List[Image.Image]:
        """
        Convert PDF to images using best available method.

        Args:
            pdf_path: Path to the PDF file
            dpi: Resolution for image conversion (default: 300 for high quality)

        Returns:
            List of PIL Images
        """
        # Try PyMuPDF first (faster).
        images = self.pdf_to_images_pymupdf(pdf_path, dpi)
        if images:
            return images

        # Fallback to pdf2image.
        logger.info("Falling back to pdf2image")
        return self.pdf_to_images_pdf2image(pdf_path, dpi)

    def ocr_image_tesseract(self, image: Image.Image) -> str:
        """
        Extract text from an image using Tesseract OCR.

        Args:
            image: PIL Image object

        Returns:
            Extracted text
        """
        try:
            logger.debug("Running Tesseract OCR")
            text = pytesseract.image_to_string(image, lang="eng")
            logger.debug(f"Tesseract extracted {len(text)} characters")
            return text.strip()
        except Exception as e:
            logger.warning(f"Tesseract OCR failed: {e}")
            return ""

    def ocr_image_easyocr(self, image: Image.Image) -> str:
        """
        Extract text from an image using EasyOCR.

        Args:
            image: PIL Image object

        Returns:
            Extracted text
        """
        try:
            logger.debug("Running EasyOCR")
            # EasyOCR expects image as numpy array or path.
            import numpy as np

            img_array = np.array(image)
            results = self.easyocr_reader.readtext(img_array)

            # Combine all detected text.
            text = " ".join([result[1] for result in results])
            logger.debug(f"EasyOCR extracted {len(text)} characters")
            return text.strip()
        except Exception as e:
            logger.warning(f"EasyOCR failed: {e}")
            return ""

    def ocr_image(self, image: Image.Image, use_easyocr: bool = False) -> str:
        """
        Extract text from an image using OCR.

        Args:
            image: PIL Image object
            use_easyocr: If True, use EasyOCR; otherwise use Tesseract

        Returns:
            Extracted text
        """
        if use_easyocr:
            text = self.ocr_image_easyocr(image)
            if text:
                return text
            # Fallback to Tesseract.
            logger.info("EasyOCR returned empty, trying Tesseract")
            return self.ocr_image_tesseract(image)
        else:
            text = self.ocr_image_tesseract(image)
            if text:
                return text
            # Fallback to EasyOCR.
            logger.info("Tesseract returned empty, trying EasyOCR")
            return self.ocr_image_easyocr(image)

    def extract_text_from_pdf(
        self, pdf_path: str, dpi: int = 300, use_easyocr: bool = False
    ) -> Optional[str]:
        """
        Extract text from PDF using OCR.

        Converts each page to high-resolution image and performs OCR.

        Args:
            pdf_path: Path to the PDF file
            dpi: Resolution for image conversion (default: 300)
            use_easyocr: Whether to prefer EasyOCR over Tesseract

        Returns:
            Combined text from all pages, or None if extraction fails
        """
        logger.info(f"Starting OCR extraction from: {pdf_path}")

        # Convert PDF to images.
        images = self.pdf_to_images(pdf_path, dpi)
        if not images:
            logger.error("Failed to convert PDF to images")
            return None

        # Perform OCR on each page.
        combined_text = ""
        for page_num, image in enumerate(images, start=1):
            logger.info(f"Performing OCR on page {page_num}/{len(images)}")
            page_text = self.ocr_image(image, use_easyocr)

            if page_text:
                combined_text += page_text + "\n\n"
                logger.info(
                    f"Page {page_num}: Extracted {len(page_text)} characters"
                )
            else:
                logger.warning(f"Page {page_num}: No text extracted")

        if combined_text.strip():
            logger.info(
                f"OCR extraction successful: Total {len(combined_text)} characters"
            )
            return combined_text.strip()
        else:
            logger.warning("OCR extraction returned no text")
            return None
