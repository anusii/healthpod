/// Feeling cell for the BP observation editor table.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/features/table/bp_editor/state.dart';

/// List of available feeling options.

const feelings = ['Excellent', 'Good', 'Okay', 'Bad'];

/// Builds a DataCell with a dropdown for selecting the feeling state.
///
/// The [editorState] is used to access the current edit state.
/// The [currentEdit] is used to access the current observation.

DataCell feelingCell(BPEditorState editorState, BPObservation currentEdit) {
  return DataCell(
    AnimatedBuilder(
      animation: editorState,
      builder: (context, child) {
        // Get the latest value from currentEdit.

        final currentFeeling = editorState.currentEdit?.feeling ?? '';

        return DropdownButton<String>(
          value: currentFeeling.isEmpty ? null : currentFeeling,
          hint: const Text('Select feeling'),
          items: feelings.map((String feeling) {
            return DropdownMenuItem<String>(
              value: feeling,
              child: Text(feeling),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue == null) return;

            // Update the state.

            final updatedObservation = currentEdit.copyWith(
              feeling: newValue,
            );

            // Update both the editor state and controller.

            editorState.currentEdit = updatedObservation;
            editorState.controllers.updateFeeling(newValue);
          },
        );
      },
    ),
  );
}
