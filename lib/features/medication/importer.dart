/// Medication data importer.
//
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:healthpod/constants/medication_csv_fields.dart';
import 'package:healthpod/constants/medication_survey.dart';
import 'package:healthpod/utils/health_data_importer_base.dart';

/// Handles importing medication data from CSV files into JSON format.
///
/// This class extends HealthDataImporterBase to provide specific implementation
/// for medication data import functionality.

class MedicationImporter extends HealthDataImporterBase {
  @override
  String get dataType => 'medication';

  @override
  String get timestampField => MedicationCSVFields.fieldTimestamp;

  @override
  List<String> get requiredColumns => MedicationCSVFields.requiredFields;

  @override
  List<String> get optionalColumns => MedicationCSVFields.optionalFields;

  @override
  Map<String, dynamic> createDefaultResponseMap() {
    return {
      MedicationSurveyConstants.fieldName: '',
      MedicationSurveyConstants.fieldDosage: '',
      MedicationSurveyConstants.fieldFrequency: '',
      MedicationSurveyConstants.fieldStartDate: '',
      MedicationSurveyConstants.fieldNotes: '',
    };
  }

  @override
  bool processField(
    String header,
    String value,
    Map<String, dynamic> responses,
    int rowIndex,
  ) {
    switch (header) {
      // Required field: Medication name.

      case String h when h == MedicationSurveyConstants.fieldName.toLowerCase():
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required medication name');
          return false;
        } else {
          responses[MedicationSurveyConstants.fieldName] = value;
          return true;
        }

      // Required field: Dosage.

      case String h
          when h == MedicationSurveyConstants.fieldDosage.toLowerCase():
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required dosage value');
          return false;
        } else {
          responses[MedicationSurveyConstants.fieldDosage] = value;
          return true;
        }

      // Required field: Frequency.

      case String h
          when h == MedicationSurveyConstants.fieldFrequency.toLowerCase():
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required frequency value');
          return false;
        } else {
          responses[MedicationSurveyConstants.fieldFrequency] = value;
          return true;
        }

      // Required field: Start Date.

      case String h
          when h == MedicationSurveyConstants.fieldStartDate.toLowerCase():
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required start date value');
          return false;
        } else {
          responses[MedicationSurveyConstants.fieldStartDate] = value;
          return true;
        }

      // Optional field: Notes.

      case String h
          when h == MedicationSurveyConstants.fieldNotes.toLowerCase():
        responses[MedicationSurveyConstants.fieldNotes] = value;
        return true;

      default:
        // Ignore unknown fields.

        return true;
    }
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> importCsv(
    String filePath,
    String dirPath,
    BuildContext context,
  ) async {
    return MedicationImporter().importFromCsv(filePath, dirPath, context);
  }
}
