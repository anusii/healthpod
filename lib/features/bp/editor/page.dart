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

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/bp/editor/state.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/bp/obs/widgets/display_row.dart';
import 'package:healthpod/features/bp/obs/widgets/editing_row.dart';

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

  @override
  Widget build(BuildContext context) {
    final error = editorState.error;
    final isLoading = editorState.isLoading;
    final observations = editorState.observations;

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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Systolic')),
                DataColumn(label: Text('Diastolic')),
                DataColumn(label: Text('Heart Rate')),
                DataColumn(label: Text('Feeling')),
                DataColumn(label: Text('Notes')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(
                observations.length,
                (index) {
                  final obs = observations[index];

                  if (editorState.editingIndex == index) {
                    // Build editing row from UI components.

                    return buildEditingRow(
                      context: context,
                      editorState: editorState,
                      editorService: editorService,
                      observation: obs,
                      index: index,
                      onCancel: () => setState(() {
                        editorState.cancelEdit();
                      }),
                      onSave: () async {
                        // Attempt to save observation, then reload data on success.

                        await editorState.saveObservation(
                          context,
                          editorService,
                          index,
                        );
                        _loadData();
                      },
                      // Update timestamp display in real time.

                      onTimestampChanged: (DateTime newTimestamp) {
                        // Wrap the update in setState to rebuild the UI.

                        setState(() {
                          editorState.currentEdit =
                              editorState.currentEdit?.copyWith(
                            timestamp: newTimestamp,
                          );
                        });
                      },
                    );
                  }

                  // Build display row from UI components.

                  return buildDisplayRow(
                    context: context,
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
      })(),
    );
  }
}
