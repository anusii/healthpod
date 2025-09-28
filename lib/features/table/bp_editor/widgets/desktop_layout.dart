/// Desktop layout widgets for blood pressure editor.
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

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/bp/obs/widgets/display_row.dart';
import 'package:healthpod/features/bp/obs/widgets/editing_row.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';

/// Builds the desktop layout for the blood pressure editor.
///
/// Uses a DataTable with responsive columns that adapt based on screen width.
/// The table shows a minimum set of columns (timestamp, systolic, diastolic)
/// and progressively reveals more columns (heart rate, notes) as screen
/// width increases.

class BPEditorDesktopLayout extends StatelessWidget {
  const BPEditorDesktopLayout({
    super.key,
    required this.editorState,
    required this.editorService,
    required this.width,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelEdit,
    required this.onSave,
    required this.onTimestampChanged,
  });

  final BPEditorState editorState;
  final BPEditorService editorService;
  final double width;
  final VoidCallback Function(int index) onEdit;
  final Future<void> Function(BPObservation obs, int index) onDelete;
  final VoidCallback onCancelEdit;
  final Future<void> Function(int index) onSave;
  final Function(DateTime timestamp) onTimestampChanged;

  @override
  Widget build(BuildContext context) {
    final columns = _getColumns(width);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: List<DataRow>.generate(
            editorState.observations.length,
            (index) {
              final obs = editorState.observations[index];

              if (editorState.editingIndex == index) {
                return buildEditingRow(
                  context: context,
                  width: width,
                  editorState: editorState,
                  editorService: editorService,
                  observation: obs,
                  index: index,
                  onCancel: onCancelEdit,
                  onSave: () => onSave(index),
                  onTimestampChanged: onTimestampChanged,
                );
              }

              return buildDisplayRow(
                context: context,
                width: width,
                observation: obs,
                index: index,
                onEdit: onEdit(index),
                onDelete: () => onDelete(obs, index),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Gets the list of columns to display in the DataTable based on screen width.
  ///
  /// Implements responsive column visibility:
  /// - Base columns (Timestamp, Systolic, Diastolic) always visible
  /// - Heart Rate visible when width > 600
  /// - Notes visible when width > 800
  /// - Actions column always visible

  List<DataColumn> _getColumns(double width) {
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Timestamp')),
      const DataColumn(label: Text('Systolic')),
      const DataColumn(label: Text('Diastolic')),
    ];

    if (width > 600) {
      columns.add(const DataColumn(label: Text('Heart Rate')));
    }

    if (width > 800) {
      columns.add(const DataColumn(label: Text('Notes')));
    }

    columns.add(const DataColumn(label: Text('Actions')));

    return columns;
  }
}
