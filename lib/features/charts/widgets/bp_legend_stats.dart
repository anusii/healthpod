/// Legend and statistics widget for blood pressure chart.
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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/charts/widgets/bp_chart_data_manager.dart';

/// Widget displaying legend and statistics for blood pressure chart.

class BPLegendStats extends StatelessWidget {
  const BPLegendStats({
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
      color: theme.colorScheme.surface,
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
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Systolic blood pressure tooltip explaining the
                      // measurement.

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
                              width: 50, // Adjust based on available space.
                              child: Text(
                                'Systolic',
                                overflow: TextOverflow.ellipsis,
                                softWrap: false, // Prevents multi-line issues.
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Info icon.

                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onSurfaceVariant,
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
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Diastolic blood pressure tooltip explaining the
                      // measurement.

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
                                  color: theme.colorScheme.onSurfaceVariant,
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
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable stats row.

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: BPChartDataManager.buildStatItems(surveyData, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
