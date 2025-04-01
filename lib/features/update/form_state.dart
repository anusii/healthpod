/// Form state class for the health survey.
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

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/features/update/question.dart';

/// A controller that manages the state and behavior of a health survey form.
///
/// This class handles focus management, form submission, and response collection
/// for a list of health survey questions.

class HealthSurveyFormController {
  /// List of survey questions in the form.

  final List<HealthSurveyQuestion> questions;

  /// Callback function that is triggered when the form is submitted.

  final void Function(Map<String, dynamic> responses) onSubmit;

  /// Global key to manage the form state.

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Stores the user's responses to the survey questions.

  final Map<String, dynamic> responses = {};

  /// Focus nodes for managing keyboard focus between input fields.

  late final List<List<FocusNode>> focusNodes;

  /// Controller for handling additional notes input.

  final TextEditingController notesController = TextEditingController();

  /// Constructor that initializes the form controller.
  ///
  /// Initialises focus nodes for each question.

  HealthSurveyFormController({
    required this.questions,
    required this.onSubmit,
  }) {
    _initializeFocusNodes();
  }

  /// Initialises focus nodes for each question.
  ///
  /// If a question has categorical options, multiple focus nodes are created.

  void _initializeFocusNodes() {
    focusNodes = List.generate(questions.length, (questionIndex) {
      final question = questions[questionIndex];
      if (question.type == HealthDataType.categorical &&
          question.options != null) {
        return List.generate(question.options!.length, (_) => FocusNode());
      } else {
        return [FocusNode()];
      }
    });
  }

  /// Disposes all allocated resources, such as focus nodes and controllers.

  void dispose() {
    for (var nodeList in focusNodes) {
      for (var node in nodeList) {
        node.dispose();
      }
    }
    notesController.dispose();
  }

  /// Handles field submission and moves focus to the next input field.
  ///
  /// If the current field is categorical and has multiple options, the focus
  /// moves to the next option. Otherwise, it moves to the next question.
  /// If it's the last question, the form is submitted.

  void handleFieldSubmitted(int questionIndex, [int? optionIndex]) {
    final currentQuestion = questions[questionIndex];

    if (currentQuestion.type == HealthDataType.categorical &&
        currentQuestion.options != null) {
      if (optionIndex != null &&
          optionIndex < currentQuestion.options!.length - 1) {
        focusNodes[questionIndex][optionIndex + 1].requestFocus();
        return;
      }
    }

    if (questionIndex < questions.length - 1) {
      final nextQuestion = questions[questionIndex + 1];
      if (nextQuestion.type == HealthDataType.categorical &&
          nextQuestion.options != null) {
        focusNodes[questionIndex + 1][0].requestFocus();
      } else {
        focusNodes[questionIndex + 1][0].requestFocus();
      }
    } else {
      submitForm();
    }
  }

  /// Validates and submits the form.
  ///
  /// If the form is valid, responses are saved and passed to the `onSubmit` callback.

  void submitForm() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      onSubmit(responses);
    }
  }

  /// Updates the user's response for a given field name.

  void updateResponse(String fieldName, dynamic value) {
    responses[fieldName] = value;
  }
}
