/// Health survey question.
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

/// Represents a single health survey question.

class HealthSurveyQuestion {
  // Question text displayed to users in UI.

  final String question;

  // Field name used for data storage (e.g. in CSV and JSON).

  final String fieldName;

  // Data type of the question.

  final HealthDataType type;

  // Options for categorical questions.

  final List<String>? options;

  // Optional unit for measurements (e.g. "mmHg", "kg").

  final String? unit;

  // Optional minimum value for numerical inputs.

  final double? min;

  // Optional maximum value for numerical inputs.

  final double? max;

  // Whether the question must be answered.

  final bool isRequired;

  // Whether to allow future dates in date/datetime inputs.

  final bool allowFutureDate;

  // Whether to show time picker for datetime inputs.

  final bool showTime;

  /// Creates a new [HealthSurveyQuestion] instance.
  ///
  /// [question] is the text displayed to users.
  /// [fieldName] is the name used for data storage.
  /// [type] is the data type of the question.
  /// [options] is the list of options for categorical questions.
  /// [unit] is the optional unit for measurements.
  /// [min] is the optional minimum value for numerical inputs.
  /// [max] is the optional maximum value for numerical inputs.
  /// [isRequired] indicates if the question must be answered.
  /// [allowFutureDate] indicates if future dates are allowed in date/datetime inputs.
  /// [showTime] indicates if time picker should be shown for datetime inputs.

  HealthSurveyQuestion({
    required this.question,
    required this.fieldName,
    required this.type,
    this.options,
    this.unit,
    this.min,
    this.max,
    this.isRequired = true,
    this.allowFutureDate = false,
    this.showTime = false,
  }) : assert(
          type != HealthDataType.categorical ||
              (options != null && options.isNotEmpty),
          'Categorical questions must have options',
        );
}
