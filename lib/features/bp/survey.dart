/// BP survey page.
//
// Time-stamp: <Monday 2025-01-20 16:54:30 +1100 Graham Williams>
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

import 'package:healthpod/constants/blood_pressure_survey.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// A page for collecting blood pressure survey data.

class BPSurvey extends StatelessWidget {
  // Define questions using centralised Health Survey constants.

  final List<HealthSurveyQuestion> questions = HealthSurveyConstants.questions;

  BPSurvey({super.key});

  /// Saves the survey responses to a local file.

  Future<void> _saveResponsesLocally(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseLocally(
      context: context,
      responses: responses,
      filePrefix: 'blood_pressure',
      dialogTitle: 'Save Blood Pressure Survey',
    );
  }

  /// Saves the survey responses directly to POD.

  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseToPod(
      context: context,
      responses: responses,
      podPath: '/blood_pressure',
      filePrefix: 'blood_pressure',
    );
  }

  /// Handles the submission of the survey.

  Future<void> _handleSubmit(
      BuildContext context, Map<String, dynamic> responses) async {
    await handleSurveySubmit(
      context: context,
      responses: responses,
      saveLocally: _saveResponsesLocally,
      saveToPod: _saveResponsesToPod,
      title: 'Save Blood Pressure Survey',
      navigateBack: false,
    );
  }

  /// Builds the health survey page.

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
