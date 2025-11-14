/// Pathology data service.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/pathology/model.dart';

/// Service for loading and managing pathology report data.

class PathologyService {
  /// Loads pathology reports from the POD.
  ///
  /// Returns a list of [ReportData] objects sorted by date (most recent first).
  ///
  /// Note: BuildContext is used for POD operations which may span async gaps.
  /// The caller should verify context.mounted before calling this method.

  static Future<List<ReportData>> loadReports(BuildContext context) async {
    // Verify context is valid at method start.

    if (!context.mounted) return [];
    final pathologyPath = '$basePath/pathology';

    // List files in the pathology directory.

    final dirUrl = await getDirUrl(pathologyPath);
    final resources = await getResourcesInContainer(dirUrl);

    // Parse the result to extract report files and their associated test data.

    final Map<String, ReportData> reportsMap = {};

    // First, find all PDF files (reports).

    for (var fileName in resources.files) {
      final name = fileName.contains('/')
          ? Uri.decodeComponent(Uri.parse(fileName).pathSegments.last)
          : Uri.decodeComponent(fileName);

      // Check for encrypted PDF files (.pdf.enc.ttl) or plain PDF files.

      final isEncryptedPdf = name.toLowerCase().endsWith('.pdf.enc.ttl');
      final isPlainPdf = name.toLowerCase().endsWith('.pdf');

      if (isEncryptedPdf || isPlainPdf) {
        // Extract the original PDF filename.

        final pdfName = isEncryptedPdf
            ? name.substring(0, name.length - '.enc.ttl'.length)
            : name;

        // Try to extract date from filename or use current date.

        final date = _extractDateFromFilename(pdfName);

        // Initialise report with empty test list.

        reportsMap[pdfName] = ReportData(
          fileName: pdfName,
          date: date,
          tests: [],
        );
      }
    }

    // Then, find JSON files and associate them with reports.

    for (var fileName in resources.files) {
      final name = fileName.contains('/')
          ? Uri.decodeComponent(Uri.parse(fileName).pathSegments.last)
          : Uri.decodeComponent(fileName);

      // Check for encrypted JSON files (.json.enc.ttl) or plain JSON files.

      final isEncryptedJson = name.toLowerCase().endsWith('.json.enc.ttl');
      final isPlainJson = name.toLowerCase().endsWith('.json');

      if (isEncryptedJson || isPlainJson) {
        try {
          // Check context validity before async operation.

          if (!context.mounted) {
            // Return what we have so far.

            final currentReports = reportsMap.values.toList();
            currentReports.sort((a, b) => b.date.compareTo(a.date));
            return currentReports;
          }

          // Extract the original JSON filename (without .enc.ttl if encrypted).

          final jsonName = isEncryptedJson
              ? name.substring(0, name.length - '.enc.ttl'.length)
              : name;

          // Read and parse the JSON file (readPod handles decryption).

          final filePath = '$pathologyPath/$name';
          final content = await readPod(
            filePath,
            context,
            const Text('Loading pathology data'),
          );

          // Skip if read failed or returned TTL format (decryption failed).

          if (content.isEmpty ||
              content == SolidFunctionCallStatus.fail.toString() ||
              content == SolidFunctionCallStatus.notLoggedIn.toString() ||
              content.trim().startsWith('@prefix')) {
            debugPrint('Failed to read or decrypt JSON file: $name');
            continue;
          }

          // Parse the JSON content.

          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          // Extract test data from JSON.

          final reportName = jsonData['report_name'] ?? jsonName;
          final testsList = jsonData['tests'] as List<dynamic>?;

          final List<PathologyTest> tests = [];
          if (testsList != null) {
            for (var test in testsList) {
              tests.add(PathologyTest.fromJson(test, reportName));
            }
          }

          // Try to match JSON file to a PDF report.

          final matchedPdfName = _findMatchingPdf(jsonName, reportsMap.keys);

          if (matchedPdfName != null) {
            // Add tests to the matched report.

            reportsMap[matchedPdfName] = ReportData(
              fileName: reportsMap[matchedPdfName]!.fileName,
              date: reportsMap[matchedPdfName]!.date,
              tests: tests,
            );
            debugPrint(
              'Matched JSON data to PDF: $jsonName -> $matchedPdfName',
            );
          }
          // If JSON file doesn't match any PDF, skip it.
          // Only PDF files should be displayed as reports.
        } catch (e) {
          // Skip files that can't be parsed.

          debugPrint('Error parsing JSON file $name: $e');
          continue;
        }
      }
    }

    // Convert map to list and sort by date, most recent first.

    final reportsList = reportsMap.values.toList();
    reportsList.sort((a, b) => b.date.compareTo(a.date));

    return reportsList;
  }

  /// Extracts date from filename or returns current date.

  static DateTime _extractDateFromFilename(String filename) {
    try {
      // Try to parse date from filename (e.g., report_2024-03-15.pdf).

      final dateRegex = RegExp(r'(\d{4})[_-]?(\d{2})[_-]?(\d{2})');
      final match = dateRegex.firstMatch(filename);

      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    } catch (e) {
      debugPrint('Error extracting date from filename: $e');
    }

    // Use current date if no date in filename.

    return DateTime.now();
  }

  /// Finds a matching PDF filename for the given JSON filename.

  static String? _findMatchingPdf(String jsonName, Iterable<String> pdfNames) {
    for (var pdfName in pdfNames) {
      // Check if JSON filename corresponds to PDF filename.

      if (jsonName.toLowerCase().startsWith(
            pdfName.toLowerCase().replaceAll('.pdf', ''),
          )) {
        return pdfName;
      }
    }
    return null;
  }
}
