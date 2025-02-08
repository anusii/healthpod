/// Display row for a blood pressure observation.
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
import 'package:healthpod/utils/parse_numeric_input.dart';

/// Creates a read-only [DataRow] for displaying a single [BPObservation].
///
/// This row shows the observation's timestamp, systolic pressure, diastolic
/// pressure, heart rate, feeling, and notes. It also provides an edit button
/// (`onEdit`) and a delete button (`onDelete`) for user interactions.
///
/// The [index] can help identify the observation's position in the parent list.
/// The [context] is used for resolving localizations, themes, or showing UI
/// feedback (e.g. snack bars).
///
/// Returns:
/// - A [DataRow] populated with various [DataCell] widgets representing the
///   observation's fields.

DataRow buildDisplayRow({
  required BuildContext context,
  required BPObservation observation,
  required int index,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return DataRow(
    cells: [
      // Timestamp cell.

      DataCell(
        Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(observation.timestamp)),
      ),

      // Systolic cell.

      DataCell(Text(parseNumericInput(observation.systolic))),

      // Diastolic cell.

      DataCell(Text(parseNumericInput(observation.diastolic))),

      // Heart rate cell.

      DataCell(Text(parseNumericInput(observation.heartRate))),

      // Feeling cell.

      DataCell(Text(observation.feeling)),

      // Notes cell (with a max width to limit horizontal space usage).

      DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            observation.notes,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ),

      // Actions cell: edit and delete icons.

      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    ],
  );
}
