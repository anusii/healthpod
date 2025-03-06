/// A widget for handling file uploads.
///
/// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'package:healthpod/features/file/service/components/preview_card.dart';

/// A widget that handles file upload functionality.
///
/// Provides:
/// - File selection via file picker
/// - File preview before upload
/// - Upload button with progress indication
/// - Success/failure feedback

class UploadPanel extends StatelessWidget {
  /// The currently selected file path.
  final String? uploadFile;

  /// Whether a file upload is in progress.
  final bool uploadInProgress;

  /// Whether the last upload was successful.
  final bool uploadDone;

  /// Callback when a file is selected.
  final Function(String) onFileSelected;

  /// Callback when upload is initiated.
  final VoidCallback onUpload;

  /// Callback when preview is requested.
  final VoidCallback onPreview;

  const UploadPanel({
    super.key,
    required this.uploadFile,
    required this.uploadInProgress,
    required this.uploadDone,
    required this.onFileSelected,
    required this.onUpload,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preview card if a file is selected.
        if (uploadFile != null) PreviewCard(filePath: uploadFile!),
        const SizedBox(height: 16),

        // Selected file info container.
        if (uploadFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.file_present,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path.basename(uploadFile!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (uploadDone)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // File selection and upload buttons.
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    onFileSelected(result.files.single.path!);
                  }
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Select File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (uploadFile == null || uploadInProgress)
                    ? null
                    : onUpload,
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Preview button.
        TextButton.icon(
          onPressed: (uploadFile == null || uploadInProgress)
              ? null
              : onPreview,
          icon: const Icon(Icons.preview),
          label: const Text('Preview File'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
} 