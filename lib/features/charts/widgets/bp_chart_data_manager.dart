/// Data manager for blood pressure chart data extraction and statistics.
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

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:healthpod/constants/blood_pressure_survey.dart';
import 'package:healthpod/features/visualise/stat_item.dart';
import 'package:healthpod/utils/parse_numeric_input.dart';

/// Utility class for managing blood pressure chart data extraction and
/// statistics.

class BPChartDataManager {
  const BPChartDataManager._();

  /// Extracts and converts systolic blood pressure data into chart points.
  ///
  /// Returns a list of [FlSpot] objects where:
  /// * X coordinate represents the data point index
  /// * Y coordinate represents the systolic pressure in mmHg.

  static List<FlSpot> getSystolicData(List<Map<String, dynamic>> surveyData) {
    List<FlSpot> spots = [];
    for (var i = 0; i < surveyData.length; i++) {
      final data = surveyData[i]['responses'];
      double value =
          parseNumericValue(data[HealthSurveyConstants.fieldSystolic]);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  /// Extracts and converts diastolic blood pressure data into chart points.
  ///
  /// Returns a list of [FlSpot] objects where:
  /// * X coordinate represents the data point index
  /// * Y coordinate represents the diastolic pressure in mmHg.

  static List<FlSpot> getDiastolicData(List<Map<String, dynamic>> surveyData) {
    List<FlSpot> spots = [];
    for (var i = 0; i < surveyData.length; i++) {
      final data = surveyData[i]['responses'];
      double value =
          parseNumericValue(data[HealthSurveyConstants.fieldDiastolic]);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  /// Safely converts various numeric formats to double.
  ///
  /// Handles integers, doubles, and string representations of numbers.
  /// Returns 0.0 if the value cannot be parsed.

  static double parseNumericValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    debugPrint('Warning: Invalid numeric value: $value');
    return 0.0;
  }

  /// Builds a list of statistical summary widgets.
  ///
  /// Calculates and displays average, minimum, and maximum values for both
  /// systolic and diastolic pressure in the format "systolic/diastolic mmHg".

  static List<Widget> buildStatItems(
    List<Map<String, dynamic>> surveyData,
    ThemeData theme,
  ) {
    // Extract values for calculations.

    final systolicValues =
        getSystolicData(surveyData).map((spot) => spot.y).toList();
    final diastolicValues =
        getDiastolicData(surveyData).map((spot) => spot.y).toList();

    // Calculate statistics for systolic pressure.

    final systolicAvg =
        systolicValues.reduce((a, b) => a + b) / systolicValues.length;
    final systolicMin = systolicValues.reduce((a, b) => a < b ? a : b);
    final systolicMax = systolicValues.reduce((a, b) => a > b ? a : b);

    // Calculate statistics for diastolic pressure.

    final diastolicAvg =
        diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
    final diastolicMin = diastolicValues.reduce((a, b) => a < b ? a : b);
    final diastolicMax = diastolicValues.reduce((a, b) => a > b ? a : b);

    // Build and return the stat items with dividers.

    return [
      StatItem(
        label: 'Average',
        value: '${parseNumericInput(systolicAvg)}/'
            '${parseNumericInput(diastolicAvg)} mmHg',
      ),
      Container(
        height: 40,
        width: 1,
        color: theme.dividerColor,
      ),
      StatItem(
        label: 'Min',
        value: '${parseNumericInput(systolicMin)}/'
            '${parseNumericInput(diastolicMin)} mmHg',
      ),
      Container(
        height: 40,
        width: 1,
        color: theme.dividerColor,
      ),
      StatItem(
        label: 'Max',
        value:
            '${parseNumericInput(systolicMax)}/${parseNumericInput(diastolicMax)} mmHg',
      ),
    ];
  }
}
