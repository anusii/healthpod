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

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/utils/parse_numeric_input.dart';

/// Manages all the state fields needed for the Blood Pressure Editor.

class BPEditorState {
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

  /// The observation currently being edited.

  BPObservation? currentEdit;

  /// Text editing controllers used for editing existing or new observations.

  TextEditingController? systolicController;
  TextEditingController? diastolicController;
  TextEditingController? heartRateController;
  TextEditingController? notesController;

  /// Prepares text controllers for a given [observation].

  void initialiseControllers(BPObservation observation) {
    disposeControllers();
    systolicController = TextEditingController(
      text: observation.systolic == 0
          ? ''
          : parseNumericInput(observation.systolic),
    );
    diastolicController = TextEditingController(
      text: observation.diastolic == 0
          ? ''
          : parseNumericInput(observation.diastolic),
    );
    heartRateController = TextEditingController(
      text: observation.heartRate == 0
          ? ''
          : parseNumericInput(observation.heartRate),
    );
    notesController = TextEditingController(text: observation.notes);
  }

  /// Dispose of text controllers to prevent memory leaks.

  void disposeControllers() {
    systolicController?.dispose();
    diastolicController?.dispose();
    heartRateController?.dispose();
    notesController?.dispose();
  }

  /// Resets editing fields and cancels the current edit.

  void cancelEdit() {
    editingIndex = null;
    isNewObservation = false;
    currentEdit = null;
    disposeControllers();
  }

  /// Enters edit mode for the observation at [index].

  void enterEditMode(int index) {
    editingIndex = index;
    isNewObservation = false;
    currentEdit = observations[index];
    initialiseControllers(currentEdit!);
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
  ///
  /// Note: The actual encryption/Pod writing is performed by the [editorService].

  Future<void> saveObservation(
    BuildContext context,
    dynamic editorService,
    int index,
  ) async {
    // Validate required fields.

    final obs = currentEdit ?? observations[index];

    if (obs.systolic == 0 || obs.diastolic == 0 || obs.heartRate == 0) {
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
