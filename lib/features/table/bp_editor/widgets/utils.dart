/// Utility widgets and methods for blood pressure editor.
///
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

/// Utility class containing shared methods for blood pressure editor components.

class BPEditorUtils {
  /// Builds a consistent row layout for displaying information.
  ///
  /// Creates a two-column layout with a label and value, optionally
  /// styling the value to indicate it is editable.
  ///
  /// @param context The build context.
  /// @param label The label text to display.
  /// @param value The value text to display.
  /// @param isEditable Whether to style the value as an editable field.
  /// @returns A Widget containing the formatted information row.

  static Widget buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isEditable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              decoration: isEditable ? TextDecoration.underline : null,
              color: isEditable ? Colors.blue : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a mobile-optimised numeric input field.
  ///
  /// @param controller The text editing controller for the field.
  /// @param label The label text for the field.
  /// @param suffix The suffix text to display (e.g., units).
  /// @returns A Widget containing the configured TextField.

  static Widget buildMobileNumericField({
    required TextEditingController? controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
