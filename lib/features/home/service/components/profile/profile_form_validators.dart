/// Form validation utilities for profile details.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Tony Chen

library;

/// Provides validation utilities for profile form fields.

class ProfileFormValidators {
  /// Validates email format - optional field.

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Validates phone number format - optional field.

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;

    // Clean the input by removing spaces, dashes and parentheses.

    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final australianPhoneRegex = RegExp(r'^(\+61|0)[0-9]{9,10}$');
    final internationalPhoneRegex = RegExp(r'^\+[0-9]{10,14}$');

    if (!australianPhoneRegex.hasMatch(cleanedValue) &&
        !internationalPhoneRegex.hasMatch(cleanedValue)) {
      return 'Enter a valid phone number (e.g. +61 4 1234 5678 or 04 1234 5678)';
    }
    return null;
  }

  /// Parses a date string into DateTime or returns a default date.

  static DateTime parseDateOrDefault(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      //debugPrint('Error parsing date: $e');
    }
    // Return a default date (30 years ago)
    return DateTime.now().subtract(const Duration(days: 365 * 30));
  }

  /// Formats a DateTime as YYYY-MM-DD.

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
