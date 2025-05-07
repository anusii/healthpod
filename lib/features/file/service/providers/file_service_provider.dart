/// File service provider for the file service feature.
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
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/feature.dart';
import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/bp/exporter.dart';
import 'package:healthpod/features/bp/importer.dart';
import 'package:healthpod/features/file/service/models/file_state.dart';
import 'package:healthpod/features/medication/exporter.dart';
import 'package:healthpod/features/medication/importer.dart';
import 'package:healthpod/features/profile/exporter.dart';
import 'package:healthpod/features/profile/importer.dart';
import 'package:healthpod/features/vaccination/exporter.dart';
import 'package:healthpod/features/vaccination/importer.dart';
import 'package:healthpod/providers/profile_provider.dart';
import 'package:healthpod/utils/is_text_file.dart';
import 'package:healthpod/utils/save_decrypted_content.dart';
import 'package:healthpod/utils/show_alert.dart';

/// A provider that manages the business logic for file operations.
///
/// This provider handles all file-related operations including upload, download,
/// and deletion, while maintaining the state of these operations.

class FileServiceNotifier extends StateNotifier<FileState> {
  FileServiceNotifier() : super(FileState());

  // Add callback for browser refresh.

  Function? _refreshCallback;

  // Method to set the refresh callback.

  void setRefreshCallback(Function callback) {
    _refreshCallback = callback;
  }

  // Method to call the refresh callback.

  void refreshBrowser() {
    _refreshCallback?.call();
  }

  /// Updates the current path and notifies listeners.

  void updateCurrentPath(String path) {
    state = state.copyWith(currentPath: path);
  }

  /// Updates import in progress state.

  void updateImportInProgress(bool inProgress) {
    state = state.copyWith(importInProgress: inProgress);
  }

  /// Handles file upload by reading its contents and encrypting it for upload.

