/// Editing row for a blood pressure observation.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/action_buttons_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/feeling_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/notes_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/numeric_cell.dart';

/// Builds an editable [DataRow] for modifying a [BPObservation].
///
/// This row shows text fields for systolic, diastolic, and heart rate,
/// a dropdown for the "feeling" field, a multi-line text field for notes,
/// and a timestamp cell for picking date/time down to the minute.
///
/// All changes are reflected in [editorState.currentEdit], so the user sees
/// them in real time. Actual file operations happen only on "Save."

DataRow buildEditingRow({
  required BuildContext context,
  required BPEditorState editorState,
  required dynamic editorService,
  required BPObservation observation,
  required int index,
  required VoidCallback onCancel,
  required VoidCallback onSave,
  required ValueChanged<DateTime> onTimestampChanged,
}) {
  // Get the "currentEdit" model that holds unsaved changes.

  final currentEdit = editorState.currentEdit ?? observation;

  return DataRow(
    cells: [
      buildTimestampCell(
        context: context,
        editorState: editorState,
        observation: observation,
        currentEdit: currentEdit,
        onTimestampChanged: onTimestampChanged,
      ),

      // Generic numeric cells for systolic, diastolic, heart rate.

      numericCell(
        controller: editorState.systolicController,
        // Value updates handled by controller listeners.

        onValueChange: (val) {},
      ),
      numericCell(
        controller: editorState.diastolicController,
        onValueChange:
            (val) {}, // Value updates handled by controller listeners
      ),
      numericCell(
        controller: editorState.heartRateController,
        onValueChange:
            (val) {}, // Value updates handled by controller listeners
      ),

      // Feeling dropdown and Notes cell.

      feelingCell(editorState, currentEdit),
      notesCell(editorState, currentEdit),

      // Action buttons for saving and canceling.

      actionButtonsCell(
        onSave: onSave,
        onCancel: onCancel,
      ),
    ],
  );
}

/// Builds a [DataCell] that lets the user pick a date/time, calling [onTimestampChanged]
/// to update the timestamp in a parent setState, which triggers a rebuild.

DataCell buildTimestampCell({
  required BuildContext context,
  required BPEditorState editorState,
  required BPObservation observation,
  required BPObservation currentEdit,

  // The callback we just added.

  required ValueChanged<DateTime> onTimestampChanged,
}) {
  return DataCell(
    InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: currentEdit.timestamp,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (!context.mounted) return;

        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(currentEdit.timestamp),
          );
          if (time != null && context.mounted) {
            final newTimestamp = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );

            // Check for duplicates.

            final conflict = editorState.observations.any(
              (r) => r.timestamp == newTimestamp && r != observation,
            );
            if (conflict) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'An observation with this date/time already exists',
                  ),
                ),
              );
              return;
            }

            // Instead of updating editorState here, call the parent's callback.

            onTimestampChanged(newTimestamp);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(currentEdit.timestamp),
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.blue,
          ),
        ),
      ),
    ),
  );
}
