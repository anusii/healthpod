/// Blood pressure editor page main entry point.
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

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/bp/obs/widgets/display_row.dart';
import 'package:healthpod/features/bp/obs/widgets/editing_row.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';

/// The main editor page for blood pressure observations.

class BPEditorPage extends StatefulWidget {
  const BPEditorPage({super.key});

  @override
  State<BPEditorPage> createState() => _BPEditorPageState();
}

class _BPEditorPageState extends State<BPEditorPage> {
  late BPEditorState editorState;
  late BPEditorService editorService;

  @override
  void initState() {
    super.initState();

    // Initialise state and service.

    editorState = BPEditorState();
    editorService = BPEditorService();

    // Load initial data.

    _loadData();
  }

  /// Loads blood pressure observations from POD storage.
  ///
  /// Fetches all .enc.ttl files from the bp directory, decrypts them,
  /// and parses them into BPObservation objects. Observations are sorted by timestamp
  /// in descending order (newest first).

  Future<void> _loadData() async {
    try {
      setState(() => editorState.isLoading = true);

      // Load observations from POD using the service.

      final observations = await editorService.loadData(context);
      setState(() {
        editorState.observations = observations;
        editorState.observations
            .sort((a, b) => b.timestamp.compareTo(a.timestamp));
        editorState.isLoading = false;
        editorState.error = null;
      });
    } catch (e) {
      setState(() {
        editorState.error = e.toString();
        editorState.isLoading = false;
      });
    }
  }

  /// Adds a new observation and immediately switches to edit mode.

  void _addNewObservation() {
    setState(() {
      editorState.addNewObservation();
    });
  }

  /// Handles canceling the current edit.

  void _handleCancelEdit() {
    setState(() {
      if (editorState.isNewObservation) {
        // Remove the new observation from the list.

        editorState.observations.removeAt(0);
      }
      editorState.cancelEdit();
    });
  }

  /// Builds the desktop layout for the blood pressure editor.
  ///
  /// Uses a DataTable with responsive columns that adapt based on screen width.
  /// The table shows a minimum set of columns (timestamp, systolic, diastolic) and
  /// progressively reveals more columns (heart rate, feeling, notes) as screen width increases.
  ///
  /// @param context The build context.
  /// @param width The current screen width.
  /// @returns A Widget containing the desktop layout.

