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
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:healthpod/features/pathology/llm_service.dart';
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

  /// Extracts text from PDF bytes.

  static String extractTextFromPdf(List<int> pdfBytes) {
    final PdfDocument pdf = PdfDocument(inputBytes: pdfBytes);
    String text = '';

    for (var i = 0; i < pdf.pages.count; i++) {
      text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
    }

    return text;
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
