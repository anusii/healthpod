/// Vaccination editor controller management.
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

import 'package:healthpod/features/table/vaccination_editor/model.dart';

/// Manages the TextEditingControllers for the Vaccination Editor.
///
/// This class handles the lifecycle and state of all text controllers used
/// in the vaccination editor, including initialization, updates, and disposal.

class VaccinationEditorControllers {
  /// Text editing controllers for various fields.
  TextEditingController? vaccineNameController;
  TextEditingController? providerController;
  TextEditingController? professionalController;
  TextEditingController? costController;
  TextEditingController? notesController;

  // Store references to our listeners so we can remove them later.
  VoidCallback? _vaccineNameListener;
  VoidCallback? _providerListener;
  VoidCallback? _professionalListener;
  VoidCallback? _costListener;
  VoidCallback? _notesListener;

  /// Keep track of the current observation state.
  VaccinationObservation? _currentState;

  /// Initialize or update controllers with values from an observation.
  void initialize(
    VaccinationObservation observation, {
    required void Function(VaccinationObservation updated) onObservationChanged,
  }) {
    // Set initial state.
    _currentState = observation;
    _onObservationChanged = onObservationChanged;

    // Remove existing listeners before updating.
    _removeListeners();

    // Create new controllers if they don't exist.
    vaccineNameController ??=
        TextEditingController(text: observation.vaccineName);
    providerController ??= TextEditingController(text: observation.provider);
    professionalController ??=
        TextEditingController(text: observation.professional);
    costController ??= TextEditingController(text: observation.cost);
    notesController ??= TextEditingController(text: observation.notes);

    // Update text values if controllers exist.
    vaccineNameController!.text = observation.vaccineName;
    providerController!.text = observation.provider;
    professionalController!.text = observation.professional;
    costController!.text = observation.cost;
    notesController!.text = observation.notes;

    // Add new listeners.
    _addListeners(onObservationChanged);
  }

  /// Callback for changes.
  void Function(VaccinationObservation updated)? _onObservationChanged;

  /// Add listeners to all controllers to update the observation.
  void _addListeners(
    void Function(VaccinationObservation updated) onObservationChanged,
  ) {
    _vaccineNameListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(
        vaccineName: vaccineNameController!.text,
      );
      onObservationChanged(_currentState!);
    };
    vaccineNameController?.addListener(_vaccineNameListener!);

    _providerListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(
        provider: providerController!.text,
      );
      onObservationChanged(_currentState!);
    };
    providerController?.addListener(_providerListener!);

    _professionalListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(
        professional: professionalController!.text,
      );
      onObservationChanged(_currentState!);
    };
    professionalController?.addListener(_professionalListener!);

    _costListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(
        cost: costController!.text,
      );
      onObservationChanged(_currentState!);
    };
    costController?.addListener(_costListener!);

    _notesListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(
        notes: notesController!.text,
      );
      onObservationChanged(_currentState!);
    };
    notesController?.addListener(_notesListener!);
  }

  /// Remove all listeners from controllers.
  void _removeListeners() {
    if (_vaccineNameListener != null) {
      vaccineNameController?.removeListener(_vaccineNameListener!);
      _vaccineNameListener = null;
    }
    if (_providerListener != null) {
      providerController?.removeListener(_providerListener!);
      _providerListener = null;
    }
    if (_professionalListener != null) {
      professionalController?.removeListener(_professionalListener!);
      _professionalListener = null;
    }
    if (_costListener != null) {
      costController?.removeListener(_costListener!);
      _costListener = null;
    }
    if (_notesListener != null) {
      notesController?.removeListener(_notesListener!);
      _notesListener = null;
    }
  }

  /// Check if any required values are missing.
  bool hasRequiredValues() {
    return vaccineNameController?.text.isNotEmpty ?? false;
  }

  /// Dispose of all controllers and clean up.
  void dispose() {
    _removeListeners();
    _onObservationChanged = null;
    vaccineNameController?.dispose();
    providerController?.dispose();
    professionalController?.dispose();
    costController?.dispose();
    notesController?.dispose();

    vaccineNameController = null;
    providerController = null;
    professionalController = null;
    costController = null;
    notesController = null;
    _currentState = null;
  }
}
