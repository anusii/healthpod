/// Process blood pressure CSV to JSON.
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
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import 'package:healthpod/constants/survey.dart';
import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';
import 'package:solidpod/solidpod.dart';

/// Process BP CSV file import, creating individual JSON files for each row.
///
/// Each row is saved as a separate JSON file with timestamp and responses.
/// Files are saved in the specified directory with timestamps in filenames.

Future<bool> processBpCsvToJson(
  String filePath,
  String dirPath,
  BuildContext context,
) async {
  try {
    // Read and parse CSV file.

    final file = File(filePath);
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (fields.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Extract and validate headers.

    final headers = List<String>.from(fields[0]);
    final requiredColumns = [
      HealthSurveyConstants.fieldTimestamp,
      HealthSurveyConstants.fieldSystolic,
      HealthSurveyConstants.fieldDiastolic,
      HealthSurveyConstants.fieldHeartRate,
    ];
    final missingColumns = requiredColumns
        .where((col) => !headers
            .map((h) => h.trim().toLowerCase())
            .contains(col.toLowerCase()))
        .toList();

    // Show error if required columns missing.

    if (missingColumns.isNotEmpty) {
      if (!context.mounted) return false;
      const requiredColumnMessage = '''

        Your CSV file must contain these required columns:

        - ${HealthSurveyConstants.fieldTimestamp}
        - ${HealthSurveyConstants.fieldSystolic}
        - ${HealthSurveyConstants.fieldDiastolic}
        - ${HealthSurveyConstants.fieldHeartRate}

        Optional columns:

        - ${HealthSurveyConstants.fieldFeeling}
        - ${HealthSurveyConstants.fieldNotes}

        ''';

      showAlert(context, requiredColumnMessage);
      return false;
    }

    // Track duplicate timestamps after rounding.

    final Set<String> seenTimestamps = {};
    final List<String> duplicateTimestamps = [];
    bool allSuccess = true;

    // Process each row after headers.

    for (var i = 1; i < fields.length; i++) {
      try {
        final row = fields[i];
        if (row.length != headers.length) continue;

        // Initialise response structure.

        final Map<String, dynamic> responses = {
          HealthSurveyConstants.fieldSystolic: 0,
          HealthSurveyConstants.fieldDiastolic: 0,
          HealthSurveyConstants.fieldHeartRate: 0,
          HealthSurveyConstants.fieldFeeling: "",
          HealthSurveyConstants.fieldNotes: "",
        };

        String timestamp = "";

        // Map CSV values to response fields.

        for (var j = 0; j < headers.length; j++) {
          final header = headers[j].trim().toLowerCase();
          final value = row[j];

          switch (header) {
            case HealthSurveyConstants.fieldTimestamp:
              timestamp = roundTimestampToSecond(value.toString());

              // Parse timestamp and normalise it to include 'T'.

              timestamp = normaliseTimestamp(value.toString());

              // Check if timestamp is valid (i.e. in ISO format with or without 'T').

              if (!isValidTimestamp(timestamp)) {
                throw FormatException('Invalid timestamp format: $value');
              }

              // Format duplicate timestamp for later display.

              if (!seenTimestamps.add(timestamp)) {
                duplicateTimestamps.add(formatTimestampForDisplay(timestamp));
              }
            case HealthSurveyConstants.fieldSystolic:
              responses[HealthSurveyConstants.fieldSystolic] =
                  int.parse(value.toString());
            case HealthSurveyConstants.fieldDiastolic:
              responses[HealthSurveyConstants.fieldDiastolic] =
                  int.parse(value.toString());
            case HealthSurveyConstants.fieldHeartRate:
              responses[HealthSurveyConstants.fieldHeartRate] =
                  int.parse(value.toString());
            case HealthSurveyConstants.fieldFeeling:
              responses[HealthSurveyConstants.fieldFeeling] = value.toString();
            case HealthSurveyConstants.fieldNotes:
              responses[HealthSurveyConstants.fieldNotes] = value.toString();
          }
        }

        // Prepare JSON data.

        final jsonData = {
          HealthSurveyConstants.fieldTimestamp: timestamp,
          'responses': responses,
        };

        // Create filename-safe timestamp and construct save path.

        timestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
        final outputFileName = 'blood_pressure_$timestamp.json.enc.ttl';
        final savePath =
            '${dirPath.replaceFirst('healthpod/data/', '')}/$outputFileName';

        if (!context.mounted) return false;

        // Save encrypted JSON file.

        final result = await writePod(
          savePath,
          json.encode(jsonData),
          context,
          Text('Converting row $i'),
          encrypted: true,
        );

        if (result != SolidFunctionCallStatus.success) {
          allSuccess = false;
        }
      } catch (rowError) {
        debugPrint('Error processing row $i: $rowError');
        allSuccess = false;
      }
    }

    // Warn about duplicate timestamps if any found.

    if (duplicateTimestamps.isNotEmpty) {
      if (!context.mounted) return allSuccess;
      showAlert(context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.');
    }

    return allSuccess;
  } catch (e) {
    debugPrint('Import error: $e');
    return false;
  }
}
