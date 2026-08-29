/// Dialog presenting the analysis returned by the Analyser Pod.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/features/bp/analyser/saved_analysis_service.dart';

/// Shows the chart and the figures the analyser sent back.
///
/// The chart carries the detail — every reading, with the two sets of average
/// lines across it — so the figures beneath it are kept to the comparison a
/// reader actually wants: mine against everybody's.

Future<void> showAnalyserResultDialog(
  BuildContext context, {
  required AnalyserResult result,
  bool savedInPod = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AnalyserResultDialog(
      result: result,
      savedInPod: savedInPod,
    ),
  );
}

/// The dialog itself, kept separate so it can be shown and tested on its own.

class AnalyserResultDialog extends StatelessWidget {
  const AnalyserResultDialog({
    super.key,
    required this.result,
    this.savedInPod = true,
  });

  /// The analysis to present.

  final AnalyserResult result;

  /// Whether this analysis is the one now kept in the user's Pod.

  final bool savedInPod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = result.chart;

    return AlertDialog(
      title: const Text('Blood pressure analysis'),
      content: SizedBox(
        width: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your ${result.observationCount} observation'
                      '${result.observationCount == 1 ? '' : 's'}, compared '
                      'with ${result.podCount} contributing Pod'
                      '${result.podCount == 1 ? '' : 's'}.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // The chart, at its natural aspect ratio.

                    if (chart != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(chart, fit: BoxFit.contain),
                      )
                    else
                      Text(
                        'The ${Analyser.displayName} did not return a chart '
                        'this time. The figures below are still current.',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),

                    const SizedBox(height: 20),
                    _ComparisonTable(result: result),

                    const SizedBox(height: 16),
                    Text(
                      'Analysed ${_formatted(result.generatedAt.toLocal())}.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            // Where the analysis went stays outside the scrolling area:
            // below a tall chart it is the first thing to fall off the
            // bottom, and it is the only place the user is told where it is
            // kept.

            const Divider(height: 24),
            SelectableText(
              savedInPod
                  ? 'Kept in your Pod at ${BPAnalysisStore.podPath}, and '
                      'reopened with the history button above the chart.'
                  : 'This analysis could not be saved to your Pod, so it is '
                      'gone once this window is closed.',
              style: savedInPod
                  ? theme.textTheme.bodySmall
                  : theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// A short, unambiguous local timestamp: `21 Aug 2026 at 09:15`.

  static String _formatted(DateTime moment) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final minute = moment.minute.toString().padLeft(2, '0');

    return '${moment.day} ${months[moment.month - 1]} ${moment.year} '
        'at ${moment.hour}:$minute';
  }
}

/// The three measurements, yours beside everybody's.

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.result});

  final AnalyserResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            Text('Average', style: headingStyle),
            Text('You', style: headingStyle),
            Text('Everyone', style: headingStyle),
          ],
        ),
        _row(
          theme,
          'Systolic (mm Hg)',
          result.own.systolic,
          result.everyone.systolic,
        ),
        _row(
          theme,
          'Diastolic (mm Hg)',
          result.own.diastolic,
          result.everyone.diastolic,
        ),
        _row(
          theme,
          'Heart rate (bpm)',
          result.own.heartRate,
          result.everyone.heartRate,
        ),
      ],
    );
  }

  TableRow _row(ThemeData theme, String label, double? own, double? everyone) {
    String show(double? value) =>
        value == null ? '—' : value.toStringAsFixed(1);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            show(own),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(show(everyone), style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
