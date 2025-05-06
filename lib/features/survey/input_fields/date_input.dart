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
import 'package:healthpod/constants/health_data_type.dart';

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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();

    // Initialize selected date and time from existing response
    final response = widget.controller.responses[widget.question.fieldName];
    if (response != null) {
      try {
        final dateTime = DateTime.parse(response.toString());
        _selectedDate = dateTime;
        _selectedTime = TimeOfDay.fromDateTime(dateTime);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    // Use today's date as default if no date is already selected
    if (_selectedDate == null) {
      _selectedDate = DateTime.now();
      if (widget.question.type == HealthDataType.datetime) {
        _selectedTime = TimeOfDay.now();
      }
      _updateResponse();
    }
  }

  void _updateResponse() {
    if (_selectedDate != null) {
      final DateTime dateTime;
      if (widget.question.type == HealthDataType.datetime &&
          _selectedTime != null) {
        dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      } else {
        dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
      }
      widget.controller.updateResponse(
        widget.question.fieldName,
        dateTime.toIso8601String(),
      );
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate:
          widget.question.allowFutureDate ? DateTime(2100) : DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateResponse();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    if (!widget.question.showTime) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateResponse();
      });
    }
  }

  String _getFormattedDateTime() {
    if (_selectedDate == null) return 'Not Selected';

    String formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate!);
    if (widget.question.type == HealthDataType.datetime &&
        _selectedTime != null) {
      formattedDate += ' at ${_selectedTime!.format(context)}';
    }
    return 'Selected: $formattedDate';
  }

  @override
  Widget build(BuildContext context) {
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedDate != null
                          ? Icons.calendar_today
                          : Icons.calendar_today_outlined,
                      color: _selectedDate != null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    if (widget.question.showTime) ...[
                      const SizedBox(width: 8),
                      Icon(
                        _selectedTime != null
                            ? Icons.access_time
                            : Icons.access_time_outlined,
                        color: _selectedTime != null
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
                onTap: () async {
                  final ctx = context;
                  await _selectDate(ctx);
                  if (widget.question.showTime && ctx.mounted) {
                    await _selectTime(ctx);
                  }
                },
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
                    Expanded(
                      child: Text(
                        _getFormattedDateTime(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
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
