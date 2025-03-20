/// Date input widget.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/survey/form_state.dart';
import 'package:healthpod/features/survey/question.dart';

/// A widget for date input in a health survey form.
///
/// This widget provides a date picker for users to select dates.
/// The selected date is stored in the survey form state.

class HealthSurveyDateInput extends StatelessWidget {
  /// The survey question associated with this date input field.

  final HealthSurveyQuestion question;

  /// The index of this input field in the survey form.

  final int index;

  /// The form controller managing survey state.

  final HealthSurveyFormController controller;

  /// Creates an instance of [HealthSurveyDateInput].

  const HealthSurveyDateInput({
    super.key,
    required this.question,
    required this.index,
    required this.controller,
  });

  /// Shows a date picker dialog and updates the form state with the selected date.

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.updateResponse(
        question.fieldName,
        '${picked.year}-${picked.month}-${picked.day}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(question.question),
      subtitle: Text(
        controller.responses[question.fieldName]?.toString() ?? 'Select a date',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () => _selectDate(context),
    );
  }
}
