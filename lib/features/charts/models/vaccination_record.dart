/// Vaccination record model.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/foundation.dart';

/// Represents a single vaccination record with all its details.

class VaccinationRecord {
  final DateTime date;
  final String name;
  final String? provider;
  final String? professional;
  final String? cost;
  final String? notes;

  /// Constructor for creating a vaccination record.

  VaccinationRecord({
    required this.date,
    required this.name,
    this.provider,
    this.professional,
    this.cost,
    this.notes,
  });

  /// Creates a VaccinationRecord from JSON data.

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    // Extract the responses object which contains the actual vaccination details.

    final responses = json['responses'] as Map<String, dynamic>? ?? {};

    // Get the date from either timestamp or date field, with fallback to current time.

    final dateStr =
        json['timestamp'] ?? json['date'] ?? DateTime.now().toIso8601String();
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('Error parsing date $dateStr: $e');
      date = DateTime.now();
    }

    // Get vaccine name from responses or top level, with fallback to Unknown.

    final vaccineName = responses['vaccine_name'] ??
        responses['vaccine'] ??
        json['vaccine'] ??
        json['vaccine_name'] ??
        'Unknown Vaccine';

    return VaccinationRecord(
      date: date,
      name: vaccineName,
      provider:
          responses['provider']?.toString() ?? json['provider']?.toString(),
      professional: responses['professional']?.toString() ??
          json['professional']?.toString(),
      cost: responses['cost']?.toString() ?? json['cost']?.toString(),
      notes: responses['notes']?.toString() ?? json['notes']?.toString(),
    );
  }
}
