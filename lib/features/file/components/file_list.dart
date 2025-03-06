/// A file list widget for displaying files.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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

import 'package:healthpod/features/file/components/file_list_item.dart';
import 'package:healthpod/features/file/models/item.dart';

/// A widget that displays a list of files with their metadata and actions.
///
/// The list includes:
/// - Section header for files.
/// - List of file items with metadata.
/// - Selection state handling.
/// - File operations (download, delete).
///
/// The widget handles empty states and coordinates file selection
/// and operations through callbacks.

class FileList extends StatelessWidget {
  /// List of files to display.

  final List<FileItem> files;

  /// The current directory path.

  final String currentPath;

  /// The currently selected file name.

  final String? selectedFile;

  /// Callback when a file is selected.

  final Function(String, String) onFileSelected;

  /// Callback when a file is downloaded.

  final Function(String, String) onFileDownload;

  /// Callback when a file is deleted.

  final Function(String, String) onFileDelete;

  const FileList({
    super.key,
    required this.files,
    required this.currentPath,
    required this.selectedFile,
    required this.onFileSelected,
    required this.onFileDownload,
    required this.onFileDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty widget if no files to display.

    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header for files.

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Text(
            'Files',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        // List of file items.

        ...files.map((file) => FileListItem(
              file: file,
              currentPath: currentPath,
              isSelected: selectedFile == file.name,
              onFileSelected: onFileSelected,
              onFileDownload: onFileDownload,
              onFileDelete: onFileDelete,
            )),
      ],
    );
  }
}
