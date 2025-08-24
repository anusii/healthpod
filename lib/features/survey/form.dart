/// Form.
//
// Time-stamp: <Thursday 2025-06-26 17:10:33 +1000 Graham Williams>
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

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/survey/form_state.dart';
import 'package:healthpod/features/survey/input_fields/categorical_input.dart';
import 'package:healthpod/features/survey/input_fields/date_input.dart';
import 'package:healthpod/features/survey/input_fields/number_input.dart';
import 'package:healthpod/features/survey/input_fields/text_input.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/features/survey/utils/get_icon_colour.dart';
import 'package:healthpod/features/survey/utils/get_question_icon.dart';

/// A widget that builds and manages a dynamic health survey form.
///
/// This form displays various types of input fields, handles focus management,
/// and submits user responses.

class HealthSurveyForm extends StatefulWidget {
  /// List of survey questions to be displayed in the form.

  final List<HealthSurveyQuestion> questions;

  /// Callback function to handle form submission.

  final void Function(Map<String, dynamic> responses) onSubmit;

  /// Customizable submit button text.

  final String submitButtonText;

  /// Creates a [HealthSurveyForm] widget.

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
  /// Controller to manage form state and input handling.

  late final HealthSurveyFormController _formController;

  @override
  void initState() {
    super.initState();
    _formController = HealthSurveyFormController(
      questions: widget.questions,
      onSubmit: widget.onSubmit,
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  /// Builds a single question widget with its corresponding input field.

  Widget _buildQuestionWidget(HealthSurveyQuestion question, int index) {
    const double fixedWidth = 300.0;

    return SizedBox(
      width: fixedWidth,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionHeader(question, index),
              const SizedBox(height: 12),
              _buildQuestionInput(question, index),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header for each question, including an icon and text.

  Widget _buildQuestionHeader(HealthSurveyQuestion question, int index) {
    return Row(
      children: [
        Icon(
          getQuestionIcon(question.type, question.question),
          size: 20,
          color: getIconColor(question.type, question.question),
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
    );
  }

  /// Builds the appropriate input field for each question based on its type.

  Widget _buildQuestionInput(HealthSurveyQuestion question, int index) {
    return switch (question.type) {
      HealthDataType.text => HealthSurveyTextInput(
          question: question,
          index: index,
          controller: _formController,
        ),
      HealthDataType.number => HealthSurveyNumberInput(
          question: question,
          index: index,
          controller: _formController,
        ),
      HealthDataType.categorical => HealthSurveyCategoricalInput(
          question: question,
          index: index,
          controller: _formController,
        ),
      HealthDataType.date || HealthDataType.datetime => HealthSurveyDateInput(
          question: question,
          index: index,
          controller: _formController,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      descendantsAreFocusable: true,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Form(
          key: _formController.formKey,
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
                      rows.add(_buildQuestionRow(i, optimalCount));
                    }

                    return Column(children: rows);
                  },
                ),
                const SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a row of questions to optimize layout based on screen width.

  Widget _buildQuestionRow(int startIndex, int count) {
    final rowQuestions = widget.questions.skip(startIndex).take(count).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowQuestions
          .map(
            (q) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildQuestionWidget(
                q,
                startIndex + rowQuestions.indexOf(q),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Builds the submit button for the form.

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: _formController.submitForm,
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
    );
  }
}
