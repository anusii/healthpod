/// Editing row for Blood Pressure Observations.
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
import 'package:intl/intl.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/editor/state.dart';

/// Builds an editable [DataRow] for modifying a [BPObservation].
///
/// This row shows text fields for systolic, diastolic, and heart rate,
/// a dropdown for the "feeling" field, and a multi-line text field for notes.
/// It also provides a timestamp cell that allows the user to pick a new date
/// and time, as well as an optional dialog to set milliseconds precisely.

DataRow buildEditingRow({
  required BuildContext context,
  required BPEditorState editorState,
  required dynamic editorService,
  required BPObservation observation,
  required int index,
  required VoidCallback onCancel,
  required VoidCallback onSave,
}) {
  // Current observation values being edited, defaulting to the passed-in observation.

  final currentEdit = editorState.currentEdit ?? observation;

  // Ensure controllers are initialised.

  if (editorState.systolicController == null) {
    editorState.initialiseControllers(observation);
  }

  return DataRow(
    cells: [
      // Timestamp cell with a date/time picker. A separate dialog for milliseconds is optional.

      DataCell(
        InkWell(
          onTap: () async {
            // Show date picker.

            final date = await showDatePicker(
              context: context,
              initialDate: currentEdit.timestamp,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );

            // Always check whether the widget is still mounted before using context.

            if (!context.mounted) return;

            if (date != null) {
              // Show time picker.

              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(currentEdit.timestamp),
              );

              if (time != null && context.mounted) {
                // (Optional) Show a dialog to set milliseconds precisely.

                final TextEditingController msController =
                    TextEditingController();
                final milliseconds = await showDialog<int>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Set Milliseconds'),
                    content: TextField(
                      controller: msController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter milliseconds (0-999)',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(0),
                        child: const Text('Skip'),
                      ),
                      TextButton(
                        onPressed: () {
                          final ms = int.tryParse(msController.text) ?? 0;
                          Navigator.of(context).pop(ms.clamp(0, 999));
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );

                // Construct a new timestamp with selected date/time and optional milliseconds.

                final newTimestamp = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                  0,
                  milliseconds ?? 0,
                );

                // Check if another observation already uses the new timestamp.

                if (editorState.observations.any(
                  (r) =>
                      r.timestamp == newTimestamp &&
                      editorState.observations.indexOf(r) != index,
                )) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'An observation with this timestamp already exists'),
                    ),
                  );
                  return;
                }

                // If valid, update the observation's timestamp in the state list.

                editorState.observations[index] =
                    observation.copyWith(timestamp: newTimestamp);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
                  .format(observation.timestamp),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),

      // Systolic text field.

      DataCell(
        TextField(
          controller: editorState.systolicController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            editorState.currentEdit = currentEdit.copyWith(
              systolic: value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
            );
          },
        ),
      ),

      // Diastolic text field.

      DataCell(
        TextField(
          controller: editorState.diastolicController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            editorState.currentEdit = currentEdit.copyWith(
              diastolic: value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
            );
          },
        ),
      ),

      // Heart Rate text field.

      DataCell(
        TextField(
          controller: editorState.heartRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            editorState.currentEdit = currentEdit.copyWith(
              heartRate: value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
            );
          },
        ),
      ),

      // Feeling dropdown.

      DataCell(
        DropdownButton<String>(
          value: currentEdit.feeling.isEmpty ? null : currentEdit.feeling,
          items: ['Excellent', 'Good', 'Fair', 'Poor']
              .map(
                (feeling) => DropdownMenuItem(
                  value: feeling,
                  child: Text(feeling),
                ),
              )
              .toList(),
          onChanged: (value) {
            editorState.currentEdit =
                currentEdit.copyWith(feeling: value ?? '');
          },
        ),
      ),

      // Notes cell.

      DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TextField(
            controller: editorState.notesController,
            maxLines: null,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
            ),
            onChanged: (value) {
              editorState.currentEdit = currentEdit.copyWith(notes: value);
            },
          ),
        ),
      ),

      // Action buttons for saving or canceling.

      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: onSave,
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    ],
  );
}
