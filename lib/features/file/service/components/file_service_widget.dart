/// File service widget using SolidUI components.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/features/file/service/providers/file_service_provider.dart';

/// The main file service widget that provides file upload, download, and
/// preview functionality.

class FileServiceWidget extends ConsumerStatefulWidget {
  const FileServiceWidget({super.key});

  @override
  ConsumerState<FileServiceWidget> createState() => _FileServiceWidgetState();
}

class _FileServiceWidgetState extends ConsumerState<FileServiceWidget> {
  final GlobalKey<SolidFileBrowserState> _browserKey = GlobalKey();

  /// Determines the friendly folder name based on the current path.

  String _getFriendlyFolderName(String currentPath) {
    final segments = currentPath.split('/');
    if (segments.length < 3) return 'Health Data';

    final folderName = segments[2];
    switch (folderName) {
      case 'bp':
        return 'Blood Pressure Data';
      case 'vaccination':
        return 'Vaccination Data';
      case 'medication':
        return 'Medication Data';
      case 'diary':
        return 'Diary Data';
      case 'profile':
        return 'Profile Data';
      default:
        String formattedName = folderName.replaceAll('_', ' ');
        formattedName =
            formattedName[0].toUpperCase() + formattedName.substring(1);
        return '$formattedName Data';
    }
  }

  /// Navigates to the feature-specific folder.

  void _navigateToFeatureFolder() {
    final currentPath =
        ref.read(fileServiceProvider).currentPath ?? 'healthpod/data';
    _browserKey.currentState?.navigateToPath(currentPath);
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

  /// Creates upload configuration based on current path.

  SolidFileUploadConfig _createUploadConfig(String currentPath) {
    // Determine which type of directory we're in

    final isInBpDirectory = currentPath.contains('/bp');
    final isInVaccinationDirectory = currentPath.contains('/vaccination');
    final isInMedicationDirectory = currentPath.contains('/medication');
    final isInDiaryDirectory = currentPath.contains('/diary');
    final isInProfileDirectory = currentPath.contains('/profile');

    // Determine if we should show CSV buttons

    final showCsvButtons = isInBpDirectory ||
        isInVaccinationDirectory ||
        isInMedicationDirectory ||
        isInDiaryDirectory;

    // Determine if we should show Profile buttons

    final showProfileButtons = isInProfileDirectory;

    // Get the appropriate format configuration

    DataFormatConfig? formatConfig;
    if (isInBpDirectory) {
      formatConfig = SolidDataFormats.bloodPressure;
    } else if (isInVaccinationDirectory) {
      formatConfig = SolidDataFormats.vaccination;
    } else if (isInMedicationDirectory) {
      formatConfig = SolidDataFormats.medication;
    } else if (isInDiaryDirectory) {
      formatConfig = SolidDataFormats.diary;
    } else if (isInProfileDirectory) {
      formatConfig = SolidDataFormats.profile;
    }

    return SolidFileUploadConfig(
      showCsvButtons: showCsvButtons,
      showProfileButtons: showProfileButtons,
      showJsonButtons: true,
      showPreviewButtons: true,
      formatConfig: formatConfig,
      uploadButtonText: 'Upload',
      uploadTooltip: '''

**Upload**: Tap here to upload a file to your Solid Health Pod.

''',
    );
  }

  /// Creates upload callbacks.

  SolidFileUploadCallbacks _createUploadCallbacks(String currentPath) {
    // Determine which type of directory we're in.

    final isInBpDirectory = currentPath.contains('/bp');
    final isInVaccinationDirectory = currentPath.contains('/vaccination');
    final isInMedicationDirectory = currentPath.contains('/medication');
    final isInDiaryDirectory = currentPath.contains('/diary');
    final isInProfileDirectory = currentPath.contains('/profile');

    // Determine if we should show buttons.

    final showCsvButtons = isInBpDirectory ||
        isInVaccinationDirectory ||
        isInMedicationDirectory ||
        isInDiaryDirectory;
    final showProfileButtons = isInProfileDirectory;

    return SolidFileUploadCallbacks(
      onUpload: () => _handleFileUpload(),
      onImportCsv: showCsvButtons
          ? () => _handleCsvImport({
                'isVaccination': isInVaccinationDirectory,
                'isMedication': isInMedicationDirectory,
                'isDiary': isInDiaryDirectory,
                'isBloodPressure': isInBpDirectory,
              })
          : null,
      onExportCsv: showCsvButtons
          ? () => _handleCsvExport({
                'isVaccination': isInVaccinationDirectory,
                'isMedication': isInMedicationDirectory,
                'isDiary': isInDiaryDirectory,
                'isBloodPressure': isInBpDirectory,
              })
          : null,
      onImportProfile: showProfileButtons ? () => _handleProfileImport() : null,
      onExportProfile: showProfileButtons ? () => _handleProfileExport() : null,
      onVisualiseJson: () => _handleVisualiseJson(),
      onPreviewFile: () => _handlePreview(),
      onConvertToJson: () => _handleConvertToJson(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);
    final currentPath = state.currentPath ?? 'healthpod/data';
    final friendlyFolderName = _getFriendlyFolderName(currentPath);

    // Create SolidFile configuration.

    final config = SolidFileConfig(
      basePath: 'healthpod/data',
      showBackButton: true,
      backButtonText: 'Back to Home Folder',
    );

    // Create callbacks.

    final callbacks = SolidFileCallbacks(
      onBackPressed: () {
        const rootPath = 'healthpod/data';
        if (state.currentPath != rootPath) {
          ref.read(fileServiceProvider.notifier).updateCurrentPath(rootPath);
          _browserKey.currentState?.navigateToPath(rootPath);
        }
      },
      onFileSelected: (fileName, filePath) {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setFilePreview(fileName)
          ..setRemoteFileName(fileName);
      },
      onFileDownload: (fileName, filePath) async {
        ref.read(fileServiceProvider.notifier)
          ..setDownloadFile(filePath)
          ..setRemoteFileName(fileName)
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

        if (confirm == true) {
          // Delete functionality would be implemented here.

          debugPrint('Delete file: $filePath');
          _browserKey.currentState?.refreshFiles();
        }
      },
      onImportCsv: (fileName, filePath) {
        // Import CSV functionality would be implemented here.

        debugPrint('Import CSV: $fileName at $filePath');
      },
      onDirectoryChanged: (path) {
        ref.read(fileServiceProvider.notifier).updateCurrentPath(path);
      },
      uploadCallbacks: _createUploadCallbacks(currentPath),
    );

    // Create SolidFile state.

    final solidFileState = SolidFileState(
      currentPath: currentPath,
      friendlyFolderName: friendlyFolderName,
      uploadConfig: _createUploadConfig(currentPath),
      uploadState: SolidFileUploadState(
        uploadInProgress: state.uploadInProgress,
        importInProgress: state.importInProgress,
        exportInProgress: state.exportInProgress,
        uploadedFilePath: state.uploadFile,
        uploadDone: state.uploadDone,
      ),
    );

    return SolidFile(
      config: config,
      callbacks: callbacks,
      state: solidFileState,
      browserKey: _browserKey,
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
        );
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

  /// Handles JSON visualisation.

  void _handleVisualiseJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        await _handlePreview();
      }
    }
  }

  /// Handles file preview.

  Future<void> _handlePreview() async {
    debugPrint('Preview file functionality');
  }

  /// Handles PDF to JSON conversion.

  void _handleConvertToJson() {
    debugPrint('Convert to JSON functionality');
  }
}
