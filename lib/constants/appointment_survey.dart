/// Appointment survey constants.
///
// Time-stamp: <Tuesday 2025-05-07 10:15:00 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Kevin Wang

library;

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// Constants for the appointment survey form.

class AppointmentSurveyConstants {
  /// Field names used in the survey.

  static const String fieldDate = 'date';
  static const String fieldTitle = 'title';
  static const String fieldDescription = 'description';

  /// Questions displayed in the survey.

  static const String date = 'When is your appointment?';
  static const String title = 'What is the appointment for?';
  static const String description = 'Any additional details?';

  /// The list of questions used in the appointment survey.

  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: date,
      fieldName: fieldDate,
      type: HealthDataType.datetime,
      isRequired: true,
      allowFutureDate: true,
      showTime: true,
    ),
    HealthSurveyQuestion(
      question: title,
      fieldName: fieldTitle,
      type: HealthDataType.text,
      isRequired: true,
    ),
    HealthSurveyQuestion(
      question: description,
      fieldName: fieldDescription,
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];
}
