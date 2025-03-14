/// Vaccination data importer.
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
/// Authors: Kevin Wang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/vaccination_survey.dart';
import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles importing vaccination data from CSV files into JSON format.
///
/// This module focuses specifically on vaccination data import functionality.
/// It processes CSV files containing vaccination records and creates individual
/// JSON files for each record.

class VaccinationImporter {
  static Future<bool> importFromCsv(
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

      // Define the required columns that must be present in the CSV.

      final requiredColumns = [
        VaccinationSurveyConstants.fieldTimestamp.toLowerCase(),
        VaccinationSurveyConstants.fieldVaccineName.toLowerCase(),
        VaccinationSurveyConstants.fieldProvider.toLowerCase(),
      ];

      // Check for any missing required columns and show an alert if any are missing.

      final missingColumns =
          requiredColumns.where((col) => !headers.contains(col)).toList();
      if (missingColumns.isNotEmpty) {
        if (!context.mounted) return false;
        showAlert(context, '''

        Required columns missing: ${missingColumns.join(", ")}

        The following columns are required:
        - ${VaccinationSurveyConstants.fieldTimestamp}
        - ${VaccinationSurveyConstants.fieldVaccineName}
        - ${VaccinationSurveyConstants.fieldProvider}

        These columns are optional:
        - ${VaccinationSurveyConstants.fieldProfessional}
        - ${VaccinationSurveyConstants.fieldCost}
        - ${VaccinationSurveyConstants.fieldNotes}

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

          // Initialize the responses map with empty values for all fields.

          final Map<String, dynamic> responses = {
            VaccinationSurveyConstants.fieldVaccineName: '',
            VaccinationSurveyConstants.fieldProvider: '',
            VaccinationSurveyConstants.fieldProfessional: '',
            VaccinationSurveyConstants.fieldCost: '',
            VaccinationSurveyConstants.fieldNotes: '',
          };

          // Initialize timestamp and validation flag.

          String timestamp = "";
          bool hasRequiredFields = true;

          // Process each column in the current row.

          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

            // Match each column header to its corresponding field and process accordingly.

            switch (header) {
              case String h
                  when h ==
                      VaccinationSurveyConstants.fieldTimestamp.toLowerCase():
                if (value.isEmpty) {
                  hasRequiredFields = false;
                  debugPrint('Row $i: Missing required timestamp');
                  break;
                }
                timestamp = normaliseTimestamp(roundTimestampToSecond(value));
                if (!isValidTimestamp(timestamp)) {
                  throw FormatException(
                      'Row $i: Invalid timestamp format: $value');
                }
                if (!seenTimestamps.add(timestamp)) {
                  duplicateTimestamps.add(formatTimestampForDisplay(timestamp));
                }

              case String h
                  when h ==
                      VaccinationSurveyConstants.fieldVaccineName.toLowerCase():
                if (value.isEmpty) {
                  hasRequiredFields = false;
                  debugPrint('Row $i: Missing required vaccine name');
                } else {
                  responses[VaccinationSurveyConstants.fieldVaccineName] =
                      value;
                }

              case String h
                  when h ==
                      VaccinationSurveyConstants.fieldProvider.toLowerCase():
                if (value.isEmpty) {
                  hasRequiredFields = false;
                  debugPrint('Row $i: Missing required provider');
                } else {
                  responses[VaccinationSurveyConstants.fieldProvider] = value;
                }

              case String h
                  when h ==
                      VaccinationSurveyConstants.fieldProfessional
                          .toLowerCase():
                responses[VaccinationSurveyConstants.fieldProfessional] = value;

              case String h
                  when h == VaccinationSurveyConstants.fieldCost.toLowerCase():
                responses[VaccinationSurveyConstants.fieldCost] = value;

              case String h
                  when h == VaccinationSurveyConstants.fieldNotes.toLowerCase():
                responses[VaccinationSurveyConstants.fieldNotes] = value;
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
            VaccinationSurveyConstants.fieldTimestamp: timestamp,
            'responses': responses,
          };

          // Generate a safe filename using the timestamp.

          final safeTimestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
          final outputFileName = 'vaccination_$safeTimestamp.json.enc.ttl';

          // Determine the correct save path based on the directory structure.

          String savePath;
          if (dirPath.endsWith('/vaccination')) {
            savePath = 'vaccination/$outputFileName';
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
