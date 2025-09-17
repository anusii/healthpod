/// Mobile layout widgets for medication editor.
///
// Time-stamp: <Tuesday 2025-04-29 15:45:00 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/features/table/medication_editor/service.dart';
import 'package:healthpod/features/table/medication_editor/state.dart';
import 'package:healthpod/features/table/medication_editor/widgets/ui_components.dart';

/// Mobile layout for the medication editor.
///
/// Creates a scrollable list of cards, each representing a medication
/// observation. Cards can be expanded to show additional details and include
/// edit/delete actions.

class MedicationMobileLayout extends StatelessWidget {
  const MedicationMobileLayout({
    super.key,
    required this.editorState,
    required this.editorService,
    required this.onEdit,
    required this.onDelete,
    required this.onReload,
  });

  final MedicationEditorState editorState;
  final MedicationEditorService editorService;
  final VoidCallback Function(int index) onEdit;
  final Future<void> Function(MedicationObservation obs) onDelete;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: editorState.observations.length,
      itemBuilder: (context, index) {
        final obs = editorState.observations[index];
        final isEditing = editorState.editingIndex == index;

        if (isEditing) {
          return MedicationMobileEditCard(
            observation: obs,
            index: index,
            editorState: editorState,
            editorService: editorService,
            onReload: onReload,
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              obs.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              '${obs.dosage} - ${obs.frequency}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MedicationUIComponents.buildInfoRow(
                      context,
                      'Start Date',
                      DateFormat('yyyy-MM-dd').format(obs.startDate),
                    ),
                    if (obs.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      MedicationUIComponents.buildInfoRow(
                        context,
                        'Notes',
                        obs.notes,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: onEdit(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => onDelete(obs),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mobile edit card for medication editing.

class MedicationMobileEditCard extends StatefulWidget {
  const MedicationMobileEditCard({
    super.key,
    required this.observation,
    required this.index,
    required this.editorState,
    required this.editorService,
    required this.onReload,
  });

  final MedicationObservation observation;
  final int index;
  final MedicationEditorState editorState;
  final MedicationEditorService editorService;
  final VoidCallback onReload;

  @override
  State<MedicationMobileEditCard> createState() =>
      _MedicationMobileEditCardState();
}

class _MedicationMobileEditCardState extends State<MedicationMobileEditCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editorState.isNewObservation
                  ? 'Add New Medication'
                  : 'Edit Medication',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            MedicationUIComponents.buildTextField(
              context,
              controller: widget.editorState.nameController!,
              label: 'Medication Name *',
            ),
            const SizedBox(height: 12),
            MedicationUIComponents.buildTextField(
              context,
              controller: widget.editorState.dosageController!,
              label: 'Dosage *',
              hint: 'e.g., 10mg, 1 tablet',
            ),
            const SizedBox(height: 12),
            MedicationUIComponents.buildTextField(
              context,
              controller: widget.editorState.frequencyController!,
              label: 'Frequency *',
              hint: 'e.g., Once daily, Twice daily, As needed',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(),
              child: MedicationUIComponents.buildInfoRow(
                context,
                'Start Date',
                DateFormat('yyyy-MM-dd').format(widget.observation.startDate),
                isEditable: true,
              ),
            ),
            const SizedBox(height: 12),
            MedicationUIComponents.buildTextField(
              context,
              controller: widget.editorState.notesController!,
              label: 'Notes',
              hint: 'Additional information',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _handleCancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: _handleSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handles date selection.

  Future<void> _selectDate() async {
    final colorScheme = Theme.of(context).colorScheme;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.observation.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.brightness == Brightness.dark
                ? colorScheme.copyWith(
                    primary: colorScheme.primaryContainer,
                    onPrimary: colorScheme.onPrimaryContainer,
                    surface: colorScheme.surface,
                    onSurface: colorScheme.onSurface,
                  )
                : colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && context.mounted) {
      setState(() {
        widget.editorState.currentEdit = widget.observation.copyWith(
          startDate: pickedDate,
        );
      });
    }
  }

  /// Handles cancel edit.

  void _handleCancelEdit() {
    if (widget.editorState.isNewObservation) {
      // Remove the new observation from the list.
      widget.editorState.observations.removeAt(0);
    }
    widget.editorState.cancelEdit();
    widget.onReload();
  }

  /// Handles save operation.

  Future<void> _handleSave() async {
    await widget.editorState.saveObservation(
      context,
      widget.editorService,
      widget.index,
    );
    widget.onReload();
  }
}
