/// Medication editor state management.
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

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/features/table/medication_editor/controllers.dart';

/// State management for the Medication editor.
///
/// This class manages the state of the Medication editor, including the current
/// observation being edited, text controllers for various fields, and methods for
/// updating and saving observations.

class MedicationEditorState with ChangeNotifier {
  /// The list of loaded medication observations, sorted by startDate.
  ///
  List<MedicationObservation> observations = [];

  /// Index of the observation currently being edited, or null if no observation is being edited.

  int? editingIndex;

  /// Whether data is currently being loaded asynchronously.

  bool isLoading = true;

  /// Error message if data loading fails, null if no error.

  String? error;

  /// Flag indicating whether we are creating a new observation (true) or editing an existing one (false).

  bool isNewObservation = false;

  /// The original observation being edited (before changes).
  /// Used for finding the original record to delete when saving edits.

  MedicationObservation? originalObservation;

  /// Controller manager for handling text input fields.
  /// Manages the lifecycle of all text controllers used in the editor.

  final controllers = MedicationEditorControllers();

  /// The medication name text controller.

  TextEditingController? get nameController => controllers.nameController;

  /// The medication dosage text controller.

  TextEditingController? get dosageController => controllers.dosageController;

  /// The medication frequency text controller.

  TextEditingController? get frequencyController =>
      controllers.frequencyController;

  /// The notes text controller.

  TextEditingController? get notesController => controllers.notesController;

  /// The observation currently being edited.

  MedicationObservation? _currentEdit;

  /// Gets the observation currently being edited.

  MedicationObservation? get currentEdit => _currentEdit;

  /// Initialises text controllers for editing a medication observation.
  ///
  /// Sets up all text controllers with the observation's current values and
  /// configures them to update the observation when their values change.
  ///
  /// @param observation The medication observation to edit.
  void initialiseControllers(MedicationObservation observation) {
    controllers.initialize(
      observation,
      onObservationChanged: (updated) {
        currentEdit = updated;
      },
    );
  }

  /// Cancels the current edit operation and resets all editing state.
  ///
  /// Disposes of text controllers, clears the editing index, and resets flags.
  /// Notifies listeners of the state change.

  void cancelEdit() {
    controllers.dispose();
    editingIndex = null;
    isNewObservation = false;
    originalObservation = null;
    _currentEdit = null;
    notifyListeners();
  }

  /// Enters edit mode for an existing observation.
  ///
  /// Sets up the state for editing the observation at the specified index,
  /// initializes controllers with the observation's values.
  ///
  /// @param index The index of the observation to edit.

  void enterEditMode(int index) {
    editingIndex = index;
    isNewObservation = false;
    // Store a copy of the original observation for later reference.

    originalObservation = observations[index];
    currentEdit = observations[index];
    initialiseControllers(currentEdit!);
  }

  /// Updates the current edit observation and notifies listeners.
  ///
  /// @param value The new observation value, or null to clear the current edit.

  set currentEdit(MedicationObservation? value) {
    _currentEdit = value;
    notifyListeners();
  }

  /// Creates a new blank observation and enters edit mode.
  ///
  /// Inserts a new observation at the top of the list with default values
  /// and initialises it for editing.

  void addNewObservation() {
    final newObservation = MedicationObservation(
      name: '',
      dosage: '',
      frequency: '',
      startDate: DateTime.now(),
      notes: '',
    );

    observations.insert(0, newObservation);
    editingIndex = 0;
    isNewObservation = true;
    originalObservation = null;
    currentEdit = newObservation;
    initialiseControllers(newObservation);
  }

  /// Saves the current observation being edited.
  ///
  /// Validates required fields, saves the observation to storage,
  /// and resets the editing state on success.
  ///
  /// @param context The build context for showing feedback.
  /// @param editorService The service for saving observations.
  /// @param index The index of the observation being saved.
  /// @returns A Future that completes when the save operation is done.

  Future<void> saveObservation(
    BuildContext context,
    dynamic editorService,
    int index,
  ) async {
    // Validate required fields.

    if (!controllers.hasRequiredValues()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter values for Name, Dosage, and Frequency.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the observation to save - either the current edit or the one at the specified index.

    final obs = currentEdit ?? observations[index];

    // Create a new observation with the current text field values to ensure we have the latest data.

    final updatedObs = MedicationObservation(
      name: nameController?.text ?? '',
      dosage: dosageController?.text ?? '',
      frequency: frequencyController?.text ?? '',
      startDate: obs.startDate,
      notes: notesController?.text ?? '',
    );

    // If editing an existing record, pass the original observation
    // to help locate and replace the existing file.

    if (!isNewObservation && originalObservation != null) {
      await editorService.saveObservationToPod(
        context,
        updatedObs,
        isEdit: true,
        oldObservation: originalObservation,
      );
    } else {
      await editorService.saveObservationToPod(
        context,
        updatedObs,
      );
    }

    // Clean up edit state.

    controllers.dispose();
    editingIndex = null;
    isNewObservation = false;
    originalObservation = null;
    _currentEdit = null;
  }

  /// Deletes an observation from storage.
  ///
  /// @param context The build context for showing feedback.
  /// @param editorService The service for deleting observations.
  /// @param observation The observation to delete.
  /// @returns A Future that completes when the delete operation is done.

  Future<void> deleteObservation(
    BuildContext context,
    dynamic editorService,
    MedicationObservation observation,
  ) async {
    // Show confirmation dialog.

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text(
          'Are you sure you want to delete this medication record? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    await editorService.deleteObservationFromPod(
      context,
      observation,
    );

    // Remove from local list if it exists.

    final index = observations.indexOf(observation);
    if (index >= 0) {
      observations.removeAt(index);
      notifyListeners();
    }
  }
}
