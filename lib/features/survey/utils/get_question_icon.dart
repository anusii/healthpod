/// Get question icon.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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

/// Returns an appropriate icon based on the [HealthDataType] and question text.
///
/// - Heart icon for blood pressure-related questions.
/// - Monitor heart icon for heart rate questions.
/// - Numbers icon for general numerical data.
/// - Mood icon for categorical data related to feelings.
/// - Notes icon for text-based data.
/// - Checklist icon for general categorical data.
/// - Help outline icon for unclassified types.

IconData getQuestionIcon(HealthDataType type, String question) {
  final lowerQuestion = question.toLowerCase();

  if (type == HealthDataType.number) {
    if (lowerQuestion.contains('blood pressure') ||
        lowerQuestion.contains('systolic') ||
        lowerQuestion.contains('diastolic')) {
      return Icons.favorite;
    } else if (lowerQuestion.contains('heart rate')) {
      return Icons.monitor_heart;
    }
    return Icons.numbers;
  }

  if (type == HealthDataType.categorical && lowerQuestion.contains('feeling')) {
    return Icons.mood;
  }

  return switch (type) {
    HealthDataType.text => Icons.notes,
    HealthDataType.categorical => Icons.checklist,
    _ => Icons.help_outline,
  };
}
