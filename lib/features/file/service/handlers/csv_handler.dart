/// CSV import/export handler for the file service provider.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import 'package:healthpod/constants/feature.dart';
import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/bp/exporter.dart';
import 'package:healthpod/features/bp/importer.dart';
import 'package:healthpod/features/diary/exporter.dart';
import 'package:healthpod/features/diary/importer.dart';
import 'package:healthpod/features/medication/exporter.dart';
import 'package:healthpod/features/medication/importer.dart';
import 'package:healthpod/features/vaccination/exporter.dart';
import 'package:healthpod/features/vaccination/importer.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles CSV import and export operations for the file service.

class CsvHandler {
  const CsvHandler._();

  /// Handles the import of BP, Vaccination, Medication or Diary data from CSV
  /// format.

  static Future<void> handleCsvImport(
    BuildContext context, {
    required String? currentPath,
    required Function? refreshCallback,
    bool isVaccination = false,
    bool isMedication = false,
    bool isDiary = false,
    bool isBloodPressure = false,
    Function(String importType)? onImportSuccess,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!context.mounted) return;

          // Import based on the type.
          if (isVaccination) {
            await _handleVaccinationImport(
              context,
              file,
              currentPath,
              refreshCallback,
              onImportSuccess,
            );
          } else if (isDiary) {
            await _handleDiaryImport(
              context,
              file,
              currentPath,
              refreshCallback,
              onImportSuccess,
            );
          } else if (isMedication) {
            await _handleMedicationImport(
              context,
              file,
              currentPath,
              refreshCallback,
              onImportSuccess,
            );
          } else if (isBloodPressure) {
            await _handleBloodPressureImport(
              context,
              file,
              currentPath,
              refreshCallback,
              onImportSuccess,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        final feature = isVaccination
            ? Feature.vaccination
            : isMedication
                ? Feature.medication
                : isDiary
                    ? Feature.diary
                    : Feature.bloodPressure;
        showAlert(
          context,
          'Failed to import ${feature.displayName} data: ${e.toString()}',
        );
      }
    }
  }

  /// Handles vaccination data import.

  static Future<bool> _handleVaccinationImport(
    BuildContext context,
    PlatformFile file,
    String? currentPath,
    Function? refreshCallback,
    Function(String)? onImportSuccess,
  ) async {
    final success = await VaccinationImporter.importCsv(
      file.path!,
      currentPath ?? basePath,
      context,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Feature.vaccination.displayName} data imported and converted '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      refreshCallback?.call();
      onImportSuccess?.call('vaccination');
    }

    return success;
  }

  /// Handles diary data import.

  static Future<bool> _handleDiaryImport(
    BuildContext context,
    PlatformFile file,
    String? currentPath,
    Function? refreshCallback,
    Function(String)? onImportSuccess,
  ) async {
    final success = await DiaryImporter.importCsv(
      file.path!,
      currentPath ?? basePath,
      context,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Feature.diary.displayName} data imported and converted '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      refreshCallback?.call();
      onImportSuccess?.call('diary');
    }

    return success;
  }

  /// Handles medication data import.

  static Future<bool> _handleMedicationImport(
    BuildContext context,
    PlatformFile file,
    String? currentPath,
    Function? refreshCallback,
    Function(String)? onImportSuccess,
  ) async {
    final success = await MedicationImporter.importCsv(
      file.path!,
      currentPath ?? basePath,
      context,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Feature.medication.displayName} data imported and converted '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      refreshCallback?.call();
      onImportSuccess?.call('medication');
    }

    return success;
  }

  /// Handles blood pressure data import with progress tracking.

  static Future<bool> _handleBloodPressureImport(
    BuildContext context,
    PlatformFile file,
    String? currentPath,
    Function? refreshCallback,
    Function(String)? onImportSuccess,
  ) async {
    // Handle web vs native file reading.

    String? fileContent;
    String filePath = file.path ?? 'web_file_${file.name}';

    if (file.bytes != null &&
        (file.path == null || file.path!.startsWith('blob:'))) {
      // Web platform - use bytes (file.path might be blob URL or null).

      fileContent = String.fromCharCodes(file.bytes!);
    }

    // Show progress dialog.

    String progressMessage = 'Preparing import...';
    double progressValue = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Importing Blood Pressure Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 16),
              Text(progressMessage),
            ],
          ),
        ),
      ),
    );

    bool success = false;

    try {
      success = await BPImporter.importCsv(
        filePath,
        currentPath ?? basePath,
        context,
        fileContent: fileContent,
        onProgress: (message, progress) {
          progressMessage = message;
          progressValue = progress;
          if (context.mounted) {
            // Update the dialog if still showing.

            (context as Element).markNeedsBuild();
          }
        },
      );

      // Close progress dialog.

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close progress dialog on error.

      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Feature.bloodPressure.displayName} data imported and converted '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      refreshCallback?.call();
      onImportSuccess?.call('blood_pressure');
    }

    return success;
  }

  /// Handles the export of BP, Vaccination, Diary or Medication data to CSV
  /// format.

  static Future<void> handleCsvExport(
    BuildContext context, {
    required String? currentPath,
    bool isVaccination = false,
    bool isDiary = false,
    bool isMedication = false,
  }) async {
    try {
      // Pick feature based on all the flags.

      final Feature feature = isVaccination
          ? Feature.vaccination
          : isMedication
              ? Feature.medication
              : isDiary
                  ? Feature.diary
                  : Feature.bloodPressure;

      // Generate the filename from its displayName.

      final String fileName =
          '${feature.displayName.toLowerCase().replaceAll(' ', '_')}_data.csv';

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
            currentPath ?? basePath,
            context,
          );
        } else if (isDiary) {
          success = await DiaryExporter.exportCsv(
            outputFile,
            currentPath ?? basePath,
            context,
          );
        } else if (isMedication) {
          success = await MedicationExporter.exportCsv(
            outputFile,
            currentPath ?? basePath,
            context,
          );
        } else {
          success = await BPExporter.exportCsv(
            outputFile,
            currentPath ?? basePath,
            context,
          );
        }

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${feature.displayName} data exported successfully',
                ),
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
            : isMedication
                ? Feature.medication
                : isDiary
                    ? Feature.diary
                    : Feature.bloodPressure;
        showAlert(
          context,
          'Failed to export ${feature.displayName} data: ${e.toString()}',
        );
      }
    }
  }
}
