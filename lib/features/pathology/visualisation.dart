/// Pathology reports visualisation page.
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

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/pathology/model.dart';
import 'package:healthpod/features/pathology/pdf_viewer.dart';

/// Widget for displaying pathology reports in a list format.

class PathologyVisualisation extends ConsumerStatefulWidget {
  const PathologyVisualisation({super.key});

  @override
  ConsumerState<PathologyVisualisation> createState() =>
      _PathologyVisualisationState();
}

/// State for the PathologyVisualisation widget.

class _PathologyVisualisationState
    extends ConsumerState<PathologyVisualisation> {
  List<PathologyReport> _reports = [];
  bool _isLoading = true;
  String? _error;
  PathologyReport? _selectedReport;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// Loads pathology reports from the POD.

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pathologyPath = '$basePath/pathology';

      // List files in the pathology directory.

      final dirUrl = await getDirUrl(pathologyPath);
      final resources = await getResourcesInContainer(dirUrl);

      // Parse the result to extract PDF files.

      final List<PathologyReport> reports = [];

      for (var fileName in resources.files) {
        // Extract filename from URL if it's a full URL.

        final name = fileName.contains('/')
            ? Uri.decodeComponent(Uri.parse(fileName).pathSegments.last)
            : Uri.decodeComponent(fileName);

        // Check for encrypted PDF files (.pdf.enc.ttl)
        final isEncryptedPdf = name.toLowerCase().endsWith('.pdf.enc.ttl');
        final isPlainPdf = name.toLowerCase().endsWith('.pdf');

        if (isEncryptedPdf || isPlainPdf) {
          // Extract the original PDF filename.

          final pdfName = isEncryptedPdf
              ? name.substring(0, name.length - '.enc.ttl'.length)
              : name;

          // Try to extract date from filename or use modified date.

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

          reports.add(
            PathologyReport(
              fileName: pdfName, // Display name without .enc.ttl
              date: date,
              filePath: '$pathologyPath/$name', // Actual storage path
            ),
          );
        }
      }

      // Sort reports by date, most recent first.

      reports.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Opens a PDF report for viewing within the current view.

  void _openReport(PathologyReport report) {
    setState(() {
      _selectedReport = report;
    });
  }

  /// Closes the PDF viewer and returns to the list.

  void _closeReport() {
    setState(() {
      _selectedReport = null;
    });
  }

  /// Extracts test results from the currently viewed PDF.

  Future<void> _extractResults() async {
    if (_selectedReport == null) return;

    try {
      // Show loading dialog.

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Extracting PDF content...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Read PDF from POD.

      final result = await readPod(
        _selectedReport!.filePath,
        context,
        const Text('Reading PDF file'),
      );

      if (result == SolidFunctionCallStatus.fail.toString() ||
          result == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to read PDF from POD');
      }

      // Convert result to bytes based on type.

      late List<int> pdfBytes;

      if (result is Uint8List) {
        pdfBytes = result as Uint8List;
      } else if (result is List<int>) {
        pdfBytes = result as List<int>;
      } else if (result is String) {
        // If it's a string, it might be base64 encoded.
        try {
          pdfBytes = base64Decode(result as String);
        } catch (e) {
          debugPrint('PDF decode failed: $e');
          // Try as raw bytes from string.
          pdfBytes = (result as String).codeUnits;
        }
      } else {
        throw Exception('Unrecognized PDF data format');
      }

      // Load PDF document.

      final PdfDocument pdf = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages.

      String text = '';
      for (var i = 0; i < pdf.pages.count; i++) {
        text += PdfTextExtractor(pdf).extractText(startPageIndex: i);
      }

      // Parse text and create JSON structure.

      final lines = text.split('\n');
      final jsonData = _createPathologyJson(lines);

      // Close loading dialog.

      if (mounted) {
        Navigator.pop(context);
      }

      // Upload JSON to POD.

      if (!mounted) return;
      final jsonFileName =
          _selectedReport!.fileName.replaceAll('.pdf', '.json.enc.ttl');
      final jsonPath = '$basePath/pathology/$jsonFileName';

      // Convert JSON to string.

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Write to POD with encryption.

      final writeResult = await writePod(
        jsonPath,
        jsonString,
        context,
        const Text('Uploading JSON file'),
        encrypted: true,
      );

      if (writeResult != SolidFunctionCallStatus.success) {
        throw Exception('Failed to upload JSON file');
      }

      // Show success message.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully extracted and saved results to $jsonFileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open.

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extraction failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Creates pathology JSON structure from extracted text.

  Map<String, dynamic> _createPathologyJson(List<String> lines) {
    final now = DateTime.now();
    final jsonData = {
      'report_name': _selectedReport!.fileName,
      'requested_date': '',
      'collected_time': '',
      'received_time': '',
      'report_upload_date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'laboratory': '',
      'tests': <Map<String, dynamic>>[],
    };

    // Extract metadata and test results.

    _parseExtractedText(lines, jsonData);

    return jsonData;
  }

  /// Parses extracted text and populates the JSON structure.

  void _parseExtractedText(List<String> lines, Map<String, dynamic> jsonData) {
    // Extract only essential metadata.

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Extract dates and times.

      if (line.contains('Collected:') || line.contains('Collection Time:')) {
        final dateTime = _extractAfterColon(line);
        final formatted = _formatDateTime(dateTime);
        if (formatted.isNotEmpty) {
          jsonData['collected_time'] = formatted;
        }
      }

      if (line.contains('Requested:') || line.contains('Request Date:')) {
        final dateStr = _extractAfterColon(line);
        final formatted = _formatDate(dateStr);
        if (formatted.isNotEmpty) {
          jsonData['requested_date'] = formatted;
        }
      }

      if (line.contains('Received:') || line.contains('Received Time:')) {
        final dateTime = _extractAfterColon(line);
        final formatted = _formatDateTime(dateTime);
        if (formatted.isNotEmpty) {
          jsonData['received_time'] = formatted;
        }
      }

      // Extract laboratory name only.

      if (line.contains('Pathology') || line.contains('Laboratory')) {
        if (jsonData['laboratory'].isEmpty) {
          if (line.contains('Lab:')) {
            jsonData['laboratory'] = _extractAfterColon(line);
          } else if (line.contains('Pathology')) {
            jsonData['laboratory'] = line.trim();
          }
        }
      }
    }

    // Extract test results.

    _extractTestResults(lines, jsonData);
  }

  /// Helper method to extract text after colon.

  String _extractAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length >= 2) {
      return parts.sublist(1).join(':').trim();
    }
    return '';
  }

  /// Formats a date string to ISO format.

  String _formatDate(String dateStr) {
    final datePattern = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    final match = datePattern.firstMatch(dateStr);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final month = match.group(2)!.padLeft(2, '0');
      final year = match.group(3);
      return '$year-$month-$day';
    }
    return '';
  }

  /// Formats a date-time string to ISO format.

  String _formatDateTime(String dateTimeStr) {
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

    final dateOnly = _formatDate(dateTimeStr);
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

  void _extractTestResults(List<String> lines, Map<String, dynamic> jsonData) {
    final tests = <Map<String, dynamic>>[];

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
            if (RegExp(r'^[a-zA-Zµ°×]+(/[a-zA-Zµ°×0-9.²³]+)*$').hasMatch(thirdLine)) {
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

      // Skip lines that look like phone numbers (contain lots of digits with dashes/spaces).
      final lineStr = parts.join(' ');
      if (RegExp(r'\d{4}[\s-]\d{4}').hasMatch(lineStr) || // Phone pattern
          RegExp(r'\d{10,}').hasMatch(lineStr) || // Long number sequence
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
      // Units are optional - some tests like eGFR may not have units shown.

      String units = '';

      if (nextIndex < parts.length) {
        for (var j = nextIndex; j < parts.length; j++) {
          final part = parts[j];

          // Skip if this looks like a reference range (not units).
          if (RegExp(r'^[<>]?\d+\.?\d*-\d+\.?\d*$').hasMatch(part) ||
              RegExp(r'^\([<>]?\d+\.?\d*-\d+\.?\d*\)$').hasMatch(part) ||
              RegExp(r'^[<>]\d+\.?\d*$').hasMatch(part)) {
            break; // This is reference range, not units.
          }

          // Check if it looks like a unit (contains /, letters, or special chars).
          // Common patterns: mmol/L, g/L, U/L, mL/min, mg/dL, µmol/L, etc.
          if (RegExp(r'^[a-zA-Zµ°×]+(/[a-zA-Zµ°×0-9.²³]+)*$').hasMatch(part)) {
            units = part;
            nextIndex = j + 1; // Update nextIndex for reference range search.
            break;
          }

          // Also check for compound units like "mL/min/1.73m²" or "× 10⁹/L"
          if (part.contains('/') && RegExp(r'[a-zA-Z]').hasMatch(part)) {
            units = part;
            nextIndex = j + 1;
            break;
          }

          // Check for "x 10^9/L" style units.
          if (part == '×' || part.toLowerCase() == 'x') {
            // Combine with next parts for units like "× 10⁹/L"
            final unitParts = <String>[part];
            for (var k = j + 1; k < parts.length && k < j + 3; k++) {
              unitParts.add(parts[k]);
            }
            units = unitParts.join(' ');
            nextIndex = j + unitParts.length;
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

    jsonData['tests'] = tests;
  }

  @override
  Widget build(BuildContext context) {
    // If a report is selected, show the PDF viewer.

    if (_selectedReport != null) {
      return _buildPdfViewer();
    }

    // Otherwise, show the report list.

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading reports: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MarkdownBody(
                    data: 'Pathology Reports',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const MarkdownTooltip(
                      message: '''
                      
                      **Refresh:** Tap here to reload your pathology reports.
                      
                      ''',
                      child: Icon(Icons.refresh),
                    ),
                    onPressed: _loadReports,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _reports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.biotech,
                              size: 64,
                              color: Colors.grey,
                            ),
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
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              report.fileName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(report.date)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openReport(report),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the PDF viewer for the selected report.

  Widget _buildPdfViewer() {
    return Column(
      children: [
        // Header with back button and file name.

        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to list',
                onPressed: _closeReport,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedReport!.fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Date: ${DateFormat('dd MMMM yyyy').format(_selectedReport!.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _extractResults,
                icon: const Icon(Icons.text_snippet, size: 18),
                label: const Text('Extract Results'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // PDF viewer.

        Expanded(
          child: PathologyPdfViewer(
            fileName: _selectedReport!.fileName,
            filePath: _selectedReport!.filePath,
            showAppBar: false,
          ),
        ),
      ],
    );
  }
}
