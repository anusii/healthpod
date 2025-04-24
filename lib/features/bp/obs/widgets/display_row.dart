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

/// Creates a read-only [DataRow] for displaying a single [BPObservation].
///
/// This row shows the observation's timestamp, systolic pressure, diastolic
/// pressure, heart rate and notes. It also provides an edit button
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
  required double width,
}) {
  final cells = <DataCell>[
    DataCell(
        Text(DateFormat('yyyy-MM-dd HH:mm').format(observation.timestamp))),
    DataCell(Text('${observation.systolic}')),
    DataCell(Text('${observation.diastolic}')),
  ];

  // Add heart rate if screen is wide enough.

  if (width > 600) {
    cells.add(DataCell(Text('${observation.heartRate}')));
  }

  // Add notes if screen is wide enough.

  if (width > 800) {
    cells.add(DataCell(Text(observation.notes)));
  }

  // Add actions column.

  cells.add(
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
  );

  return DataRow(cells: cells);
}
