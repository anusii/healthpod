/// Survey form for health survey questions.
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
import 'package:flutter/services.dart';
import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/question.dart';

/// A widget for rendering a dynamic health survey form.
///
/// The form displays a series of questions with various input types, including
/// text, number, and categorical options. It validates responses and submits
/// them as a map when the form is completed.

class HealthSurveyForm extends StatefulWidget {
  final List<HealthSurveyQuestion> questions;
  final void Function(Map<String, dynamic> responses) onSubmit;
  final String submitButtonText;

  const HealthSurveyForm({
    super.key,
    required this.questions,
    required this.onSubmit,
    this.submitButtonText = 'Submit',
  });

  @override
  State<HealthSurveyForm> createState() => _HealthSurveyFormState();
}

class _HealthSurveyFormState extends State<HealthSurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};

  // Focus nodes for each question, enabling custom tab order traversal.
  //
  // List of lists to support multiple focus points per question if needed.

  List<List<FocusNode>> _focusNodes = [];

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialise focus nodes for all questions and their options.

    _focusNodes = List.generate(widget.questions.length, (questionIndex) {
      final question = widget.questions[questionIndex];
      if (question.type == HealthDataType.categorical &&
          question.options != null) {
        // Create a focus node for each option in categorical questions.

        return List.generate(question.options!.length, (_) => FocusNode());
      } else {
        // Single focus node for non-categorical questions.

        return [FocusNode()];
      }
    });
  }

  @override
  void dispose() {
    // Clean up all focus nodes.

    for (var nodeList in _focusNodes) {
      for (var node in nodeList) {
        node.dispose();
      }
    }
    _notesController.dispose();
    super.dispose();
  }

  /// Controls focus movement between questions in logical order
  /// regardless of their visual layout in columns.

  void _handleFieldSubmitted(int questionIndex, [int? optionIndex]) {
    // Get current question.

    final currentQuestion = widget.questions[questionIndex];

    if (currentQuestion.type == HealthDataType.categorical &&
        currentQuestion.options != null) {
      // For categorical questions.

      if (optionIndex != null) {
        if (optionIndex < currentQuestion.options!.length - 1) {
          // Move to next option within categorical question.

          _focusNodes[questionIndex][optionIndex + 1].requestFocus();
          return;
        }
      }
    }

    // Move to next question if available.

    if (questionIndex < widget.questions.length - 1) {
      final nextQuestion = widget.questions[questionIndex + 1];
      // If next question is categorical, focus its first option.

      if (nextQuestion.type == HealthDataType.categorical &&
          nextQuestion.options != null) {
        _focusNodes[questionIndex + 1][0].requestFocus();
      } else {
        // Focus the input field directly.

        _focusNodes[questionIndex + 1][0].requestFocus();
      }
    } else {
      // If we're at the last question/option, focus the submit button.

      _submitForm();
    }
  }

  /// Builds a text input field for a health survey question.

  Widget _buildTextInput(HealthSurveyQuestion question, int questionIndex) {
    return TextFormField(
      // First/primary focus node for this question.

      focusNode: _focusNodes[questionIndex][0],
      decoration: InputDecoration(
        hintText: 'Enter your response',
        suffixText: question.unit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: (value) {
        if (question.isRequired && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleFieldSubmitted(questionIndex),
      onSaved: (value) {
        _responses[question.fieldName] =
            value; // Ensure we use the health survey field rather than full question as key.
      },
    );
  }

  /// Generates UI for each survey question, including text, number, and categorical options.

  Widget _buildQuestionWidget(HealthSurveyQuestion question, int index) {
    // Define a fixed width for all fields.

    const double fixedWidth = 300.0;

    // Build the UI for the question based on its type.

    if (question.type == HealthDataType.text) {
      return SizedBox(
        width: fixedWidth,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notes, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${index + 1}. ${question.question}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  focusNode: _focusNodes[index][0],
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your notes here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (question.isRequired &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter a value';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleFieldSubmitted(index),
                  onSaved: (value) {
                    _responses[question.fieldName] = value;
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: fixedWidth,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getQuestionIcon(question.type, question.question),
                    size: 20,
                    color: _getIconColor(question.type, question.question),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${index + 1}. ${question.question}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (question.type != HealthDataType.categorical)
                _buildInputField(question, index)
              else
                _buildCategoricalQuestion(question, index),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns an icon based on the question type and content.

  IconData _getQuestionIcon(HealthDataType type, String question) {
    // Return specific icons based on both type and question content.

    if (type == HealthDataType.number) {
      if (question.toLowerCase().contains('blood pressure') ||
          question.toLowerCase().contains('systolic') ||
          question.toLowerCase().contains('diastolic')) {
        // Heart icon for blood pressure.

        return Icons.favorite;
      } else if (question.toLowerCase().contains('heart rate')) {
        // Heart monitor for heart rate.

        return Icons.monitor_heart;
      }
      // Default for other numeric inputs.

      return Icons.numbers;
    }

    if (type == HealthDataType.categorical &&
        question.toLowerCase().contains('feeling')) {
      // Mood icon for feeling questions.

      return Icons.mood;
    }

    return switch (type) {
      HealthDataType.text => Icons.notes,
      HealthDataType.categorical => Icons.checklist,
      _ => Icons.help_outline,
    };
  }

  /// Returns a color based on the question type and content.

  Color _getIconColor(HealthDataType type, String question) {
    if (type == HealthDataType.number) {
      if (question.toLowerCase().contains('blood pressure') ||
          question.toLowerCase().contains('systolic') ||
          question.toLowerCase().contains('diastolic')) {
        // Red for blood pressure.

        return Colors.red.shade400;
      } else if (question.toLowerCase().contains('heart rate')) {
        // Pink for heart rate.

        return Colors.pink.shade400;
      }
      // Blue for other numbers.

      return Colors.blue.shade400;
    }

    if (type == HealthDataType.categorical &&
        question.toLowerCase().contains('feeling')) {
      // Amber for mood/feeling.

      return Colors.amber.shade400;
    }

    return switch (type) {
      // Green for text.

      HealthDataType.text => Colors.green.shade400,

      // Purple for other categorical.

      HealthDataType.categorical => Colors.purple.shade400,

      // Grey as fallback.

      _ => Colors.grey.shade400,
    };
  }

  /// Builds an input field for a health survey question.

  Widget _buildInputField(HealthSurveyQuestion question, int index) {
    return SizedBox(
      width: double.infinity,
      child: Focus(
        descendantsAreFocusable: true,
        child: switch (question.type) {
          HealthDataType.number => _buildNumberInput(question, index),
          HealthDataType.text => _buildTextInput(question, index),
          _ => const SizedBox(),
        },
      ),
    );
  }

  /// Builds a text input field for a health survey question.
  ///
  /// Applies visual styling and validation to number inputs.
  /// Handles range validation and unit display.

  Widget _buildNumberInput(HealthSurveyQuestion question, int questionIndex) {
    return TextFormField(
      focusNode: _focusNodes[questionIndex][0],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter value',
        suffixText: question.unit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return question.isRequired ? 'Please enter a value' : null;
        }
        final number = double.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        if (question.min != null && number < question.min!) {
          return 'Value must be at least ${question.min}';
        }
        if (question.max != null && number > question.max!) {
          return 'Value must not exceed ${question.max}';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        // Directly handle field submission without intermediate steps.

        _handleFieldSubmitted(questionIndex);
      },
      onTapOutside: (event) {
        // Prevent focus loss on tap outside.

        FocusScope.of(context).unfocus();
      },
      onSaved: (value) {
        _responses[question.fieldName] = double.tryParse(value ?? '');
      },
    );
  }

  /// Creates categorical input with radio buttons.
  ///
  /// Maintains logical focus order within options
  /// while providing keyboard navigation support.

  Widget _buildCategoricalQuestion(
      HealthSurveyQuestion question, int questionIndex) {
    return Focus(
      skipTraversal: false,
      descendantsAreTraversable: true,
      child: FormField<String>(
        validator: (value) {
          if (question.isRequired && (value == null || value.isEmpty)) {
            return 'Please select an option';
          }
          return null;
        },
        builder: (FormFieldState<String> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...question.options!.asMap().entries.map(
                (entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Focus(
                      focusNode: _focusNodes[questionIndex][optionIndex],
                      descendantsAreFocusable: false,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          field.didChange(option);
                          _responses[question.fieldName] = option;
                        }
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.tab) {
                            if (HardwareKeyboard.instance.isShiftPressed) {
                              // Handle Shift+Tab (backward navigation).

                              if (optionIndex > 0) {
                                _focusNodes[questionIndex][optionIndex - 1]
                                    .requestFocus();
                              } else if (questionIndex > 0) {
                                _focusNodes[questionIndex - 1][0]
                                    .requestFocus();
                              }
                            } else {
                              // Direct forward navigation.

                              _handleFieldSubmitted(questionIndex, optionIndex);
                            }
                            return KeyEventResult.handled;
                          } else if (event.logicalKey ==
                                  LogicalKeyboardKey.space ||
                              event.logicalKey == LogicalKeyboardKey.enter) {
                            field.didChange(option);
                            _responses[question.fieldName] = option;
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: RadioListTile<String>(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(option),
                        value: option,
                        groupValue: field.value,
                        onChanged: (value) {
                          field.didChange(value);
                          _responses[question.fieldName] = value;
                          // Direct movement to next field.

                          _handleFieldSubmitted(questionIndex, optionIndex);
                        },
                      ),
                    ),
                  );
                },
              ),
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

  /// Submits the form when the submit button is pressed.

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(_responses);
    }
  }

  /// Generates responsive grid layout while maintaining logical tab order.
  ///
  /// Questions are arranged in rows based on available width
  /// but focus traversal follows question index order.

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      descendantsAreFocusable: true,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final optimalCount = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 600
                            ? 2
                            : 1;

                    final rows = <Widget>[];
                    for (var i = 0;
                        i < widget.questions.length;
                        i += optimalCount) {
                      final rowItems = <Widget>[];

                      for (var j = 0;
                          j < optimalCount && i + j < widget.questions.length;
                          j++) {
                        rowItems.add(
                          FocusTraversalOrder(
                            order: NumericFocusOrder(i + j + 1.0),
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: j < optimalCount - 1 ? 16.0 : 0,
                              ),
                              child: _buildQuestionWidget(
                                widget.questions[i + j],
                                i + j,
                              ),
                            ),
                          ),
                        );
                      }

                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rowItems
                                .map((item) => Expanded(child: item))
                                .toList(),
                          ),
                        ),
                      );
                    }

                    return Column(children: rows);
                  },
                ),
                const SizedBox(height: 40),
                Center(
                  child: FocusTraversalOrder(
                    order: NumericFocusOrder(widget.questions.length + 1.0),
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.send),
                        label: Text(widget.submitButtonText),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
