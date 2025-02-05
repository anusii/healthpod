/// BP combined visualisation widget.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:healthpod/utils/parse_bp_numeric_input.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/constants/survey.dart';
import 'package:healthpod/features/visualise/stat_item.dart';
import 'package:healthpod/utils/get_month_abbrev.dart';

/// Combined blood pressure visualisation widget.
///
/// A widget for visualising both systolic and diastolic blood pressure
/// measurements on a single chart. This widget processes survey data to create an
/// interactive line chart showing blood pressure trends over time, with:
/// * Dual line visualisation for systolic and diastolic readings
/// * Interactive tooltips showing exact values
/// * Summary statistics including averages, minimums, and maximums
/// * Date-based X-axis and pressure-based Y-axis (mmHg)
/// * Color-coded lines and legend for easy differentiation
///
/// The widget expects survey data in a specific format with 'timestamp' and 'responses'
/// fields, where responses contain the blood pressure measurements.

class BPCombinedVisualisation extends StatefulWidget {
  /// Survey data containing blood pressure measurements.
  ///
  /// Each entry should be a map with 'timestamp' and 'responses' fields, where
  /// responses contains the systolic and diastolic blood pressure readings.

  final List<Map<String, dynamic>> surveyData;

  const BPCombinedVisualisation({
    super.key,
    required this.surveyData,
  });

  @override
  State<BPCombinedVisualisation> createState() =>
      _BPCombinedVisualisationState();
}

class _BPCombinedVisualisationState extends State<BPCombinedVisualisation> {
  /// Extracts and converts systolic blood pressure data into chart points.
  ///
  /// Returns a list of [FlSpot] objects where:
  /// * X coordinate represents the data point index
  /// * Y coordinate represents the systolic pressure in mmHg.

