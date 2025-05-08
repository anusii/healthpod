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

import 'package:flutter/material.dart';

import 'package:healthpod/constants/vaccination_survey.dart';

import 'package:healthpod/utils/health_data_importer_base.dart';

/// Handles importing vaccination data from CSV files into JSON format.
///
/// This class extends HealthDataImporterBase to provide specific implementation
/// for vaccination data import functionality.

class VaccinationImporter extends HealthDataImporterBase {
  @override
  String get dataType => 'vaccination';

  @override
  String get timestampField => VaccinationSurveyConstants.fieldDate;

  @override
  List<String> get requiredColumns => [
        VaccinationSurveyConstants.fieldDate,
        VaccinationSurveyConstants.fieldVaccineName,
        VaccinationSurveyConstants.fieldProvider,
      ];

  @override
  List<String> get optionalColumns => [
        VaccinationSurveyConstants.fieldProfessional,
        VaccinationSurveyConstants.fieldCost,
        VaccinationSurveyConstants.fieldNotes,
      ];

  @override
  Map<String, dynamic> createDefaultResponseMap() {
    return {
      VaccinationSurveyConstants.fieldVaccineName: '',
      VaccinationSurveyConstants.fieldProvider: '',
      VaccinationSurveyConstants.fieldProfessional: '',
      VaccinationSurveyConstants.fieldCost: '',
      VaccinationSurveyConstants.fieldNotes: '',
    };
  }

  @override
  bool processField(
    String header,
    String value,
    Map<String, dynamic> responses,
    int rowIndex,
  ) {
    // Ensure value is not null, use empty string if it is.

    final safeValue = value;

    switch (header) {
      case String h
          when h == VaccinationSurveyConstants.fieldVaccineName.toLowerCase():
        responses[VaccinationSurveyConstants.fieldVaccineName] = safeValue;
        return true;

      case String h
          when h == VaccinationSurveyConstants.fieldProvider.toLowerCase():
        responses[VaccinationSurveyConstants.fieldProvider] = safeValue;
        return true;

      case String h
          when h == VaccinationSurveyConstants.fieldProfessional.toLowerCase():
        responses[VaccinationSurveyConstants.fieldProfessional] = safeValue;
        return true;

      case String h
          when h == VaccinationSurveyConstants.fieldCost.toLowerCase():
        responses[VaccinationSurveyConstants.fieldCost] = safeValue;
        return true;

      case String h
          when h == VaccinationSurveyConstants.fieldNotes.toLowerCase():
        responses[VaccinationSurveyConstants.fieldNotes] = safeValue;
        return true;

      default:
        return true;
    }
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> importCsv(
    String filePath,
    String dirPath,
    BuildContext context,
  ) async {
    return VaccinationImporter().importFromCsv(filePath, dirPath, context);
  }
}
