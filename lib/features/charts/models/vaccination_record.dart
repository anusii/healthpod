/// Vaccination record model.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

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

    final responses = json['responses'] as Map<String, dynamic>?;

    // If there's no responses object, try to use the top-level data.

    if (responses == null) {
      return VaccinationRecord(
        date: DateTime.parse(json['timestamp'] ??
            json['date'] ??
            DateTime.now().toIso8601String()),
        name: json['vaccine'] ?? json['vaccine_name'] ?? 'Unknown Vaccine',
        provider: json['provider'],
        professional: json['professional'],
        cost: json['cost']?.toString(),
        notes: json['notes']?.toString(),
      );
    }

    // Use the date from responses if available, otherwise use the timestamp.

    DateTime date;
    if (responses['date'] != null) {
      try {
        // Try to parse the date from responses.

        date = DateTime.parse(responses['date']);
      } catch (e) {
        // If parsing fails, try to handle format like "2025-3-7".

        final parts = responses['date'].toString().split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
          );
        } else {
          // Fall back to the timestamp.

          date = DateTime.parse(json['timestamp']);
        }
      }
    } else {
      // Use the timestamp if no date in responses.

      date = DateTime.parse(json['timestamp']);
    }

    return VaccinationRecord(
      date: date,
      // Check multiple possible field names for the vaccine name.

      name: responses['vaccine_name'] ??
          responses['vaccine'] ??
          'Unknown Vaccine',
      provider: responses['provider']?.toString(),
      professional: responses['professional']?.toString(),
      cost: responses['cost']?.toString(),
      notes: responses['notes']?.toString(),
    );
  }
}
