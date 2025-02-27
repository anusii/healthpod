/// Blood pressure data exporter.
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
import 'package:healthpod/utils/normalise_timestamp.dart';

/// Handles exporting blood pressure data from JSON files to a single CSV file.
///
/// This module is specifically focused on BP data export functionality.
/// It reads all JSON files from the BP directory, processes them, and combines
/// them into a single CSV file sorted by timestamp.

class BPExporter {
  /// Process BP JSON files to CSV export.
  ///
  /// Reads all JSON files in the BP directory, extracts the blood pressure data,
  /// and combines them into a single CSV file sorted by timestamp.

  static Future<bool> exportToCsv(
    String savePath,
    String dirPath,
    BuildContext context,
  ) async {
    try {
      // Get the directory URL for the bp folder.

      final dirUrl = await getDirUrl(dirPath);

      // Get resources in the container.

      final resources = await getResourcesInContainer(dirUrl);
      final files =
          resources.files.where((file) => file.endsWith('.enc.ttl')).toList();

      // Use 'Blood pressure' instead of BP for user clarity.

      if (files.isEmpty) {
        throw Exception('No Blood pressure data files found in directory');
      }

      // Store all BP readings.

      List<Map<String, dynamic>> allReadings = [];

      // Process each JSON file.

      for (var fileName in files) {
        try {
          // Read and decrypt the file.

          if (!context.mounted) return false;
          final content = await readPod(
            '$dirPath/$fileName',
            context,
            const Text('Reading Blood pressure data'),
          );

          if (content == SolidFunctionCallStatus.fail ||
              content == SolidFunctionCallStatus.notLoggedIn) {
            continue;
          }

          // Parse JSON content.

          final jsonData = json.decode(content);

          // Ensure we use ISO format for timestamp with T and Z.

          var timestamp = normaliseTimestamp(
              jsonData[HealthSurveyConstants.fieldTimestamp],
              toIso: true);

          final responses = jsonData['responses'];

          // Add to readings list.

          allReadings.add({
            HealthSurveyConstants.fieldTimestamp: timestamp,
            HealthSurveyConstants.fieldSystolic:
                responses[HealthSurveyConstants.fieldSystolic],
            HealthSurveyConstants.fieldDiastolic:
                responses[HealthSurveyConstants.fieldDiastolic],
            HealthSurveyConstants.fieldHeartRate:
                responses[HealthSurveyConstants.fieldHeartRate],
            HealthSurveyConstants.fieldFeeling:
                responses[HealthSurveyConstants.fieldFeeling],
            HealthSurveyConstants.fieldNotes:
                responses[HealthSurveyConstants.fieldNotes],
          });
        } catch (e) {
          debugPrint('Error processing file $fileName: $e');
          continue;
        }
      }

      if (allReadings.isEmpty) {
        throw Exception('No valid Blood pressure readings found');
      }

      // Sort readings by timestamp.

      allReadings.sort((a, b) => a[HealthSurveyConstants.fieldTimestamp]
          .compareTo(b[HealthSurveyConstants.fieldTimestamp]));

      // Prepare CSV data.

      final headers = [
        HealthSurveyConstants.fieldTimestamp,
        HealthSurveyConstants.fieldSystolic,
        HealthSurveyConstants.fieldDiastolic,
        HealthSurveyConstants.fieldHeartRate,
        HealthSurveyConstants.fieldFeeling,
        HealthSurveyConstants.fieldNotes,
      ];

      List<List<dynamic>> rows = [headers];

      // Add data rows.

      for (var reading in allReadings) {
        rows.add(headers.map((header) => reading[header]).toList());
      }

      // Convert to CSV.

      final csv = const ListToCsvConverter().convert(rows);

      // Save CSV file.

      final file = File(savePath);
      await file.writeAsString(csv);

      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }
}
