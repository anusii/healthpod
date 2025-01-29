/// Data record widget.
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

/// Model class representing a blood pressure record.
///
/// Stores complete blood pressure measurements including systolic/diastolic pressure,
/// heart rate, subjective feeling, and any additional health notes. Provides JSON
/// serialization and object copying functionality.

class BPRecord {
  /// When the measurement was taken.

  final DateTime timestamp;

  /// Systolic blood pressure in mmHg (upper number).

  final int systolic;

  /// Diastolic blood pressure in mmHg (lower number).

  final int diastolic;

  /// Heart rate in beats per minute (BPM).

  final int heartRate;

  /// Subjective feeling (Excellent/Good/Fair/Poor).

  final String feeling;

  /// Additional health notes or observations.

  final String notes;

  BPRecord({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.feeling,
    required this.notes,
  });

  /// Creates a BPRecord from JSON data.
  ///
  /// Expects specific survey response format with blood pressure measurements,
  /// heart rate, feeling and notes stored under 'responses' key.

  factory BPRecord.fromJson(Map<String, dynamic> json) {
    return BPRecord(
      timestamp: DateTime.parse(json['timestamp']),
      systolic: json['responses']["What's your systolic blood pressure?"],
      diastolic: json['responses']["What's your diastolic measurement?"],
      heartRate: json['responses']["What's your heart rate?"],
      feeling: json['responses']["How are you feeling?"] ?? '',
      notes: json['responses']["Any additional notes about your health?"] ?? '',
    );
  }

  /// Converts record to JSON format matching survey response structure.
  ///
  /// Creates a map with timestamp and responses containing all measurements.

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        "What's your systolic blood pressure?": systolic,
        "What's your diastolic measurement?": diastolic,
        "What's your heart rate?": heartRate,
        "How are you feeling?": feeling,
        "Any additional notes about your health?": notes,
      },
    };
  }

  /// Creates a copy of this record with optionally updated fields.
  ///
  /// Any field not specified retains its original value.

  BPRecord copyWith({
    DateTime? timestamp,
    int? systolic,
    int? diastolic,
    int? heartRate,
    String? feeling,
    String? notes,
  }) {
    return BPRecord(
      timestamp: timestamp ?? this.timestamp,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      heartRate: heartRate ?? this.heartRate,
      feeling: feeling ?? this.feeling,
      notes: notes ?? this.notes,
    );
  }
}
