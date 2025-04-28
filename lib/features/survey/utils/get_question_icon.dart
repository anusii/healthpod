/// Get question icon.
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

/// Returns an appropriate icon based on the [HealthDataType] and question text.
///
/// - Heart icon for blood pressure-related questions.
/// - Monitor heart icon for heart rate questions.
/// - Numbers icon for general numerical data.
/// - Notes icon for text-based data.
/// - Checklist icon for general categorical data.
/// - Calendar icon for date inputs.
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
  } else if (type == HealthDataType.categorical) {
    return Icons.checklist;
  } else if (type == HealthDataType.text) {
    if (lowerQuestion.contains('which vaccine did you receive')) {
      return Icons.vaccines;
    } else if (lowerQuestion.contains('where did you receive the vaccine')) {
      return Icons.local_hospital;
    } else if (lowerQuestion.contains('healthcare professional name')) {
      return Icons.person;
    } else if (lowerQuestion.contains('cost of vaccination')) {
      return Icons.attach_money;
    } else if (lowerQuestion.contains('any additional notes')) {
      return Icons.notes;
    }
    return Icons.notes;
  } else if (type == HealthDataType.date) {
    if (lowerQuestion.contains('when did you receive the vaccination')) {
      return Icons.calendar_month;
    }
    return Icons.calendar_today;
  }
  return Icons.help_outline;
}
