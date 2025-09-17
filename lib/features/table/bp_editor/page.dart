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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/bp/obs/service.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';
import 'package:healthpod/features/table/bp_editor/widgets/desktop_layout.dart';
import 'package:healthpod/features/table/bp_editor/widgets/mobile_layout.dart';

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
      if (!mounted) return;
      setState(() => editorState.isLoading = true);

      // Load observations from POD using the service.

      final observations = await editorService.loadData(context);

      // Check if widget is still mounted before updating state.

      if (!mounted) return;

      setState(() {
        editorState.observations = observations;
        editorState.observations
            .sort((a, b) => b.timestamp.compareTo(a.timestamp));
        editorState.isLoading = false;
        editorState.error = null;
      });
    } catch (e) {
      // Check if widget is still mounted before updating state.

      if (!mounted) return;

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

  /// Handles saving an observation.

  Future<void> _handleSave(int index) async {
    await editorState.saveObservation(
      context,
      editorService,
      index,
    );
    _loadData();
  }

  /// Handles deleting an observation.

  Future<void> _handleDelete(BPObservation obs, int index) async {
    try {
      await editorState.deleteObservation(
        context,
        editorService,
        obs,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Blood pressure reading deleted successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reading: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reload data to reflect current state.

      _loadData();
    }
  }

  /// Handles timestamp changes during editing.

  void _handleTimestampChanged(DateTime newTimestamp) {
    setState(() {
      editorState.currentEdit = editorState.currentEdit?.copyWith(
        timestamp: newTimestamp,
      );
    });
  }

  /// Builds the desktop layout for the blood pressure editor.

  Widget _buildDesktopLayout(BuildContext context, double width) {
    return BPEditorDesktopLayout(
      editorState: editorState,
      editorService: editorService,
      width: width,
      onEdit: (index) => () => setState(() {
            editorState.enterEditMode(index);
          }),
      onDelete: _handleDelete,
      onCancelEdit: _handleCancelEdit,
      onSave: _handleSave,
      onTimestampChanged: _handleTimestampChanged,
    );
  }

  /// Builds the mobile layout for the blood pressure editor.

  Widget _buildMobileLayout(BuildContext context) {
    return BPEditorMobileLayout(
      editorState: editorState,
      editorService: editorService,
      onEdit: (index) => () => setState(() {
            editorState.enterEditMode(index);
          }),
      onDelete: _handleDelete,
      onCancelEdit: _handleCancelEdit,
      onSave: _handleSave,
      onTimestampChanged: _handleTimestampChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = editorState.error;
    final isLoading = editorState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Observations'),
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
