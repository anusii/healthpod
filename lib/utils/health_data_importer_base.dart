/// Base class for health data importers.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Kevin Wang.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Abstract base class for health data importers.
///
/// This class provides common functionality for importing health data from CSV files,
/// including file reading, CSV parsing, timestamp validation, and file saving.
/// Specific health data importers should extend this class and implement the abstract methods.

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
    BuildContext context,
  ) async {
    try {
      // Start processing the CSV file by reading its contents.
      debugPrint('Starting CSV processing');
      final file = File(filePath);
      final String content = await file.readAsString();

      // Convert CSV content to a list of fields using specific parsing settings.
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
      final headers = List<String>.from(
          fields[0].map((h) => h.toString().trim().toLowerCase()));

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

      // Initialize tracking variables for duplicate detection and success monitoring.
      final Set<String> seenTimestamps = {};
      final List<String> duplicateTimestamps = [];
      bool allSuccess = true;
      int successfulSaves = 0;

      // Process each row in the CSV file starting from the second row.
      for (var i = 1; i < fields.length; i++) {
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
          String timestamp = "";
          bool hasRequiredFields = true;

          // Process each column in the current row.
          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

            // Handle timestamp field specially
            if (header == timestampField.toLowerCase()) {
              if (value.isEmpty) {
                hasRequiredFields = false;
                debugPrint('Row $i: Missing required timestamp');
                continue;
              }

              timestamp = normaliseTimestamp(roundTimestampToSecond(value));
              if (!isValidTimestamp(timestamp)) {
                throw FormatException(
                    'Row $i: Invalid timestamp format: $value');
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
            debugPrint(
                'Skipping row $i due to missing or invalid required fields');
            continue;
          }

          // Create the JSON data structure for the current record.
          final jsonData = {
            timestampField: timestamp,
            'responses': responses,
          };

          // Generate a safe filename using the timestamp.
          final safeTimestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
          final outputFileName = '${dataType}_$safeTimestamp.json.enc.ttl';

          // Determine the correct save path based on the directory structure.
          String savePath;
          if (dirPath.endsWith('/$dataType')) {
            savePath = '$dataType/$outputFileName';
          } else {
            final cleanDirPath =
                dirPath.replaceFirst(RegExp(r'^healthpod/data/?'), '');
            savePath = cleanDirPath.isEmpty
                ? outputFileName
                : '$cleanDirPath/$outputFileName';
          }

          // Check if context is still valid before proceeding.
          if (!context.mounted) return false;

          // Write the encrypted data to the pod.
          final result = await writePod(
            savePath,
            json.encode(jsonData),
            context,
            Text('Converting row $i'),
            encrypted: true,
          );

          // Track the success status of each save operation.
          if (result == SolidFunctionCallStatus.success) {
            successfulSaves++;
          } else {
            allSuccess = false;
            debugPrint('Failed to save file for row $i');
          }
        } catch (rowError) {
          debugPrint('Error processing row $i: $rowError');
          allSuccess = false;
        }
      }

      // Log the completion status.
      debugPrint(
          'Processing complete. Successfully saved $successfulSaves files');

      // Show warning for any duplicate timestamps found.
      if (duplicateTimestamps.isNotEmpty) {
        if (!context.mounted) return allSuccess;
        showAlert(
          context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.',
        );
      }

      // Return overall success status.
      return allSuccess && successfulSaves > 0;
    } catch (e) {
      // Handle any errors during the import process.
      debugPrint('Import error: $e');
      if (context.mounted) {
        showAlert(context, 'Error importing CSV: ${e.toString()}');
      }
      return false;
    }
  }
}
