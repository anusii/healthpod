/// File management content widget for the home screen.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/home/widgets/pdf_processor.dart';
import 'package:healthpod/providers/tab_state.dart';

/// File management content widget using SolidFile.

class FileManagementContent extends ConsumerStatefulWidget {
  /// Callback function to handle import success navigation.

  final Function(String importType)? onImportSuccess;

  /// Flag to track whether the user has ever actively selected a feature tab.

  final bool hasUserSelectedFeatureTab;

  const FileManagementContent({
    super.key,
    this.onImportSuccess,
    required this.hasUserSelectedFeatureTab,
  });

  @override
  ConsumerState<FileManagementContent> createState() =>
      _FileManagementContentState();
}

class _FileManagementContentState extends ConsumerState<FileManagementContent> {
  final GlobalKey<SolidFileBrowserState> _browserKey = GlobalKey();

  /// Flag to track whether the user has manually navigated to a different
  /// folder. If true, we won't override the user's choice with tab
  /// coordination.

  bool _userHasManuallyNavigated = false;

  /// Track the last tab index we coordinated with to avoid redundant
  /// navigation.

  int? _lastCoordinatedTabIndex;

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });

      // Check if we should navigate to a specific folder based on current tab
      // selection, but only if user has actively selected a feature tab.

      final currentTabIndex = ref.read(tabStateProvider).selectedIndex;
      String initialPath = basePath;

      // Map tab index to directory only if we're coordinating with other tabs
      // and the user has actually selected a feature tab.

      if (!_userHasManuallyNavigated && widget.hasUserSelectedFeatureTab) {
        switch (currentTabIndex) {
          case 0:
            initialPath = '$basePath/diary'; // Appointments
            break;
          case 1:
            initialPath = '$basePath/blood_pressure'; // Blood Pressure
            break;
          case 2:
            initialPath = '$basePath/medication'; // Medications
            break;
          case 3:
            initialPath = '$basePath/vaccination'; // Vaccinations
            break;
          default:
            initialPath = basePath; // Default to home
            break;
        }
      }

      // Initialise to the appropriate folder.

      Future(() {
        ref.read(fileServiceProvider.notifier).updateCurrentPath(initialPath);
        if (initialPath != basePath) {
          _browserKey.currentState?.navigateToPath(initialPath);
        }

        // Update the coordinated tab index to avoid conflicts.

        _lastCoordinatedTabIndex = currentTabIndex;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Navigates to the feature-specific folder based on the current tab
  /// selection.

  void _navigateToFeatureFolder() {
    // If the user has manually navigated, don't override their choice.

    if (_userHasManuallyNavigated) {
      return;
    }

    // Read the selected tab index from the provider to coordinate with other
    // tabs.

    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    // Map the tab index to the corresponding directory name.
    // Index 0: Appointments → diary
    // Index 1: Blood Pressure → blood_pressure
    // Index 2: Medications → medication
    // Index 3: Vaccinations → vaccination

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    final targetPath =
        featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
    final currentPath = ref.read(fileServiceProvider).currentPath ?? basePath;
    if (currentPath != targetPath) {
      ref.read(fileServiceProvider.notifier).updateCurrentPath(targetPath);
      _browserKey.currentState?.navigateToPath(targetPath);
    }
  }

  /// Gets the expected path for the current tab selection.

  String _getExpectedPathForCurrentTab() {
    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    return featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
  }

  /// Creates upload callbacks.

  SolidFileUploadCallbacks _createUploadCallbacks(String currentPath) {
    Map<String, bool> computeDirectoryFlags() {
      final livePath = ref.read(fileServiceProvider).currentPath ?? basePath;
      final isInBpDirectory = livePath.contains('/blood_pressure');
      final isInVaccinationDirectory = livePath.contains('/vaccination');
      final isInMedicationDirectory = livePath.contains('/medication');
      final isInDiaryDirectory = livePath.contains('/diary');

      return {
        'isVaccination': isInVaccinationDirectory,
        'isMedication': isInMedicationDirectory,
        'isDiary': isInDiaryDirectory,
        'isBloodPressure': isInBpDirectory,
      };
    }

    bool inProfileDirectory() {
      final livePath = ref.read(fileServiceProvider).currentPath ?? basePath;
      return livePath.contains('/profile');
    }

    return SolidFileUploadCallbacks(
      onUpload: () => _handleFileUpload(),
      onImportCsv: () => _handleCsvImport(computeDirectoryFlags()),
      onExportCsv: () => _handleCsvExport(computeDirectoryFlags()),
      onImportSuccess: _handleImportSuccess,
      onImportProfile: () {
        if (inProfileDirectory()) _handleProfileImport();
      },
      onExportProfile: () {
        if (inProfileDirectory()) _handleProfileExport();
      },
      onVisualiseJson: () => _handleVisualiseJson(),
      onSelectLocalJson: () => _handleSelectLocalJson(),
      onPreviewFile: () => _handlePreview(),
      onConvertToJson: () => _handleConvertToJson(),
    );
  }

  /// Handles file upload.

  void _handleFileUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null && mounted) {
        ref.read(fileServiceProvider.notifier).setUploadFile(file.path);
        await ref.read(fileServiceProvider.notifier).handleUpload(context);
      }
    }
  }

  /// Handles CSV import.

  void _handleCsvImport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvImport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isBloodPressure: directoryFlags['isBloodPressure'] ?? false,
          onImportSuccess: _handleImportSuccess,
        );
  }

  /// Handles successful CSV import.

  void _handleImportSuccess(String importType) {
    // Call the parent callback if provided.

    widget.onImportSuccess?.call(importType);
  }

  /// Handles CSV export.

  void _handleCsvExport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvExport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
        );
  }

  /// Handles Profile import.

  void _handleProfileImport() {
    debugPrint('Import Profile functionality');
  }

  /// Handles Profile export.

  void _handleProfileExport() {
    debugPrint('Export Profile functionality');
  }

  /// Handles selecting and previewing local JSON files.

  void _handleSelectLocalJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _handlePreviewLocalFile(file.path!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select JSON file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles previewing a local file by path.

  Future<void> _handlePreviewLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();

      String displayContent;
      try {
        final jsonData = jsonDecode(content);
        displayContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        // If it's not valid JSON, just show the raw content.

        displayContent = content;
      }

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);
      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      } else {
        setState(() {}); // Force a widget rebuild
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Local JSON file loaded: ${path.basename(filePath)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load local file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles JSON visualisation from POD.

  void _handleVisualiseJson() async {
    final state = ref.read(fileServiceProvider);

    if (state.remoteFileName == null || state.currentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construct the full file path by combining directory and filename.

    String filePath;
    if (state.downloadFile != null && state.downloadFile!.isNotEmpty) {
      filePath = '${state.downloadFile}/${state.remoteFileName}';
    } else {
      // Fallback to manual construction using currentPath.

      filePath = state.currentPath == basePath
          ? '$basePath/${state.remoteFileName}'
          : '${state.currentPath}/${state.remoteFileName}';
    }

    try {
      // Read the file content from POD.

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Reading JSON file'),
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to read file from POD');
      }

      // Try to parse and format the JSON content.

      String displayContent;
      try {
        final jsonData = jsonDecode(fileContent);
        // Pretty format the JSON with indentation.

        displayContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      } catch (e) {
        // If it's not valid JSON, just show the raw content.

        displayContent = fileContent;
      }

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);

      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      } else {
        // Force a widget rebuild by calling setState on a parent widget.

        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to load JSON: ${e.toString()}');
    }
  }

  /// Handles file preview.

  Future<void> _handlePreview() async {
    final state = ref.read(fileServiceProvider);

    if (state.remoteFileName == null || state.currentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Construct the full file path.

    final filePath = state.currentPath == basePath
        ? '$basePath/${state.remoteFileName}'
        : '${state.currentPath}/${state.remoteFileName}';

    try {
      // Read the file content from POD.

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Reading file'),
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to read file from POD');
      }

      // Display content (truncate if too long).

      String displayContent = fileContent.length > 1000
          ? '${fileContent.substring(0, 1000)}...\n\n[Content truncated]'
          : fileContent;

      // Update the file preview state.

      ref.read(fileServiceProvider.notifier).setFilePreview(displayContent);

      // Always ensure preview is shown when content is loaded.

      final currentState = ref.read(fileServiceProvider);
      if (!currentState.showPreview) {
        ref.read(fileServiceProvider.notifier).togglePreview();
      }
    } catch (e) {
      debugPrint('Failed to load file: ${e.toString()}');
    }
  }

  /// Handles PDF to JSON conversion.

  void _handleConvertToJson() async {
    final state = ref.read(fileServiceProvider);
    if (state.uploadFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file uploaded for conversion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await PdfProcessor.convertPDFToJsonUpload(
      File(state.uploadFile!),
      context,
      ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final currentPath = state.currentPath ?? basePath;

    // Watch the tab state and trigger navigation when it changes.

    final currentTabState = ref.watch(tabStateProvider);

    // Check if tab has changed and we need to coordinate navigation.

    if (!_userHasManuallyNavigated &&
        _lastCoordinatedTabIndex != currentTabState.selectedIndex) {
      // Update the last coordinated index.

      _lastCoordinatedTabIndex = currentTabState.selectedIndex;

      // Use a post-frame callback to trigger navigation after build completes.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userHasManuallyNavigated) {
          _navigateToFeatureFolder();
        }
      });
    }

    return SolidFile(
      basePath: basePath,
      currentPath: currentPath,
      browserKey: _browserKey,
      autoConfig: true,
      showBackButton: true,
      backButtonText: 'Back to Home Folder',
      onBackPressed: () {
        const rootPath = basePath;
        // Set manual navigation flag to prevent automatic coordination after
        // back press.

        _userHasManuallyNavigated = true;

        // Reset coordinated index to allow future tab coordination if needed.

        _lastCoordinatedTabIndex = null;
        ref.read(fileServiceProvider.notifier).updateCurrentPath(rootPath);
        _browserKey.currentState?.navigateToPath(rootPath);

        // Re-enable coordination after a short delay to allow tab coordination
        // again.

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _userHasManuallyNavigated = false;
          }
        });

        // Force refresh the widget to ensure immediate update.

        setState(() {});
      },
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
        // Show confirmation dialogue before deleting.

        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(
                'Are you sure you want to delete "$fileName"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        if (!context.mounted) return;

        if (confirm == true) {
          String actualPath = '$filePath/$fileName';

          try {
            // Delete the main file first.

            await deleteFile(actualPath);

            // Try to delete the ACL file.

            try {
              await deleteFile('$actualPath.acl');
            } catch (e) {
              // ACL files are optional and may not exist.
            }

            // Show success message.

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('File deleted successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );

              // Refresh the file browser.

              _browserKey.currentState?.refreshFiles();
            }
          } catch (e) {
            if (context.mounted) {
              final message = e.toString().contains('404') ||
                      e.toString().contains('NotFoundHttpError')
                  ? 'File not found or already deleted'
                  : 'Delete failed: ${e.toString()}';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      onImportCsv: (fileName, filePath) {
        // Import CSV functionality would be implemented here.

        debugPrint('Import CSV: $fileName at $filePath');
      },
      onDirectoryChanged: (path) {
        final expectedPath = _getExpectedPathForCurrentTab();
        final isTabCoordinatedNavigation = (path == expectedPath);

        if (!isTabCoordinatedNavigation) {
          _userHasManuallyNavigated = true;
          _lastCoordinatedTabIndex = null;
        }

        ref.read(fileServiceProvider.notifier).updateCurrentPath(path);
        setState(() {});
      },
      onClosePreview: () {
        final currentState = ref.read(fileServiceProvider);
        if (currentState.showPreview) {
          ref.read(fileServiceProvider.notifier).togglePreview();
        }
      },
      uploadCallbacks: _createUploadCallbacks(currentPath),
      uploadState: SolidFileUploadState(
        uploadInProgress: state.uploadInProgress,
        importInProgress: state.importInProgress,
        exportInProgress: state.exportInProgress,
        uploadedFilePath: state.uploadFile,
        uploadDone: state.uploadDone,
        filePreview: state.filePreview,
        showPreview: state.showPreview,
      ),
    );
  }
}
