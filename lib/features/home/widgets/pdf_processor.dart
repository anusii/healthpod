/// PDF processing utilities for converting PDF to JSON.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
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

      final Map<String, dynamic> finalJson = _createBaseJsonStructure();

      // Parse the extracted text.

      _parseExtractedText(lines, finalJson);

      // Create a temporary file for the final JSON.

      final tempDir = await Directory.systemTemp.createTemp();
      if (!context.mounted) return;

      // Create a file with a name based on the original PDF.

      final jsonFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(file.path)}_final.json',
      );
      await jsonFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(finalJson));

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

  /// Creates the base JSON structure for pathology data.

  static Map<String, dynamic> _createBaseJsonStructure() {
    return {
      'timestamp': '',
      'clinical_note': '',
      'referrer': '',
      'clinic': '',
      'laboratory': '4Cyte Pathology',
      'pathologist': '',
      'sodium': 0.0,
      'potassium': 0.0,
      'chloride': 0.0,
      'bicarbonate': 0.0,
      'anion_gap': 0.0,
      'urea': 0.0,
      'creatinine': 0.0,
      'egfr': 0.0,
      'total_protien': 0.0,
      'globulin': 0.0,
      'albumin': 0.0,
      'bilirubin_total': 0.0,
      'alk_phosphatase': 0.0,
      'gamma_gt': 0.0,
      'alt': 0.0,
      'ast': 0.0,
    };
  }

  /// Parses extracted text and populates the JSON structure.

  static void _parseExtractedText(
    List<String> lines,
    Map<String, dynamic> finalJson,
  ) {
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Extract timestamp.

      if (line.contains('Collected:')) {
        _extractTimestamp(line, finalJson);
      }

      // Extract clinical note.

      if (line.contains('Clinical Notes:')) {
        finalJson['clinical_note'] = line.split('Clinical Notes:')[1].trim();
      }

      // Extract referrer.

      if (line.startsWith('Dr ')) {
        finalJson['referrer'] = line;
      }

      // Extract clinic address.

      if (line.contains('Medical Centre')) {
        finalJson['clinic'] = line;
      }

      // Extract pathologist.

      if (line.contains('Pathologist:')) {
        finalJson['pathologist'] = line.split('Pathologist:')[1].trim();
      }

      // Extract test results.

      _extractTestResults(line, lines, finalJson);
    }
  }

  /// Extracts timestamp from a line containing collection date.

  static void _extractTimestamp(String line, Map<String, dynamic> finalJson) {
    final dateTime = line.split('Collected:')[1].trim();
    final parts = dateTime.split(' ');
    if (parts.length == 2) {
      final date = parts[0].split('/');
      if (date.length == 3) {
        final year = date[2];
        final month = date[1].padLeft(2, '0');
        final day = date[0].padLeft(2, '0');
        final time = parts[1];
        finalJson['timestamp'] = '$year-$month-$day $time';
      }
    }
  }

  /// Extracts test results from the text lines.

  static void _extractTestResults(
    String line,
    List<String> lines,
    Map<String, dynamic> finalJson,
  ) {
    if (line.contains('Sodium')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['sodium'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Potassium')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['potassium'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Chloride')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['chloride'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Bicarbonate')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['bicarbonate'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Anion Gap')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['anion_gap'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Urea')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['urea'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Creatinine')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['creatinine'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('eGFR')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['egfr'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Total Protein')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 3) {
        finalJson['total_protien'] = double.tryParse(parts[2]) ?? 0.0;
      }
    } else if (line.contains('Globulin')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['globulin'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Albumin')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['albumin'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('Bilirubin Total')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 3) {
        finalJson['bilirubin_total'] = double.tryParse(parts[2]) ?? 0.0;
      }
    } else if (line.contains('Alk Phosphatase')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 3) {
        finalJson['alk_phosphatase'] = double.tryParse(parts[2]) ?? 0.0;
      }
    } else if (line.contains('Gamma GT')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 3) {
        finalJson['gamma_gt'] = double.tryParse(parts[2]) ?? 0.0;
      }
    } else if (line.contains('ALT')) {
      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        finalJson['alt'] = double.tryParse(parts[1]) ?? 0.0;
      }
    } else if (line.contains('AST')) {
      final nextLineIndex = lines.indexOf(line) + 1;
      if (nextLineIndex < lines.length) {
        final nextLine = lines[nextLineIndex].trim();
        finalJson['ast'] = double.tryParse(nextLine) ?? 0.0;
      }
    }
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
}
