/// Validation function to check if uploaded health plan data is valid.
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

/// Validation function to check if uploaded health plan data is valid.

bool validateHealthPlanData(Map<String, dynamic> data) {
  if (!data.containsKey('title') || data['title'] is! String) {
    return false;
  }

  if (!data.containsKey('planItems') || data['planItems'] is! List) {
    return false;
  }

  // Check that all plan items are strings.

  final planItems = data['planItems'] as List;
  for (final item in planItems) {
    if (item is! String) {
      return false;
    }
  }

  return true;
}
