/// Constants for the health profile measurements.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// Defines the measurements kept in the health profile.
///
/// Each measurement is recorded with the date it was entered, so a value and
/// the date it was last updated are always read back together.

class HealthProfileConstants {
  // Pod folder and file prefix for the health profile records.

  static const String folder = 'health_profile';

  // Data field names (for storage/CSV).

  static const String fieldWeight = 'weight';
  static const String fieldHeight = 'height';
  static const String fieldWaist = 'waist';
  static const String fieldHip = 'hip';

  /// The measurements recorded, in display order, with their units.

  static const Map<String, String> units = {
    fieldWeight: 'kg',
    fieldHeight: 'cm',
    fieldWaist: 'cm',
    fieldHip: 'cm',
  };

  /// Labels for the measurements, in display order.

  static const Map<String, String> labels = {
    fieldWeight: 'Weight',
    fieldHeight: 'Height',
    fieldWaist: 'Waist',
    fieldHip: 'Hip',
  };

  // Question texts (for UI only).

  static const String weight = "What's your weight?";
  static const String height = 'How tall are you?';
  static const String waist = "What's your waist circumference?";
  static const String hip = "What's your hip circumference?";

  /// The list of questions used to record a new set of measurements.
  ///
  /// None are required, so a single measurement can be updated on its own
  /// without disturbing the date recorded against the others.

  static final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: weight,
      fieldName: fieldWeight,
      type: HealthDataType.number,
      unit: 'kg',
      min: 20,
      max: 400,
      isRequired: false,
    ),
    HealthSurveyQuestion(
      question: height,
      fieldName: fieldHeight,
      type: HealthDataType.number,
      unit: 'cm',
      min: 50,
      max: 250,
      isRequired: false,
    ),
    HealthSurveyQuestion(
      question: waist,
      fieldName: fieldWaist,
      type: HealthDataType.number,
      unit: 'cm',
      min: 30,
      max: 250,
      isRequired: false,
    ),
    HealthSurveyQuestion(
      question: hip,
      fieldName: fieldHip,
      type: HealthDataType.number,
      unit: 'cm',
      min: 30,
      max: 250,
      isRequired: false,
    ),
  ];

  // Advice on what the calculated values mean. Australian government and
  // World Health Organization guidance rather than commercial calculators.

  static const String bmiAdviceUrl =
      'https://www.healthdirect.gov.au/body-mass-index-bmi-and-waist-circumference';
  static const String bmiCalculatorUrl =
      'https://www.heartfoundation.org.au/bmi-calculator';
  static const String waistHipAdviceUrl =
      'https://www.who.int/publications/i/item/9789241501491';
}
