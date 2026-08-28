/// The table of recorded health profile measurements.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/health_profile.dart';
import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/utils/format_measure.dart';
import 'package:healthpod/widgets/action_buttons.dart';

/// One row per recorded entry, one column per measurement.
///
/// A blank cell means that measurement was not entered at that time, which is
/// how a single measurement can be updated on its own.

class HealthProfileHistoryTable extends StatelessWidget {
  const HealthProfileHistoryTable({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  /// The recorded entries, in the order they are shown.

  final List<HealthProfileEntry> entries;

  /// Called to remove an entry from the pod.

  final void Function(HealthProfileEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: Theme.of(context).textTheme.titleSmall,

          // Tighter than the default so the measurements and the delete
          // button fit a window without scrolling sideways.

          columnSpacing: 24,
          columns: [
            const DataColumn(label: Text('Recorded')),
            ...HealthProfileConstants.units.entries.map(
              (measure) => DataColumn(
                label: Text(
                  '${HealthProfileConstants.labels[measure.key]} '
                  '(${measure.value})',
                ),
                numeric: true,
              ),
            ),
            const DataColumn(label: Text('')),
          ],
          rows: entries.map((entry) => _row(context, entry)).toList(),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, HealthProfileEntry entry) {
    return DataRow(
      cells: [
        DataCell(
          Text(DateFormat('d MMM y h:mm a').format(entry.timestamp)),
        ),
        ...HealthProfileConstants.units.keys.map((field) {
          final value = entry.values[field];
          return DataCell(Text(value == null ? '' : formatMeasure(value)));
        }),
        DataCell(
          MarkdownTooltip(
            message: '''

              **Delete:** Remove this record from your pod.

              Use this for an entry made in error. The other entries, and the
              measurements they hold, are left as they are.

            ''',
            child: DeleteButton(
              record: 'record',
              showTooltip: false,
              onPressed: () => onDelete(entry),
            ),
          ),
        ),
      ],
    );
  }
}
