/// Pinned Y axis for the horizontally scrollable blood pressure chart.
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

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

/// Y axis labels for the blood pressure chart, drawn outside the scroll view.
///
/// The plot itself scrolls horizontally once there are more observations than
/// fit the window, so the pressure scale is rendered separately to keep it
/// visible. It is an empty chart sharing the pressure range and the space
/// reserved for the date labels, so its ticks line up with the plot's grid.

class BPChartYAxis extends StatelessWidget {
  const BPChartYAxis({super.key, required this.builder});

  /// Builds a label for a pressure value, shared with the plot's styling.

  final Widget Function(double value, ThemeData theme) builder;

  /// Minimum expected diastolic pressure.

  static const double minY = 40;

  /// Maximum expected systolic pressure.

  static const double maxY = 200;

  /// Spacing between pressure gridlines and labels, in mmHg.

  static const double interval = 20;

  /// Space reserved for the pressure labels.

  static const double labelWidth = 45;

  /// Space reserved beneath the plot for the date labels.

  static const double dateHeight = 30;

  /// Overall width, allowing a sliver of plot area for the chart to lay out.

  static const double width = labelWidth + 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: LineChart(
        LineChartData(
          backgroundColor: theme.colorScheme.surface,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: labelWidth,
                getTitlesWidget: (value, meta) => builder(value, theme),
              ),
            ),

            // Reserve the same space the plot gives its date labels so the
            // pressure labels align with the plot's gridlines.

            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: dateHeight,
                getTitlesWidget: _noLabel,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          minX: 0,
          maxX: 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: const [],
        ),
      ),
    );
  }

  static Widget _noLabel(double value, TitleMeta meta) =>
      const SizedBox.shrink();
}
