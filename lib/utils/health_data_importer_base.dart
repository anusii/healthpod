/// Base class for health data importers.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang, Tony Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/health_importer/dialogs/health_importer_dialogs.dart';
import 'package:healthpod/utils/health_importer/managers/health_importer_file_manager.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Abstract base class for health data importers.
///
/// This class provides common functionality for importing health data from CSV
/// files, including file reading, CSV parsing, timestamp validation, and
/// file saving. Specific health data importers should extend this class and
/// implement the abstract methods.

/// Abstract base class for health data importers.
///
/// This class provides common functionality for importing health data from CSV
/// files, including file reading, CSV parsing, timestamp validation, and
/// file saving. Specific health data importers should extend this class and
/// implement the abstract methods.

abstract class HealthDataImporterBase {
  /// The data type identifier (e.g., 'blood_pressure', 'vaccination').

  String get dataType;

  /// The field name for timestamp in the data model.

  String get timestampField;

  /// Get the list of required column names that must be present in the CSV.

  List<String> get requiredColumns;

  /// Get the list of optional column names that may be present in the CSV.

  List<String> get optionalColumns;

  /// Create a response map with default values for a new record.
  ///
  /// This method should initialize a map with all the fields needed for the specific data type.

  Map<String, dynamic> createDefaultResponseMap();

  /// Process a specific field from the CSV row.
  ///
  /// This method handles the specific logic for each field type in the data model.
  /// Returns true if the field was processed successfully, false otherwise.
  ///
  /// Parameters:
  /// - [header]: The column header name
  /// - [value]: The value from the CSV
  /// - [responses]: The map to update with the processed value
  /// - [rowIndex]: The current row index for error reporting

  bool processField(
    String header,
    String value,
    Map<String, dynamic> responses,
    int rowIndex,
  );

  /// Helper method to check if a file exists in the POD.

  Future<bool> fileExistsInPod(String filePath) async {
    return HealthImporterFileManager.fileExistsInPod(dataType, filePath);
  }

  /// Import health data from a CSV file.
  ///
  /// This method reads a CSV file, validates its structure, processes each row,
  /// and saves the data as individual encrypted JSON files in the specified directory.
  ///
  /// Parameters:
  /// - [filePath]: Path to the CSV file to import
  /// - [dirPath]: Directory path where the JSON files will be saved
  /// - [context]: Flutter build context for UI interactions
  ///
  /// Returns a boolean indicating whether the import was successful.

