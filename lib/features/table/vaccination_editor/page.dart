/// Vaccination editor page main entry point.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/table/vaccination_editor/controllers.dart';
import 'package:healthpod/features/table/vaccination_editor/model.dart';
import 'package:healthpod/features/table/vaccination_editor/service.dart';
// Use the mock service for now until we resolve the null safety issues
import 'package:healthpod/features/table/vaccination_editor/service_mock.dart';
import 'package:healthpod/features/table/vaccination_editor/state.dart';

/// The main editor page for vaccination observations.
class VaccinationEditorPage extends StatefulWidget {
  const VaccinationEditorPage({super.key});

  @override
  State<VaccinationEditorPage> createState() => _VaccinationEditorPageState();
}

class _VaccinationEditorPageState extends State<VaccinationEditorPage> {
  late VaccinationEditorState editorState;
  late VaccinationEditorService editorService;

  @override
  void initState() {
    super.initState();

    // Initialise state and service.
    editorState = VaccinationEditorState();
    editorService = VaccinationEditorService();

    // Load initial data.
    _loadData();
  }

  /// Loads vaccination observations from storage.
  Future<void> _loadData() async {
    try {
      setState(() => editorState.isLoading = true);

      // Load observations from storage using the service.
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

  @override
  Widget build(BuildContext context) {
    final error = editorState.error;
    final isLoading = editorState.isLoading;
    final observations = editorState.observations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Records'),
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
                              Text('Add New Vaccination'),
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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Vaccine')),
                DataColumn(label: Text('Provider')),
                DataColumn(label: Text('Professional')),
                DataColumn(label: Text('Cost')),
                DataColumn(label: Text('Notes')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(
                observations.length,
                (index) {
                  final obs = observations[index];

                  if (editorState.editingIndex == index) {
                    // Editing row
                    return DataRow(
                      cells: [
                        DataCell(
                          TextButton(
                            onPressed: () async {
                              final currentDate = obs.timestamp;
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: currentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null && context.mounted) {
                                setState(() {
                                  if (editorState.currentEdit != null) {
                                    editorState.currentEdit =
                                        editorState.currentEdit!.copyWith(
                                      timestamp: pickedDate,
                                    );
                                  }
                                });
                              }
                            },
                            child: Text(
                              '${obs.timestamp.year}-${obs.timestamp.month.toString().padLeft(2, '0')}-${obs.timestamp.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        DataCell(
                          TextField(
                            controller: editorState.vaccineNameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter vaccine name',
                            ),
                          ),
                        ),
                        DataCell(
                          TextField(
                            controller: editorState.providerController,
                            decoration: const InputDecoration(
                              hintText: 'Enter provider',
                            ),
                          ),
                        ),
                        DataCell(
                          TextField(
                            controller: editorState.professionalController,
                            decoration: const InputDecoration(
                              hintText: 'Enter professional',
                            ),
                          ),
                        ),
                        DataCell(
                          TextField(
                            controller: editorState.costController,
                            decoration: const InputDecoration(
                              hintText: 'Enter cost',
                            ),
                          ),
                        ),
                        DataCell(
                          TextField(
                            controller: editorState.notesController,
                            decoration: const InputDecoration(
                              hintText: 'Enter notes',
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
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
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: _handleCancelEdit,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Display row
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        '${obs.timestamp.year}-${obs.timestamp.month.toString().padLeft(2, '0')}-${obs.timestamp.day.toString().padLeft(2, '0')}',
                      )),
                      DataCell(Text(obs.vaccineName)),
                      DataCell(Text(obs.provider)),
                      DataCell(Text(obs.professional)),
                      DataCell(Text(obs.cost)),
                      DataCell(Text(obs.notes)),
                      DataCell(
                        Row(
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
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      })(),
    );
  }
}
