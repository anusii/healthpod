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

import 'package:flutter/material.dart';

import 'package:healthpod/constants/blood_pressure_survey.dart';
import 'package:healthpod/constants/csv_fields.dart';
import 'package:healthpod/utils/health_data_importer_base.dart';

/// Handles importing blood pressure data from CSV files into JSON format.
///
/// This class extends HealthDataImporterBase to provide specific implementation
/// for blood pressure data import functionality.

class BPImporter extends HealthDataImporterBase {
  @override
  String get dataType => 'blood_pressure';

  @override
  String get timestampField => HealthSurveyConstants.fieldTimestamp;

  @override
  List<String> get requiredColumns => BPCSVFields.requiredFields;

  @override
  List<String> get optionalColumns => BPCSVFields.optionalFields;

  @override
  Map<String, dynamic> createDefaultResponseMap() {
    return {
      BPCSVFields.fieldSystolic: 0,
      BPCSVFields.fieldDiastolic: 0,
      BPCSVFields.fieldHeartRate: 0,
      BPCSVFields.fieldNotes: '',
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
      // Required field: Systolic blood pressure.

      case String h when h == HealthSurveyConstants.fieldSystolic.toLowerCase():
        final systolic = double.tryParse(value);
        if (systolic == null) {
          debugPrint(
            'Row $rowIndex: Invalid or missing systolic value: $value',
          );
          return false;
        } else {
          responses[HealthSurveyConstants.fieldSystolic] = systolic;
          return true;
        }

      // Required field: Diastolic blood pressure.

      case String h
          when h == HealthSurveyConstants.fieldDiastolic.toLowerCase():
        final diastolic = double.tryParse(value);
        if (diastolic == null) {
          debugPrint(
            'Row $rowIndex: Invalid or missing diastolic value: $value',
          );
          return false;
        } else {
          responses[HealthSurveyConstants.fieldDiastolic] = diastolic;
          return true;
        }

      // Required field: Heart rate.

      case String h
          when h == HealthSurveyConstants.fieldHeartRate.toLowerCase():
        final heartRate = double.tryParse(value);
        if (heartRate == null) {
          debugPrint(
            'Row $rowIndex: Invalid or missing heart rate value: $value',
          );
          return false;
        } else {
          responses[HealthSurveyConstants.fieldHeartRate] = heartRate;
          return true;
        }

      // Optional field: Notes - can be any value including empty.

      case String h when h == HealthSurveyConstants.fieldNotes.toLowerCase():
        responses[HealthSurveyConstants.fieldNotes] = value;
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
    BuildContext context, {
    // Optional: provide content directly for web.

    String? fileContent,
    // Progress callback.

    void Function(String message, double progress)? onProgress,
  }) async {
    // Remove verbose debug logs for cleaner console output.

    try {
      final result = await BPImporter().importFromCsv(
        filePath,
        dirPath,
        context,
        fileContent: fileContent,
        onProgress: onProgress,
      );
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [BP Import] Import failed: $e');
      debugPrint('❌ [BP Import] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
