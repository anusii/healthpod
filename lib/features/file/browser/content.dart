/// A content widget for the file browser.
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

import 'package:healthpod/features/file/browser/components/directory_list.dart';
import 'package:healthpod/features/file/browser/components/file_list.dart';
import 'package:healthpod/features/file/browser/models/file_item.dart';

/// A widget that displays the main content of the file browser.
///
/// The content includes:
/// - List of directories with their file counts.
/// - List of files with their metadata and actions.
/// - Visual separation between directories and files.
///
/// The widget coordinates the display of directories and files,
/// handling the layout and visual hierarchy of the browser content.

class FileBrowserContent extends StatelessWidget {
  /// List of directory names to display.

  final List<String> directories;

  /// List of files to display.

  final List<FileItem> files;

  /// Map of directory names to their file counts.

  final Map<String, int> directoryCounts;

  /// The current directory path.

  final String currentPath;

  /// The currently selected file name.

  final String? selectedFile;

  /// Callback when a directory is selected.

  final Function(String) onDirectorySelected;

  /// Callback when a file is selected.

  final Function(String, String) onFileSelected;

  /// Callback when a file is downloaded.

  final Function(String, String) onFileDownload;

  /// Callback when a file is deleted.

  final Function(String, String) onFileDelete;

  const FileBrowserContent({
    super.key,
    required this.directories,
    required this.files,
    required this.directoryCounts,
    required this.currentPath,
    required this.selectedFile,
    required this.onDirectorySelected,
    required this.onFileSelected,
    required this.onFileDownload,
    required this.onFileDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Display directory list at the top.

        DirectoryList(
          directories: directories,
          directoryCounts: directoryCounts,
          onDirectorySelected: onDirectorySelected,
        ),

        // Add visual separator if both directories and files exist.

        if (directories.isNotEmpty && files.isNotEmpty)
          Divider(
            height: 24,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).dividerColor.withAlpha(20),
          ),

        // Display file list below directories.

        FileList(
          files: files,
          currentPath: currentPath,
          selectedFile: selectedFile,
          onFileSelected: onFileSelected,
          onFileDownload: onFileDownload,
          onFileDelete: onFileDelete,
        ),
      ],
    );
  }
}
