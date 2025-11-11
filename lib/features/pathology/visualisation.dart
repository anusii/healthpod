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

import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/pathology/pdf_viewer.dart';

/// Widget for displaying pathology reports in a list format.

class PathologyVisualisation extends StatefulWidget {
  const PathologyVisualisation({super.key});

  @override
  State<PathologyVisualisation> createState() => _PathologyVisualisationState();
}

/// Represents a pathology report file.

class PathologyReport {
  final String fileName;
  final DateTime date;
  final String filePath;

  PathologyReport({
    required this.fileName,
    required this.date,
    required this.filePath,
  });
}

/// State for the PathologyVisualisation widget.

class _PathologyVisualisationState extends State<PathologyVisualisation> {
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
                color: Colors.black.withOpacity(0.1),
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
