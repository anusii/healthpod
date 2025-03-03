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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/file/item.dart';
import 'package:healthpod/utils/view_file_content.dart';

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

  /// Builds a list item widget for displaying a file with its metadata and actions.
  ///
  /// This widget adapts its layout based on available width constraints:
  /// - At < 40px: Shows only the file name
  /// - At 40-100px: Adds file icon with minimal spacing
  /// - At 100-150px: Increases icon spacing
  /// - At > 150px: Shows modification date
  /// - At > 200px: Shows action buttons (download, delete)
  ///
  /// The item supports selection state, showing a highlight when selected.
  /// Action buttons are conditionally rendered based on available space.
  ///
  /// Parameters:
  /// - [file]: The FileItem containing the file's metadata
  /// - [context]: The build context for theming
  ///
  /// Returns a padded, responsive list item widget with the file's information
  /// and available actions.

  Widget _buildFileListItem(FileItem file, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Define minimum width threshold for showing action buttons.

          const minWidthForButtons = 200;
          final showButtons = constraints.maxWidth >= minWidthForButtons;

          return InkWell(
            onTap: () {
              // Update selection state and notify parent.

              setState(() {
                selectedFile = file.name;
              });
              widget.onFileSelected.call(file.name, currentPath);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              // Apply selection highlighting using theme colours.

              decoration: BoxDecoration(
                color: selectedFile == file.name
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withAlpha(10)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              // Adjust horizontal padding based on available width.

              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 50 ? 4 : 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show file icon only if width permits.

                  if (constraints.maxWidth > 40)
                    Icon(
                      Icons.insert_drive_file,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  // Responsive spacing after icon.

                  if (constraints.maxWidth > 40)
                    SizedBox(width: constraints.maxWidth < 100 ? 4 : 12),
                  // File information column.

                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File name with overflow protection.

                        Text(
                          file.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Show modification date if width permits.

                        if (constraints.maxWidth > 150)
                          Text(
                            'Modified: ${file.dateModified.toString().split('.')[0]}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Action buttons shown only if sufficient width.

                  if (showButtons) ...[
                    const SizedBox(width: 8),
                    // Preview button.

                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.preview,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        // Capture the current BuildContext.
                        
                        final BuildContext contextCopy = context;

                        // Wrapper function to handle the async operations.

                        void handlePdfPreview() async {
                          // Retrieve the PDF file content as a base64-encoded string.

                          final String fileContent =
                              await getFileContent(file.path, contextCopy);

                          // Decode the base64 string into raw PDF bytes.

                          final Uint8List pdfBytes = base64Decode(fileContent);

                          // Check if the BuildContext is still valid before using it.

                          if (!contextCopy.mounted) return;

                          // Use the verified context.

                          showDialog(
                            context: contextCopy,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text("File Preview"),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 500,
                                child: PdfPreview(
                                  build: (PdfPageFormat format) async =>
                                      pdfBytes,
                                  canChangeOrientation: false,
                                  canChangePageFormat: false,
                                  allowPrinting: false,
                                  allowSharing: false,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        }

                        // Call the wrapper function.
                        
                        handlePdfPreview();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(10),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(35, 35),
                      ),
                    ),

                    smallGapH,
                    // Download button.

                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.download,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () =>
                          widget.onFileDownload.call(file.name, currentPath),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(10),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(35, 35),
                      ),
                    ),
                    smallGapH,
                    // Delete button.

                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () =>
                          widget.onFileDelete.call(file.name, currentPath),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error.withAlpha(10),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(35, 35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (pathHistory.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: navigateUp,
                          tooltip: 'Go up',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(10),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentPath,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: refreshFiles,
                        tooltip: 'Refresh',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(10),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  // Display current directory file count below path bar.

                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Files in current directory: $currentDirFileCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
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
                            if (directories.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Folders',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...directories.map((dir) => ListTile(
                                    leading: Icon(
                                      Icons.folder,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            dir,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        // Display file count badge for each directory.

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(10),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            // Show file count from directoryCounts map.

                                            '${directoryCounts[dir] ?? 0} files',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    onTap: () => navigateToDirectory(dir),
                                  )),
                              if (files.isNotEmpty)
                                Divider(
                                  height: 24,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withAlpha(20),
                                ),
                            ],
                            if (files.isNotEmpty) ...[
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...files.map(
                                  (file) => _buildFileListItem(file, context)),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
