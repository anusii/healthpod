/// Vaccination data exporter.
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

import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/constants/survey.dart';

/// Handles exporting vaccination data from JSON files to a single CSV file.
///
/// This module is specifically focused on vaccination data export functionality.
/// It reads all JSON files from the vaccination directory, processes them, and combines
/// them into a single CSV file sorted by timestamp.

class VaccinationExporter {
  /// Process vaccination JSON files to CSV export.
  static Future<bool> exportToCsv(
    String savePath,
    String dirPath,
    BuildContext context,
  ) async {
    try {
      final dirUrl = await getDirUrl(dirPath);
      final resources = await getResourcesInContainer(dirUrl);
      final files =
          resources.files.where((file) => file.endsWith('.enc.ttl')).toList();

      if (files.isEmpty) {
        throw Exception('No vaccination data files found in directory');
      }

      List<Map<String, dynamic>> allRecords = [];

      for (var fileName in files) {
        try {
          if (!context.mounted) return false;
          final content = await readPod(
            '$dirPath/$fileName',
            context,
            const Text('Reading vaccination data'),
          );

          if (content == SolidFunctionCallStatus.fail ||
              content == SolidFunctionCallStatus.notLoggedIn) {
            continue;
          }

          final jsonData = json.decode(content);
          var timestamp = normaliseTimestamp(
              jsonData[VaccinationSurveyConstants.fieldTimestamp],
              toIso: true);

          final responses = jsonData['responses'];

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
          debugPrint('Error processing file $fileName: $e');
          continue;
        }
      }

      if (allRecords.isEmpty) {
        throw Exception('No valid vaccination records found');
      }

      allRecords.sort((a, b) => a[VaccinationSurveyConstants.fieldTimestamp]
          .compareTo(b[VaccinationSurveyConstants.fieldTimestamp]));

      final headers = [
        VaccinationSurveyConstants.fieldTimestamp,
        VaccinationSurveyConstants.fieldVaccine,
        VaccinationSurveyConstants.fieldProvider,
        VaccinationSurveyConstants.fieldProfessional,
        VaccinationSurveyConstants.fieldCost,
        VaccinationSurveyConstants.fieldNotes,
      ];

      List<List<dynamic>> rows = [headers];
      for (var record in allRecords) {
        rows.add(headers.map((header) => record[header]).toList());
      }

      final csv = const ListToCsvConverter().convert(rows);
      await File(savePath).writeAsString(csv);

      return true;
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }
}
