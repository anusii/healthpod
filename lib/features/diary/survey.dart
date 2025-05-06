/// Appointment survey form.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/appointment_survey.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// A page for collecting appointment survey data.
class AppointmentSurvey extends StatelessWidget {
  /// The list of questions for the appointment survey.
  final List<HealthSurveyQuestion> questions;

  /// Creates a new [AppointmentSurvey] widget.
  AppointmentSurvey({super.key})
      : questions = AppointmentSurveyConstants.questions;

  /// Saves the survey responses to a local file.
  Future<void> _saveResponsesLocally(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseLocally(
      context: context,
      responses: responses,
      filePrefix: 'appointment',
      dialogTitle: 'Save Appointment',
    );
  }

  /// Saves the survey responses directly to POD.
  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseToPod(
      context: context,
      responses: responses,
      podPath: '/diary',
      filePrefix: 'appointment',
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
      title: 'Save Appointment',
      navigateBack: false,
    );
  }

  /// Builds the appointment survey page.
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
