/// Appointment editor page.
///
// Time-stamp: <Friday 2025-05-07 17:02:01 +1100 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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

import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/features/diary/service.dart';

/// A page that displays and manages appointments in a data table format.
/// Allows users to view, edit, and delete appointments.

class AppointmentEditorPage extends StatefulWidget {
  const AppointmentEditorPage({super.key});

  @override
  State<AppointmentEditorPage> createState() => _AppointmentEditorPageState();
}

class _AppointmentEditorPageState extends State<AppointmentEditorPage> {
  /// List of all appointments loaded from storage.

  List<Appointment> _appointments = [];

  /// Loading state indicator.

  bool _isLoading = true;

  /// Index of the appointment currently being edited, null if not editing.

  int? _editingIndex;

  /// Controllers for the title and description text fields during editing.

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  /// Date being edited, null if not editing.

  DateTime? _editingDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadAppointments();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed.

    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Loads appointments from storage and sorts them by date.

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;
    final appointments = await DiaryService.loadAppointments(context);

    if (mounted) {
      setState(() {
        _appointments = appointments;
        // Sort appointments with most recent first.

        _appointments.sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    }
  }

  /// Initiates editing mode for the specified appointment.

  void _startEditing(int index, Appointment appointment) {
    setState(() {
      _editingIndex = index;
      _titleController.text = appointment.title;
      _descriptionController.text = appointment.description;
      _editingDate = appointment.date;
    });
  }

  /// Cancels editing mode and clears all editing-related fields.

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _titleController.clear();
      _descriptionController.clear();
      _editingDate = null;
    });
  }

  /// Saves the edited appointment and updates storage.
  /// Creates a new appointment with edited values and deletes the original.

  Future<void> _saveEditing(Appointment originalAppointment) async {
    final newAppointment = Appointment(
      date: _editingDate ?? originalAppointment.date,
      title: _titleController.text,
      description: _descriptionController.text,
      isPast:
          (_editingDate ?? originalAppointment.date).isBefore(DateTime.now()),
    );

    if (mounted) {
      final success =
          await DiaryService.saveAppointment(context, newAppointment);
      if (success && mounted) {
        // Delete the old appointment after saving the new one.

        await DiaryService.deleteAppointment(context, originalAppointment);
        _loadAppointments();
      }
    }

    _cancelEditing();
  }

  /// Shows a confirmation dialog and deletes the appointment if confirmed.

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            Text('Are you sure you want to delete "${appointment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await DiaryService.deleteAppointment(context, appointment);
      if (success && mounted) {
        _loadAppointments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _appointments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final appointment = entry.value;
                    final isEditing = _editingIndex == index;

                    // Return an editable row if this appointment is being edited.

                    if (isEditing) {
                      return DataRow(
                        cells: [
                          DataCell(
                            TextButton(
                              onPressed: () async {
                                final ctx = context;
                                // Show date picker dialog.

                                final pickedDate = await showDatePicker(
                                  context: ctx,
                                  initialDate: _editingDate ?? appointment.date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null && ctx.mounted) {
                                  // Show time picker dialog after date is selected.

                                  final pickedTime = await showTimePicker(
                                    context: ctx,
                                    initialTime: TimeOfDay.fromDateTime(
                                        _editingDate ?? appointment.date),
                                  );
                                  if (pickedTime != null && ctx.mounted) {
                                    setState(() {
                                      // Combine picked date and time into a single DateTime.

                                      _editingDate = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              child: Text(
                                DateFormat('dd MMM, yyyy')
                                    .format(_editingDate ?? appointment.date),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('hh:mm a')
                                  .format(_editingDate ?? appointment.date),
                            ),
                          ),
                          DataCell(
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          DataCell(
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          DataCell(
                            Text((_editingDate ?? appointment.date)
                                    .isBefore(DateTime.now())
                                ? 'Past'
                                : 'Upcoming'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Save button.

                                IconButton(
                                  icon: const Icon(Icons.save),
                                  onPressed: () => _saveEditing(appointment),
                                  color: Colors.green,
                                ),
                                // Cancel button.

                                IconButton(
                                  icon: const Icon(Icons.cancel),
                                  onPressed: _cancelEditing,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Return a non-editable row for viewing.

                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('dd MMM, yyyy')
                            .format(appointment.date))),
                        DataCell(Text(
                            DateFormat('hh:mm a').format(appointment.date))),
                        DataCell(Text(appointment.title)),
                        DataCell(Text(appointment.description)),
                        DataCell(
                            Text(appointment.isPast ? 'Past' : 'Upcoming')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit button.

                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _startEditing(index, appointment),
                                color: Colors.blue,
                              ),
                              // Delete button.

                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteAppointment(appointment),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