  List<FlSpot> _getSystolicData() {
    List<FlSpot> spots = [];
    for (var i = 0; i < widget.surveyData.length; i++) {
      final data = widget.surveyData[i]['responses'];
      double value =
          _parseNumericValue(data[HealthSurveyConstants.fieldSystolic]);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  /// Extracts and converts diastolic blood pressure data into chart points.
  ///
  /// Returns a list of [FlSpot] objects where:
  /// * X coordinate represents the data point index
  /// * Y coordinate represents the diastolic pressure in mmHg.

  List<FlSpot> _getDiastolicData() {
    List<FlSpot> spots = [];
    for (var i = 0; i < widget.surveyData.length; i++) {
      final data = widget.surveyData[i]['responses'];
      double value =
          _parseNumericValue(data[HealthSurveyConstants.fieldDiastolic]);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  /// Safely converts various numeric formats to double.
  ///
  /// Handles integers, doubles, and string representations of numbers.
  /// Returns 0.0 if the value cannot be parsed.

  double _parseNumericValue(dynamic value) {
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

  List<Widget> _buildStatItems() {
    // Extract values for calculations.

    final systolicValues = _getSystolicData().map((spot) => spot.y).toList();
    final diastolicValues = _getDiastolicData().map((spot) => spot.y).toList();

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
        value:
            '${parseBpNumericInput(systolicAvg)}/${parseBpNumericInput(diastolicAvg)} mmHg',
      ),
      Container(
        height: 40,
        width: 1,
        color: Colors.grey[300],
      ),
      StatItem(
        label: 'Min',
        value:
            '${parseBpNumericInput(systolicMin)}/${parseBpNumericInput(diastolicMin)} mmHg',
      ),
      Container(
        height: 40,
        width: 1,
        color: Colors.grey[300],
      ),
      StatItem(
        label: 'Max',
        value:
            '${parseBpNumericInput(systolicMax)}/${parseBpNumericInput(diastolicMax)} mmHg',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            MarkdownTooltip(
              message: '''
          **Blood Pressure Trends:** This chart displays your systolic and diastolic 
          blood pressure measurements over time. It helps you track fluctuations 
          and understand your cardiovascular health trends.
        ''',
              child: Row(children: [
                Text(
                  'Blood Pressure Trends',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ]),
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: titleBackgroundColor,
      ),

      // Main container padding providing consistent spacing around all content.

      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main chart area showing blood pressure trends.

            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.white,
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          /// Threshold line indicating normal systolic pressure limit.
                          ///
                          /// Uses a dashed purple line matching the systolic data color.
                          /// Upper systolic threshold line (120 mmHg).

                          HorizontalLine(
                            y: 120,
                            color: const Color(0xFF9F70FF),
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
                            color: const Color(0xFF00BD9D),
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
                          tooltipRoundedRadius: 8,
                          tooltipBorder: const BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),

                          /// Custom tooltip content generator showing pressure values
                          /// and normal ranges for each type.

                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot spot) {
                              final isSystolic = spot.barIndex == 0;
                              String label = '';
                              if (isSystolic) {
                                label =
                                    'Systolic: ${parseBpNumericInput(spot.y)} mmHg\nNormal: below 120 mmHg';
                              } else {
                                label =
                                    'Diastolic: ${parseBpNumericInput(spot.y)} mmHg\nNormal: below 80 mmHg';
                              }
                              return LineTooltipItem(
                                label,
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),

                      /// Grid configuration for better data readability.
                      /// Uses light grey dashed lines for subtle visual guidance.

                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 20,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 0.5,
                            dashArray: [5, 5],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
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
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < widget.surveyData.length &&
                                  value == index.toDouble()) {
                                final date = DateTime.parse(
                                    widget.surveyData[index]['timestamp']);

                                // Show year if this is first data point or if year changed from previous point.

                                bool showYear = index == 0 ||
                                    (index > 0 &&
                                        DateTime.parse(
                                                    widget.surveyData[index - 1]
                                                        ['timestamp'])
                                                .year !=
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
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        // Y-axis configuration showing pressure values.

                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
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
                        border: Border.all(color: Colors.grey[300]!),
                      ),

                      /// Chart value range configuration.

                      minX: 0,
                      maxX: (widget.surveyData.length - 1).toDouble(),
                      minY: 40, // Minimum expected diastolic pressure.
                      maxY: 200, // Maximum expected systolic pressure.
                      lineBarsData: [
                        // Systolic pressure line configuration.

                        // Bright purple and teal lines for systolic and diastolic pressure.
                        // From Bang Wong's colourblind-safe palette.

                        LineChartBarData(
                          spots: _getSystolicData(),
                          isCurved: true,
                          color: const Color(0xFF9F70FF), // Bright purple.
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor:
                                    Theme.of(context).colorScheme.primary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Diastolic pressure line configuration.

                        LineChartBarData(
                          spots: _getDiastolicData(),
                          isCurved: true,
                          color: const Color(0xFF00BD9D), // Turquoise/mint.
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor:
                                    Theme.of(context).colorScheme.secondary,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend and statistics card.

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  children: [
                    // Legend items.

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Systolic pressure legend item.
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Colour indicator dot.

                              Flexible(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFF9F70FF), // Bright purple.
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Systolic blood pressure tooltip explaining the measurement.

                              MarkdownTooltip(
                                message: '''

                                  **Systolic Blood Pressure:** The top number in your reading.
                                  Measures the pressure when your heart contracts to pump blood.
                                  Normal reading is typically below 120 mmHg.

                                ''',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width:
                                          50, // Adjust based on available space.
                                      child: Text(
                                        'Systolic',
                                        overflow: TextOverflow.ellipsis,
                                        softWrap:
                                            false, // Prevents multi-line issues.
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Info icon.

                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Diastolic pressure legend item.

                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Colour indicator dot.

                              Flexible(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFF00BD9D), // Turquoise/mint.
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Diastolic blood pressure tooltip explaining the measurement.

                              MarkdownTooltip(
                                message: '''

                                  **Diastolic Blood Pressure:** The bottom number in your reading.
                                  Measures the pressure when your heart relaxes between beats.
                                  Normal reading is typically below 80 mmHg.

                                ''',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(child: const Text('Diastolic')),
                                    const SizedBox(width: 4),
                                    // Info icon.

                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit
                                            .scaleDown, // Scales down to fit available space.
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scrollable stats row.

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildStatItems(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
