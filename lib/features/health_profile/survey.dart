/// A page for recording the health profile measurements.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/health_profile.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';
import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// A page for recording weight, height, waist and hip measurements.
///
/// Any measurement can be entered on its own. Only what is entered is
/// recorded, so each value carries the date it was actually updated.

class HealthProfileSurvey extends StatelessWidget {
  /// The list of questions for the health profile.

  final List<HealthSurveyQuestion> questions;

  /// Creates a new [HealthProfileSurvey] widget.

  HealthProfileSurvey({super.key})
      : questions = HealthProfileConstants.questions;

  /// Drops the measurements left blank so they are not recorded as values.

  Map<String, dynamic> _measured(Map<String, dynamic> responses) =>
      Map<String, dynamic>.from(responses)
        ..removeWhere((_, value) => value == null);

  /// Saves the measurements to a local file.

  Future<void> _saveResponsesLocally(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    await saveResponseLocally(
      context: context,
      responses: _measured(responses),
      filePrefix: HealthProfileConstants.folder,
      dialogTitle: 'Save Health Profile',
    );
  }

  /// Saves the measurements directly to POD.

  Future<void> _saveResponsesToPod(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    await saveResponseToPod(
      context: context,
      responses: _measured(responses),
      podPath: HealthProfileConstants.folder,
      filePrefix: HealthProfileConstants.folder,
    );
  }

  /// Handles the submission of the measurements.

  Future<void> _handleSubmit(
    BuildContext context,
    Map<String, dynamic> responses,
  ) async {
    // Nothing entered is nothing to record, and saving it would stamp today's
    // date against measurements that have not changed.

    if (_measured(responses).isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nothing to save'),
          content: const Text(
            'Enter at least one measurement before saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;

    await handleSurveySubmit(
      context: context,
      responses: responses,
      saveLocally: _saveResponsesLocally,
      saveToPod: _saveResponsesToPod,
      title: 'Save Health Profile',
      navigateBack: false,
    );
  }

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
