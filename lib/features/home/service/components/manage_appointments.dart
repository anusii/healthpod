library;

import 'package:flutter/material.dart';
import 'package:healthpod/theme/card_style.dart';
import 'package:intl/intl.dart';

/// A widget to display and manage healthcare appointments.
///
/// This widget allows users to view their upcoming appointments,
/// add new appointments, edit existing ones, and set reminders.

class ManageAppointments extends StatefulWidget {
  const ManageAppointments({super.key});

  @override
  State<ManageAppointments> createState() => _ManageAppointmentsState();
}

class _ManageAppointmentsState extends State<ManageAppointments> {
  // Appointments data
  final List<Appointment> _appointments = [
    Appointment(
      doctorName: 'Dr. Smith',
      specialty: 'Cardiologist',
      location: 'Heart Health Clinic',
      date: DateTime.now().add(const Duration(days: 7)),
      time: const TimeOfDay(hour: 10, minute: 30),
      notes: 'Bring recent test results',
    ),
    Appointment(
      doctorName: 'Dr. Johnson',
      specialty: 'Endocrinologist',
      location: 'Diabetes Care Center',
      date: DateTime.now().add(const Duration(days: 14)),
      time: const TimeOfDay(hour: 14, minute: 15),
      notes: 'Follow-up appointment',
    ),
  ];

  /// Opens dialog to add or edit an appointment
  void _showAppointmentDialog([Appointment? appointment, int? index]) {
    final bool isEditing = appointment != null;
    
    final doctorController = TextEditingController(text: appointment?.doctorName ?? '');
    final specialtyController = TextEditingController(text: appointment?.specialty ?? '');
    final locationController = TextEditingController(text: appointment?.location ?? '');
    final notesController = TextEditingController(text: appointment?.notes ?? '');
    
    TimeOfDay selectedTime = appointment?.time ?? const TimeOfDay(hour: 9, minute: 0);
    DateTime selectedDate = appointment?.date ?? DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${isEditing ? 'Edit' : 'Add'} Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor Name',
                        hintText: 'e.g., Dr. Smith',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specialtyController,
                      decoration: const InputDecoration(
                        labelText: 'Specialty',
                        hintText: 'e.g., Cardiologist',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g., Heart Health Clinic',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Time: '),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Text(
                            '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'e.g., Bring recent test results',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final appointment = Appointment(
                      doctorName: doctorController.text.trim(),
                      specialty: specialtyController.text.trim(),
                      location: locationController.text.trim(),
                      date: selectedDate,
                      time: selectedTime,
                      notes: notesController.text.trim(),
                    );
                    
                    if (appointment.doctorName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Doctor name is required'),
                        ),
                      );
                      return;
                    }
                    
                    this.setState(() {
                      if (isEditing && index != null) {
                        _appointments[index] = appointment;
                      } else {
                        _appointments.add(appointment);
                      }
                      
                      // Sort appointments by date and time
                      _appointments.sort((a, b) {
                        int dateCompare = a.date.compareTo(b.date);
                        if (dateCompare != 0) return dateCompare;
                        
                        return (a.time.hour * 60 + a.time.minute)
                            .compareTo(b.time.hour * 60 + b.time.minute);
                      });
                    });
                    
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Deletes an appointment at the specified index
  void _deleteAppointment(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: Text(
            'Are you sure you want to delete the appointment with ${_appointments[index].doctorName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _appointments.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatAppointmentDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final appointmentDate = DateTime(date.year, date.month, date.day);
    
    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAppointmentDialog(),
                tooltip: 'Add Appointment',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appointments.isEmpty)
            const Center(
              child: Text(
                'No appointments scheduled',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.doctorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(appointment.specialty),
                                  Text(
                                    appointment.location,
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showAppointmentDialog(appointment, index),
                                  tooltip: 'Edit',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => _deleteAppointment(index),
                                  tooltip: 'Delete',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _formatAppointmentDate(appointment.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${appointment.time.hour}:${appointment.time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (appointment.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appointment.notes,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Model class to represent an appointment
class Appointment {
  final String doctorName;
  final String specialty;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final String notes;

  Appointment({
    required this.doctorName,
    required this.specialty,
    required this.location,
    required this.date,
    required this.time,
    required this.notes,
  });
} 