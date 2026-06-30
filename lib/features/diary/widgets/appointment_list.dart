/// Appointment list (busy / month / day) for the appointments calendar.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import 'appointment_details_dialog.dart';

/// The list below the calendar. Shows a busy indicator while [loading]; then,
/// when [items] is filtered to a day (see [filtering]), that day's
/// appointments, otherwise every appointment in the month.

class AppointmentList extends StatelessWidget {
  const AppointmentList({
    super.key,
    required this.loading,
    required this.filtering,
    required this.monthName,
    required this.selectedDay,
    required this.items,
    required this.onShowMonth,
    required this.onDelete,
    required this.onEdit,
  });

  final bool loading;
  final bool filtering;
  final String monthName;
  final DateTime? selectedDay;
  final List<Appointment> items;
  final VoidCallback onShowMonth;
  final ValueChanged<Appointment> onDelete;
  final ValueChanged<Appointment> onEdit;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading appointments…'),
          ],
        ),
      );
    }

    final heading = filtering && selectedDay != null
        ? 'Appointments on ${DateFormat('d MMM').format(selectedDay!)}'
        : 'Appointments in $monthName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (filtering)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Show month'),
                  onPressed: onShowMonth,
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    filtering
                        ? 'No appointments on this day.'
                        : 'No appointments in $monthName.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final appointment = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(appointment.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'd MMM, h:mm a',
                              ).format(appointment.date),
                            ),
                            if (appointment.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: MarkdownBody(
                                  data: appointment.description,
                                  shrinkWrap: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: appointment.description.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Editing the note/description is allowed for any
                            // appointment, including past ones.
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () => onEdit(appointment),
                            ),
                            if (!appointment.isPast)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () => onDelete(appointment),
                              ),
                          ],
                        ),
                        onTap: () =>
                            showAppointmentDetails(context, appointment),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
