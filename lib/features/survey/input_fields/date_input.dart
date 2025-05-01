/// Date input widget.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/survey/form_state.dart';
import 'package:healthpod/features/survey/question.dart';

class HealthSurveyDateInput extends StatefulWidget {
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

  @override
  State<HealthSurveyDateInput> createState() => _HealthSurveyDateInputState();
}

class _HealthSurveyDateInputState extends State<HealthSurveyDateInput> {
  /// Shows a date picker dialog and updates the form state with the selected date.

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Format the date with leading zeros for month and day.

      final formattedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      widget.controller.updateResponse(
        widget.question.fieldName,
        formattedDate,
      );
      // Force rebuild after date selection.

      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    // Use today's date as default if no date is already selected.

    if (widget.controller.responses[widget.question.fieldName] == null) {
      final now = DateTime.now();
      final todayFormatted =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      widget.controller.updateResponse(
        widget.question.fieldName,
        todayFormatted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate =
        widget.controller.responses[widget.question.fieldName]?.toString();
    String formattedDate = 'Not Selected';

    if (selectedDate != null) {
      try {
        final dateParts = selectedDate.split('-');
        if (dateParts.length == 3) {
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          formattedDate = DateFormat('dd MMMM yyyy').format(date);
          formattedDate = 'Selected: $formattedDate';
        }
      } catch (e) {
        debugPrint('Error formatting date: $e');
        formattedDate = selectedDate;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(widget.question.question),
                trailing: Icon(
                  selectedDate != null
                      ? Icons.calendar_today
                      : Icons.calendar_today_outlined,
                  color: selectedDate != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => _selectDate(context),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ' $formattedDate',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
