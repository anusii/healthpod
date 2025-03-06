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

import 'package:healthpod/features/file/models/file_item.dart';
import 'package:healthpod/features/file/components/path_bar.dart';
import 'package:healthpod/features/file/operations/file_operations.dart';
import 'package:healthpod/features/file/utils/empty_directory_view.dart';
import 'package:healthpod/features/file/browser/loading_state.dart';
import 'package:healthpod/features/file/browser/content.dart';

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
  Map<String, int> directoryCounts = {};
  bool isLoading = true;
  String? selectedFile;
  String currentPath = 'healthpod/data';
  List<String> pathHistory = ['healthpod/data'];
  int currentDirFileCount = 0;

  @override
  void initState() {
    super.initState();
    refreshFiles();
  }

  Future<void> navigateToDirectory(String dirName) async {
    setState(() {
      currentPath = '$currentPath/$dirName';
      pathHistory.add(currentPath);
    });
    await refreshFiles();
    widget.onDirectoryChanged.call(currentPath);
  }

  Future<void> navigateUp() async {
    if (pathHistory.length > 1) {
      pathHistory.removeLast();
      setState(() => currentPath = pathHistory.last);
      widget.onDirectoryChanged.call(currentPath);
      await refreshFiles();
    }
  }

  Future<void> refreshFiles() async {
    setState(() => isLoading = true);

    try {
      final dirUrl = await getDirUrl(currentPath);
      final resources = await getResourcesInContainer(dirUrl);

      if (!mounted) return;

      setState(() => directories = resources.subDirs);

      currentDirFileCount =
          resources.files.where((f) => f.endsWith('.enc.ttl')).length;

      final counts = await FileOperations.getDirectoryCounts(
        currentPath,
        directories,
      );

      final processedFiles = await FileOperations.getFiles(
        currentPath,
        context,
      );

      if (!mounted) return;

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
