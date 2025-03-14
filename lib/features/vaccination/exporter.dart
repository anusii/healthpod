/// Vaccination data exporter.
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
import 'package:healthpod/utils/normalise_timestamp.dart';

/// Handles exporting vaccination data from JSON files to a single CSV file.
///
/// This module is specifically focused on vaccination data export functionality.
/// It reads all JSON files from the vaccination directory, processes them, and combines
/// them into a single CSV file sorted by timestamp.

class VaccinationExporter {
  /// Process vaccination JSON files to CSV export.
  ///
  static Future<bool> exportToCsv(
    String savePath,
    String dirPath,
    BuildContext context,
  ) async {
    try {
      // Get the directory URL for the vaccination folder.

      final dirUrl = await getDirUrl(dirPath);

      // Get all resources in the container.

      final resources = await getResourcesInContainer(dirUrl);

      // Filter for only encrypted files with .enc.ttl extension.

      final files =
          resources.files.where((file) => file.endsWith('.enc.ttl')).toList();

      // Throw error if no files are found.

      if (files.isEmpty) {
        throw Exception('No vaccination data files found in directory');
      }

      // Initialize list to store all vaccination records.

      List<Map<String, dynamic>> allRecords = [];

      // Process each file one by one.

      for (var fileName in files) {
        try {
          // Check if context is still valid before proceeding.

          if (!context.mounted) return false;

          // Read and decrypt the file contents.

          final content = await readPod(
            '$dirPath/$fileName',
            context,
            const Text('Reading vaccination data'),
          );

          // Skip file if read operation failed.

          if (content == SolidFunctionCallStatus.fail ||
              content == SolidFunctionCallStatus.notLoggedIn) {
            continue;
          }

          // Parse the JSON content from the file.

          final jsonData = json.decode(content);

          // Normalize the timestamp to ISO format.

          var timestamp = normaliseTimestamp(
              jsonData[VaccinationSurveyConstants.fieldTimestamp],
              toIso: true);

          // Extract the responses section containing vaccination details.

          final responses = jsonData['responses'];

          // Add the record with all fields to the collection.

          allRecords.add({
            VaccinationSurveyConstants.fieldTimestamp: timestamp,
            VaccinationSurveyConstants.fieldVaccine:
                responses[VaccinationSurveyConstants.fieldVaccine],
            VaccinationSurveyConstants.fieldProvider:
                responses[VaccinationSurveyConstants.fieldProvider],
            VaccinationSurveyConstants.fieldProfessional:
                responses[VaccinationSurveyConstants.fieldProfessional],
            VaccinationSurveyConstants.fieldCost:
                responses[VaccinationSurveyConstants.fieldCost],
            VaccinationSurveyConstants.fieldNotes:
                responses[VaccinationSurveyConstants.fieldNotes],
          });
        } catch (e) {
          // Log error and continue with next file if current file fails.

          debugPrint('Error processing file $fileName: $e');
          continue;
        }
      }

      // Verify we have at least one valid record.

      if (allRecords.isEmpty) {
        throw Exception('No valid vaccination records found');
      }

      // Sort all records by timestamp in ascending order.

      allRecords.sort((a, b) => a[VaccinationSurveyConstants.fieldTimestamp]
          .compareTo(b[VaccinationSurveyConstants.fieldTimestamp]));

      // Define the CSV column headers.

      final headers = [
        VaccinationSurveyConstants.fieldTimestamp,
        VaccinationSurveyConstants.fieldVaccine,
        VaccinationSurveyConstants.fieldProvider,
        VaccinationSurveyConstants.fieldProfessional,
        VaccinationSurveyConstants.fieldCost,
        VaccinationSurveyConstants.fieldNotes,
      ];

      // Create CSV rows starting with headers.

      List<List<dynamic>> rows = [headers];

      // Add data rows by mapping each record to the headers.

      for (var record in allRecords) {
        rows.add(headers.map((header) => record[header]).toList());
      }

      // Convert rows to CSV format.

      final csv = const ListToCsvConverter().convert(rows);

      // Write the CSV content to the specified file.

      await File(savePath).writeAsString(csv);

      return true;
    } catch (e) {
      // Log any errors during export process.

      debugPrint('Export error: $e');
      return false;
    }
  }
}
