/// Vaccination survey constants.
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

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// Defines the standard set of vaccination survey questions.
class VaccinationSurveyConstants {
  /// Data field names (for storage/CSV).
  static const String fieldTimestamp = 'timestamp';
  static const String fieldVaccine = 'vaccine';
  static const String fieldProvider = 'provider';
  static const String fieldProfessional = 'professional';
  static const String fieldCost = 'cost';
  static const String fieldNotes = 'notes';

  /// Question texts (for UI only).
  static const String vaccine = "Which vaccine did you receive?";
  static const String provider = "Where did you receive the vaccine?";
  static const String professional = "Healthcare professional name";
  static const String cost = "Cost of vaccination";
  static const String notes = "Any additional notes?";

  /// The list of questions used in the vaccination survey.
  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: vaccine,
      fieldName: fieldVaccine,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: provider,
      fieldName: fieldProvider,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: professional,
      fieldName: fieldProfessional,
      type: HealthDataType.text,
      isRequired: false,
    ),
    HealthSurveyQuestion(
      question: cost,
      fieldName: fieldCost,
      type: HealthDataType.text,
      isRequired: false,
    ),
    HealthSurveyQuestion(
      question: notes,
      fieldName: fieldNotes,
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];
}
