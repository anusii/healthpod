/// Upload callback handler for file management operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';

/// Handles upload-related callbacks and operations for file management.

class UploadCallbackHandler {
  final WidgetRef ref;
  final BuildContext context;
  final Function(String) onImportSuccess;
  final Function() onVisualiseJson;
  final Function() onSelectLocalJson;
  final Function() onPreviewFile;
  final Function() onConvertToJson;

  const UploadCallbackHandler({
    required this.ref,
    required this.context,
    required this.onImportSuccess,
    required this.onVisualiseJson,
    required this.onSelectLocalJson,
    required this.onPreviewFile,
    required this.onConvertToJson,
  });

  /// Creates upload callbacks for SolidFile.

  SolidFileUploadCallbacks createUploadCallbacks(String currentPath) {
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
      onUpload: () => handleFileUpload(),
      onImportCsv: () => handleCsvImport(computeDirectoryFlags()),
      onExportCsv: () => handleCsvExport(computeDirectoryFlags()),
      onImportSuccess: handleImportSuccess,
      onImportProfile: () {
        if (inProfileDirectory()) handleProfileImport();
      },
      onExportProfile: () {
        if (inProfileDirectory()) handleProfileExport();
      },
      onVisualiseJson: onVisualiseJson,
      onSelectLocalJson: onSelectLocalJson,
      onPreviewFile: onPreviewFile,
      onConvertToJson: onConvertToJson,
    );
  }

  /// Handles file upload.

  Future<void> handleFileUpload() async {
    final result = await FilePicker.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null && context.mounted) {
        ref.read(fileServiceProvider.notifier).setUploadFile(file.path);
        await ref.read(fileServiceProvider.notifier).handleUpload(context);
      }
    }
  }

  /// Handles CSV import.

  void handleCsvImport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvImport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isBloodPressure: directoryFlags['isBloodPressure'] ?? false,
          onImportSuccess: handleImportSuccess,
        );
  }

  /// Handles successful CSV import.

  void handleImportSuccess(String importType) {
    // Call the parent callback if provided.

    onImportSuccess(importType);
  }

  /// Handles CSV export.

  void handleCsvExport(Map<String, bool> directoryFlags) {
    ref.read(fileServiceProvider.notifier).handleCsvExport(
          context,
          isVaccination: directoryFlags['isVaccination'] ?? false,
          isDiary: directoryFlags['isDiary'] ?? false,
          isMedication: directoryFlags['isMedication'] ?? false,
        );
  }

  /// Handles Profile import.

  void handleProfileImport() {
    debugPrint('Import Profile functionality');
  }

  /// Handles Profile export.

  void handleProfileExport() {
    debugPrint('Export Profile functionality');
  }
}
