/// Categorical input widget.
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

/// A form input widget for categorical (multiple choice) questions in the health survey.
///
/// This widget creates a list of radio buttons for the user to select from predefined options.
/// It supports both mouse/touch interaction and keyboard navigation, including:
/// * Tab/Shift+Tab navigation between options
/// * Arrow key navigation (Up/Down/Left/Right)
/// * Space/Enter to select an option
/// * Visual feedback for focus and selection states
///
/// The widget maintains its own focus nodes for precise navigation control while
/// integrating with the parent form's overall focus management system.

class HealthSurveyCategoricalInput extends StatefulWidget {
  /// The question data containing options and validation rules.

  final HealthSurveyQuestion question;

  /// The index of this question in the form.

  final int index;

  /// The form controller managing state and focus.

  final HealthSurveyFormController controller;

  const HealthSurveyCategoricalInput({
    super.key,
    required this.question,
    required this.index,
    required this.controller,
  });

  @override
  State<HealthSurveyCategoricalInput> createState() =>
      _HealthSurveyCategoricalInputState();
}

class _HealthSurveyCategoricalInputState
    extends State<HealthSurveyCategoricalInput> {
  /// Tracks the currently selected option.

  String? selectedValue;

  /// Focus nodes for each option to enable keyboard navigation.

  late final List<FocusNode> _optionFocusNodes;

  @override
  void initState() {
    super.initState();
    // Create a focus node for each option in the question.

    _optionFocusNodes = List.generate(
      widget.question.options?.length ?? 0,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    // Clean up focus nodes to prevent memory leaks.

    for (var node in _optionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Moves focus to the next option or next question if at the last option.

  void _handleNextFocus(int currentIndex) {
    if (currentIndex < (_optionFocusNodes.length - 1)) {
      _optionFocusNodes[currentIndex + 1].requestFocus();
    } else {
      // If we're at the last option, move to the next question.

      widget.controller.handleFieldSubmitted(widget.index);
    }
  }

  /// Moves focus to the previous option or previous question if at the first option.

  void _handlePreviousFocus(int currentIndex) {
    if (currentIndex > 0) {
      _optionFocusNodes[currentIndex - 1].requestFocus();
    } else {
      // If we're at the first option, move to the previous question.

      if (widget.index > 0) {
        widget.controller.focusNodes[widget.index - 1][0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in FocusTraversalGroup to manage tab order within the question.

    return FocusTraversalGroup(
      child: FormField<String>(
        initialValue: selectedValue,
        validator: (value) => HealthSurveyValidator.validateCategoricalInput(
            value, widget.question),
        builder: (FormFieldState<String> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Build a radio button for each option.

              ...widget.question.options!.asMap().entries.map(
                (entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  return _buildOption(context, field, option, optionIndex);
                },
              ),
              // Show error message if validation fails.

              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a single radio button option with focus and selection handling.

  Widget _buildOption(BuildContext context, FormFieldState<String> field,
      String option, int optionIndex) {
    final isSelected = field.value == option;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        // Highlight border when option is selected.

        border: Border.all(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: isSelected ? 1 : 0,
        ),
      ),
      child: Focus(
        focusNode: _optionFocusNodes[optionIndex],
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Keep arrow keys for “within” navigation of the radio group.

            if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _handleNextFocus(optionIndex);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _handlePreviousFocus(optionIndex);
              return KeyEventResult.handled;
            }

            // Keep space/enter for selecting an option.

            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _selectOption(field, option, optionIndex);
              return KeyEventResult.handled;
            }
          }
          // Let Flutter handle Tab automatically.

          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectOption(field, option, optionIndex),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Radio<String>(
                    value: option,
                    groupValue: field.value,
                    onChanged: (value) =>
                        _selectOption(field, value!, optionIndex),
                    // Skip the radio button itself in tab order to avoid double-tabbing.

                    focusNode: FocusNode(skipTraversal: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Updates the selected option in both local state and form controller.

  void _selectOption(
      FormFieldState<String> field, String option, int optionIndex) {
    setState(() {
      selectedValue = option;
    });
    field.didChange(option);
    widget.controller.updateResponse(widget.question.fieldName, option);
  }
}
