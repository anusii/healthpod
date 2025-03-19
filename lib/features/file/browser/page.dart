/// A file browser widget.
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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/browser/components/path_bar.dart';
import 'package:healthpod/features/file/browser/content.dart';
import 'package:healthpod/features/file/browser/loading_state.dart';
import 'package:healthpod/features/file/browser/models/file_item.dart';
import 'package:healthpod/features/file/browser/operations/file_operations.dart';
import 'package:healthpod/features/file/browser/utils/empty_directory_view.dart';

/// A file browser widget to interact with files and directories in user's POD.
///
/// The browser handles the display of files and directories, and allows for
/// navigation and file operations.
///
/// [FileBrowser] is a [StatefulWidget] as it needs to change its contents based
/// on the user's actions, such as navigating directories or refreshing the
/// view.  A few key callbacks are provided to allow for interaction outside
/// this widget, such as selecting a file, downloading a file, and deleting a
/// file.

class FileBrowser extends StatefulWidget {
  /// Callback when a file is selected.

  final Function(String, String) onFileSelected;

  /// Callback when a file is downloaded.

  final Function(String, String) onFileDownload;

  /// Callback when a file is deleted.

  final Function(String, String) onFileDelete;

  /// Callback when the current directory changes.

  final Function(String) onDirectoryChanged;

  /// Callback to handle CSV file imports.

  final Function(String, String) onImportCsv;

  /// Key to access the browser state from outside the widget.

  final GlobalKey<FileBrowserState> browserKey;

  const FileBrowser({
    super.key,
    required this.onFileSelected,
    required this.onFileDownload,
    required this.onFileDelete,
    required this.browserKey,
    required this.onImportCsv,
    required this.onDirectoryChanged,
  });

  @override
  State<FileBrowser> createState() => FileBrowserState();
}

/// State class for the [FileBrowser] widget.
///
/// Manages the browser's state including:
/// - Current directory path and navigation history.
/// - Lists of files and directories.
/// - Loading states and file counts.
/// - File selection state.
///
/// Handles all file operations and navigation logic.

class FileBrowserState extends State<FileBrowser> {
  /// List of files in the current directory.

  List<FileItem> files = [];

  /// List of subdirectories in the current directory.

  List<String> directories = [];

  /// Map of directory names to their file counts.

  Map<String, int> directoryCounts = {};

  /// Whether the browser is currently loading content.

  bool isLoading = true;

  /// The currently selected file name.

  String? selectedFile;

  /// The current directory path being displayed.

  String currentPath = basePath;

  /// History of visited directories for navigation.

  List<String> pathHistory = [basePath];

  /// Number of files in the current directory.

  int currentDirFileCount = 0;

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  /// Navigates into a subdirectory.
  ///
  /// Updates the current path and history, then refreshes the file list.

  Future<void> navigateToDirectory(String dirName) async {
    setState(() {
      currentPath = '$currentPath/$dirName';
      pathHistory.add(currentPath);
    });
    await refreshFiles();
    widget.onDirectoryChanged.call(currentPath);
  }

  /// Navigates up one directory level.
  ///
  /// Removes the last directory from the path history and refreshes the file list.

  Future<void> navigateUp() async {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      setState(() => currentPath = pathHistory.last);
      widget.onDirectoryChanged.call(currentPath);
      await refreshFiles();
    }
  }

  /// Refreshes the current directory's contents.
  ///
  /// Fetches and processes:
  /// - List of files and directories.
  /// - File counts for each subdirectory.
  /// - File metadata and validation.

  Future<void> refreshFiles() async {
    setState(() => isLoading = true);

    try {
      // Get current directory contents.

      final dirUrl = await getDirUrl(currentPath);
      final resources = await getResourcesInContainer(dirUrl);

      if (!mounted) return;

      // Update directories list.

      setState(() => directories = resources.subDirs);

      // Count files in current directory.

      currentDirFileCount =
          resources.files.where((f) => f.endsWith('.enc.ttl')).length;

      // Get file counts for all subdirectories.

      final counts = await FileOperations.getDirectoryCounts(
        currentPath,
        directories,
      );

      if (!mounted) return;

      // Process and validate files.

      final processedFiles = await FileOperations.getFiles(
        currentPath,
        context,
      );

      if (!mounted) return;

      // Update state with processed data.

      setState(() {
        files = processedFiles;
        directoryCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Navigate to a specific path in the file browser
  void navigateToPath(String path) {
    setState(() {
      currentPath = path;
      refreshFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 100,
          maxHeight: MediaQuery.of(context).size.height - 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navigation and path display bar.

            PathBar(
              currentPath: currentPath,
              pathHistory: pathHistory,
              onNavigateUp: navigateUp,
              onRefresh: refreshFiles,
              isLoading: isLoading,
              currentDirFileCount: currentDirFileCount,
            ),

            const SizedBox(height: 12),

            // Main content area with conditional rendering.

            Expanded(
              child: isLoading
                  ? const FileBrowserLoadingState()
                  : directories.isEmpty && files.isEmpty
                      ? const EmptyDirectoryView()
                      : FileBrowserContent(
                          directories: directories,
                          files: files,
                          directoryCounts: directoryCounts,
                          currentPath: currentPath,
                          selectedFile: selectedFile,
                          onDirectorySelected: navigateToDirectory,
                          onFileSelected: (name, path) {
                            setState(() => selectedFile = name);
                            widget.onFileSelected.call(name, path);
                          },
                          onFileDownload: widget.onFileDownload,
                          onFileDelete: widget.onFileDelete,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
