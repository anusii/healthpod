/// Medication CSV field constants.
///
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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

import 'package:healthpod/constants/medication_survey.dart';

/// CSV field constants for medication data.
///
/// This class provides the field names for CSV imports and exports of medication data.
/// The field names correspond to the JSON structure used in the medication feature.

class MedicationCSVFields {
  /// Timestamp field for recording when the medication entry was created.
  static const String fieldTimestamp = 'timestamp';

  /// Required fields for medication CSV.
  static const List<String> requiredFields = [
    fieldTimestamp,
    MedicationSurveyConstants.fieldName,
    MedicationSurveyConstants.fieldDosage,
    MedicationSurveyConstants.fieldFrequency,
    MedicationSurveyConstants.fieldStartDate,
  ];

  /// Optional fields for medication CSV.
  static const List<String> optionalFields = [
    MedicationSurveyConstants.fieldNotes,
  ];

  /// All fields that can be included in a medication CSV.
  static const List<String> allFields = [
    fieldTimestamp,
    MedicationSurveyConstants.fieldName,
    MedicationSurveyConstants.fieldDosage,
    MedicationSurveyConstants.fieldFrequency,
    MedicationSurveyConstants.fieldStartDate,
    MedicationSurveyConstants.fieldNotes,
  ];
}
