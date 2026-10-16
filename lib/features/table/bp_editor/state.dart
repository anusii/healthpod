/// Blood pressure editor state management.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/table/bp_editor/controllers.dart';

/// State management for the Blood Pressure editor.
///
/// This class manages the state of the Blood Pressure editor, including the current
/// observation being edited, text controllers for various fields, and methods for
/// updating and saving observations.

class BPEditorState with ChangeNotifier {
  /// The list of loaded blood pressure observations, sorted by timestamp.

  List<BPObservation> observations = [];

  /// Index of the observation currently being edited, or null if no observation is being edited.

  int? editingIndex;

  /// Whether data is currently being loaded asynchronously.

  bool isLoading = true;

  /// Error message if data loading fails, null if no error.

  String? error;

  /// Flag indicating whether we are creating a new observation (true) or editing an existing one (false).

  bool isNewObservation = false;

  /// Number of saved observations, excluding an unsaved new row being added.

  int get savedObservationCount =>
      observations.length - (isNewObservation ? 1 : 0);

  /// Controller manager for handling text input fields.
  /// Manages the lifecycle of all text controllers used in the editor.

  final controllers = BPEditorControllers();

  /// The systolic blood pressure text controller.
  /// @returns The text controller for the systolic field, or null if not initialised.

  TextEditingController? get systolicController =>
      controllers.systolicController;

  /// The diastolic blood pressure text controller.
  /// @returns The text controller for the diastolic field, or null if not initialised.

  TextEditingController? get diastolicController =>
      controllers.diastolicController;

  /// The heart rate text controller.
  /// @returns The text controller for the heart rate field, or null if not initialised.

  TextEditingController? get heartRateController =>
      controllers.heartRateController;

  /// The notes text controller.
  /// @returns The text controller for the notes field, or null if not initialised.

  TextEditingController? get notesController => controllers.notesController;

  /// The observation currently being edited.

  BPObservation? _currentEdit;

  /// Gets the observation currently being edited.
  /// @returns The current observation being edited, or null if no observation is being edited.

  BPObservation? get currentEdit => _currentEdit;

  /// Initialises text controllers for editing a blood pressure observation.
  ///
  /// Sets up all text controllers with the observation's current values and
  /// configures them to update the observation when their values change.
  ///
  /// @param observation The blood pressure observation to edit.

  void initialiseControllers(BPObservation observation) {
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
    _currentEdit = null;
    notifyListeners();
  }

  /// Enters edit mode for an existing observation.
  ///
  /// Sets up the state for editing the observation at the specified index,
  /// initialises controllers with the observation's values.
  ///
  /// @param index The index of the observation to edit.

  void enterEditMode(int index) {
    // A new reading still being added is abandoned, as Cancel would do.
    // Left in place it would sit in the list as a blank 0/0 row that was
    // never saved, and be counted as one.

    if (isNewObservation && editingIndex != null) {
      observations.removeAt(editingIndex!);
      if (index > editingIndex!) index--;
    }

    editingIndex = index;
    isNewObservation = false;
    currentEdit = observations[index];
    initialiseControllers(currentEdit!);
  }

  /// Changes the timestamp of the observation being edited.

  void updateTimestamp(DateTime timestamp) {
    controllers.updateTimestamp(timestamp);
    currentEdit = currentEdit?.copyWith(timestamp: timestamp);
  }

  /// Leaves edit mode without touching the list, for when the list itself
  /// has just been replaced by a fresh load from the Pod.

  void resetEditing() {
    controllers.dispose();
    editingIndex = null;
    isNewObservation = false;
    _currentEdit = null;
  }

  /// Updates the current edit observation and notifies listeners.
  ///
  /// @param value The new observation value, or null to clear the current edit.

  set currentEdit(BPObservation? value) {
    _currentEdit = value;
    notifyListeners();
  }

  /// Creates a new blank observation and enters edit mode.
  ///
  /// Inserts a new observation at the top of the list with default values
  /// and initialises it for editing.

  void addNewObservation() {
    // Only one new reading at a time: a second press would push the first,
    // still blank, down the list as a 0/0 row.

    if (isNewObservation) return;

    // An edit in progress is abandoned, as Cancel would do.

    if (editingIndex != null) cancelEdit();

    final newObservation = BPObservation(
      timestamp: DateTime.now(),
      systolic: 0,
      diastolic: 0,
      heartRate: 0,
      notes: '',
    );
    observations.insert(0, newObservation);
    editingIndex = 0;
    isNewObservation = true;
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
  /// @returns The saved observation, or null when validation rejected it.

  Future<BPObservation?> saveObservation(
    BuildContext context,
    dynamic editorService,
    int index,
  ) async {
    // Validate required fields.

    if (!controllers.hasRequiredValues()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter values for Systolic, Diastolic, and Heart Rate.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // Build what is saved from the fields on screen, which are also what was
    // just validated. The listeners that keep [currentEdit] in step are a
    // convenience for display; trusting them here allowed a reading to be
    // validated against one set of values and saved with another.

    final values = controllers.getCurrentValues();
    final obs = (currentEdit ?? observations[index]).copyWith(
      systolic: values['systolic'],
      diastolic: values['diastolic'],
      heartRate: values['heartRate'],
      notes: controllers.notesController?.text,
    );

    await editorService.saveObservationToPod(
      context: context,
      observation: obs,
      isNew: isNewObservation,
      oldObservation: !isNewObservation ? observations[index] : null,
    );

    if (!context.mounted) return obs;

    // Show success message.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Blood pressure reading saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );

    // Reset editing state.

    editingIndex = null;
    isNewObservation = false;
    currentEdit = null;
    controllers.dispose();

    return obs;
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
    BPObservation observation,
  ) async {
    await editorService.deleteObservationFromPod(context, observation);
  }
}
