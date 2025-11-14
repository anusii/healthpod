/// Medication editor page.
///
// Time-stamp: <Tuesday 2025-04-29 15:45:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/features/table/medication_editor/service.dart';
import 'package:healthpod/features/table/medication_editor/state.dart';
import 'package:healthpod/features/table/medication_editor/widgets/desktop_layout.dart';
import 'package:healthpod/features/table/medication_editor/widgets/mobile_layout.dart';

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

  /// Handles deleting a medication observation.

  Future<void> _handleDelete(MedicationObservation obs) async {
    try {
      await editorState.deleteObservation(context, editorService, obs);
    } catch (e) {
      debugPrint('Error in medication deletion UI: $e');
    } finally {
      _loadData();
    }
  }

  /// Handles saving a medication observation.

  Future<void> _handleSave(int index) async {
    await editorState.saveObservation(context, editorService, index);
    _loadData();
  }

  /// Builds the desktop layout for the medication editor.

  Widget _buildDesktopLayout(BuildContext context, double width) {
    return MedicationDesktopLayout(
      editorState: editorState,
      editorService: editorService,
      width: width,
      onEdit: (index) => () => setState(() {
            editorState.enterEditMode(index);
          }),
      onDelete: _handleDelete,
      onCancelEdit: _handleCancelEdit,
      onSave: _handleSave,
    );
  }

  /// Builds the mobile layout for the medication editor.

  Widget _buildMobileLayout(BuildContext context) {
    return MedicationMobileLayout(
      editorState: editorState,
      editorService: editorService,
      onEdit: (index) => () => setState(() {
            editorState.enterEditMode(index);
          }),
      onDelete: _handleDelete,
      onReload: _loadData,
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
        automaticallyImplyLeading: false,
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isNarrowScreen ? 12 : 8,
                        ),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
