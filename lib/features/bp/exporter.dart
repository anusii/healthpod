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

import 'package:healthpod/constants/blood_pressure_survey.dart';
import 'package:healthpod/constants/csv_fields.dart';
import 'package:healthpod/utils/health_data_exporter_base.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';

/// Handles exporting blood pressure data from JSON files to a single CSV file.
///
/// This class extends HealthDataExporterBase to provide specific implementation
/// for blood pressure data export functionality.

class BPExporter extends HealthDataExporterBase {
  @override
  String get dataType => 'bp';

  @override
  String get timestampField => HealthSurveyConstants.fieldTimestamp;

  @override
  List<String> get csvHeaders => BPCSVFields.allFields;

  @override
  Map<String, dynamic> processRecord(Map<String, dynamic> jsonData) {
    var timestamp =
        normaliseTimestamp(jsonData[BPCSVFields.fieldTimestamp], toIso: true);

    final responses = jsonData['responses'];

    return {
      BPCSVFields.fieldTimestamp: timestamp,
      BPCSVFields.fieldSystolic: responses[BPCSVFields.fieldSystolic],
      BPCSVFields.fieldDiastolic: responses[BPCSVFields.fieldDiastolic],
      BPCSVFields.fieldHeartRate: responses[BPCSVFields.fieldHeartRate],
      BPCSVFields.fieldNotes: responses[BPCSVFields.fieldNotes],
    };
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> exportCsv(
    String savePath,
    String dirPath,
    BuildContext context,
  ) async {
    return BPExporter().exportToCsv(savePath, dirPath, context);
  }

  /// Process BP JSON files to CSV export.
  ///
  /// Reads all JSON files in the BP directory, extracts the blood pressure data,
  /// and combines them into a single CSV file sorted by timestamp.

  @override
  Future<bool> exportToCsv(
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

          if (content == SolidFunctionCallStatus.fail.toString() ||
              content == SolidFunctionCallStatus.notLoggedIn.toString()) {
            continue;
          }

          // Parse JSON content.

          final jsonData = json.decode(content);

          // Ensure we use ISO format for timestamp with T and Z.

          var timestamp = normaliseTimestamp(
              jsonData[BPCSVFields.fieldTimestamp],
              toIso: true);

          final responses = jsonData['responses'];

          // Add to readings list.

          allReadings.add({
            BPCSVFields.fieldTimestamp: timestamp,
            BPCSVFields.fieldSystolic: responses[BPCSVFields.fieldSystolic],
            BPCSVFields.fieldDiastolic: responses[BPCSVFields.fieldDiastolic],
            BPCSVFields.fieldHeartRate: responses[BPCSVFields.fieldHeartRate],
            BPCSVFields.fieldNotes: responses[BPCSVFields.fieldNotes],
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

      allReadings.sort((a, b) => a[BPCSVFields.fieldTimestamp]
          .compareTo(b[BPCSVFields.fieldTimestamp]));

      // Prepare CSV data.

      final headers = BPCSVFields.allFields;

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
