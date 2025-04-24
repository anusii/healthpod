/// Get icon colour.
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

import 'package:healthpod/constants/health_data_type.dart';

/// Returns an appropriate color based on the [HealthDataType] and question text.
///
/// - Red for blood pressure-related questions.
/// - Pink for heart rate questions.
/// - Blue for general numerical data.
/// - Green for text-based data.
/// - Purple for general categorical data.
/// - Grey for unclassified types.

Color getIconColor(HealthDataType type, String question) {
  final lowerQuestion = question.toLowerCase();

  if (type == HealthDataType.number) {
    if (lowerQuestion.contains('blood pressure') ||
        lowerQuestion.contains('systolic') ||
        lowerQuestion.contains('diastolic')) {
      return Colors.red.shade400;
    } else if (lowerQuestion.contains('heart rate')) {
      return Colors.pink.shade400;
    }
    return Colors.blue.shade400;
  }

  return switch (type) {
    HealthDataType.text => Colors.green.shade400,
    HealthDataType.categorical => Colors.purple.shade400,
    _ => Colors.grey.shade400,
  };
}
