/// Profile data validation utilities.
///
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
/// Authors: Ashley Tang, Tony Chen

library;

/// Utility class for validating profile data.

class ProfileValidator {
  const ProfileValidator._();

  /// Validates profile JSON data against expected structure.
  ///
  /// Returns a map with validation result, data, and error message if any.

  static Map<String, dynamic> validateProfileData(
    Map<String, dynamic> jsonData,
  ) {
    // Define required profile fields.

    final requiredFields = [
      'name',
      'address',
      'bestContactPhone',
      'alternativeContactNumber',
      'email',
      'dateOfBirth',
      'gender',
    ];

    // Check direct structure.

    final directMissingFields = _checkRequiredFields(jsonData, requiredFields);
    if (directMissingFields.isEmpty) {
      return {
        'isValid': true,
        'data': {
          'data': jsonData,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'message': 'Valid profile data',
      };
    }

    // Check data nested under 'data' key.

    if (jsonData.containsKey('data') &&
        jsonData['data'] is Map<String, dynamic>) {
      final nestedData = jsonData['data'] as Map<String, dynamic>;
      final dataMissingFields =
          _checkRequiredFields(nestedData, requiredFields);
      if (dataMissingFields.isEmpty) {
        return {
          'isValid': true,
          'data': jsonData,
          'message': 'Valid profile data structure',
        };
      }
    }

    // Check data nested under 'responses' key.

    if (jsonData.containsKey('responses') &&
        jsonData['responses'] is Map<String, dynamic>) {
      final nestedData = jsonData['responses'] as Map<String, dynamic>;
      final responsesMissingFields =
          _checkRequiredFields(nestedData, requiredFields);
      if (responsesMissingFields.isEmpty) {
        return {
          'isValid': true,
          'data': {
            'data': nestedData,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'message': 'Valid profile data under responses',
        };
      }
    }

    // Determine which missing fields to report.

    List<String> missingFieldsList = directMissingFields;

    // Try to get the most specific error (fewest missing fields).

    if (jsonData.containsKey('data') &&
        jsonData['data'] is Map<String, dynamic>) {
      final dataMissingFields = _checkRequiredFields(
        jsonData['data'] as Map<String, dynamic>,
        requiredFields,
      );
      if (dataMissingFields.length < missingFieldsList.length) {
        missingFieldsList = dataMissingFields;
      }
    }

    if (jsonData.containsKey('responses') &&
        jsonData['responses'] is Map<String, dynamic>) {
      final responsesMissingFields = _checkRequiredFields(
        jsonData['responses'] as Map<String, dynamic>,
        requiredFields,
      );
      if (responsesMissingFields.length < missingFieldsList.length) {
        missingFieldsList = responsesMissingFields;
      }
    }

    // Format missing fields for display.

    final formattedMissingFields =
        missingFieldsList.map(formatFieldName).join(', ');

    return {
      'isValid': false,
      'message': 'Invalid profile data structure - '
          'missing required fields: $formattedMissingFields',
    };
  }

  /// Helper function to check required fields and return list of missing fields.
  ///
  /// Returns a list of missing field names. Empty list means all required
  /// fields are present.

  static List<String> _checkRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        missingFields.add(field);
      }
    }

    return missingFields;
  }

  /// Format field names for display.

  static String formatFieldName(String field) {
    // Convert camelCase to Title Case with spaces.

    final result = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }
}
