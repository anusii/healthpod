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

import 'package:healthpod/features/pathology/model.dart';
import 'package:healthpod/features/pathology/service.dart';
import 'package:healthpod/features/pathology/widgets/report_card.dart';

/// Editor page for pathology reports.

class PathologyEditorPage extends StatefulWidget {
  const PathologyEditorPage({super.key});

  @override
  State<PathologyEditorPage> createState() => _PathologyEditorPageState();
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
      final reports = await PathologyService.loadReports(context);

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
      return _buildErrorState();
    }

    if (_reports.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        return PathologyReportCard(report: _reports[index]);
      },
    );
  }

  /// Builds the error state view.

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.biotech, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          MarkdownBody(
            data: 'Please go to Add tab to upload your first pathology report.',
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

  /// Builds the empty state view.

  Widget _buildEmptyState() {
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
}
