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

/// A widget for date input in a health survey form.
///
/// This widget provides a date picker for users to select dates.
/// The selected date is stored in the survey form state.

/// A widget to display the selected date with visual feedback.
class SelectedDateDisplay extends StatelessWidget {
  /// The selected date string in YYYY-MM-DD format.

  final String? selectedDate;

  /// Creates a new [SelectedDateDisplay] widget.

  const SelectedDateDisplay({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) return const SizedBox.shrink();

    String formattedDate;
    try {
      final dateParts = selectedDate!.split('-');
      if (dateParts.length == 3) {
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        formattedDate = DateFormat('MMMM dd, yyyy').format(date);
      } else {
        formattedDate = selectedDate!;
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
      formattedDate = selectedDate!;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
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
            'Selected: $formattedDate',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    final selectedDate =
        widget.controller.responses[widget.question.fieldName]?.toString();
    String formattedDate = 'Select a date';

    if (selectedDate != null) {
      try {
        final dateParts = selectedDate.split('-');
        if (dateParts.length == 3) {
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          formattedDate = DateFormat('MMMM dd, yyyy').format(date);
        }
      } catch (e) {
        debugPrint('Error formatting date: $e');
        formattedDate = selectedDate; // Fallback to raw date if parsing fails.
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
                subtitle: Text(
                  formattedDate,
                  style: TextStyle(
                    color: selectedDate != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: selectedDate != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => _selectDate(context),
              ),
              if (selectedDate != null) ...[
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
                        'Selected: ${DateFormat('MMMM dd, yyyy').format(DateTime(
                          int.parse(selectedDate.split('-')[0]),
                          int.parse(selectedDate.split('-')[1]),
                          int.parse(selectedDate.split('-')[2]),
                        ))}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
