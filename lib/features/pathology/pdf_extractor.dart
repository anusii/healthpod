/// PDF extraction utilities for pathology reports.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:healthpod/features/pathology/llm_service.dart';
import 'package:healthpod/features/pathology/pdf_ocr_service.dart';
import 'package:healthpod/features/pathology/pdf_processor.dart';

/// Utility class for extracting and analysing PDF content.

class PdfExtractor {
  const PdfExtractor._();

  /// Converts various byte formats to List(int).

  static List<int> convertToBytes(dynamic result) {
    if (result is Uint8List) {
      return result;
    } else if (result is List<int>) {
      return result;
    } else {
      // If it's a string, it might be base64 encoded.

      try {
        return base64Decode(result);
      } catch (e) {
        debugPrint('PDF decode failed: $e');

        // Try as raw bytes from string.

        return (result).codeUnits;
      }
    }
  }

  /// Extracts text from PDF bytes with OCR fallback.

  static Future<String> extractTextFromBytesWithFallback(List<int> pdfBytes) async {
    try {
      // Step 1: Try standard text extraction from bytes.

      final PdfDocument pdf = PdfDocument(inputBytes: pdfBytes);
      String text = '';

      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      if (text.trim().isNotEmpty) {
        debugPrint(
          'Successfully extracted text using standard method: '
          '${text.length} characters',
        );
        return text.trim();
      }

      // Step 2: Text is empty, need to use OCR.
      // Save bytes to temporary file for OCR processing.

      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/temp_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      try {
        // Write bytes to temp file.

        await tempFile.writeAsBytes(pdfBytes);
        debugPrint('Created temporary file for OCR: ${tempFile.path}');

        // Use Tesseract OCR.

        text = await PdfOcrService.performOcr(tempFile.path);

        if (text.trim().isNotEmpty) {
          debugPrint(
            'Successfully extracted text using OCR: ${text.length} characters',
          );
          return text.trim();
        }

        // OCR returned empty text.

        throw Exception(
          'No text could be extracted from the PDF. '
          'The document may be empty or contain only images without '
          'recognisable text. Tried: standard extraction and OCR.',
        );
      } finally {
        // Clean up temporary file.

        if (await tempFile.exists()) {
          await tempFile.delete();
          debugPrint('Deleted temporary file: ${tempFile.path}');
        }
      }
    } catch (e) {
      debugPrint('Text extraction from bytes failed: $e');
      rethrow;
    }
  }

  /// Extracts text from PDF file path with automatic OCR fallback.

  static Future<String> extractTextWithFallback(String pdfPath) async {
    try {
      // Step 1: Try standard text extraction from file.

      final pdfFile = File(pdfPath);
      final bytes = await pdfFile.readAsBytes();
      
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);
      String text = '';

      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      if (text.trim().isNotEmpty) {
        debugPrint(
          'Successfully extracted text using standard method: '
          '${text.length} characters',
        );
        return text.trim();
      }

      // Step 2: Text is empty, try OCR.

      text = await PdfOcrService.performOcr(pdfPath);

      if (text.trim().isNotEmpty) {
        debugPrint(
          'Successfully extracted text using OCR: ${text.length} characters',
        );
        return text.trim();
      }

      // Step 3: OCR returned empty text.

      throw Exception(
        'No text could be extracted from the PDF. '
        'The document may be empty or contain only images without '
        'recognisable text. Tried: standard extraction and OCR.',
      );
    } catch (e) {
      debugPrint('Text extraction failed: $e');
      rethrow;
    }
  }

  /// Analyses text using LLM with fallback to traditional parsing.

  static Future<Map<String, dynamic>> analyseTextWithLLM({
    required String text,
    required String fileName,
    String llmServerUrl = 'http://localhost:8000',
  }) async {
    try {
      // Create LLM service instance.

      final llmService = PathologyLLMService(
        baseUrl: llmServerUrl,
        timeout: const Duration(seconds: 900), // 900 seconds (15 minutes)
      );

      // Check if LLM server is available.

      final isConnected = await llmService.checkConnection();

      if (isConnected) {
        // Use LLM to analyse the extracted text.

        final jsonData = await llmService.analyseText(text, fileName);
        debugPrint('Successfully analysed with LLM');
        return jsonData;
      } else {
        // Fall back to traditional parsing if LLM server not available.

        debugPrint('LLM server not available, using traditional parsing');
        return _traditionalParsing(text, fileName);
      }
    } catch (llmError) {
      // If LLM fails, fall back to traditional parsing.

      debugPrint('LLM analysis failed: $llmError');
      debugPrint('Falling back to traditional parsing');

      return _traditionalParsing(text, fileName);
    }
  }

  /// Traditional parsing fallback method.

  static Map<String, dynamic> _traditionalParsing(
    String text,
    String fileName,
  ) {
    final lines = text.split('\n');
    return PdfProcessor.createPathologyJson(fileName, lines);
  }
}
