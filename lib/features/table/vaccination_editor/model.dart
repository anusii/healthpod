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
    // Handle both 'date' and 'timestamp' fields
    final timestamp = json['date'] ?? json['timestamp'];
    if (timestamp == null) {
      throw FormatException('Missing date/timestamp field in vaccination data');
    }

    // Get responses map, defaulting to empty map if null
    final responses = json['responses'] as Map<String, dynamic>? ?? {};

    return VaccinationObservation(
      timestamp: DateTime.parse(timestamp),
      vaccineName:
          responses[VaccinationSurveyConstants.fieldVaccineName]?.toString() ??
              '',
      provider:
          responses[VaccinationSurveyConstants.fieldProvider]?.toString() ?? '',
      professional:
          responses[VaccinationSurveyConstants.fieldProfessional]?.toString() ??
              '',
      cost: responses[VaccinationSurveyConstants.fieldCost]?.toString() ?? '',
      notes: responses[VaccinationSurveyConstants.fieldNotes]?.toString() ?? '',
    );
  }

  /// Creates a VaccinationObservation from CSV data.
  ///
  /// Expects a map with CSV headers as keys and corresponding values.

  factory VaccinationObservation.fromCsv(Map<String, String> csvData) {
    return VaccinationObservation(
      timestamp: DateTime.parse(csvData['date'] ?? ''),
      vaccineName: csvData['vaccine'] ?? '',
      provider: csvData['provider'] ?? '',
      professional: csvData['professional'] ?? '',
      cost: csvData['cost'] ?? '',
      notes: csvData['notes'] ?? '',
    );
  }

  /// Creates a VaccinationObservation from either JSON or CSV data.
  ///
  /// Automatically detects the format and parses accordingly.

  static VaccinationObservation parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Check if it's a CSV format by looking for 'date' and 'vaccine' keys
      if (data.containsKey('date') && data.containsKey('vaccine')) {
        return VaccinationObservation.fromCsv(
          Map<String, String>.from(data),
        );
      }
      // Otherwise treat as JSON
      return VaccinationObservation.fromJson(data);
    }
    throw FormatException('Unsupported data format');
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

  /// Converts observation to the format expected by the visualization component.
  ///
  /// This ensures consistent data format across the application.

  Map<String, dynamic> toVisualizationFormat() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'responses': {
        'vaccine': vaccineName,
        'provider': provider,
        'professional': professional,
        'cost': cost,
        'notes': notes,
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