  Future<bool> importFromCsv(
    String filePath,
    String dirPath,
    BuildContext context, {
    // Optional: provide content directly for web.

    String? fileContent,

    // Progress callback.

    void Function(String message, double progress)? onProgress,
  }) async {
    // Remove verbose debug logs for cleaner console output.

    try {
      // Start processing the CSV file by reading its contents.
      onProgress?.call('Reading CSV file...', 0.1);

      final String content;
      if (fileContent != null) {
        // Content provided directly (typically from web file bytes).

        content = fileContent;
      } else {
        // Native platform - read from file path.

        final file = File(filePath);
        content = await file.readAsString();
      }

      // Convert CSV content to a list of fields using specific parsing settings.

      onProgress?.call('Parsing CSV content...', 0.2);

      final fields = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: ',',
        allowInvalid: true,
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(content);

      // Check if the CSV file contains any data.

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract and normalize the header row from the CSV.

      onProgress?.call('Validating CSV format...', 0.3);

      final headers = List<String>.from(
        fields[0].map((h) => h.toString().trim().toLowerCase()),
      );

      // Check for any missing required columns and show an alert if any are missing.

      final lowerRequiredColumns =
          requiredColumns.map((col) => col.toLowerCase()).toList();
      final missingColumns =
          lowerRequiredColumns.where((col) => !headers.contains(col)).toList();

      if (missingColumns.isNotEmpty) {
        if (!context.mounted) return false;

        // Build the alert message with required and optional columns.

        final requiredColumnsStr =
            requiredColumns.map((col) => '- $col').join('\n');
        final optionalColumnsStr =
            optionalColumns.map((col) => '- $col').join('\n');

        showAlert(context, '''
        Required columns missing: ${missingColumns.join(", ")}

        The following columns are required:
        $requiredColumnsStr

        These columns are optional:
        $optionalColumnsStr
        ''');
        return false;
      }

      // Initialise tracking variables for duplicate detection and success monitoring.

      final Set<String> seenTimestamps = {};
      final List<String> duplicateTimestamps = [];
      final List<String> allTimestamps = [];
      bool allSuccess = true;
      int successfulSaves = 0;

      // First pass: collect all timestamps from the CSV file.

      for (var i = 1; i < fields.length; i++) {
        final row =
            List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
        if (row.isEmpty) continue;

        while (row.length < headers.length) {
          row.add('');
        }

        for (var j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = row[j].toString().trim();

          if (header == timestampField.toLowerCase() && value.isNotEmpty) {
            try {
              final timestamp =
                  normaliseTimestamp(roundTimestampToSecond(value));
              if (isValidTimestamp(timestamp)) {
                allTimestamps.add(timestamp);
              }
            } catch (e) {
              // Skip invalid timestamps.
            }
            break;
          }
        }
      }

      // Check for existing files that would be overridden.

      List<String> duplicateFiles = [];

      if (allTimestamps.isNotEmpty) {
        try {
          duplicateFiles =
              await HealthImporterFileManager.checkForExistingFiles(
            dataType,
            dirPath,
            allTimestamps,
          );

          // If duplicate files exist, show confirmation dialog.

          if (duplicateFiles.isNotEmpty && context.mounted) {
            final shouldOverride =
                await HealthImporterDialogs.showOverrideConfirmationDialog(
              context,
              duplicateFiles,
            );

            // If user cancels the override, abort the import.

            if (!shouldOverride) {
              return false;
            }

            if (!context.mounted) return false;

            // Delete the existing files before proceeding with import.

            await HealthImporterFileManager.deleteExistingFiles(
              context,
              dataType,
              dirPath,
              duplicateFiles,
            );
          }
        } catch (e) {
          // Show warning that we can't check for duplicates.

          if (context.mounted) {
            final shouldProceed =
                await HealthImporterDialogs.showDuplicateCheckFailedDialog(
              context,
            );
            if (!shouldProceed) {
              return false;
            }
          }
        }
      }

      // Process each row in the CSV file starting from the second row.

      // Exclude header row.

      final totalRows = fields.length - 1;
      onProgress?.call('Processing $totalRows records...', 0.4);

      for (var i = 1; i < fields.length; i++) {
        // Update progress for each row.

        final currentProgress = 0.4 + (0.5 * (i - 1) / totalRows);
        onProgress?.call(
          'Processing record $i of $totalRows...',
          currentProgress,
        );
        try {
          // Convert row data to a list of strings, handling null values.

          final row =
              List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
          if (row.isEmpty) continue;

          // Pad the row with empty strings if it has fewer columns than headers.

          while (row.length < headers.length) {
            row.add('');
          }

          // Initialize the responses map with default values.

          final Map<String, dynamic> responses = createDefaultResponseMap();

          // Initialize timestamp and validation flag.

          String timestamp = '';
          bool hasRequiredFields = true;

          // Process each column in the current row.

          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

            // Handle timestamp field specially
            if (header == timestampField.toLowerCase()) {
              if (value.isEmpty) {
                hasRequiredFields = false;
                continue;
              }

              timestamp = normaliseTimestamp(roundTimestampToSecond(value));
              if (!isValidTimestamp(timestamp)) {
                throw FormatException(
                  'Row $i: Invalid timestamp format: $value',
                );
              }

              if (!seenTimestamps.add(timestamp)) {
                duplicateTimestamps.add(formatTimestampForDisplay(timestamp));
              }
              continue;
            }

            // Process other fields using the implementation-specific method
            final fieldProcessed = processField(header, value, responses, i);
            if (!fieldProcessed && lowerRequiredColumns.contains(header)) {
              hasRequiredFields = false;
            }
          }

          // Skip rows with missing required fields.

          if (!hasRequiredFields) {
            continue;
          }

          // Create the JSON data structure for the current record.

          final jsonData = {
            timestampField: timestamp,
            'responses': responses,
          };

          // Generate a safe filename using the timestamp.

          final safeTimestamp =
              timestamp.replaceAll(':', '-').replaceAll('.', '-');
          final outputFileName = '${dataType}_$safeTimestamp.json.enc.ttl';

          // Determine the correct save path based on the directory structure.
          // Use simpler path handling that matches successful upload functions.

          String savePath;
          if (dirPath.endsWith('/$dataType')) {
            savePath = '$dataType/$outputFileName';
          } else {
            // Clean the directory path by removing leading healthpod/data/ prefix.

            String cleanDirPath = dirPath;

            if (cleanDirPath.startsWith(basePath)) {
              cleanDirPath = cleanDirPath.substring(basePath.length);
            } else if (cleanDirPath.startsWith(basePath)) {
              cleanDirPath = cleanDirPath.substring(basePath.length);
            }

            // Remove leading slash if present.

            if (cleanDirPath.startsWith('/')) {
              cleanDirPath = cleanDirPath.substring(1);
            }

            savePath = cleanDirPath.isEmpty
                ? outputFileName
                : '$cleanDirPath/$outputFileName';
          }

          // Check if context is still valid before proceeding.

          if (!context.mounted) return false;

          // Write the encrypted data to the pod.
          final SolidFunctionCallStatus result;
          try {
            result = await writePod(
              savePath,
              json.encode(jsonData),
              context,
              Text('Converting row $i'),
              encrypted: true,
            );
          } catch (writeError, writeStackTrace) {
            debugPrint('❌ [CSV Import] WritePod failed: $writeError');
            debugPrint('❌ [CSV Import] Error type: ${writeError.runtimeType}');
            debugPrint('❌ [CSV Import] Stack trace: $writeStackTrace');
            rethrow;
          }

          // Track the success status of each save operation.

          if (result == SolidFunctionCallStatus.success) {
            successfulSaves++;
          } else {
            allSuccess = false;
          }
        } catch (rowError) {
          allSuccess = false;
        }
      }

      // Log the completion status.

      // Show warning for any duplicate timestamps found within the CSV.

      if (duplicateTimestamps.isNotEmpty) {
        if (!context.mounted) return allSuccess;
        showAlert(
          context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.',
        );
      }

      // Return overall success status.

      onProgress?.call('Import completed successfully!', 1.0);
      return allSuccess && successfulSaves > 0;
    } catch (e, stackTrace) {
      // Handle any errors during the import process.

      debugPrint('❌ [CSV Import] Import failed with error: $e');
      debugPrint('❌ [CSV Import] Error type: ${e.runtimeType}');
      debugPrint('❌ [CSV Import] Stack trace: $stackTrace');

      if (context.mounted) {
        showAlert(context, 'Error importing CSV: ${e.toString()}');
      }
      return false;
    }
  }
}
