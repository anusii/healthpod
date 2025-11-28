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
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/pathology/llm_service.dart';
import 'package:healthpod/features/pathology/model.dart';
import 'package:healthpod/features/pathology/pdf_viewer.dart';
import 'package:healthpod/features/pathology/widgets/pdf_viewer_header.dart';
import 'package:healthpod/features/pathology/widgets/report_list_item.dart';

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

  /// Extracts test results from the currently viewed PDF using LLM.

  Future<void> _extractResults() async {
    if (_selectedReport == null) return;

    // Show confirmation dialog before proceeding.

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    try {
      // Show loading dialogue.

      _showLoadingDialog(
        'Analysing report...',
      );

      // Read PDF bytes from POD.

      final pdfBytes = await _readPdfFromPod();

      // Create temporary file for the PDF.

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await tempFile.writeAsBytes(pdfBytes);

      try {
        // Send PDF to Python server for complete processing.

        final llmService = PathologyLLMService(
          baseUrl: 'http://localhost:8000',
          timeout: const Duration(seconds: 900), // 15 minutes
        );

        final jsonData = await llmService.analysePdf(tempFile);

        // Close loading dialog.

        if (mounted) {
          Navigator.pop(context);
        }

        // Upload JSON to POD.

        await _uploadJsonToPod(jsonData);

        // Show completion dialog.

        await _showCompletionDialog(jsonData);
      } finally {
        // Clean up temporary file.

        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      _handleExtractionError(e);
    }
  }

  /// Shows a confirmation dialogue before sending data to server.

  Future<bool> _showConfirmationDialog() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Data Processing Confirmation'),
        content: const Text(
          'The report will be sent to the analysis server for processing.\n\n'
          'Do you wish to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Shows a completion dialogue after extraction is finished.

  Future<void> _showCompletionDialog(Map<String, dynamic> jsonData) async {
    if (!mounted) return;

    final testCount = jsonData['tests']?.length ?? 0;
    final jsonFileName =
        _selectedReport!.fileName.replaceAll('.pdf', '.json.enc.ttl');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extraction Complete'),
        content: Text(
          'Successfully extracted $testCount tests and saved to $jsonFileName.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialogue with a message.

  void _showLoadingDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Reads PDF bytes from POD.

  Future<List<int>> _readPdfFromPod() async {
    final result = await readPod(
      _selectedReport!.filePath,
      context,
      const Text('Reading PDF file'),
    );

    if (result == SolidFunctionCallStatus.fail.toString() ||
        result == SolidFunctionCallStatus.notLoggedIn.toString()) {
      throw Exception('Failed to read PDF from POD');
    }

    return _convertToBytes(result);
  }

  /// Converts various byte formats to List(int).

  List<int> _convertToBytes(dynamic result) {
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

        return (result as String).codeUnits;
      }
    }
  }

  /// Uploads JSON data to POD.

  Future<void> _uploadJsonToPod(Map<String, dynamic> jsonData) async {
    if (!mounted) return;

    final jsonFileName =
        _selectedReport!.fileName.replaceAll('.pdf', '.json.enc.ttl');
    final jsonPath = '$basePath/pathology/$jsonFileName';

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

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
  }

  /// Handles extraction errors.

  void _handleExtractionError(Object error) {
    // Close loading dialogue if open.

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show error message.

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extraction failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
                        return ReportListItem(
                          report: report,
                          onTap: () => _openReport(report),
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
        PdfViewerHeader(
          report: _selectedReport!,
          onBack: _closeReport,
          onExtract: _extractResults,
        ),
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
