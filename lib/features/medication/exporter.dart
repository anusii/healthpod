/// Medication data exporter.
//
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
//
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/medication_csv_fields.dart';
import 'package:healthpod/constants/medication_survey.dart';
import 'package:healthpod/utils/health_data_exporter_base.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';

/// Handles exporting medication data from JSON files to a single CSV file.
///
/// This class extends HealthDataExporterBase to provide specific implementation
/// for medication data export functionality.

class MedicationExporter extends HealthDataExporterBase {
  @override
  String get dataType => 'medication';

  @override
  String get timestampField => MedicationCSVFields.fieldTimestamp;

  @override
  List<String> get csvHeaders => MedicationCSVFields.allFields;

  @override
  Map<String, dynamic> processRecord(Map<String, dynamic> jsonData) {
    var timestamp = normaliseTimestamp(
      jsonData[MedicationCSVFields.fieldTimestamp],
      toIso: true,
    );

    final responses = jsonData['responses'];

    return {
      MedicationCSVFields.fieldTimestamp: timestamp,
      MedicationSurveyConstants.fieldName:
          responses[MedicationSurveyConstants.fieldName],
      MedicationSurveyConstants.fieldDosage:
          responses[MedicationSurveyConstants.fieldDosage],
      MedicationSurveyConstants.fieldFrequency:
          responses[MedicationSurveyConstants.fieldFrequency],
      MedicationSurveyConstants.fieldStartDate:
          responses[MedicationSurveyConstants.fieldStartDate],
      MedicationSurveyConstants.fieldNotes:
          responses[MedicationSurveyConstants.fieldNotes],
    };
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> exportCsv(
    String savePath,
    String dirPath,
    BuildContext context,
  ) async {
    return MedicationExporter().exportToCsv(savePath, dirPath);
  }

  /// Process Medication JSON files to CSV export.
  ///
  /// Reads all JSON files in the medication directory, extracts the medication data,
  /// and combines them into a single CSV file sorted by timestamp.

  @override
  Future<bool> exportToCsv(
    String savePath,
    String dirPath,
  ) async {
    try {
      // Get the directory URL for the medication folder.

      final dirUrl = await getDirUrl(dirPath);

      // Get resources in the container.

      final resources = await getResourcesInContainer(dirUrl);
      final files =
          resources.files.where((file) => file.endsWith('.enc.ttl')).toList();

      if (files.isEmpty) {
        throw Exception('No Medication data files found in directory');
      }

      // Store all medication readings.

      List<Map<String, dynamic>> allReadings = [];

      // Process each JSON file.

      for (var fileName in files) {
        try {
          // Read and decrypt the file.

          final content = await readPod('$dirPath/$fileName');

          if (content == SolidFunctionCallStatus.fail.toString() ||
              content == SolidFunctionCallStatus.notLoggedIn.toString()) {
            continue;
          }

          // Parse JSON content.

          final jsonData = json.decode(content);

          // Ensure we use ISO format for timestamp with T and Z.

          var timestamp = normaliseTimestamp(
            jsonData[MedicationCSVFields.fieldTimestamp],
            toIso: true,
          );

          final responses = jsonData['responses'];

          // Add to readings list.

          allReadings.add({
            MedicationCSVFields.fieldTimestamp: timestamp,
            MedicationSurveyConstants.fieldName:
                responses[MedicationSurveyConstants.fieldName],
            MedicationSurveyConstants.fieldDosage:
                responses[MedicationSurveyConstants.fieldDosage],
            MedicationSurveyConstants.fieldFrequency:
                responses[MedicationSurveyConstants.fieldFrequency],
            MedicationSurveyConstants.fieldStartDate:
                responses[MedicationSurveyConstants.fieldStartDate],
            MedicationSurveyConstants.fieldNotes:
                responses[MedicationSurveyConstants.fieldNotes] ?? '',
          });
        } catch (e) {
          debugPrint('Error processing file $fileName: $e');
          continue;
        }
      }

      if (allReadings.isEmpty) {
        throw Exception('No valid Medication readings found');
      }

      // Sort readings by timestamp.

      allReadings.sort(
        (a, b) => a[MedicationCSVFields.fieldTimestamp].compareTo(
          b[MedicationCSVFields.fieldTimestamp],
        ),
      );

      // Prepare CSV data.

      final headers = MedicationCSVFields.allFields;

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
