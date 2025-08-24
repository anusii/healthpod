/// Medication observation model class.
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

/// Model class representing a medication observation.
///
/// Stores complete medication information including name, dosage, frequency,
/// start date, and notes. Provides JSON serialization and object copying functionality.

class MedicationObservation {
  /// Name of the medication.

  final String name;

  /// Dosage information.

  final String dosage;

  /// How often the medication should be taken.

  final String frequency;

  /// When the medication intake started.

  final DateTime startDate;

  /// Additional notes about the medication.

  final String notes;

  MedicationObservation({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.notes = '',
  });

  /// Creates a MedicationObservation from JSON data.
  ///
  /// Expects specific survey response format with medication information
  /// stored under 'responses' key.

  factory MedicationObservation.fromJson(Map<String, dynamic> json) {
    return MedicationObservation(
      name: json['responses'][MedicationSurveyConstants.fieldName],
      dosage: json['responses'][MedicationSurveyConstants.fieldDosage],
      frequency: json['responses'][MedicationSurveyConstants.fieldFrequency],
      startDate: DateTime.parse(
        json['responses'][MedicationSurveyConstants.fieldStartDate],
      ),
      notes: json['responses'][MedicationSurveyConstants.fieldNotes] ?? '',
    );
  }

  /// Converts observation to JSON format matching survey response structure.
  ///
  /// Creates a map with responses containing all medication information.

  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'responses': {
        MedicationSurveyConstants.fieldName: name,
        MedicationSurveyConstants.fieldDosage: dosage,
        MedicationSurveyConstants.fieldFrequency: frequency,
        MedicationSurveyConstants.fieldStartDate: startDate.toIso8601String(),
        MedicationSurveyConstants.fieldNotes: notes,
      },
    };
  }

  /// Creates a copy of this observation with optionally updated fields.
  ///
  /// Any field not specified retains its original value.

  MedicationObservation copyWith({
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    String? notes,
  }) {
    return MedicationObservation(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
    );
  }
}
