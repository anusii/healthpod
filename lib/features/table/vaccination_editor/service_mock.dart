/// Mock vaccination observation service for testing.
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

import 'package:flutter/material.dart';

import 'package:healthpod/features/table/vaccination_editor/model.dart';

/// Mock implementation of the vaccination editor service for testing.
/// This provides sample data without requiring actual Pod access.

class VaccinationEditorServiceMock {
  /// Load mock vaccination data
  Future<List<VaccinationObservation>> loadData(BuildContext context) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      VaccinationObservation(
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        vaccineName: 'COVID-19 Booster',
        provider: 'City Medical Center',
        professional: 'Dr. Smith',
        cost: '\$45.00',
        notes: 'Pfizer booster shot',
      ),
      VaccinationObservation(
        timestamp: DateTime.now().subtract(const Duration(days: 180)),
        vaccineName: 'Flu Shot',
        provider: 'Community Pharmacy',
        professional: 'Pharmacist Johnson',
        cost: '\$25.00',
        notes: 'Annual influenza vaccine',
      ),
      VaccinationObservation(
        timestamp: DateTime.now().subtract(const Duration(days: 365)),
        vaccineName: 'COVID-19 Second Dose',
        provider: 'City Medical Center',
        professional: 'Dr. Smith',
        cost: '\$0.00',
        notes: 'Pfizer second dose',
      ),
    ];
  }

  /// Mock saving a vaccination observation
  Future<void> saveObservationToPod({
    required BuildContext context,
    required VaccinationObservation observation,
    required bool isNew,
    required VaccinationObservation? oldObservation,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real implementation, this would save to storage
  }

  /// Mock deleting a vaccination observation
  Future<void> deleteObservationFromPod(
    BuildContext context,
    VaccinationObservation observation,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real implementation, this would delete from storage
  }
}
