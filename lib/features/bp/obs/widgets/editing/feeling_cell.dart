/// Feeling cell widget.
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

import 'package:healthpod/features/bp/editor/state.dart';
import 'package:healthpod/features/bp/obs/model.dart';

/// Builds a [DataCell] with a dropdown to edit the "feeling" field.

DataCell feelingCell(BPEditorState editorState, BPObservation currentEdit) {
  return DataCell(
    DropdownButton<String>(
      value: currentEdit.feeling.isEmpty ? null : currentEdit.feeling,
      items: ['Excellent', 'Good', 'Fair', 'Poor']
          .map((feeling) => DropdownMenuItem(
                value: feeling,
                child: Text(feeling),
              ))
          .toList(),
      onChanged: (value) {
        editorState.currentEdit = currentEdit.copyWith(feeling: value ?? '');
      },
    ),
  );
}
