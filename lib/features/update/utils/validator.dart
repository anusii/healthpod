/// Validator class for survey inputs.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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

import 'package:healthpod/features/update/question.dart';

/// A class containing validation methods for different types of survey inputs.

class HealthSurveyValidator {
  /// Validates text input fields.
  ///
  /// - Returns an error message if the field is required but empty.
  /// - Otherwise, returns `null`.

  static String? validateTextInput(
      String? value, HealthSurveyQuestion question) {
    if (question.isRequired && (value == null || value.isEmpty)) {
      return 'Please enter a value';
    }
    return null;
  }

  /// Validates number input fields.
  ///
  /// - Ensures the value is not empty if required.
  /// - Checks if the input is a valid number.
  /// - Ensures the number is within the specified min and max range.
  /// - Returns an error message if validation fails, otherwise returns `null`.

  static String? validateNumberInput(
      String? value, HealthSurveyQuestion question) {
    if (value == null || value.isEmpty) {
      return question.isRequired ? 'Please enter a value' : null;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (question.min != null && number < question.min!) {
      return 'Value must be at least ${question.min}';
    }

    if (question.max != null && number > question.max!) {
      return 'Value must not exceed ${question.max}';
    }

    return null;
  }

  /// Validates categorical input fields.
  ///
  /// - Ensures the value is not empty if required.
  /// - Returns an error message if validation fails, otherwise returns `null`.

  static String? validateCategoricalInput(
      String? value, HealthSurveyQuestion question) {
    if (question.isRequired && (value == null || value.isEmpty)) {
      return 'Please select an option';
    }
    return null;
  }
}
