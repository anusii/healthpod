/// Blood observation model class.
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

import 'package:healthpod/constants/blood_pressure_survey.dart';

/// Model class representing a blood pressure observation.
///
/// Stores complete blood pressure measurements including systolic/diastolic pressure,
/// heart rate and any additional health notes. Provides JSON
/// serialization and object copying functionality.
///
/// Note: previously 'BPRecord' was used as the class name, but 'BPObservation' is
/// more accurate as it represents a single observation rather than a collection of
/// records.

class BPObservation {
  /// When the measurement was taken.

  final DateTime timestamp;

  /// Systolic blood pressure in mmHg (upper number).

  final double
      systolic; // Use double instead of int for potential readings with decimal places.

  /// Diastolic blood pressure in mmHg (lower number).

  final double diastolic;

  /// Heart rate in beats per minute (BPM).

  final double heartRate;

  /// Additional health notes or observations.

  final String notes;

  BPObservation({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.notes,
  });

  /// Creates a BPObservation from JSON data.
  ///
  /// Expects specific survey response format with blood pressure measurements,
  /// heart rate and notes stored under 'responses' key.

  factory BPObservation.fromJson(Map<String, dynamic> json) {
    return BPObservation(
      timestamp: DateTime.parse(json['timestamp']),
      systolic: (json['responses'][HealthSurveyConstants.fieldSystolic] as num)
          .toDouble(), // Convert int/double to double
      diastolic:
          (json['responses'][HealthSurveyConstants.fieldDiastolic] as num)
              .toDouble(),
      heartRate:
          (json['responses'][HealthSurveyConstants.fieldHeartRate] as num)
              .toDouble(),
      notes: json['responses'][HealthSurveyConstants.fieldNotes] ?? '',
    );
  }

  /// Converts observation to JSON format matching survey response structure.
  ///
  /// Creates a map with timestamp and responses containing all measurements.

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        HealthSurveyConstants.fieldSystolic:
            systolic, // Use BP survey field variable instead of full question.
        HealthSurveyConstants.fieldDiastolic: diastolic,
        HealthSurveyConstants.fieldHeartRate: heartRate,
        HealthSurveyConstants.fieldNotes: notes,
      },
    };
  }

  /// Creates a copy of this observation with optionally updated fields.
  ///
  /// Any field not specified retains its original value.

  BPObservation copyWith({
    DateTime? timestamp,
    double? systolic,
    double? diastolic,
    double? heartRate,
    String? notes,
  }) {
    return BPObservation(
      timestamp: timestamp ?? this.timestamp,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      notes: notes ?? this.notes,
    );
  }
}
