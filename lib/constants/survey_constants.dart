/// Survey constants.
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
/// Authors: Ashley Tang

library;

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// Defines the standard set of health survey questions.
/// These questions are used consistently throughout the application
/// for collecting health-related data.

class HealthSurveyConstants {
  /// The list of questions used in the health survey.
  /// Each question includes type validation, units where applicable,
  /// and value constraints.

  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: "What's your systolic blood pressure?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 70,
      max: 200,
    ),
    HealthSurveyQuestion(
      question: "What's your diastolic measurement?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "What's your heart rate?",
      type: HealthDataType.number,
      unit: "bpm",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "How are you feeling?",
      type: HealthDataType.categorical,
      options: ["Excellent", "Good", "Fair", "Poor"],
    ),
    HealthSurveyQuestion(
      question: "Any additional notes about your health?",
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];

  /// Question keys for accessing specific responses.

  static const String systolicBP = "What's your systolic blood pressure?";
  static const String diastolicBP = "What's your diastolic measurement?";
  static const String heartRate = "What's your heart rate?";
  static const String feeling = "How are you feeling?";
  static const String notes = "Any additional notes about your health?";
}
