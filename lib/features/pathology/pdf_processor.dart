/// PDF processing utilities for converting PDF to JSON.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/pathology/llm_service.dart';

/// Utility class for processing PDF files and converting them to JSON.

class PdfProcessor {
  const PdfProcessor._();

  /// Converts PDF to JSON and uploads both files.

  static Future<void> convertPDFToJsonUpload(
    File file,
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Show loading dialog while processing.

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Read PDF file.

      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.

      String text = '';
      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      // Structure the data to match kt_pathology.json format.

      final List<String> lines = text.split('\n');

      // Close loading dialog.
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Extract final structured data.

      final fileName = path.basename(file.path);
      final Map<String, dynamic> finalJson =
          createPathologyJson(fileName, lines);

      // Create a temporary file for the final JSON.

      final tempDir = await Directory.systemTemp.createTemp();
      if (!context.mounted) return;

      // Create a file with a name based on the original PDF.

      final jsonFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(file.path)}_final.json',
      );
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(finalJson),
      );

      // Upload both files to POD.

      if (!context.mounted) return;

      await _uploadFiles(file, jsonFile, context, ref);

      // Clean up temporary file.

      await jsonFile.delete();
      await tempDir.delete();

      // Show success message.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF and JSON files uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Creates a basic JSON structure for pathology data.
  ///
  /// This is a simplified fallback when LLM is not available.
  /// Returns a basic structure with minimal parsing.

  static Map<String, dynamic> createPathologyJson(
    String fileName,
    List<String> lines,
  ) {
    final now = DateTime.now();
    final jsonData = {
      'report_name': fileName,
      'requested_date': '',
      'collected_time': '',
      'received_time': '',
      'report_upload_date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}'
              '-${now.day.toString().padLeft(2, '0')}',
      'laboratory': 'Unknown',
      'tests': <Map<String, dynamic>>[],
    };

    // Add a note that manual review is recommended.

    jsonData['tests'] = [
      {
        'test_name': 'Manual Review Required',
        'result': 'N/A',
        'units': '',
        'reference_interval': '',
        'comment': 'LLM analysis unavailable.',
      }
    ];

    return jsonData;
  }

  /// Uploads both PDF and JSON files to the POD.

  static Future<void> _uploadFiles(
    File pdfFile,
    File jsonFile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;

    // First upload the PDF.

    ref.read(fileServiceProvider.notifier).setUploadFile(pdfFile.path);
    if (!context.mounted) return;

    // Store context reference for safe async usage.

    final currentContext = context;
    await ref.read(fileServiceProvider.notifier).handleUpload(currentContext);
    if (!context.mounted) return;

    // Then upload the JSON.

    ref.read(fileServiceProvider.notifier).setUploadFile(jsonFile.path);
    if (!context.mounted) return;

    // Store context reference for safe async usage.

    final currentContext2 = context;
    await ref.read(fileServiceProvider.notifier).handleUpload(currentContext2);
  }

  /// Converts PDF to JSON using LLM and uploads both files.
  ///
  /// This method extracts text from PDF first, then uses LLM to analyse the
  /// text. Only text is sent to the server, not the entire PDF file.

  static Future<void> convertPDFToJsonUploadLLM(
    File file,
    BuildContext context,
    WidgetRef ref, {
    String llmServerUrl = 'http://localhost:8000',
  }) async {
    try {
      // Show loading dialog while processing.

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Extracting text from PDF...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Read PDF file and extract text.

      final bytes = await file.readAsBytes();
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);

      // Extract text from all pages.

      String text = '';
      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      // Update loading message.

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Analysing with LLM...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      // Create LLM service instance.

      final llmService = PathologyLLMService(baseUrl: llmServerUrl);

      // Check connection first.

      final isConnected = await llmService.checkConnection();
      if (!isConnected) {
        throw Exception(
          'Cannot connect to LLM server at $llmServerUrl. '
          'Please ensure the server is running.',
        );
      }

      // Analyse text using LLM (only send text, not the PDF file).

      final fileName = path.basename(file.path);
      final analysisResult = await llmService.analyseText(text, fileName);

      // Close loading dialog.

      if (context.mounted) {
        Navigator.pop(context);
      }

      // Create JSON file from LLM result.

      final tempDir = await Directory.systemTemp.createTemp();
      final jsonFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(file.path)}_llm.json',
      );

      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(analysisResult),
      );

      // Upload both files to POD.

      if (!context.mounted) return;
      await _uploadFiles(file, jsonFile, context, ref);

      // Clean up temporary files.

      await jsonFile.delete();
      await tempDir.delete();

      // Show success message.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF analysed with LLM and uploaded successfully. '
              'Found ${analysisResult['tests']?.length ?? 0} tests.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Try to close loading dialog if still open.

        Navigator.of(context, rootNavigator: true).popUntil((route) {
          return route is! PopupRoute;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing PDF with LLM: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Converts PDF to JSON with automatic fallback between LLM and traditional
  /// parsing.
  ///
  /// Tries LLM analysis first, falls back to traditional parsing if LLM fails.

  static Future<void> convertPDFToJsonUploadWithFallback(
    File file,
    BuildContext context,
    WidgetRef ref, {
    String llmServerUrl = 'http://localhost:8000',
  }) async {
    try {
      // Try LLM first.

      await convertPDFToJsonUploadLLM(
        file,
        context,
        ref,
        llmServerUrl: llmServerUrl,
      );
    } catch (e) {
      // If LLM fails, fall back to traditional parsing.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'LLM analysis failed, falling back to traditional parsing...',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Use traditional parsing.

        await convertPDFToJsonUpload(file, context, ref);
      }
    }
  }
}
