/// Pathology report upload interface.
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

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';

/// A page for uploading pathology reports in PDF format.

class PathologySurvey extends ConsumerStatefulWidget {
  const PathologySurvey({super.key});

  @override
  ConsumerState<PathologySurvey> createState() => _PathologySurveyState();
}

class _PathologySurveyState extends ConsumerState<PathologySurvey> {
  bool _isUploading = false;

  /// Handles the PDF file upload.

  Future<void> _handlePdfUpload() async {
    try {
      // Pick a PDF file.

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _isUploading = true;
          });

          // Navigate to pathology directory if not already there.

          final currentPath = ref.read(fileServiceProvider).currentPath;
          final pathologyPath = '$basePath/pathology';

          if (currentPath != pathologyPath) {
            ref
                .read(fileServiceProvider.notifier)
                .updateCurrentPath(pathologyPath);
          }

          // Upload the PDF file.

          ref.read(fileServiceProvider.notifier).setUploadFile(file.path);

          if (mounted) {
            await ref
                .read(fileServiceProvider.notifier)
                .handleUpload(context);
          }

          setState(() {
            _isUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pathology report uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.biotech,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Upload Pathology Report',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload your pathology reports in PDF format to securely store them in your health pod.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _handlePdfUpload,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select PDF File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 16),
              const Text(
                'Supported format: PDF',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
