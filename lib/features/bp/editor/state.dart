/// Blood pressure editor state management.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';
import 'package:healthpod/features/bp/editor/controllers.dart';

import 'package:healthpod/features/bp/obs/model.dart';

/// Manages all the state fields needed for the Blood Pressure Editor.
///
/// Contains the list of observations, the current observation being edited,
/// and the state of the text editing controllers.
///
/// ChangeNotifier is used to notify listeners of changes to the state.

class BPEditorState with ChangeNotifier {
  /// The list of loaded observations.

  List<BPObservation> observations = [];

  /// Index of the observation currently being edited, or null if none.

  int? editingIndex;

  /// Whether data is currently loading (async).

  bool isLoading = true;

  /// Error message if data loading fails.

  String? error;

  /// Flag tracking whether we are creating a new observation.

  bool isNewObservation = false;

  /// Controller manager for text editing.

  final controllers = BPEditorControllers();

  /// Getter for controllers.

  TextEditingController? get systolicController =>
      controllers.systolicController;
  TextEditingController? get diastolicController =>
      controllers.diastolicController;
  TextEditingController? get heartRateController =>
      controllers.heartRateController;
  TextEditingController? get notesController => controllers.notesController;

  /// The observation currently being edited.

  BPObservation? _currentEdit;

  /// Getter for currentEdit.

  BPObservation? get currentEdit => _currentEdit;

  /// Prepares text controllers for a given [observation].

  void initialiseControllers(BPObservation observation) {
    controllers.initialize(
      observation,
      onObservationChanged: (updated) {
        currentEdit = updated;
      },
    );
  }

  /// Resets editing fields and cancels the current edit.

  void cancelEdit() {
    controllers.dispose();
    editingIndex = null;
    isNewObservation = false;
    _currentEdit = null;
    notifyListeners();
  }

  /// Enters edit mode for the observation at [index].

  void enterEditMode(int index) {
    editingIndex = index;
    isNewObservation = false;
    currentEdit = observations[index];
    initialiseControllers(currentEdit!);
  }

  /// Setter for currentEdit that triggers UI updates.

  set currentEdit(BPObservation? value) {
    _currentEdit = value;
    notifyListeners();
  }

  /// Add new blank observation at the top of the list and go to edit mode.

  void addNewObservation() {
    final newObservation = BPObservation(
      timestamp: DateTime.now(),
      systolic: 0,
      diastolic: 0,
      heartRate: 0,
      feeling: '',
      notes: '',
    );
    observations.insert(0, newObservation);
    editingIndex = 0;
    isNewObservation = true;
    currentEdit = newObservation;
    initialiseControllers(newObservation);
  }

  /// Save the observation at [index], using the provided service.

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
            'Please enter values for Systolic, Diastolic, and Heart Rate',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final obs = currentEdit ?? observations[index];

    await editorService.saveObservationToPod(
      context: context,
      observation: obs,
      isNew: isNewObservation,
      oldObservation: !isNewObservation ? observations[index] : null,
    );

    // Reset editing state.

    editingIndex = null;
    isNewObservation = false;
    currentEdit = null;
    controllers.dispose();
  }

  /// Delete an observation from the Pod via the [editorService].

  Future<void> deleteObservation(
    BuildContext context,
    dynamic editorService,
    BPObservation observation,
  ) async {
    await editorService.deleteObservationFromPod(context, observation);
  }
}
