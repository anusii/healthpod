/// Survey constants for medication.
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

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// Defines the standard set of medication survey questions.
/// These questions are used consistently throughout the application
/// for collecting medication-related data.

class MedicationSurveyConstants {
  // Data field names (for storage/CSV).

  static const String fieldName = 'name';
  static const String fieldDosage = 'dosage';
  static const String fieldFrequency = 'frequency';
  static const String fieldStartDate = 'start_date';
  static const String fieldNotes = 'notes';

  /// Question texts (for UI only).

  static const String name = 'What medication are you taking?';
  static const String dosage = 'What is the dosage?';
  static const String frequency = 'How often do you take it?';
  static const String startDate = 'When did you start taking it?';
  static const String notes = 'Any additional notes?';

  /// The list of questions used in the medication survey.
  /// Each question includes type validation, and required status.

  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: name,
      fieldName: fieldName,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: dosage,
      fieldName: fieldDosage,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: frequency,
      fieldName: fieldFrequency,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: startDate,
      fieldName: fieldStartDate,
      type: HealthDataType.date,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: notes,
      fieldName: fieldNotes,
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];
}
