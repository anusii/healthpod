/// Dialog for managing appointments.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
/// Authors: Zheyuan Xu, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/features/diary/service.dart';
import 'package:healthpod/features/home/service/components/dialogs/add_appointment_dialog.dart';

/// Dialog for managing all appointments with options to add, delete, import,
/// or export.

class AppointmentManagementDialog extends StatefulWidget {
  const AppointmentManagementDialog({
    super.key,
    required this.appointments,
    required this.onAppointmentsUpdated,
  });

  final List<Appointment> appointments;
  final Function(List<Appointment> appointments) onAppointmentsUpdated;

  @override
  State<AppointmentManagementDialog> createState() =>
      _AppointmentManagementDialogState();
}

class _AppointmentManagementDialogState
    extends State<AppointmentManagementDialog> {
  late List<Appointment> appointments;

  @override
  void initState() {
    super.initState();
    appointments = List.from(widget.appointments);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Appointments'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Appointments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(appointment.title),
                      subtitle: Text(
                        '${DateFormat('d MMM yyyy').format(appointment.date)} '
                        'at ${DateFormat('h:mm a').format(appointment.date)}'
                        '\n${appointment.description}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteAppointment(index, appointment),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: _showAddAppointmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Appointment'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _showImportComingSoon,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import'),
                ),
                OutlinedButton.icon(
                  onPressed: _showExportComingSoon,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Deletes an appointment from the list.

  Future<void> _deleteAppointment(int index, Appointment appointment) async {
    final success = await DiaryService.deleteAppointment(context, appointment);
    if (success) {
      setState(() {
        appointments.removeAt(index);
      });
    }
  }

  /// Shows the add appointment dialog.

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddAppointmentDialog(
          onAppointmentAdded: (appointment) {
            setState(() {
              appointments.add(appointment);
            });
          },
        );
      },
    );
  }

  /// Shows a placeholder message for import functionality.

  void _showImportComingSoon() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }

  /// Shows a placeholder message for export functionality.

  void _showExportComingSoon() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  /// Saves changes and updates the parent widget.

  void _saveChanges() {
    widget.onAppointmentsUpdated(appointments);
    Navigator.pop(context);
  }
}
