/// Safely parse date strings with fallbacks for various formats.
///
// Time-stamp: <Tuesday 2025-04-29 15:30:00 +1000 Graham Williams>
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

import 'package:flutter/material.dart';

/// Safely parse date strings with fallbacks for various formats.

DateTime? parseDateSafely(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;

  try {
    // First try standard ISO format.

    return DateTime.parse(dateStr);
  } catch (e) {
    // If that fails, try other formats.

    try {
      // Try handling just the date part (YYYY-MM-DD).

      if (dateStr.length >= 10) {
        final datePart = dateStr.substring(0, 10);
        return DateTime.parse(datePart);
      }
    } catch (e) {
      debugPrint('Error parsing date part: $e');
    }

    // Try custom format parsing as a last resort.

    try {
      // Handle MM/DD/YYYY format.

      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]) ?? 1;
        final day = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? 2000;
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing custom date format: $e');
    }

    debugPrint('Unable to parse date: $dateStr');
    return null;
  }
}
