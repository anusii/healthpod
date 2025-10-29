/// Mobile layout widgets for blood pressure editor.
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

import 'package:intl/intl.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';
import 'package:healthpod/features/table/bp_editor/widgets/utils.dart';

/// Builds the mobile layout for the blood pressure editor.
///
/// Creates a scrollable list of cards, each representing a blood pressure
/// observation. Cards can be expanded to show additional details and include
/// edit/delete actions.

class BPEditorMobileLayout extends StatelessWidget {
  const BPEditorMobileLayout({
    super.key,
    required this.editorState,
    required this.editorService,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelEdit,
    required this.onSave,
    required this.onTimestampChanged,
  });

  final BPEditorState editorState;
  final BPEditorService editorService;
  final VoidCallback Function(int index) onEdit;
  final Future<void> Function(BPObservation obs, int index) onDelete;
  final VoidCallback onCancelEdit;
  final Future<void> Function(int index) onSave;
  final Function(DateTime timestamp) onTimestampChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: editorState.observations.length,
      itemBuilder: (context, index) {
        final obs = editorState.observations[index];
        final isEditing = editorState.editingIndex == index;

        if (isEditing) {
          return _MobileEditCard(
            observation: obs,
            index: index,
            editorState: editorState,
            onCancel: onCancelEdit,
            onSave: () => onSave(index),
            onTimestampChanged: onTimestampChanged,
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(obs.timestamp),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'BP: ${obs.systolic.round()}/${obs.diastolic.round()} mmHg',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BPEditorUtils.buildInfoRow(
                      context,
                      'Heart Rate',
                      '${obs.heartRate.round()} BPM',
                    ),
                    if (obs.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      BPEditorUtils.buildInfoRow(context, 'Notes', obs.notes),
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
                          onPressed: () => onDelete(obs, index),
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

/// Mobile editing card widget for blood pressure observations.
///
/// Creates a form-style card with fields for editing all observation properties.
/// Optimised for touch interaction and mobile screen sizes.

class _MobileEditCard extends StatelessWidget {
  const _MobileEditCard({
    required this.observation,
    required this.index,
    required this.editorState,
    required this.onCancel,
    required this.onSave,
    required this.onTimestampChanged,
  });

  final BPObservation observation;
  final int index;
  final BPEditorState editorState;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Function(DateTime timestamp) onTimestampChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Reading',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDateTime(context),
              child: BPEditorUtils.buildInfoRow(
                context,
                'Date/Time',
                DateFormat('yyyy-MM-dd HH:mm').format(
                  editorState.currentEdit?.timestamp ?? observation.timestamp,
                ),
                isEditable: true,
              ),
            ),
            const SizedBox(height: 16),
            BPEditorUtils.buildMobileNumericField(
              controller: editorState.systolicController,
              label: 'Systolic',
              suffix: 'mmHg',
            ),
            const SizedBox(height: 8),
            BPEditorUtils.buildMobileNumericField(
              controller: editorState.diastolicController,
              label: 'Diastolic',
              suffix: 'mmHg',
            ),
            const SizedBox(height: 8),
            BPEditorUtils.buildMobileNumericField(
              controller: editorState.heartRateController,
              label: 'Heart Rate',
              suffix: 'BPM',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editorState.notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handles date and time selection for mobile interface.

  Future<void> _selectDateTime(BuildContext context) async {
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
  }
}
