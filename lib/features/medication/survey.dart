/// Medication survey page.
///
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:healthpod/constants/medication_survey.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// A page for collecting medication survey data.

class MedicationSurvey extends StatelessWidget {
  /// The list of questions for the medication survey.

  final List<HealthSurveyQuestion> questions;

  /// Creates a new [MedicationSurvey] widget.

  MedicationSurvey({super.key})
      : questions = MedicationSurveyConstants.questions;

  /// Saves the survey responses to a local file.

  Future<void> _saveResponsesLocally(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    await saveResponseLocally(
      context: context,
      responses: responses,
      filePrefix: 'medication',
      dialogTitle: 'Save Medication Record',
    );
  }

  /// Saves the survey responses directly to POD.

  Future<void> _saveResponsesToPod(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    await saveResponseToPod(
      context: context,
      responses: responses,
      podPath: 'medication', // Use relative path to match reading operations
      filePrefix: 'medication',
    );
  }

  /// Handles the submission of the survey.

  Future<void> _handleSubmit(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    await handleSurveySubmit(
      context: context,
      responses: responses,
      saveLocally: _saveResponsesLocally,
      saveToPod: _saveResponsesToPod,
      title: 'Save Medication Record',
      navigateBack: false,
    );
  }

  /// Builds the medication survey page.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HealthSurveyForm(
        questions: questions,
        onSubmit: (responses) => _handleSubmit(context, responses),
      ),
    );
  }
}
