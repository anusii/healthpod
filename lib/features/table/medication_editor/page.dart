/// Medication editor page.
///
// Time-stamp: <Tuesday 2025-04-29 15:45:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/features/table/medication_editor/service.dart';
import 'package:healthpod/features/table/medication_editor/state.dart';

/// A page for viewing and editing medication observations.
///
/// Displays a table of medication entries and provides interfaces for adding,
/// editing, and deleting medication records.

class MedicationEditorPage extends StatefulWidget {
  const MedicationEditorPage({super.key});

  @override
  State<MedicationEditorPage> createState() => _MedicationEditorPageState();
}

class _MedicationEditorPageState extends State<MedicationEditorPage> {
  late MedicationEditorState editorState;
  late MedicationEditorService editorService;

  @override
  void initState() {
    super.initState();

    // Initialise state and service.

    editorState = MedicationEditorState();
    editorService = MedicationEditorService();

    // Load initial data.

    _loadData();
  }

  /// Loads medication data from the POD.

  Future<void> _loadData() async {
    try {
      setState(() => editorState.isLoading = true);

      final observations = await editorService.loadData(context);

      // Sort by startDate descending (newest first).

      observations.sort((a, b) => b.startDate.compareTo(a.startDate));

      setState(() {
        editorState.observations = observations;
        editorState.isLoading = false;
        editorState.error = null;
      });
    } catch (e) {
      setState(() {
        editorState.error = 'Failed to load medication data: $e';
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

  /// Builds the desktop layout for the medication editor.
  ///
  /// Uses a DataTable with responsive columns that adapt based on screen width.

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

              // If this row is being edited, build the editing row.

              if (editorState.editingIndex == index) {
                return _buildEditingDataRow(obs, index);
              }

              // Otherwise show regular display row.

              return _buildDataRow(obs, index);
            },
          ),
        ),
      ),
    );
  }

  /// Builds the mobile layout for the medication editor.
  ///
  /// Creates a scrollable list of cards, each representing a medication observation.
  /// Cards can be expanded to show additional details and include edit/delete actions.

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
                    _buildInfoRow(
                      'Start Date',
                      DateFormat('yyyy-MM-dd').format(obs.startDate),
                    ),
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
                            try {
                              await editorState.deleteObservation(
                                context,
                                editorService,
                                obs,
                              );
                            } catch (e) {
                              // Error handling is done in the service/state layers.
                              // Just log here for debugging.

                              debugPrint('Error in medication deletion UI: $e');
                            } finally {
                              // Always reload data to reflect current state.

                              _loadData();
                            }
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

  /// Builds a mobile edit card for medication.

  Widget _buildMobileEditCard(MedicationObservation observation, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editorState.isNewObservation
                  ? 'Add New Medication'
                  : 'Edit Medication',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: editorState.nameController!,
              label: 'Medication Name *',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: editorState.dosageController!,
              label: 'Dosage *',
              hint: 'e.g., 10mg, 1 tablet',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: editorState.frequencyController!,
              label: 'Frequency *',
              hint: 'e.g., Once daily, Twice daily, As needed',
            ),
            const SizedBox(height: 12),
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
                    editorState.currentEdit = observation.copyWith(
                      startDate: pickedDate,
                    );
                  });
                }
              },
              child: _buildInfoRow(
                'Start Date',
                DateFormat('yyyy-MM-dd').format(observation.startDate),
                isEditable: true,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: editorState.notesController!,
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

  /// Customisable text field with consistent styling for dark/light mode.

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isDarkMode
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : null,
        labelStyle: TextStyle(
          color:
              isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.8) : null,
        ),
        hintStyle: TextStyle(
          color:
              isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.5) : null,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outline : colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// Consistent row layout for displaying information.

  Widget _buildInfoRow(String label, String value, {bool isEditable = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              decoration: isEditable ? TextDecoration.underline : null,
              color: isEditable
                  ? (isDarkMode ? colorScheme.primaryContainer : Colors.blue)
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// Get the list of columns for the DataTable based on screen width.

  List<DataColumn> _getColumns(double width) {
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Dosage')),
    ];

    if (width > 500) {
      columns.add(const DataColumn(label: Text('Frequency')));
    }

    if (width > 700) {
      columns.add(const DataColumn(label: Text('Start Date')));
    }

    if (width > 900) {
      columns.add(const DataColumn(label: Text('Notes')));
    }

    columns.add(const DataColumn(label: Text('Actions')));

    return columns;
  }

  /// Build a standard data row for the table.

  DataRow _buildDataRow(
    MedicationObservation observation,
    int index,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final cells = <DataCell>[];

    // Base cells (always visible).

    cells.add(DataCell(Text(observation.name)));
    cells.add(DataCell(Text(observation.dosage)));

    // Responsive cells.

    final width = MediaQuery.of(context).size.width;

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
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() {
                editorState.enterEditMode(index);
              }),
              tooltip: 'Edit',
              color: Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                try {
                  await editorState.deleteObservation(
                    context,
                    editorService,
                    observation,
                  );
                } catch (e) {
                  // Error handling is done in the service/state layers
                  // Just log here for debugging
                  debugPrint('Error in medication deletion UI: $e');
                } finally {
                  // Always reload data to reflect current state.

                  _loadData();
                }
              },
              tooltip: 'Delete',
              color: Colors.red.shade300,
            ),
          ],
        ),
      ),
    );

    return DataRow(cells: cells);
  }

  /// Build a data row for editing an observation.

  DataRow _buildEditingDataRow(
    MedicationObservation observation,
    int index,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return DataRow(
      color: WidgetStateProperty.all(
        isDarkMode
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.grey.shade200,
      ),
      cells: [
        DataCell(_buildInlineTextField(editorState.nameController!)),
        DataCell(_buildInlineTextField(editorState.dosageController!)),
        if (MediaQuery.of(context).size.width > 500)
          DataCell(_buildInlineTextField(editorState.frequencyController!)),
        if (MediaQuery.of(context).size.width > 700)
          DataCell(
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
                  setState(() {
                    editorState.currentEdit = observation.copyWith(
                      startDate: pickedDate,
                    );
                  });
                }
              },
              child: Text(
                DateFormat('yyyy-MM-dd').format(
                  editorState.currentEdit?.startDate ?? observation.startDate,
                ),
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color:
                      isDarkMode ? colorScheme.primaryContainer : Colors.blue,
                ),
              ),
            ),
          ),
        if (MediaQuery.of(context).size.width > 900)
          DataCell(_buildInlineTextField(editorState.notesController!)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _handleCancelEdit,
                tooltip: 'Cancel',
                color: isDarkMode ? Colors.red.shade300 : Colors.red,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  await editorState.saveObservation(
                    context,
                    editorService,
                    index,
                  );
                  _loadData();
                },
                tooltip: 'Save',
                color: isDarkMode
                    ? colorScheme.primaryContainer
                    : colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build an inline text field with appropriate dark mode styling.

  Widget _buildInlineTextField(TextEditingController controller) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        filled: true,
        fillColor: isDarkMode ? colorScheme.surface : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outline : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = editorState.error;
    final isLoading = editorState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Records'),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                              horizontal: 16,
                              vertical: 16,
                            ),
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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              const Text('Add New Medication'),
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
