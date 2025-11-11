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

class _PathologyEditorPageState extends State<PathologyEditorPage> {
  List<PathologyReport> _reports = [];
  bool _isLoading = true;
  String? _error;

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

        // Check for encrypted PDF files (.pdf.enc.ttl).
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
              fileName: pdfName,
              date: date,
              filePath: '$pathologyPath/$name',
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
              data:
                  'No pathology reports found.\n\nUpload reports using the **Add** tab.',
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Report Filename')),
          ],
          rows: List<DataRow>.generate(_reports.length, (index) {
            final report = _reports[index];

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '${report.date.year}-${report.date.month.toString().padLeft(2, '0')}-${report.date.day.toString().padLeft(2, '0')}',
                  ),
                ),
                DataCell(
                  Text(report.fileName),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
