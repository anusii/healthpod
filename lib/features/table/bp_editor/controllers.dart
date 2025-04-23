/// Blood pressure editor controller management.
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

/// Manages the TextEditingControllers for the Blood Pressure Editor.
///
/// This class handles the lifecycle and state of all text controllers used
/// in the blood pressure editor, including initialization, updates, and disposal.

/// Blood pressure editor controller management.

class BPEditorControllers {
  /// Text editing controllers for various fields.

  TextEditingController? systolicController;
  TextEditingController? diastolicController;
  TextEditingController? heartRateController;
  TextEditingController? notesController;

  // Store references to our listeners so we can remove them later.

  VoidCallback? _systolicListener;
  VoidCallback? _diastolicListener;
  VoidCallback? _heartRateListener;
  VoidCallback? _notesListener;

  /// Keep track of the current observation state.

  BPObservation? _currentState;

  /// Initialize or update controllers with values from an observation.

  void initialize(
    BPObservation observation, {
    required void Function(BPObservation updated) onObservationChanged,
  }) {
    // Set initial state.

    _currentState = observation;

    // Remove existing listeners before updating.

    _removeListeners();

    // Create new controllers if they don't exist.

    systolicController ??= TextEditingController(
      text: observation.systolic == 0
          ? ''
          : parseNumericInput(observation.systolic),
    );
    diastolicController ??= TextEditingController(
      text: observation.diastolic == 0
          ? ''
          : parseNumericInput(observation.diastolic),
    );
    heartRateController ??= TextEditingController(
      text: observation.heartRate == 0
          ? ''
          : parseNumericInput(observation.heartRate),
    );
    notesController ??= TextEditingController(text: observation.notes);

    // Update text values if controllers exist.

    systolicController!.text = observation.systolic == 0
        ? ''
        : parseNumericInput(observation.systolic);
    diastolicController!.text = observation.diastolic == 0
        ? ''
        : parseNumericInput(observation.diastolic);
    heartRateController!.text = observation.heartRate == 0
        ? ''
        : parseNumericInput(observation.heartRate);
    notesController!.text = observation.notes;

    // Add new listeners.

    _addListeners(onObservationChanged);
  }

  /// Add listeners to all controllers to update the observation.

  void _addListeners(
    void Function(BPObservation updated) onObservationChanged,
  ) {
    _systolicListener = () {
      if (_currentState == null) return;

      final value = systolicController!.text.isEmpty
          ? 0.0
          : (double.tryParse(systolicController!.text) ?? 0.0);
      _currentState = _currentState!.copyWith(systolic: value);
      onObservationChanged(_currentState!);
    };
    systolicController?.addListener(_systolicListener!);

    _diastolicListener = () {
      if (_currentState == null) return;

      final value = diastolicController!.text.isEmpty
          ? 0.0
          : (double.tryParse(diastolicController!.text) ?? 0.0);
      _currentState = _currentState!.copyWith(diastolic: value);
      onObservationChanged(_currentState!);
    };
    diastolicController?.addListener(_diastolicListener!);

    _heartRateListener = () {
      if (_currentState == null) return;

      final value = heartRateController!.text.isEmpty
          ? 0.0
          : (double.tryParse(heartRateController!.text) ?? 0.0);
      _currentState = _currentState!.copyWith(heartRate: value);
      onObservationChanged(_currentState!);
    };
    heartRateController?.addListener(_heartRateListener!);

    _notesListener = () {
      if (_currentState == null) return;

      _currentState = _currentState!.copyWith(notes: notesController!.text);
      onObservationChanged(_currentState!);
    };
    notesController?.addListener(_notesListener!);
  }

  /// Remove all listeners from controllers.

  void _removeListeners() {
    if (_systolicListener != null) {
      systolicController?.removeListener(_systolicListener!);
      _systolicListener = null;
    }
    if (_diastolicListener != null) {
      diastolicController?.removeListener(_diastolicListener!);
      _diastolicListener = null;
    }
    if (_heartRateListener != null) {
      heartRateController?.removeListener(_heartRateListener!);
      _heartRateListener = null;
    }
    if (_notesListener != null) {
      notesController?.removeListener(_notesListener!);
      _notesListener = null;
    }
  }

  /// Get current values from controllers.

  Map<String, double> getCurrentValues() {
    return {
      'systolic': systolicController!.text.isEmpty
          ? 0.0
          : (double.tryParse(systolicController!.text) ?? 0.0),
      'diastolic': diastolicController!.text.isEmpty
          ? 0.0
          : (double.tryParse(diastolicController!.text) ?? 0.0),
      'heartRate': heartRateController!.text.isEmpty
          ? 0.0
          : (double.tryParse(heartRateController!.text) ?? 0.0),
    };
  }

  /// Check if any required values are missing.

  bool hasRequiredValues() {
    final values = getCurrentValues();
    return values['systolic'] != 0 &&
        values['diastolic'] != 0 &&
        values['heartRate'] != 0;
  }

  /// Dispose of all controllers and clean up.

  void dispose() {
    _removeListeners();
    systolicController?.dispose();
    diastolicController?.dispose();
    heartRateController?.dispose();
    notesController?.dispose();

    systolicController = null;
    diastolicController = null;
    heartRateController = null;
    notesController = null;
    _currentState = null;
  }
}
