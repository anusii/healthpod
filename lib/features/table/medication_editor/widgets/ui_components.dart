/// UI component utilities for medication editor.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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

/// Utility class for building consistent UI components in the medication editor.

class MedicationUIComponents {
  const MedicationUIComponents._();

  /// Builds a customisable text field with consistent styling for dark/light mode.

  static Widget buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: isDarkMode
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : null,
        labelStyle: TextStyle(
          color:
              isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.8) : null,
        ),
        hintStyle: TextStyle(
          color:
              isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.5) : null,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outline : colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// Builds an inline text field with appropriate dark mode styling for table cells.

  static Widget buildInlineTextField(
    BuildContext context,
    TextEditingController controller,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        filled: true,
        fillColor: isDarkMode ? colorScheme.surface : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDarkMode ? colorScheme.outline : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// Builds a consistent row layout for displaying information.

  static Widget buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isEditable = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              decoration: isEditable ? TextDecoration.underline : null,
              color: isEditable
                  ? (isDarkMode ? colorScheme.primaryContainer : Colors.blue)
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