  Future<void> handleUpload(BuildContext context) async {
    if (state.uploadFile == null) return;

    try {
      state = state.copyWith(
        uploadInProgress: true,
        uploadDone: false,
      );

      final file = File(state.uploadFile!);
      String fileContent;

      // For text files, we directly read the content.
      // For binary files, we encode them into base64 format.

      if (isTextFile(state.uploadFile!)) {
        fileContent = await file.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        fileContent = base64Encode(bytes);
      }

      // Sanitise file name and append encryption extension.

      String sanitizedFileName = path
          .basename(state.uploadFile!)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '');

      final remoteFileName = '$sanitizedFileName.enc.ttl';
      final cleanFileName = sanitizedFileName;

      // Extract the subdirectory path.

      String? subPath = state.currentPath?.replaceFirst(basePath, '').trim();
      String uploadPath = subPath == null || subPath.isEmpty
          ? remoteFileName
          : '${subPath.startsWith("/") ? subPath.substring(1) : subPath}/$remoteFileName';

      // debugPrint('Upload path: $uploadPath');

      if (!context.mounted) return;

      // Upload file with encryption.

      final result = await writePod(
        uploadPath,
        fileContent,
        context,
        const Text('Upload'),
        encrypted: true,
      );

      state = state.copyWith(
        uploadDone: result == SolidFunctionCallStatus.success,
        uploadInProgress: false,
        remoteFileName: remoteFileName,
        cleanFileName: cleanFileName,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Show success message.

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
          // Call the refresh callback to update the browser.

          _refreshCallback?.call();
        }
      } else if (context.mounted) {
        showAlert(context,
            'Upload failed - please check your connection and permissions.');
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Upload error: ${e.toString()}');
        debugPrint('Upload error: $e');
      }
      state = state.copyWith(uploadInProgress: false);
    }
  }

  /// Handles the download and decryption of files from the POD.

  Future<void> handleDownload(BuildContext context) async {
    if (state.remoteFileName == null || state.currentPath == null) return;

    try {
      state = state.copyWith(
        downloadInProgress: true,
        downloadDone: false,
      );

      // Let user choose where to save the file.

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file as:',
        fileName: state.cleanFileName ??
            state.remoteFileName?.replaceAll('.enc.ttl', ''),
      );

      if (outputFile == null) {
        state = state.copyWith(downloadInProgress: false);
        return;
      }

      final baseDir = basePath;
      final relativePath = state.currentPath == baseDir
          ? '$baseDir/${state.remoteFileName}'
          : '${state.currentPath}/${state.remoteFileName}';

      // debugPrint('Attempting to download from path: $relativePath');

      if (!context.mounted) return;

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to download the file'),
      );

      if (!context.mounted) return;

      final fileContent = await readPod(
        relativePath,
        context,
        const Text('Downloading'),
      );

      if (!context.mounted) return;

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      await saveDecryptedContent(fileContent, outputFile);

      state = state.copyWith(
        downloadDone: true,
        downloadInProgress: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Download error: ${e.toString()}');
        debugPrint('Download error: $e');
      }
      state = state.copyWith(downloadInProgress: false);
    }
  }

  /// Updates the selected file for upload.

  void setUploadFile(String? file) {
    state = state.copyWith(uploadFile: file);
  }

  /// Updates the selected file for download.

  void setDownloadFile(String file) {
    state = state.copyWith(downloadFile: file);
  }

  /// Updates the file preview content.

  void setFilePreview(String preview) {
    state = state.copyWith(filePreview: preview);
  }

  /// Updates the remote file name.

  void setRemoteFileName(String fileName) {
    state = state.copyWith(
      remoteFileName: fileName,
      cleanFileName: fileName.replaceAll('.enc.ttl', ''),
    );
  }

  /// Handles file deletion from the POD.

  Future<void> handleDelete(BuildContext context) async {
    if (state.remoteFileName == null || state.currentPath == null) return;

    try {
      state = state.copyWith(
        deleteInProgress: true,
        deleteDone: false,
      );

      final baseDir = basePath;
      final filePath = state.currentPath == baseDir
          ? '$baseDir/${state.remoteFileName}'
          : '${state.currentPath}/${state.remoteFileName}';

      // debugPrint('Attempting to delete file at path: $filePath');

      if (!context.mounted) return;

      // First try to delete the main file.

      bool mainFileDeleted = false;
      try {
        await deleteFile(filePath);
        mainFileDeleted = true;
        // debugPrint('Successfully deleted main file: $filePath');
      } catch (e) {
        debugPrint('Error deleting main file: $e');
        // Only rethrow if it's not a 404 error.

        if (!e.toString().contains('404') &&
            !e.toString().contains('NotFoundHttpError')) {
          rethrow;
        }
      }

      if (!context.mounted) return;

      // If main file deletion succeeded, try to delete the ACL file.

      if (mainFileDeleted) {
        try {
          await deleteFile('$filePath.acl');
          // debugPrint('Successfully deleted ACL file');
        } catch (e) {
          // ACL files are optional and may not exist.

          if (e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')) {
            debugPrint('ACL file not found (safe to ignore)');
          } else {
            debugPrint('Error deleting ACL file: ${e.toString()}');
          }
        }

        if (!context.mounted) return;
        state = state.copyWith(deleteDone: true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );

          // Call the refresh callback to update the browser.

          _refreshCallback?.call();
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      state = state.copyWith(deleteDone: false);

      // Provide user-friendly error messages.

      final message = e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')
          ? 'File not found or already deleted'
          : 'Delete failed: ${e.toString()}';

      showAlert(context, message);
      debugPrint('Delete error: $e');
    } finally {
      if (context.mounted) {
        state = state.copyWith(deleteInProgress: false);
      }
    }
  }

  /// Toggles the preview visibility.

  void togglePreview() {
    state = state.copyWith(showPreview: !state.showPreview);
  }

  /// Handles the import of BP, Vaccination, or Medication data from CSV format.

  Future<void> handleCsvImport(BuildContext context,
      {bool isVaccination = false, bool isMedication = false}) async {
    try {
      state = state.copyWith(importInProgress: true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!context.mounted) return;

          bool success;
          final Feature feature;

          if (isVaccination) {
            feature = Feature.vaccination;
            success = await VaccinationImporter.importCsv(
              file.path!,
              state.currentPath ?? basePath,
              context,
            );
          } else if (isMedication) {
            feature = Feature.medication;
            success = await MedicationImporter.importCsv(
              file.path!,
              state.currentPath ?? basePath,
              context,
            );
          } else {
            feature = Feature.bloodPressure;
            success = await BPImporter.importCsv(
              file.path!,
              state.currentPath ?? basePath,
              context,
            );
          }

          if (context.mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${feature.displayName} data imported and converted successfully'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        final feature = isVaccination
            ? Feature.vaccination
            : (isMedication ? Feature.medication : Feature.bloodPressure);
        showAlert(context,
            'Failed to import ${feature.displayName} data: ${e.toString()}');
      }
    } finally {
      if (context.mounted) {
        state = state.copyWith(importInProgress: false);
      }
    }
  }

  /// Handles the export of BP, Vaccination, or Medication data to CSV format.

  Future<void> handleCsvExport(BuildContext context,
      {bool isVaccination = false, bool isMedication = false}) async {
    try {
      state = state.copyWith(exportInProgress: true);

      final feature = isVaccination
          ? Feature.vaccination
          : (isMedication ? Feature.medication : Feature.bloodPressure);

      final fileName = isVaccination
          ? 'vaccination_data.csv'
          : (isMedication ? 'medication_data.csv' : 'blood_pressure_data.csv');

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${feature.displayName} data as CSV:',
        fileName: fileName,
      );

      if (outputFile != null) {
        if (!context.mounted) return;

        bool success;

        if (isVaccination) {
          success = await VaccinationExporter.exportCsv(
            outputFile,
            state.currentPath ?? basePath,
            context,
          );
        } else if (isMedication) {
          success = await MedicationExporter.exportCsv(
            outputFile,
            state.currentPath ?? basePath,
            context,
          );
        } else {
          success = await BPExporter.exportCsv(
            outputFile,
            state.currentPath ?? basePath,
            context,
          );
        }

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('${feature.displayName} data exported successfully'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          } else {
            showAlert(context, 'Failed to export ${feature.displayName} data');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        final feature = isVaccination
            ? Feature.vaccination
            : (isMedication ? Feature.medication : Feature.bloodPressure);
        showAlert(context,
            'Failed to export ${feature.displayName} data: ${e.toString()}');
      }
    } finally {
      if (context.mounted) {
        state = state.copyWith(exportInProgress: false);
      }
    }
  }

  /// Handles the import of profile data from JSON format.

  Future<void> handleProfileImport(BuildContext context,
      {required WidgetRef ref}) async {
    try {
      state = state.copyWith(importInProgress: true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!context.mounted) return;

          await ProfileImporter.importJson(
            file.path!,
            'profile',
            context,
            onSuccess: () {
              if (!context.mounted) return;

              // Show success message first
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile data imported successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );

              // Use microtask to ensure UI operations complete first.

              Future.microtask(() {
                if (!context.mounted) return;
                // Refresh profile data after successful import.

                ref.read(profileProvider.notifier).refreshProfileData(context);

                // Refresh file browser.

                refreshBrowser();
              });
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Failed to import profile data: ${e.toString()}');
      }
    } finally {
      if (context.mounted) {
        state = state.copyWith(importInProgress: false);
      }
    }
  }

  /// Handles the export of profile data to JSON format.

  Future<void> handleProfileExport(BuildContext context) async {
    try {
      state = state.copyWith(exportInProgress: true);

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Profile data as JSON:',
        fileName: 'profile_export.json',
      );

      if (outputFile != null) {
        if (!context.mounted) return;

        final success = await ProfileExporter.exportJson(
          outputFile,
          state.currentPath ?? 'profile',
          context,
        );

        // Add a newline character at the end of the file if export was successful.

        if (success) {
          final file = File(outputFile);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (!content.endsWith('\n')) {
              await file.writeAsString('$content\n');
            }
          }
        }

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile data exported successfully'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          } else {
            showAlert(context, 'Failed to export profile data');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Failed to export profile data: ${e.toString()}');
      }
    } finally {
      if (context.mounted) {
        state = state.copyWith(exportInProgress: false);
      }
    }
  }
}

/// The provider instance for file service operations.

final fileServiceProvider =
    StateNotifierProvider<FileServiceNotifier, FileState>((ref) {
  return FileServiceNotifier();
});
