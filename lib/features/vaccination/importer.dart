/// Vaccination data importer.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

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
      debugPrint('Starting CSV processing');
      final file = File(filePath);
      final String content = await file.readAsString();

      final fields = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: ',',
        allowInvalid: true,
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(content);

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headers = List<String>.from(
          fields[0].map((h) => h.toString().trim().toLowerCase()));

      final requiredColumns = [
        VaccinationSurveyConstants.fieldTimestamp.toLowerCase(),
        VaccinationSurveyConstants.fieldVaccine.toLowerCase(),
        VaccinationSurveyConstants.fieldProvider.toLowerCase(),
      ];

      final missingColumns =
          requiredColumns.where((col) => !headers.contains(col)).toList();
      if (missingColumns.isNotEmpty) {
        if (!context.mounted) return false;
        showAlert(context, '''

        Required columns missing: ${missingColumns.join(", ")}

        The following columns are required:
        - ${VaccinationSurveyConstants.fieldTimestamp}
        - ${VaccinationSurveyConstants.fieldVaccine}
        - ${VaccinationSurveyConstants.fieldProvider}

        These columns are optional:
        - ${VaccinationSurveyConstants.fieldProfessional}
        - ${VaccinationSurveyConstants.fieldCost}
        - ${VaccinationSurveyConstants.fieldNotes}

        ''');
        return false;
      }

      final Set<String> seenTimestamps = {};
      final List<String> duplicateTimestamps = [];
      bool allSuccess = true;
      int successfulSaves = 0;

      for (var i = 1; i < fields.length; i++) {
        try {
          final row =
              List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
          if (row.isEmpty) continue;

          while (row.length < headers.length) {
            row.add('');
          }

          final Map<String, dynamic> responses = {
            VaccinationSurveyConstants.fieldVaccine: '',
            VaccinationSurveyConstants.fieldProvider: '',
            VaccinationSurveyConstants.fieldProfessional: '',
            VaccinationSurveyConstants.fieldCost: '',
            VaccinationSurveyConstants.fieldNotes: '',
          };

          String timestamp = "";
          bool hasRequiredFields = true;

          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

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
                      VaccinationSurveyConstants.fieldVaccine.toLowerCase():
                if (value.isEmpty) {
                  hasRequiredFields = false;
                  debugPrint('Row $i: Missing required vaccine name');
                } else {
                  responses[VaccinationSurveyConstants.fieldVaccine] = value;
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

          if (!hasRequiredFields) {
            debugPrint(
                'Skipping row $i due to missing or invalid required fields');
            continue;
          }

          final jsonData = {
            VaccinationSurveyConstants.fieldTimestamp: timestamp,
            'responses': responses,
          };

          final safeTimestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
          final outputFileName = 'vaccination_$safeTimestamp.json.enc.ttl';

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

          if (!context.mounted) return false;

          final result = await writePod(
            savePath,
            json.encode(jsonData),
            context,
            Text('Converting row $i'),
            encrypted: true,
          );

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

      if (duplicateTimestamps.isNotEmpty) {
        if (!context.mounted) return allSuccess;
        showAlert(
          context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.',
        );
      }

      return allSuccess && successfulSaves > 0;
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        showAlert(context, 'Error importing CSV: ${e.toString()}');
      }
      return false;
    }
  }
}
