/// Number input widget.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
import 'package:flutter/services.dart';

import 'package:healthpod/features/update/form_state.dart';
import 'package:healthpod/features/update/question.dart';
import 'package:healthpod/features/update/utils/validator.dart';

/// A widget for numeric input in a health survey form.
///
/// This widget represents a text field that allows users to input numeric values,
/// optionally with a unit suffix. The input is validated and stored in the survey form state.

class HealthSurveyNumberInput extends StatelessWidget {
  /// The survey question associated with this input field.

  final HealthSurveyQuestion question;

  /// The index of this input field in the form.

  final int index;

  /// The form controller that manages the survey state.

  final HealthSurveyFormController controller;

  /// Creates an instance of [HealthSurveyNumberInput].

  const HealthSurveyNumberInput({
    super.key,
    required this.question,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Sets focus for this input field.

      focusNode: controller.focusNodes[index][0],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter value',
        // Displays unit if applicable.

        suffixText: question.unit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),

      // Validates the input using predefined validation logic.

      validator: (value) =>
          HealthSurveyValidator.validateNumberInput(value, question),

      // Handles field submission event.

      onFieldSubmitted: (_) => controller.handleFieldSubmitted(index),

      // Unfocuses the text field when tapping outside.

      onTapOutside: (event) => FocusScope.of(context).unfocus(),

      // Saves the entered value in the form state.

      onSaved: (value) => controller.updateResponse(
        question.fieldName,
        double.tryParse(value ?? ''),
      ),

      // Restricts input to numeric values (including decimals).

      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
    );
  }
}
