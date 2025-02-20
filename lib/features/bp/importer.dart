/// Blood pressure data importer.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/survey.dart';
import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles importing blood pressure data from CSV files into JSON format.
///
/// This module focuses specifically on BP data import functionality.
/// It processes CSV files containing BP readings and creates individual
/// JSON files for each reading.

class BPImporter {
  /// Process BP CSV file import, creating individual JSON files for each row.
  ///
  /// Each row is saved as a separate JSON file with timestamp and responses.
  /// Files are saved in the specified directory with timestamps in filenames.

  static Future<bool> importFromCsv(
    String filePath, // Path to the input CSV file.
    String dirPath, // Directory path where JSON files will be saved.
    BuildContext context, // Flutter build context for UI interactions.
  ) async {
    try {
      // Start processing and log initial parameters.

      debugPrint('Starting CSV processing');
      final file = File(filePath);
      final String content = await file.readAsString();

      /// Configure CSV parser with specific settings for handling blood pressure data.
      ///
      /// - shouldParseNumbers: false -> Keep all values as strings initially for proper validation.
      /// - allowInvalid: true -> Don't fail on malformed rows, we'll validate manually.
      /// - textDelimiter: '"' -> Handle quoted fields (e.g., for notes with commas).

      final fields = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: ',',
        allowInvalid: true,
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(content);

      // Basic validation - ensure file isn't empty.

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract headers and normalise them (lowercase, trimmed) for consistent comparison.

      final headers = List<String>.from(
          fields[0].map((h) => h.toString().trim().toLowerCase()));

      // Define required columns - these must be present in the CSV.
      // Optional columns (feeling, notes) don't need to be validated here.

      final requiredColumns = [
        HealthSurveyConstants.fieldTimestamp.toLowerCase(),
        HealthSurveyConstants.fieldSystolic.toLowerCase(),
        HealthSurveyConstants.fieldDiastolic.toLowerCase(),
        HealthSurveyConstants.fieldHeartRate.toLowerCase(),
      ];

      // Validate that all required columns are present in the CSV.

      final missingColumns =
          requiredColumns.where((col) => !headers.contains(col)).toList();
      if (missingColumns.isNotEmpty) {
        if (!context.mounted) return false;
        // Show detailed error message explaining required and optional columns.

        showAlert(context, '''

        Required columns missing: ${missingColumns.join(", ")}

        The following columns are required:
        - ${HealthSurveyConstants.fieldTimestamp}
        - ${HealthSurveyConstants.fieldSystolic}
        - ${HealthSurveyConstants.fieldDiastolic}
        - ${HealthSurveyConstants.fieldHeartRate}

        These columns are optional:
        - ${HealthSurveyConstants.fieldFeeling}
        - ${HealthSurveyConstants.fieldNotes}

        ''');
        return false;
      }

      // Initialise tracking variables for processing state.

      final Set<String> seenTimestamps = {}; // Track unique timestamps.
      final List<String> duplicateTimestamps =
          []; // Track duplicate timestamps for warning.
      bool allSuccess = true; // Track overall success.
      int successfulSaves = 0; // Count successful saves.

      // Process each data row (skip header row by starting at index 1).

      for (var i = 1; i < fields.length; i++) {
        try {
          // Convert row data to strings, replacing null values with empty strings.

          final row =
              List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
          if (row.isEmpty) continue; // Skip empty rows.

          // Ensure row has enough columns by padding with empty strings if needed.

          while (row.length < headers.length) {
            row.add('');
          }

          // Initialise response map with default values
          // Required fields default to 0, optional fields to empty string.

          final Map<String, dynamic> responses = {
            HealthSurveyConstants.fieldSystolic: 0,
            HealthSurveyConstants.fieldDiastolic: 0,
            HealthSurveyConstants.fieldHeartRate: 0,
            HealthSurveyConstants.fieldFeeling: "",
            HealthSurveyConstants.fieldNotes: "",
          };

          String timestamp = "";
          bool hasRequiredFields =
              true; // Track if all required fields are valid.

          // Process each field in the row.

          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

            // Use pattern matching to handle different field types.

            switch (header) {
              // Required field: Timestamp.

              case String h
                  when h == HealthSurveyConstants.fieldTimestamp.toLowerCase():
                if (value.isEmpty) {
                  hasRequiredFields = false;
                  debugPrint('Row $i: Missing required timestamp');
                  break;
                }
                // Normalise and validate timestamp format.

                timestamp = normaliseTimestamp(roundTimestampToSecond(value));
                if (!isValidTimestamp(timestamp)) {
                  throw FormatException(
                      'Row $i: Invalid timestamp format: $value');
                }
                // Track duplicate timestamps.

                if (!seenTimestamps.add(timestamp)) {
                  duplicateTimestamps.add(formatTimestampForDisplay(timestamp));
                }

              // Required field: Systolic blood pressure.

              case String h
                  when h == HealthSurveyConstants.fieldSystolic.toLowerCase():
                final systolic =
                    double.tryParse(value); // Handle decimal numbers as well.
                if (systolic == null) {
                  hasRequiredFields = false;
                  debugPrint(
                      'Row $i: Invalid or missing systolic value: $value');
                } else {
                  responses[HealthSurveyConstants.fieldSystolic] = systolic;
                }

              // Required field: Diastolic blood pressure.

              case String h
                  when h == HealthSurveyConstants.fieldDiastolic.toLowerCase():
                final diastolic = double.tryParse(value);
                if (diastolic == null) {
                  hasRequiredFields = false;
                  debugPrint(
                      'Row $i: Invalid or missing diastolic value: $value');
                } else {
                  responses[HealthSurveyConstants.fieldDiastolic] = diastolic;
                }

              // Required field: Heart rate.

              case String h
                  when h == HealthSurveyConstants.fieldHeartRate.toLowerCase():
                final heartRate = double.tryParse(value);
                if (heartRate == null) {
                  hasRequiredFields = false;
                  debugPrint(
                      'Row $i: Invalid or missing heart rate value: $value');
                } else {
                  responses[HealthSurveyConstants.fieldHeartRate] = heartRate;
                }

              // Optional field: Feeling - can be any value including empty.

              case String h
                  when h == HealthSurveyConstants.fieldFeeling.toLowerCase():
                responses[HealthSurveyConstants.fieldFeeling] = value;

              // Optional field: Notes - can be any value including empty.

              case String h
                  when h == HealthSurveyConstants.fieldNotes.toLowerCase():
                responses[HealthSurveyConstants.fieldNotes] = value;
            }
          }

          // Skip this row if any required field is missing or invalid.

          if (!hasRequiredFields) {
            debugPrint(
                'Skipping row $i due to missing or invalid required fields');
            continue;
          }

          // Prepare JSON data structure.

          final jsonData = {
            HealthSurveyConstants.fieldTimestamp: timestamp,
            'responses': responses,
          };

          // Create safe filename by replacing invalid characters.

          final safeTimestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
          final outputFileName = 'blood_pressure_$safeTimestamp.json.enc.ttl';

          // Construct proper save path based on directory structure.

          String savePath;
          if (dirPath.endsWith('/blood_pressure')) {
            savePath = 'blood_pressure/$outputFileName';
          } else {
            final cleanDirPath =
                dirPath.replaceFirst(RegExp(r'^healthpod/data/?'), '');
            savePath = cleanDirPath.isEmpty
                ? outputFileName
                : '$cleanDirPath/$outputFileName';
          }

          if (!context.mounted) return false;

          // Save encrypted JSON file to POD.

          final result = await writePod(
            savePath,
            json.encode(jsonData),
            context,
            Text('Converting row $i'),
            encrypted: true,
          );

          // Track save success/failure.

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

      debugPrint(
          'Processing complete. Successfully saved $successfulSaves files');

      // Show warning if duplicate timestamps were found.

      if (duplicateTimestamps.isNotEmpty) {
        if (!context.mounted) return allSuccess;
        showAlert(
          context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.',
        );
      }

      // Return true only if at least one file was successfully saved.

      return allSuccess && successfulSaves > 0;
    } catch (e) {
      // Handle any unexpected errors.

      debugPrint('Import error: $e');
      if (context.mounted) {
        showAlert(context, 'Error importing CSV: ${e.toString()}');
      }
      return false;
    }
  }
}
