/// Main line chart widget for blood pressure visualisation.
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
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/blood_pressure_survey.dart';
import 'package:healthpod/features/charts/widgets/bp_chart_data_manager.dart';
import 'package:healthpod/utils/get_month_abbrev.dart';
import 'package:healthpod/utils/parse_numeric_input.dart';

/// Main line chart widget for displaying blood pressure trends.

class BPLineChart extends StatelessWidget {
  const BPLineChart({
    super.key,
    required this.surveyData,
  });

  final List<Map<String, dynamic>> surveyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            backgroundColor: theme.colorScheme.surface,
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                /// Danger systolic threshold line (180 mmHg).
                ///
                /// Uses a dashed red line to indicate dangerous systolic
                /// levels.

                HorizontalLine(
                  y: 180,
                  color: theme.colorScheme.error,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                    alignment: Alignment.topRight,
                    labelResolver: (line) => 'Danger',
                  ),
                ),

                /// Threshold line indicating normal systolic pressure limit.
                ///
                /// Uses a dashed purple line matching the systolic data color.
                /// Upper systolic threshold line (120 mmHg).

                HorizontalLine(
                  y: 120,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: false, // Hide by default.
                  ),
                ),

                /// Threshold line indicating normal diastolic pressure limit.
                ///
                /// Uses a dashed teal line matching the diastolic data color.
                /// Upper diastolic threshold line (80 mmHg).

                HorizontalLine(
                  y: 80,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: false, // Hide by default.
                  ),
                ),
              ],
            ),

            /// Touch interaction configuration for data point inspection.

            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpots) =>
                    theme.colorScheme.surfaceContainerHighest,
                tooltipBorder: BorderSide(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                tooltipMargin: 8,
                maxContentWidth: 300,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipHorizontalAlignment: FLHorizontalAlignment.center,

                /// Custom tooltip content generator showing pressure values
                /// and additional data.

                getTooltipItems: (List<LineBarSpot> touchedSpots) =>
                    _buildTooltipItems(touchedSpots, theme),
              ),
              handleBuiltInTouches: true,
              touchSpotThreshold: 20,
            ),

            /// Grid configuration for better data readability.

            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 20,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  strokeWidth: 0.5,
                  dashArray: [5, 5],
                );
              },
            ),

            // Configure axis titles and labels.

            titlesData: FlTitlesData(
              /// X-axis shows dates with dynamic year display.

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) =>
                      _buildXAxisLabel(value, theme),
                ),
              ),

              // Y-axis configuration showing pressure values.

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) =>
                      _buildYAxisLabel(value, theme),
                ),
              ),

              /// Hide unnecessary axis titles.

              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),

            /// Chart border for visual containment.

            borderData: FlBorderData(
              show: true,
              border: Border.all(color: theme.dividerColor),
            ),

            /// Chart value range configuration.

            minX: 0,
            maxX: (surveyData.length - 1).toDouble(),
            minY: 40, // Minimum expected diastolic pressure.
            maxY: 200, // Maximum expected systolic pressure.
            lineBarsData: [
              // Systolic pressure line configuration.

              LineChartBarData(
                spots: BPChartDataManager.getSystolicData(surveyData),
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: theme.colorScheme.surface,
                      strokeWidth: 3,
                      strokeColor: theme.colorScheme.primary,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),

              // Diastolic pressure line configuration.

              LineChartBarData(
                spots: BPChartDataManager.getDiastolicData(surveyData),
                isCurved: true,
                color: theme.colorScheme.secondary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: theme.colorScheme.surface,
                      strokeWidth: 3,
                      strokeColor: theme.colorScheme.secondary,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds tooltip items for chart data points.

  List<LineTooltipItem> _buildTooltipItems(
    List<LineBarSpot> touchedSpots,
    ThemeData theme,
  ) {
    if (touchedSpots.isEmpty) return [];

    // Get the index of the data point from the first spot.

    final index = touchedSpots[0].x.toInt();
    final data = surveyData[index]['responses'];

    // Extract shared metadata.

    final heartRate = data[HealthSurveyConstants.fieldHeartRate] ?? 'N/A';
    final notes = data[HealthSurveyConstants.fieldNotes] ?? '';
    final timestamp = DateTime.parse(surveyData[index]['timestamp']);
    String timeStr = DateFormat('dd MMMM y h:mm a').format(timestamp);

    // Get both systolic and diastolic values from the data.

    final systolicValue = parseNumericInput(
      BPChartDataManager.parseNumericValue(
        data[HealthSurveyConstants.fieldSystolic],
      ),
    );
    final diastolicValue = parseNumericInput(
      BPChartDataManager.parseNumericValue(
        data[HealthSurveyConstants.fieldDiastolic],
      ),
    );

    // Create a consistent tooltip regardless of which point was touched.

    final List<String> contentLines = [
      'BLOOD PRESSURE: $systolicValue/$diastolicValue mmHg',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      '🕒 Time: $timeStr',
      '❤️ Heart Rate: ${parseNumericInput(BPChartDataManager.parseNumericValue(heartRate))} bpm',
    ];

    // Add notes if they exist.

    if (notes.isNotEmpty) {
      contentLines.add('📝 Notes: $notes');
    }

    // Join lines with consistent newlines.

    final tooltipContent = contentLines.join('\n');

    // Return tooltip items.

    final List<LineTooltipItem> items = [];

    for (int i = 0; i < touchedSpots.length; i++) {
      if (i == 0) {
        items.add(
          LineTooltipItem(
            tooltipContent,
            TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.8,
            ),
            textAlign: TextAlign.left,
          ),
        );
      } else {
        items.add(
          LineTooltipItem(
            '',
            const TextStyle(fontSize: 0),
          ),
        );
      }
    }

    return items;
  }

  /// Builds X-axis labels showing dates.

  Widget _buildXAxisLabel(double value, ThemeData theme) {
    final index = value.toInt();
    if (index >= 0 && index < surveyData.length && value == index.toDouble()) {
      final date = DateTime.parse(surveyData[index]['timestamp']);

      // Show year if this is first data point or if year changed from previous
      // point.

      bool showYear = index == 0 ||
          (index > 0 &&
              DateTime.parse(surveyData[index - 1]['timestamp']).year !=
                  date.year);

      /// Date label with hover tooltip showing time.

      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: MarkdownTooltip(
          message: '''

            **Time:** ${DateFormat('HH:mm').format(date)}

          ''',
          child: Text(
            '${date.day} ${getMonthAbbrev(date.month)}${showYear ? " '${(date.year % 100).toString().padLeft(2, '0')}" : ""}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return const Text('');
  }

  /// Builds Y-axis labels showing pressure values.

  Widget _buildYAxisLabel(double value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        value.toInt().toString(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
