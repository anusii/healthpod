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

  /// Creates the base JSON structure for pathology data.
  ///
  /// Uses a flexible structure with a tests array to support various test types.

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
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'laboratory': '',
      'tests': <Map<String, dynamic>>[],
    };

    // Extract metadata and test results.

    parseExtractedText(lines, jsonData);

    return jsonData;
  }

  /// Parses extracted text and populates the JSON structure.
  ///
  /// This method extracts only essential metadata and test results from the PDF text.

  static void parseExtractedText(
    List<String> lines,
    Map<String, dynamic> finalJson,
  ) {
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      // Extract collection time.

      if (line.contains('Collected:') || line.contains('Collection Time:')) {
        _extractCollectionTime(line, finalJson);
      }

      // Extract requested date.

      if (line.contains('Requested:') || line.contains('Request Date:')) {
        _extractRequestedDate(line, finalJson);
      }

      // Extract received time.

      if (line.contains('Received:') || line.contains('Received Time:')) {
        _extractReceivedTime(line, finalJson);
      }

      // Extract laboratory name only.

      if (line.contains('Pathology') ||
          line.contains('Laboratory') ||
          line.contains('Lab:')) {
        _extractLaboratory(line, finalJson);
      }
    }

    // Extract test results using improved pattern matching.

    extractTestResults(lines, finalJson);
  }

  /// Helper method to extract text after colon.

  static String extractAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length >= 2) {
      return parts.sublist(1).join(':').trim();
    }
    return '';
  }

  /// Extracts collection time from a line.

  static void _extractCollectionTime(
    String line,
    Map<String, dynamic> finalJson,
  ) {
    final dateTime = extractAfterColon(line);
    if (dateTime.isNotEmpty) {
      final formatted = formatDateTime(dateTime);
      if (formatted.isNotEmpty) {
        finalJson['collected_time'] = formatted;
      }
    }
  }

  /// Extracts requested date from a line.

  static void _extractRequestedDate(
    String line,
    Map<String, dynamic> finalJson,
  ) {
    final dateStr = extractAfterColon(line);
    if (dateStr.isNotEmpty) {
      final formatted = formatDate(dateStr);
      if (formatted.isNotEmpty) {
        finalJson['requested_date'] = formatted;
      }
    }
  }

  /// Extracts received time from a line.

  static void _extractReceivedTime(
    String line,
    Map<String, dynamic> finalJson,
  ) {
    final dateTime = extractAfterColon(line);
    if (dateTime.isNotEmpty) {
      final formatted = formatDateTime(dateTime);
      if (formatted.isNotEmpty) {
        finalJson['received_time'] = formatted;
      }
    }
  }

  /// Extracts laboratory name.

  static void _extractLaboratory(String line, Map<String, dynamic> finalJson) {
    if (finalJson['laboratory'].isEmpty) {
      // Try to extract lab name from common patterns.

      if (line.contains('Lab:')) {
        finalJson['laboratory'] = extractAfterColon(line);
      } else if (line.contains('Pathology')) {
        finalJson['laboratory'] = line.trim();
      }
    }
  }

  /// Formats a date string to ISO format (YYYY-MM-DD).

  static String formatDate(String dateStr) {
    // Try different date formats.
    // Format: DD/MM/YYYY or D/M/YYYY

    final datePattern1 = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    final match1 = datePattern1.firstMatch(dateStr);
    if (match1 != null) {
      final day = match1.group(1)!.padLeft(2, '0');
      final month = match1.group(2)!.padLeft(2, '0');
      final year = match1.group(3);
      return '$year-$month-$day';
    }

    // Format: YYYY-MM-DD (already formatted)

    final datePattern2 = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    final match2 = datePattern2.firstMatch(dateStr);
    if (match2 != null) {
      return match2.group(0)!;
    }

    return '';
  }

  /// Formats a date-time string to ISO format (YYYY-MM-DDTHH:MM:SS).

  static String formatDateTime(String dateTimeStr) {
    // Try to parse date and time separately.
    // Format: DD/MM/YYYY HH:MM or similar

    final dateTimePattern = RegExp(
      r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?',
    );
    final match = dateTimePattern.firstMatch(dateTimeStr);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3);
      final hour = match.group(4)!.padLeft(2, '0');
      final minute = match.group(5)!.padLeft(2, '0');
      final second = match.group(6)?.padLeft(2, '0') ?? '00';
      return '$year-$month-${day}T$hour:$minute:$second';
    }

    // Try just date format.

    final dateOnly = formatDate(dateTimeStr);
    if (dateOnly.isNotEmpty) {
      return '${dateOnly}T00:00:00';
    }

    return '';
  }

  /// Extracts test results from the text lines.
  ///
  /// Parses standard pathology test result lines with 2-5 columns:
  /// Test Name | Result | [H/L Flag] | [Units] | [Reference Range]
  /// Also handles multi-line formats where data spans 2-3 lines.

  static void extractTestResults(
    List<String> lines,
    Map<String, dynamic> finalJson,
  ) {
    final tests = <Map<String, dynamic>>[];

    // Common test patterns - matches test name, result, H/L flag, units, and range.
    // Pattern examples:
    // "Sodium 140 H mmol/L (135-145)"  (5 columns)
    // "Potassium 4.2 mmol/L (3.5-5.0)"  (4 columns)
    // "TSH 2.1 mU/L"  (3 columns)
    // "eGFR 65 (>60)"  (3 columns, no units)
    // "Result 30 H"  (2 columns with H/L flag)
    // Multi-line format:
    // Line 1: "Bilirubin Total 30 H"
    // Line 2: "(< 21)"
    // Line 3: "umol/L"

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;

      // Try to merge multi-line data if current line looks incomplete.
      // Check if next 1-2 lines might be continuation.

      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();

        // If next line looks like a reference range or units, merge it.

        if (RegExp(r'^\([<>]?[\d.]+-?[\d.]*\)$').hasMatch(nextLine) ||
            RegExp(r'^[a-zA-Zµ°×]+(/[a-zA-Zµ°×0-9.²³]+)*$').hasMatch(nextLine)) {
          line = '$line $nextLine';
          i++; // Skip next line as we've merged it.

          // Check if there's another line to merge (for 3-line format).

          if (i + 1 < lines.length) {
            final thirdLine = lines[i + 1].trim();
            if (RegExp(r'^[a-zA-Zµ°×]+(/[a-zA-Zµ°×0-9.²³]+)*$')
                .hasMatch(thirdLine)) {
              line = '$line $thirdLine';
              i++; // Skip third line as we've merged it.
            }
          }
        }
      }

      final parts =
          line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

      // Standard test result lines have 2-5 main columns, but may have more
      // due to multi-word test names or parenthesised ranges.
      // Skip lines with too few or too many parts.

      if (parts.length < 2 || parts.length > 10) continue;

      // Skip lines that don't start with a letter (uppercase or lowercase).
      // This allows test names like eGFR, pH, etc.

      if (!RegExp(r'^[A-Za-z]').hasMatch(parts[0])) continue;

      // Skip common address patterns and non-test lines.

      final firstWord = parts[0].toLowerCase();
      if (firstWord == 'unit' ||
          firstWord == 'street' ||
          firstWord == 'road' ||
          firstWord == 'avenue' ||
          firstWord == 'po' ||
          firstWord == 'suite' ||
          firstWord == 'level' ||
          firstWord == 'floor' ||
          firstWord == 'ref' ||
          firstWord == 'phone' ||
          firstWord == 'tel' ||
          firstWord == 'fax' ||
          firstWord == 'email') {
        continue;
      }

      // Skip lines containing state/territory codes (ACT, NSW, VIC, etc.).

      if (parts.any((p) =>
          p == 'ACT' ||
          p == 'NSW' ||
          p == 'VIC' ||
          p == 'QLD' ||
          p == 'SA' ||
          p == 'WA' ||
          p == 'TAS' ||
          p == 'NT')) {
        continue;
      }

      // Skip lines that look like phone numbers (contain lots of digits with
      // dashes/spaces).

      final lineStr = parts.join(' ');
      if (RegExp(r'\d{4}[\s-]\d{4}').hasMatch(lineStr) || // Phone pattern.
          RegExp(r'\d{10,}').hasMatch(lineStr) || // Long number sequence.
          lineStr.toLowerCase().contains('ref:') ||
          lineStr.toLowerCase().contains('reference:')) {
        continue;
      }

      // Try to find a numeric value (the result).
      // The result should be in position 1-3 typically.

      String? result;
      int? resultIndex;

      for (var j = 0; j < parts.length && j < 4; j++) {
        var part = parts[j];

        // Check for numeric value (may have < or > prefix).

        final cleanPart = part.replaceAll(RegExp(r'^[<>]'), '');

        if (double.tryParse(cleanPart) != null) {
          result = part; // Keep < or > prefix if present.
          resultIndex = j;
          break;
        }
      }

      if (result == null || resultIndex == null) continue;

      // Result should not be in first position (that's the test name).

      if (resultIndex == 0) continue;

      // Extract test name (everything before the result).

      final testNameParts = parts.sublist(0, resultIndex);
      if (testNameParts.isEmpty) continue;

      final testName = testNameParts.join(' ');

      // Check if test name looks valid (not an address or random text).
      // Valid test names are typically 2-50 characters.

      if (testName.length < 2 || testName.length > 50) continue;

      // Skip if test name contains postal code patterns (4 digits).

      if (RegExp(r'\b\d{4}\b').hasMatch(testName)) continue;

      // Skip if test name contains common address words.

      final testNameLower = testName.toLowerCase();
      if (testNameLower.contains('unit') ||
          testNameLower.contains('street') ||
          testNameLower.contains('road') ||
          testNameLower.contains('avenue') ||
          testNameLower.contains('somewhere') ||
          testNameLower.contains('address') ||
          testNameLower.contains('ref') ||
          testNameLower.contains('phone') ||
          testNameLower.contains('tel')) {
        continue;
      }

      // Check for H/L flag in the next column after result.

      String comment = '';
      int nextIndex = resultIndex + 1;

      if (nextIndex < parts.length) {
        final nextPart = parts[nextIndex];
        if (nextPart == 'H' || nextPart == 'L') {
          comment = nextPart; // Store H or L in comment.
          nextIndex++; // Move to next column.
        }
      }

      // Extract units - look for patterns like mmol/L, g/L, U/L, etc.
      // Units can appear in different positions:
      // - Format 1: Test Name | Result | Units | Reference Range
      // - Format 2: Test Name | Result | H/L | Units | Reference Range
      // We search from the position after the result/flag.

      String units = '';
      int unitsIndex = -1; // Track where we found units.

      if (nextIndex < parts.length) {
        for (var j = nextIndex; j < parts.length; j++) {
          final part = parts[j];

          // Skip if this looks like a reference range (not units).
          // Reference ranges typically contain numeric patterns like "3.5-5.0"
          // or "<10".

          if (RegExp(r'^[<>]?\d+\.?\d*-\d+\.?\d*$').hasMatch(part) ||
              RegExp(r'^\([<>]?\d+\.?\d*-\d+\.?\d*\)$').hasMatch(part) ||
              RegExp(r'^[<>]\d+\.?\d*$').hasMatch(part)) {
            break; // This is reference range, not units.
          }

          // Check if it looks like a unit (contains /, letters, or special chars).
          // Common patterns: mmol/L, g/L, U/L, mL/min, mg/dL, µmol/L, etc.
          // Also allow units like "sec", "min", "hr", "L", "mL", "%".

          if (RegExp(r'^[a-zA-Zµ°×%]+(/[a-zA-Zµ°×0-9.²³]+)*$').hasMatch(part)) {
            units = part;
            unitsIndex = j;
            nextIndex = j + 1; // Update nextIndex for reference range search.
            break;
          }

          // Also check for compound units like "mL/min/1.73m²" or "× 10⁹/L"
          // These contain multiple slashes or special characters.

          if (part.contains('/') && RegExp(r'[a-zA-Z]').hasMatch(part)) {
            units = part;
            unitsIndex = j;
            nextIndex = j + 1;
            break;
          }

          // Check for "x 10^9/L" style units (with multiplication sign).

          if (part == '×' || part.toLowerCase() == 'x') {
            // Combine with next parts for units like "× 10⁹/L".

            final unitParts = <String>[part];
            for (var k = j + 1; k < parts.length && k < j + 3; k++) {
              unitParts.add(parts[k]);
            }
            units = unitParts.join(' ');
            unitsIndex = j;
            nextIndex = j + unitParts.length;
            break;
          }

          // If we've checked 3-4 positions after the result and found nothing,
          // there might be no units (which is valid for some tests like eGFR).

          if (j - nextIndex >= 3) {
            break;
          }
        }
      }

      // Extract reference interval (typically in parentheses or standalone).

      String referenceInterval = '';

      // First try to find range in parentheses.

      final rangePattern1 = RegExp(r'\(([^)]+)\)');
      final rangeMatch1 = rangePattern1.firstMatch(line);
      if (rangeMatch1 != null) {
        referenceInterval = rangeMatch1.group(1)!;
      } else {
        // Look for standalone range pattern like "135-145" or ">60" or "<5.5"
        // Search in the parts after units (or after H/L if no units).

        for (var j = nextIndex; j < parts.length; j++) {
          final part = parts[j];
          if (RegExp(r'^([<>]\s*[\d.]+|[\d.]+-[\d.]+)$').hasMatch(part)) {
            // Make sure this isn't the result itself.

            if (part != result) {
              referenceInterval = part;
              break;
            }
          }
        }
      }

      // Final validation: test must have at least a name and result.
      // Units, reference interval, and comment are all optional.

      if (testName.isNotEmpty && result.isNotEmpty) {
        tests.add({
          'test_name': testName,
          'result': result,
          'units': units,
          'reference_interval': referenceInterval,
          'comment': comment,
        });
      }
    }

    finalJson['tests'] = tests;
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
