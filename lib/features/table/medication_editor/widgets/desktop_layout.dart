/// Desktop layout widgets for medication editor.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/features/table/medication_editor/service.dart';
import 'package:healthpod/features/table/medication_editor/state.dart';
import 'package:healthpod/features/table/medication_editor/widgets/table_columns.dart';
import 'package:healthpod/features/table/medication_editor/widgets/ui_components.dart';
import 'package:healthpod/widgets/action_buttons.dart';

/// Desktop layout for the medication editor.
///
/// Uses a DataTable with responsive columns that adapt based on screen width.

class MedicationDesktopLayout extends StatelessWidget {
  const MedicationDesktopLayout({
    super.key,
    required this.editorState,
    required this.editorService,
    required this.width,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelEdit,
    required this.onSave,
  });

  final MedicationEditorState editorState;
  final MedicationEditorService editorService;
  final double width;
  final VoidCallback Function(int index) onEdit;
  final Future<void> Function(MedicationObservation obs) onDelete;
  final VoidCallback onCancelEdit;
  final Future<void> Function(int index) onSave;

  @override
  Widget build(BuildContext context) {
    final columns = MedicationTableColumns.getColumns(width);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: List<DataRow>.generate(editorState.observations.length, (
            index,
          ) {
            final obs = editorState.observations[index];

            // If this row is being edited, build the editing row.

            if (editorState.editingIndex == index) {
              return MedicationDataRowBuilder.buildEditingDataRow(
                context,
                editorState,
                obs,
                index,
                onCancelEdit,
                () => onSave(index),
              );
            }

            // Otherwise show regular display row.

            return MedicationDataRowBuilder.buildDataRow(
              context,
              obs,
              index,
              width,
              onEdit(index),
              () => onDelete(obs),
            );
          }),
        ),
      ),
    );
  }
}

/// Builder class for medication table data rows.

class MedicationDataRowBuilder {
  const MedicationDataRowBuilder._();

  /// Builds a standard data row for the table.

  static DataRow buildDataRow(
    BuildContext context,
    MedicationObservation observation,
    int index,
    double width,
    VoidCallback onEdit,
    Future<void> Function() onDelete,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final cells = <DataCell>[];

    // Base cells (always visible).

    cells.add(DataCell(Text(observation.name)));
    cells.add(DataCell(Text(observation.dosage)));

    // Responsive cells.

    if (width > 500) {
      cells.add(DataCell(Text(observation.frequency)));
    }

    if (width > 700) {
      cells.add(DataCell(Text(dateFormat.format(observation.startDate))));
    }

    if (width > 900) {
      cells.add(
        DataCell(
          Text(
            observation.notes.isEmpty ? '-' : observation.notes,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Actions cell (always visible).

    cells.add(
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: actionButtonSpacing,
          children: [
            EditButton(record: 'medication', onPressed: onEdit),
            DeleteButton(record: 'medication', onPressed: onDelete),
          ],
        ),
      ),
    );

    return DataRow(cells: cells);
  }

  /// Builds a data row for editing an observation.

  static DataRow buildEditingDataRow(
    BuildContext context,
    MedicationEditorState editorState,
    MedicationObservation observation,
    int index,
    VoidCallback onCancel,
    Future<void> Function() onSave,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return DataRow(
      color: WidgetStateProperty.all(
        isDarkMode
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.grey.shade200,
      ),
      cells: [
        DataCell(
          MedicationUIComponents.buildInlineTextField(
            context,
            editorState.nameController!,
          ),
        ),
        DataCell(
          MedicationUIComponents.buildInlineTextField(
            context,
            editorState.dosageController!,
          ),
        ),
        if (width > 500)
          DataCell(
            MedicationUIComponents.buildInlineTextField(
              context,
              editorState.frequencyController!,
            ),
          ),
        if (width > 700) _buildDateCell(context, editorState, observation),
        if (width > 900)
          DataCell(
            MedicationUIComponents.buildInlineTextField(
              context,
              editorState.notesController!,
            ),
          ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: actionButtonSpacing,
            children: [
              SaveButton(onPressed: () async => onSave()),
              CancelButton(onPressed: onCancel),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the date selection cell for editing mode.

  static DataCell _buildDateCell(
    BuildContext context,
    MedicationEditorState editorState,
    MedicationObservation observation,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return DataCell(
      InkWell(
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: observation.startDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: isDarkMode
                      ? colorScheme.copyWith(
                          primary: colorScheme.primaryContainer,
                          onPrimary: colorScheme.onPrimaryContainer,
                        )
                      : colorScheme,
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null && context.mounted) {
            editorState.currentEdit = observation.copyWith(
              startDate: pickedDate,
            );
          }
        },
        child: Text(
          DateFormat(
            'yyyy-MM-dd',
          ).format(editorState.currentEdit?.startDate ?? observation.startDate),
          style: TextStyle(
            decoration: TextDecoration.underline,
            color: isDarkMode ? colorScheme.primaryContainer : Colors.blue,
          ),
        ),
      ),
    );
  }
}
