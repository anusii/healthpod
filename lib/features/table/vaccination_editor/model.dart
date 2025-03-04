/// Vaccination observation model class.
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

import 'package:healthpod/constants/vaccination_survey.dart';

/// Model class representing a vaccination observation.
///
/// Stores complete vaccination information including timestamp, vaccine name,
/// provider, professional, cost, and notes. Provides JSON serialization and
/// object copying functionality.

class VaccinationObservation {
  /// When the vaccination was administered.
  final DateTime timestamp;

  /// Name of the vaccine administered.
  final String vaccineName;

  /// Provider or location where vaccination was administered.
  final String provider;

  /// Healthcare professional who administered the vaccine.
  final String professional;

  /// Cost of the vaccination.
  final String cost;

  /// Additional notes or observations.
  final String notes;

  VaccinationObservation({
    required this.timestamp,
    required this.vaccineName,
    this.provider = '',
    this.professional = '',
    this.cost = '',
    this.notes = '',
  });

  /// Creates a VaccinationObservation from JSON data.
  ///
  /// Expects specific survey response format with vaccination information
  /// stored under 'responses' key.

  factory VaccinationObservation.fromJson(Map<String, dynamic> json) {
    return VaccinationObservation(
      timestamp: DateTime.parse(json['timestamp']),
      vaccineName:
          json['responses'][VaccinationSurveyConstants.fieldVaccineName] ?? '',
      provider:
          json['responses'][VaccinationSurveyConstants.fieldProvider] ?? '',
      professional:
          json['responses'][VaccinationSurveyConstants.fieldProfessional] ?? '',
      cost: json['responses'][VaccinationSurveyConstants.fieldCost] ?? '',
      notes: json['responses'][VaccinationSurveyConstants.fieldNotes] ?? '',
    );
  }

  /// Converts observation to JSON format matching survey response structure.
  ///
  /// Creates a map with timestamp and responses containing all vaccination information.

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        VaccinationSurveyConstants.fieldVaccineName: vaccineName,
        VaccinationSurveyConstants.fieldProvider: provider,
        VaccinationSurveyConstants.fieldProfessional: professional,
        VaccinationSurveyConstants.fieldCost: cost,
        VaccinationSurveyConstants.fieldNotes: notes,
      },
    };
  }

  /// Creates a copy of this observation with optionally updated fields.
  ///
  /// Any field not specified retains its original value.

  VaccinationObservation copyWith({
    DateTime? timestamp,
    String? vaccineName,
    String? provider,
    String? professional,
    String? cost,
    String? notes,
  }) {
    return VaccinationObservation(
      timestamp: timestamp ?? this.timestamp,
      vaccineName: vaccineName ?? this.vaccineName,
      provider: provider ?? this.provider,
      professional: professional ?? this.professional,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
    );
  }
}
