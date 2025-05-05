/// Medication editor controllers.
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

/// Manages text controllers for medication editor fields.
///
/// This class manages the lifecycle of text controllers for editing medication
/// observations, including initialisation, event handling, and disposal.

class MedicationEditorControllers {
  /// Controller for the medication name field.

  TextEditingController? _nameController;

  /// Controller for the medication dosage field.

  TextEditingController? _dosageController;

  /// Controller for the medication frequency field.

  TextEditingController? _frequencyController;

  /// Controller for any additional notes about the medication.

  TextEditingController? _notesController;

  /// Gets the name controller.

  TextEditingController? get nameController => _nameController;

  /// Gets the dosage controller.

  TextEditingController? get dosageController => _dosageController;

  /// Gets the frequency controller.

  TextEditingController? get frequencyController => _frequencyController;

  /// Gets the notes controller.

  TextEditingController? get notesController => _notesController;

  /// Initialises controllers with values from a medication observation.
  ///
  /// Sets up listeners that update the observation when input values change.
  ///
  /// @param observation The medication observation to use for initial values.
  /// @param onObservationChanged Callback that receives updated observations.

  void initialize(
    MedicationObservation observation, {
    required void Function(MedicationObservation) onObservationChanged,
  }) {
    // Create the controllers with initial values from the observation.

    _nameController = TextEditingController(text: observation.name);
    _dosageController = TextEditingController(text: observation.dosage);
    _frequencyController = TextEditingController(text: observation.frequency);
    _notesController = TextEditingController(text: observation.notes);

    // Listen for changes and update the observation.

    _nameController!.addListener(() {
      onObservationChanged(
        observation.copyWith(
          name: _nameController!.text,
        ),
      );
    });

    _dosageController!.addListener(() {
      onObservationChanged(
        observation.copyWith(
          dosage: _dosageController!.text,
        ),
      );
    });

    _frequencyController!.addListener(() {
      onObservationChanged(
        observation.copyWith(
          frequency: _frequencyController!.text,
        ),
      );
    });

    _notesController!.addListener(() {
      onObservationChanged(
        observation.copyWith(
          notes: _notesController!.text,
        ),
      );
    });
  }

  /// Disposes of all text controllers.
  ///
  /// Should be called when editing is completed or cancelled.

  void dispose() {
    _nameController?.dispose();
    _dosageController?.dispose();
    _frequencyController?.dispose();
    _notesController?.dispose();

    _nameController = null;
    _dosageController = null;
    _frequencyController = null;
    _notesController = null;
  }

  /// Checks if all required fields have values.
  ///
  /// @returns true if all required fields have non-empty values.

  bool hasRequiredValues() {
    return _nameController?.text.isNotEmpty == true &&
        _dosageController?.text.isNotEmpty == true &&
        _frequencyController?.text.isNotEmpty == true;
  }
}
