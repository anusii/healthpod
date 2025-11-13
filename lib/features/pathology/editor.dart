/// Pathology reports editor page.
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

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/pathology/model.dart';

/// Editor page for pathology reports.

class PathologyEditorPage extends StatefulWidget {
  const PathologyEditorPage({super.key});

  @override
  State<PathologyEditorPage> createState() => _PathologyEditorPageState();
}

/// Represents a report with its associated tests.

class ReportData {
  final String fileName;
  final DateTime date;
  final List<PathologyTest> tests;

  ReportData({
    required this.fileName,
    required this.date,
    required this.tests,
  });
}

class _PathologyEditorPageState extends State<PathologyEditorPage> {
  List<ReportData> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// Loads pathology reports from the POD.

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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

          DateTime date;
          try {
            // Try to parse date from filename (e.g., report_2024-03-15.pdf).

            final dateRegex = RegExp(r'(\d{4})[_-]?(\d{2})[_-]?(\d{2})');
            final match = dateRegex.firstMatch(pdfName);

            if (match != null) {
              date = DateTime(
                int.parse(match.group(1)!),
                int.parse(match.group(2)!),
                int.parse(match.group(3)!),
              );
            } else {
              // Use current date if no date in filename.

              date = DateTime.now();
            }
          } catch (e) {
            date = DateTime.now();
          }

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
            if (!mounted) break;

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

            String? matchedPdfName;
            for (var pdfName in reportsMap.keys) {
              // Check if JSON filename corresponds to PDF filename.

              if (jsonName.toLowerCase().startsWith(
                      pdfName.toLowerCase().replaceAll('.pdf', ''))) {
                matchedPdfName = pdfName;
                break;
              }
            }

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

      if (mounted) {
        setState(() {
          _reports = reportsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pathology Reports'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.biotech, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            MarkdownBody(
              data:
                  'Please go to Add tab to upload your first pathology report.',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: '**Error details:** $_error',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 12, color: Colors.grey),
                strong: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.biotech, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            MarkdownBody(
              data: 'No pathology reports found.\n\n'
                  'Upload reports using the **Add** tab.',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  /// Builds a card for a single report with its test results.

  Widget _buildReportCard(ReportData report) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header.

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.fileName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${report.date.day.toString().padLeft(2, '0')}/'
                            '${report.date.month.toString().padLeft(2, '0')}/'
                            '${report.date.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Test results section.

          if (report.tests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No test data available for this report',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table header.

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Test Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Result',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Units',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Reference Range',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Test rows.

                  ...report.tests.asMap().entries.map((entry) {
                    final test = entry.value;
                    final isEven = entry.key % 2 == 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : Colors.grey.shade50,
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              test.testName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              test.result,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              test.units,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              test.referenceInterval,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
