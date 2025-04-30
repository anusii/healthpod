/// Normalise frequency text to group similar entries.
//
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

/// Normalise frequency text to group similar entries.

  String normaliseFrequency(String frequency) {
    // Convert to lowercase.  

    final lower = frequency.toLowerCase();
    
    // Group common patterns.

    if (lower.contains('once') && (lower.contains('day') || lower.contains('daily'))) {
      return 'Once daily';
    }
    if (lower.contains('twice') && (lower.contains('day') || lower.contains('daily'))) {
      return 'Twice daily';
    }
    if (lower.contains('three') && (lower.contains('day') || lower.contains('daily')) ||
        lower.contains('3') && (lower.contains('day') || lower.contains('daily'))) {
      return 'Three times daily';
    }
    if (lower.contains('week')) {
      return 'Weekly';
    }
    if (lower.contains('month')) {
      return 'Monthly';
    }
    
    // Return original if no match.

    return frequency;
  }