  Widget _buildDesktopLayout(BuildContext context, double width) {
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
                  onCancel: _handleCancelEdit,
                  onSave: () async {
                    await editorState.saveObservation(
                      context,
                      editorService,
                      index,
                    );
                    _loadData();
                  },
                  onTimestampChanged: (DateTime newTimestamp) {
                    setState(() {
                      editorState.currentEdit =
                          editorState.currentEdit?.copyWith(
                        timestamp: newTimestamp,
                      );
                    });
                  },
                );
              }

              return buildDisplayRow(
                context: context,
                width: width,
                observation: obs,
                index: index,
                onEdit: () => setState(() {
                  editorState.enterEditMode(index);
                }),
                onDelete: () async {
                  await editorState.deleteObservation(
                    context,
                    editorService,
                    obs,
                  );
                  _loadData();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the mobile layout for the blood pressure editor.
  ///
  /// Creates a scrollable list of cards, each representing a blood pressure observation.
  /// Cards can be expanded to show additional details and include edit/delete actions.
  ///
  /// @param context The build context.
  /// @returns A Widget containing the mobile layout.

  Widget _buildMobileLayout(BuildContext context) {
    return ListView.builder(
      itemCount: editorState.observations.length,
      itemBuilder: (context, index) {
        final obs = editorState.observations[index];
        final isEditing = editorState.editingIndex == index;

        if (isEditing) {
          return _buildMobileEditCard(obs, index);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(obs.timestamp),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'BP: ${obs.systolic}/${obs.diastolic} mmHg',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Heart Rate', '${obs.heartRate} BPM'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Feeling', obs.feeling),
                    if (obs.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Notes', obs.notes),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => setState(() {
                            editorState.enterEditMode(index);
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await editorState.deleteObservation(
                              context,
                              editorService,
                              obs,
                            );
                            _loadData();
                          },
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

  /// Builds a mobile-optimised numeric input field.

  Widget _buildMobileNumericField({
    required TextEditingController? controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }

  /// Builds an editing card for the mobile layout.
  ///
  /// Creates a form-style card with fields for editing all observation properties.
  /// Optimized for touch interaction and mobile screen sizes.
  ///
  /// @param obs The blood pressure observation being edited.
  /// @param index The index of the observation in the list.
  /// @returns A Widget containing the mobile editing form.

  Widget _buildMobileEditCard(BPObservation obs, int index) {
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
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: obs.timestamp,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (!context.mounted) return;

                if (date != null) {
                  if (!mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(obs.timestamp),
                  );
                  if (time != null && context.mounted) {
                    final newTimestamp = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    setState(() {
                      editorState.currentEdit =
                          editorState.currentEdit?.copyWith(
                        timestamp: newTimestamp,
                      );
                    });
                  }
                }
              },
              child: _buildInfoRow(
                'Date/Time',
                DateFormat('yyyy-MM-dd HH:mm').format(
                    editorState.currentEdit?.timestamp ?? obs.timestamp),
                isEditable: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildMobileNumericField(
              controller: editorState.systolicController,
              label: 'Systolic',
              suffix: 'mmHg',
            ),
            const SizedBox(height: 8),
            _buildMobileNumericField(
              controller: editorState.diastolicController,
              label: 'Diastolic',
              suffix: 'mmHg',
            ),
            const SizedBox(height: 8),
            _buildMobileNumericField(
              controller: editorState.heartRateController,
              label: 'Heart Rate',
              suffix: 'BPM',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: editorState.currentEdit?.feeling.isEmpty ?? true
                  ? 'Good'
                  : editorState.currentEdit?.feeling ?? obs.feeling,
              decoration: const InputDecoration(labelText: 'Feeling'),
              items: ['Excellent', 'Good', 'Fair', 'Poor']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    editorState.updateFeeling(newValue);
                  });
                }
              },
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
                  onPressed: _handleCancelEdit,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await editorState.saveObservation(
                      context,
                      editorService,
                      index,
                    );
                    _loadData();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a consistent row layout for displaying information.
  ///
  /// Creates a two-column layout with a label and value, optionally styling the value
  /// to indicate it is editable.
  ///
  /// @param label The label text to display.
  /// @param value The value text to display.
  /// @param isEditable Whether to style the value as an editable field.
  /// @returns A Widget containing the formatted information row.

  Widget _buildInfoRow(String label, String value, {bool isEditable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              decoration: isEditable ? TextDecoration.underline : null,
              color: isEditable ? Colors.blue : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Gets the list of columns to display in the DataTable based on screen width.
  ///
  /// Implements responsive column visibility:
  /// - Base columns (Timestamp, Systolic, Diastolic) always visible
  /// - Heart Rate visible when width > 600
  /// - Feeling and Notes visible when width > 800
  /// - Actions column always visible
  ///
  /// @param width The current screen width.
  /// @returns A list of DataColumn objects.

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
      columns.add(const DataColumn(label: Text('Feeling')));
      columns.add(const DataColumn(label: Text('Notes')));
    }

    columns.add(const DataColumn(label: Text('Actions')));

    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final error = editorState.error;
    final isLoading = editorState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Observations'),
        backgroundColor: titleBackgroundColor,
        actions: [
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isNarrowScreen = screenWidth < 600;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: isNarrowScreen
                          ? const EdgeInsets.all(12)
                          : const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(isNarrowScreen ? 12 : 8),
                      ),
                      minimumSize: isNarrowScreen ? const Size(46, 46) : null,
                    ),
                    onPressed: _addNewObservation,
                    child: isNarrowScreen
                        ? const Icon(Icons.add_circle)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle),
                              SizedBox(width: 8),
                              Text('Add New Reading'),
                            ],
                          ),
                  );
                },
              ),
            ),
        ],
      ),
      body: (() {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (error != null) {
          return Center(child: Text('Error: $error'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            if (isSmallScreen) {
              return _buildMobileLayout(context);
            } else {
              return _buildDesktopLayout(context, constraints.maxWidth);
            }
          },
        );
      })(),
    );
  }
}
