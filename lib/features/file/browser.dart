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

import 'package:healthpod/features/file/directory_list.dart';
import 'package:healthpod/features/file/file_list.dart';
import 'package:healthpod/features/file/item.dart';
import 'package:healthpod/features/file/path_bar.dart';

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
  final Function(String, String) onFileSelected;
  final Function(String, String) onFileDownload;
  final Function(String, String) onFileDelete;
  final Function(String) onDirectoryChanged;

  /// Callback to handle CSV file imports.

  final Function(String, String) onImportCsv;

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

/// State variables for the [FileBrowser].

class FileBrowserState extends State<FileBrowser> {
  List<FileItem> files = [];
  List<String> directories = [];

  /// Store directory file counts.

  Map<String, int> directoryCounts = {};

  bool isLoading = true;
  String? selectedFile;
  String currentPath = 'healthpod/data';
  List<String> pathHistory = ['healthpod/data'];

  /// Total files in current directory.

  int currentDirFileCount = 0;

  final smallGapH = const SizedBox(width: 10);

  /// As the widget initialises, we fetch the file list.

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  /// When a user clicks a directory, we navigate deeper into it.

  Future<void> navigateToDirectory(String dirName) async {
    setState(() {
      currentPath = '$currentPath/$dirName';
      pathHistory.add(currentPath);
    });
    await refreshFiles();

    // Notify parent about directory change.

    widget.onDirectoryChanged.call(currentPath);
  }

  /// Navigate up by removing the last directory from the path history.

  Future<void> navigateUp() async {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      setState(() {
        currentPath = pathHistory.last;

        // Notify parent about directory change.

        widget.onDirectoryChanged.call(currentPath);
      });
      await refreshFiles();
    }
  }

  /// Get file count for a specific directory.

  Future<int> getDirectoryFileCount(String dirPath) async {
    try {
      final dirUrl = await getDirUrl(dirPath);
      final resources = await getResourcesInContainer(dirUrl);

      // Only count files that match our encryption extension pattern.

      return resources.files.where((f) => f.endsWith('.enc.ttl')).length;
    } catch (e) {
      debugPrint('Error counting files in directory: $e');
      return 0; // Return 0 on error to maintain UI stability.
    }
  }

  /// The core of the file browser, fetch the list of directories and files,
  /// processing each file for metadata.

  Future<void> refreshFiles() async {
    // Set loading state to show progress indicator.

    setState(() {
      isLoading = true;
    });

    try {
      // Get current directory URL and its resources.

      final dirUrl = await getDirUrl(currentPath);
      final resources = await getResourcesInContainer(dirUrl);

      if (!mounted) return;

      // Update directories list immediately.

      setState(() {
        directories = resources.subDirs;
      });

      // Count files in current directory.

      currentDirFileCount =
          resources.files.where((f) => f.endsWith('.enc.ttl')).length;

      // Get file counts for each subdirectory.

      final counts = <String, int>{};
      for (var dir in directories) {
        counts[dir] = await getDirectoryFileCount('$currentPath/$dir');
      }

      // Process and validate files.

      final processedFiles = <FileItem>[];

      for (var fileName in resources.files) {
        // Filter for .enc.ttl files while preserving the full extension.
        // This ensures we only show encrypted turtle files that our app can handle.

        if (!fileName.endsWith('.enc.ttl')) {
          continue;
        }

        // Construct the full path for the file.

        final relativePath = '$currentPath/$fileName';

        // Validate file accessibility and metadata.
        // This step ensures we only display files that are properly formatted
        // and accessible to the current user.

        if (!mounted) return;

        final metadata = await readPod(
          relativePath,
          context,
          const Text('Reading file info'),
        );

        // Only add files that pass validation.
        // This prevents displaying corrupt or inaccessible files.

        if (metadata != SolidFunctionCallStatus.fail &&
            metadata != SolidFunctionCallStatus.notLoggedIn) {
          processedFiles.add(FileItem(
            name: fileName, // Use complete filename with extension
            path: relativePath,
            dateModified: DateTime.now(),
          ));
        }
      }

      // Update UI with processed files.

      setState(() {
        files = processedFiles;
        directoryCounts = counts; // Store the directory counts.
        isLoading = false;
      });
    } catch (e) {
      // Handle any errors during the refresh process.

      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
            PathBar(
              currentPath: currentPath,
              pathHistory: pathHistory,
              onNavigateUp: navigateUp,
              onRefresh: refreshFiles,
              isLoading: isLoading,
              currentDirFileCount: currentDirFileCount,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : directories.isEmpty && files.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(50),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'This folder is empty',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            DirectoryList(
                              directories: directories,
                              directoryCounts: directoryCounts,
                              onDirectorySelected: navigateToDirectory,
                            ),
                            if (directories.isNotEmpty && files.isNotEmpty)
                              Divider(
                                height: 24,
                                indent: 16,
                                endIndent: 16,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withAlpha(20),
                              ),
                            FileList(
                              files: files,
                              currentPath: currentPath,
                              selectedFile: selectedFile,
                              onFileSelected: (name, path) {
                                setState(() {
                                  selectedFile = name;
                                });
                                widget.onFileSelected.call(name, path);
                              },
                              onFileDownload: widget.onFileDownload,
                              onFileDelete: widget.onFileDelete,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
