/// Profile data validation utility.
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

import 'package:healthpod/constants/profile.dart';

/// Result of profile data validation.
class ProfileValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? data;

  ProfileValidationResult({
    required this.isValid,
    this.error,
    this.data,
  });
}

/// Validates profile data from JSON.
///
/// Returns a [ProfileValidationResult] indicating whether the data is valid
/// and contains all required fields in the correct format.
ProfileValidationResult validateProfileJson(Map<String, dynamic> json) {
  try {
    // Check if the JSON has the required structure
    if (!json.containsKey('data')) {
      return ProfileValidationResult(
        isValid: false,
        error: 'Invalid profile format: missing "data" field',
      );
    }

    final data = json['data'] as Map<String, dynamic>;
    final defaultData = defaultProfileData['data'] as Map<String, dynamic>;

    // Check if all required fields are present
    for (final field in defaultData.keys) {
      if (!data.containsKey(field)) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Missing required field: $field',
        );
      }
    }

    // Validate field types
    if (data['identifyAsIndigenous'] is! bool) {
      return ProfileValidationResult(
        isValid: false,
        error: 'Field "identifyAsIndigenous" must be a boolean',
      );
    }

    // Validate string fields are not null
    for (final field in [
      'patientName',
      'address',
      'bestContactPhone',
      'alternativeContactNumber',
      'email',
      'dateOfBirth',
      'gender',
    ]) {
      if (data[field] == null) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Field "$field" cannot be null',
        );
      }
      if (data[field] is! String) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Field "$field" must be a string',
        );
      }
    }

    // Validate email format if provided
    if (data['email'].isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(data['email'])) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Invalid email format',
        );
      }
    }

    // Validate phone numbers if provided
    if (data['bestContactPhone'].isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s-]+$');
      if (!phoneRegex.hasMatch(data['bestContactPhone'])) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Invalid phone number format for best contact',
        );
      }
    }

    if (data['alternativeContactNumber'].isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s-]+$');
      if (!phoneRegex.hasMatch(data['alternativeContactNumber'])) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Invalid phone number format for alternative contact',
        );
      }
    }

    // Validate date of birth format if provided
    if (data['dateOfBirth'].isNotEmpty) {
      try {
        DateTime.parse(data['dateOfBirth']);
      } catch (e) {
        return ProfileValidationResult(
          isValid: false,
          error: 'Invalid date of birth format. Use YYYY-MM-DD',
        );
      }
    }

    // If all validations pass, return success with the data
    return ProfileValidationResult(
      isValid: true,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      },
    );
  } catch (e) {
    return ProfileValidationResult(
      isValid: false,
      error: 'Invalid JSON format: $e',
    );
  }
} 