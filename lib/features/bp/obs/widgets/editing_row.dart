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

import 'package:intl/intl.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/action_buttons_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/feeling_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/notes_cell.dart';
import 'package:healthpod/features/bp/obs/widgets/editing/numeric_cell.dart';

/// Builds an editing row for a blood pressure observation.
///
/// @param context The build context.
/// @param editorState The editor state containing current values.
/// @param editorService The service for saving observations.
/// @param observation The observation being edited.
/// @param index The index of the observation in the list.
/// @param onCancel Callback when edit is cancelled.
/// @param onSave Callback when edit is saved.
/// @param onTimestampChanged Callback when timestamp is changed.
/// @param width The width of the screen.
/// @returns A DataRow widget configured for editing mode.

DataRow buildEditingRow({
  required BuildContext context,
  required dynamic editorState,
  required dynamic editorService,
  required BPObservation observation,
  required int index,
  required VoidCallback onCancel,
  required VoidCallback onSave,
  required Function(DateTime) onTimestampChanged,
  required double width,
}) {
  final cells = <DataCell>[
    // Timestamp cell.

    DataCell(
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: observation.timestamp,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (!context.mounted) return;

          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(observation.timestamp),
            );
            if (time != null && context.mounted) {
              final newTimestamp = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              onTimestampChanged(newTimestamp);
            }
          }
        },
        child: Text(
          DateFormat('yyyy-MM-dd HH:mm').format(
            editorState.currentEdit?.timestamp ?? observation.timestamp,
          ),
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.blue,
          ),
        ),
      ),
    ),

    // Systolic cell.

    numericCell(
      controller: editorState.systolicController,
      onValueChange: (_) {},
    ),

    // Diastolic cell.

    numericCell(
      controller: editorState.diastolicController,
      onValueChange: (_) {},
    ),
  ];

  // Add heart rate if screen is wide enough.

  if (width > 600) {
    cells.add(
      numericCell(
        controller: editorState.heartRateController,
        onValueChange: (_) {},
      ),
    );
  }

  // Add feeling and notes if screen is wide enough.

  if (width > 800) {
    cells.add(feelingCell(editorState, observation));
    cells.add(notesCell(editorState, observation));
  }

  // Add actions column.

  cells.add(actionButtonsCell(onSave: onSave, onCancel: onCancel));

  return DataRow(cells: cells);
}
