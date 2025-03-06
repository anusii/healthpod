/// A widget for displaying file operation status.
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

import 'package:flutter/material.dart';

/// A widget that displays the current status of file operations.
///
/// Shows a progress indicator and status text when any operation
/// (upload, download, delete, import) is in progress.

class OperationStatus extends StatelessWidget {
  /// Whether a file upload is in progress.
  final bool uploadInProgress;

  /// Whether a file download is in progress.
  final bool downloadInProgress;

  /// Whether a file deletion is in progress.
  final bool deleteInProgress;

  /// Whether a CSV import is in progress.
  final bool importInProgress;

  const OperationStatus({
    super.key,
    required this.uploadInProgress,
    required this.downloadInProgress,
    required this.deleteInProgress,
    required this.importInProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (!uploadInProgress &&
        !downloadInProgress &&
        !deleteInProgress &&
        !importInProgress) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const SizedBox(width: 16),
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          uploadInProgress
              ? 'Uploading...'
              : downloadInProgress
                  ? 'Downloading...'
                  : importInProgress
                      ? 'Importing...'
                      : 'Deleting...',
          style: const TextStyle(
            color: Colors.blue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
} 