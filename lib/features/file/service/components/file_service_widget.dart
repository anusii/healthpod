/// File service widget that provides file upload, download, and preview functionality.
///
// Time-stamp: <Monday 2025-05-13 10:00:00 +1000 Graham Williams>
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'package:healthpod/features/file/browser/page.dart';
import 'package:healthpod/features/file/service/components/file_upload_section.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/update/tab.dart';
import 'package:healthpod/providers/tab_state.dart';

/// The main file service widget that provides file upload, download, and preview functionality.
///
/// This widget composes the individual components for file operations and provides
/// a unified interface for file management.

class FileServiceWidget extends ConsumerStatefulWidget {
  const FileServiceWidget({super.key});

  @override
  ConsumerState<FileServiceWidget> createState() => _FileServiceWidgetState();
}

class _FileServiceWidgetState extends ConsumerState<FileServiceWidget> {
  final _browserKey = GlobalKey<FileBrowserState>();

  /// Navigate to the appropriate folder based on the selected tab.

  void _navigateToFeatureFolder() {
    // Read the selected tab index from the provider.

    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    // Map the index to the corresponding directory name.
    // Note: Ensure these directory names match the actual folder names in the Pod.
    // Using surveyPanels as the source for titles/order.

    String featureDir;
    if (selectedIndex >= 0 && selectedIndex < surveyPanels.length) {
      final title = surveyPanels[selectedIndex]['title'] as String;
      switch (title) {
        case 'Appointments':
          featureDir = 'diary';
          break;
        case 'Blood Pressure':
          featureDir = 'bp';
          break;
        case 'Medications':
          featureDir = 'medication';
          break;
        case 'Vaccinations':
          featureDir = 'vaccination';
          break;
        // Default to root if title doesn't match.

        default:
          featureDir = '';
          break;
      }
    } else {
      // Default to root if index is out of bounds.

      featureDir = '';
    }

    // Construct the full path using forward slashes for Pod compatibility.

    final targetPath =
        featureDir.isNotEmpty ? 'healthpod/data/$featureDir' : 'healthpod/data';

    // Use WidgetsBinding to ensure the browser state is ready.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only update and navigate if the current path is different
      // or if the browser state is available and needs update.

      final currentPath = ref.read(fileServiceProvider).currentPath;
      if (currentPath != targetPath && _browserKey.currentState != null) {
        ref.read(fileServiceProvider.notifier).updateCurrentPath(targetPath);
        _browserKey.currentState?.navigateToPath(targetPath);
      } else if (currentPath != targetPath) {
        // If browser state isn't ready yet, just update the path provider.
        // The browser should pick it up when it initialises.

        ref.read(fileServiceProvider.notifier).updateCurrentPath(targetPath);
      }
    });
  }

  // Helper function to get a user-friendly name from the path.

  String _getFriendlyFolderName(String pathValue) {
    const String root = 'healthpod/data';
    if (pathValue.isEmpty || pathValue == root) {
      return 'Home Folder';
    }

    // Use path.basename to safely get the last component.

    final dirName = path.basename(pathValue);

    switch (dirName) {
      case 'diary':
        return 'Appointments Data';
      case 'bp':
        return 'Blood Pressure Data';
      case 'medication':
        return 'Medication Data';
      case 'vaccination':
        return 'Vaccination Data';
      case 'profile':
        return 'Profile Data';
      case 'health_plan':
        return 'Health Plan Data';
      case 'pathology':
        return 'Pathology Data';

      default:
        // Basic formatting for unknown folders: capitalize first letter, replace underscores.

        if (dirName.isEmpty) return 'Folder';
        String formattedName = dirName.replaceAll('_', ' ');
        formattedName =
            formattedName[0].toUpperCase() + formattedName.substring(1);
        return '$formattedName Data';
    }
  }

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });
      _navigateToFeatureFolder();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigateToFeatureFolder();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a wide screen.

    final isWideScreen = MediaQuery.of(context).size.width > 800;

    // Get current path and friendly name.

    final currentPath =
        ref.watch(fileServiceProvider).currentPath ?? 'healthpod/data';
    final String friendlyFolderName = _getFriendlyFolderName(currentPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button to root folder (now only the button).

        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: TextButton.icon(
            onPressed: () {
              const rootPath = 'healthpod/data';
              if (ref.read(fileServiceProvider).currentPath != rootPath) {
                ref
                    .read(fileServiceProvider.notifier)
                    .updateCurrentPath(rootPath);
                _browserKey.currentState?.navigateToPath(rootPath);
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Home Folder'),
          ),
        ),
        // Main content area.

        Expanded(
          child: SingleChildScrollView(
            child: isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File browser on the left.

                      Expanded(
                        flex: 2,
                        child: Card(
                          margin: const EdgeInsets.only(left: 16, right: 8),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: FileBrowser(
                              key: _browserKey,
                              browserKey: _browserKey,
                              friendlyFolderName: friendlyFolderName,
                              onFileSelected: (fileName, filePath) {
                                ref.read(fileServiceProvider.notifier)
                                  ..setDownloadFile(filePath)
                                  ..setFilePreview(fileName)
                                  ..setRemoteFileName(path.basename(fileName));
                              },
                              onFileDownload: (fileName, filePath) async {
                                ref.read(fileServiceProvider.notifier)
                                  ..setDownloadFile(filePath)
                                  ..setRemoteFileName(path.basename(fileName))
                                  ..handleDownload(context);
                              },
                              onFileDelete: (fileName, filePath) async {
                                // Show confirmation dialog before deleting.

                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text(
                                          'Are you sure you want to delete "$fileName"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (!context.mounted) return;

                                if (confirm == true) {
                                  ref.read(fileServiceProvider.notifier)
                                    ..setRemoteFileName(path.basename(fileName))
                                    ..handleDelete(context);
                                }
                              },
                              onImportCsv: (fileName, filePath) {
                                // Handle CSV import if needed.
                              },
                              onDirectoryChanged: (path) {
                                if (mounted) {
                                  ref
                                      .read(fileServiceProvider.notifier)
                                      .updateCurrentPath(path);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      // Upload section on the right.

                      Expanded(
                        flex: 1,
                        child: Card(
                          margin: const EdgeInsets.only(
                              left: 8, right: 16, top: 16),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: FileUploadSection(),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File browser.

                      Card(
                        margin: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: FileBrowser(
                            key: _browserKey,
                            browserKey: _browserKey,
                            friendlyFolderName: friendlyFolderName,
                            onFileSelected: (fileName, filePath) {
                              ref.read(fileServiceProvider.notifier)
                                ..setDownloadFile(filePath)
                                ..setFilePreview(fileName)
                                ..setRemoteFileName(path.basename(fileName));
                            },
                            onFileDownload: (fileName, filePath) async {
                              ref.read(fileServiceProvider.notifier)
                                ..setDownloadFile(filePath)
                                ..setRemoteFileName(path.basename(fileName))
                                ..handleDownload(context);
                            },
                            onFileDelete: (fileName, filePath) async {
                              // Show confirmation dialog before deleting.

                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                        'Are you sure you want to delete "$fileName"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (!context.mounted) return;

                              if (confirm == true) {
                                ref.read(fileServiceProvider.notifier)
                                  ..setRemoteFileName(path.basename(fileName))
                                  ..handleDelete(context);
                              }
                            },
                            onImportCsv: (fileName, filePath) {
                              // Handle CSV import if needed.
                            },
                            onDirectoryChanged: (path) {
                              if (mounted) {
                                ref
                                    .read(fileServiceProvider.notifier)
                                    .updateCurrentPath(path);
                              }
                            },
                          ),
                        ),
                      ),
                      // Upload section.

                      Card(
                        margin: const EdgeInsets.all(16),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: FileUploadSection(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
