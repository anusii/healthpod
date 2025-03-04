/// Vaccination editor state management.
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

import 'package:healthpod/features/table/vaccination_editor/controllers.dart';

/// Manages all the state fields needed for the Vaccination Editor.
///
/// Contains the list of observations, the current observation being edited,
/// and the state of the text editing controllers.
///
/// ChangeNotifier is used to notify listeners of changes to the state.

class VaccinationEditorState with ChangeNotifier {
  /// The list of loaded observations.
  List<VaccinationObservation> observations = [];

  /// Index of the observation currently being edited, or null if none.
  int? editingIndex;

  /// Whether data is currently loading (async).
  bool isLoading = true;

  /// Error message if data loading fails.
  String? error;

  /// Flag tracking whether we are creating a new observation.
  bool isNewObservation = false;

  /// Controller manager for text editing.
  final controllers = VaccinationEditorControllers();

  /// Getter for controllers.
  TextEditingController? get vaccineNameController =>
      controllers.vaccineNameController;
  TextEditingController? get providerController =>
      controllers.providerController;
  TextEditingController? get professionalController =>
      controllers.professionalController;
  TextEditingController? get costController => controllers.costController;
  TextEditingController? get notesController => controllers.notesController;

  /// The observation currently being edited.
  VaccinationObservation? _currentEdit;

  /// Getter for currentEdit.
  VaccinationObservation? get currentEdit => _currentEdit;

  /// Prepares text controllers for a given [observation].
  void initialiseControllers(VaccinationObservation observation) {
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
  set currentEdit(VaccinationObservation? value) {
    _currentEdit = value;
    notifyListeners();
  }

  /// Add new blank observation at the top of the list and go to edit mode.
  void addNewObservation() {
    final newObservation = VaccinationObservation(
      timestamp: DateTime.now(),
      vaccineName: '',
      provider: '',
      professional: '',
      cost: '',
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
            'Please enter a vaccine name',
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

    if (!context.mounted) return;

    // Show success message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vaccination record saved successfully'),
        backgroundColor: Colors.green,
      ),
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
    VaccinationObservation observation,
  ) async {
    await editorService.deleteObservationFromPod(context, observation);
  }
}
