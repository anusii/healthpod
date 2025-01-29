/// BP visualisation widget.
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

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/constants/survey.dart';
import 'package:healthpod/features/visualise/stat_item.dart';

/// Data visualisation widget.
///
/// A tool for presenting health data trends in a visual and interactive format.
/// This widget processes survey data and creates charts and summarises to help users
/// track their health.

/// Main widget for health data visualisation.
///
/// Displays a line chart and summary statistics for key health metrics.

class BPVisualisation extends StatefulWidget {
  final List<Map<String, dynamic>> surveyData;

  // Accepts a list of survey data that will be used for charting and analysis.

  const BPVisualisation({
    super.key,
    required this.surveyData,
  });

  @override
  State<BPVisualisation> createState() => _BPVisualisationState();
}

class _BPVisualisationState extends State<BPVisualisation> {
  String _selectedMetric = 'systolic'; // Default selected metric

  /// Processes survey data and converts it into chart-friendly FlSpot objects.
  ///
  /// Each FlSpot represents a data point in the chart.

  List<FlSpot> _getChartData(String metric) {
    List<FlSpot> spots = [];
    for (var i = 0; i < widget.surveyData.length; i++) {
      final data = widget.surveyData[i]['responses'];
      double value = 0;

      // Ensure we use the field or variable name for BP survey instead of full questions.

      switch (metric) {
        case 'systolic':
          value = _parseNumericValue(data[HealthSurveyConstants.fieldSystolic]);
          break;
        case 'diastolic':
          value =
              _parseNumericValue(data[HealthSurveyConstants.fieldDiastolic]);
          break;
        case 'heartRate':
          value =
              _parseNumericValue(data[HealthSurveyConstants.fieldHeartRate]);
          break;
      }

      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  /// Helper function to handle numeric parsing for various data formats.
  ///
  /// Ensures robust handling of integers, doubles and strings.

  double _parseNumericValue(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.parse(value);
    }

    debugPrint('Warning: Invalid numeric value: $value');
    return 0.0; // Default value or error handling
  }

  /// Determines Y-axis range for selected metric to keep chart scaled.

  (double, double) _getYAxisRange(String metric) {
    switch (metric) {
      case 'systolic':
        return (70, 200);
      case 'diastolic':
        return (40, 120);
      case 'heartRate':
        return (40, 220);
      default:
        return (0, 200);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (yMin, yMax) = _getYAxisRange(_selectedMetric);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Data Trends',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: titleBackgroundColor,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Metric selector enables users to switch between different health metrics.

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(95);
                        }
                        return Colors.white;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) {
                        return Theme.of(context)
                            .colorScheme
                            .primary; // Purple text
                      },
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'systolic',
                      label: Text(
                        'Systolic BP',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ButtonSegment(
                      value: 'diastolic',
                      label: Text(
                        'Diastolic BP',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ButtonSegment(
                      value: 'heartRate',
                      label: Text(
                        'Heart Rate',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  selected: {_selectedMetric},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedMetric = selection.first;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chart area shows visual representation of health data trends.

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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          tooltipBorder: BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                touchedSpot.y.toString(),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
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
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval:
                                1, // Ensure we only get labels at whole number intervals
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              // Only show label if it's an exact match for a data point index.

                              if (index >= 0 &&
                                  index < widget.surveyData.length &&
                                  value == index.toDouble()) {
                                // This ensures we only show labels at exact data points.

                                final date = DateTime.parse(
                                    widget.surveyData[index]['timestamp']);
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text(
                                  ''); // Return empty text for non-data points
                            },
                          ),
                        ),
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
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      minX: 0,
                      maxX: (widget.surveyData.length - 1).toDouble(),
                      minY: yMin,
                      maxY: yMax,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(_selectedMetric),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
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
                          belowBarData: BarAreaData(
                            show: false, // remove filled area below line chart
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics summary displays average, min and max values for selected metric.

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildStatItems(_selectedMetric),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds widgets to display key statistics: average, minimum and maximum values.

  List<Widget> _buildStatItems(String metric) {
    final values = _getChartData(metric).map((spot) => spot.y).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    String unit = metric == 'heartRate' ? 'bpm' : 'mmHg';

    return [
      StatItem(
        label: 'Average',
        value: '${avg.toStringAsFixed(1)} $unit',
      ),
      Container(
        height: 40,
        width: 1,
        color: Colors.grey[300],
      ),
      StatItem(
        label: 'Min',
        value: '${min.toStringAsFixed(1)} $unit',
      ),
      Container(
        height: 40,
        width: 1,
        color: Colors.grey[300],
      ),
      StatItem(
        label: 'Max',
        value: '${max.toStringAsFixed(1)} $unit',
      ),
    ];
  }
}
