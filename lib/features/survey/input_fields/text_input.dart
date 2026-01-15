/// Text input widget.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/survey/form_state.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/features/survey/utils/validator.dart';
import 'package:healthpod/widgets/middle_click_paste_wrapper.dart';

/// A widget for text input in a health survey form.
///
/// This widget provides a multi-line text field for users to input responses.
/// The input is validated and stored in the survey form state.

class HealthSurveyTextInput extends StatefulWidget {
  /// The survey question associated with this text input field.

  final HealthSurveyQuestion question;

  /// The index of this input field in the survey form.

  final int index;

  /// The form controller managing survey state.

  final HealthSurveyFormController controller;

  /// Creates an instance of [HealthSurveyTextInput].

  const HealthSurveyTextInput({
    super.key,
    required this.question,
    required this.index,
    required this.controller,
  });

  @override
  State<HealthSurveyTextInput> createState() => _HealthSurveyTextInputState();
}

class _HealthSurveyTextInputState extends State<HealthSurveyTextInput> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MiddleClickPasteWrapper(
      controller: _textController,
      focusNode: widget.controller.focusNodes[widget.index][0],
      child: TextFormField(
        // Use the local text controller for middle-click paste support.

        controller: _textController,

        // Sets focus for this input field.

        focusNode: widget.controller.focusNodes[widget.index][0],

        // Allows multiple lines for longer text input.

        maxLines: null,
        minLines: 3,

        style: theme.textTheme.bodyLarge,

        decoration: InputDecoration(
          hintText: 'Enter your response',

          // Displays unit if applicable.

          suffixText: widget.question.unit,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.all(12),
        ),

        // Validates the text input using predefined validation logic.

        validator: (value) =>
            HealthSurveyValidator.validateTextInput(value, widget.question),

        // Handles field submission event.

        onFieldSubmitted: (_) =>
            widget.controller.handleFieldSubmitted(widget.index),

        // Saves the entered text response in the form state.

        onSaved: (value) =>
            widget.controller.updateResponse(widget.question.fieldName, value),
      ),
    );
  }
}
