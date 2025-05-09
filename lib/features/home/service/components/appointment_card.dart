/// Combined appointment card widget.
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/theme/card_style.dart';
import 'package:healthpod/features/diary/service.dart';
import 'package:healthpod/features/diary/models/appointment.dart';

// Global flag to track if transport audio is currently playing.

bool transportAudioIn = false;

/// A widget that displays both next appointment details and appointment summary.
///
/// This component combines the functionality of showing the next appointment
/// details and the total number of upcoming appointments in a single card.

class AppointmentCard extends StatefulWidget {
  const AppointmentCard({super.key});

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  // Flag indicating whether audio is currently playing.

  bool _isPlaying = false;

  // Audio player instance for handling transport eligibility audio.

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Card title displayed at the top of the component.

  String title = 'Medical Appointments';

  // Subtitle shown when displaying next appointment details.

  String subtitle = 'Next Appointment Details';

  // Date and time of the next appointment.

  DateTime appointmentDate = DateTime(2023, 3, 13, 14, 30);

  // Location where the appointment will take place.

  String location = 'Gurriny Yealamucka';

  // Flag indicating if transport assistance is needed.

  bool needsTransport = true;

  // Phone number to call for transport assistance.

  String transportPhone = '(07) 4226 4100';

  // Additional note about transport service availability.

  String transportNote = '(only during office hours)';

  // Flag indicating if clinic bus service is available.

  bool useClinicBus = true;

  // List of all upcoming appointments with their details.

  List<Appointment> appointments = [];

  // Flag indicating if appointments are currently loading.

  bool _isLoading = true;

  /// Toggles the audio playback state.
  ///
  /// Stops playback if currently playing, or starts playback if stopped.
  /// Ensures only one audio instance plays at a time.

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.stop();

      setState(() {
        _isPlaying = false;
        transportAudioIn = false;
      });
    } else {
      if (!transportAudioIn) {
        await _audioPlayer.play(AssetSource('audio/transport_eligibility.mp3'));

        setState(() {
          _isPlaying = !_isPlaying;
          transportAudioIn = true;
        });
      }
    }
  }

  /// Handles the completion of audio playback.
  ///
  /// Resets the playing state and global audio flag when playback finishes.

  void _onAudioComplete() {
    setState(() {
      _isPlaying = false;
      transportAudioIn = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _audioPlayer.onPlayerComplete.listen((event) {
      _onAudioComplete();
    });
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;
    final loadedAppointments = await DiaryService.loadAppointments(context);

    debugPrint('Loaded appointments: $loadedAppointments');

    if (mounted) {
      setState(() {
        // Filter out past appointments and sort by date
        appointments = loadedAppointments
            .where((appointment) => !appointment.isPast)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        debugPrint('Future appointments: $appointments');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    transportAudioIn = false;
    super.dispose();
  }

  /// Opens a dialog to manage all appointments.
  ///
  /// Displays a list of current appointments with options to add, delete,
  /// import, or export appointments.

  void _manageAppointments() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                                '${DateFormat('MMM d, yyyy').format(appointment.date)} at ${DateFormat('h:mm a').format(appointment.date)}\n${appointment.description}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final success =
                                      await DiaryService.deleteAppointment(
                                          context, appointment);
                                  if (success) {
                                    setState(() {
                                      appointments.removeAt(index);
                                    });
                                  }
                                },
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
                        onPressed: () {
                          // Show dialog to add new appointment.

                          _showAddAppointmentDialog(context, setState);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Appointment'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Import button.

                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement import functionality.

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Import feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import'),
                        ),
                        // Export button.

                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement export functionality.

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Export feature coming soon'),
                              ),
                            );
                          },
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      // Update the next appointment if there are any appointments.

                      if (appointments.isNotEmpty) {
                        final nextAppointment = appointments.first;
                        appointmentDate = nextAppointment.date;
                        location = nextAppointment.description;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog to add a new appointment.
  ///
  /// Provides form fields for appointment title, doctor name, location,
  /// date, and time selection.

  void _showAddAppointmentDialog(
      BuildContext context, void Function(void Function()) parentSetState) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Appointment Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Set Date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: const Text('Set Time'),
                      ),
                    ),
                  ],
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
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an appointment title'),
                    ),
                  );
                  return;
                }

                final newAppointment = Appointment(
                  date: selectedDate,
                  title: titleController.text,
                  description: descriptionController.text,
                  isPast: selectedDate.isBefore(DateTime.now()),
                );

                final success =
                    await DiaryService.saveAppointment(context, newAppointment);
                if (success) {
                  parentSetState(() {
                    appointments.add(newAppointment);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              MarkdownTooltip(
                message: '**Manage** your appointments',
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _manageAppointments,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointments.isEmpty
                ? 'No current appointments recorded.'
                : appointments.length == 1
                    ? 'Only one appointment in the future'
                    : '${appointments.length} appointments scheduled',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (appointments.isNotEmpty) ...[
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Date.

            _buildInfoRow(
              'Date:',
              'Monday, ${DateFormat('d MMMM').format(appointments.first.date)}',
            ),
            const SizedBox(height: 8),
            // Time.

            _buildInfoRow(
              'Time:',
              DateFormat('h:mm a').format(appointments.first.date),
            ),
            const SizedBox(height: 8),
            // Description.

            _buildInfoRow('Description:', appointments.first.description),
            const SizedBox(height: 16),
            // Transport.

            if (useClinicBus)
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Transport:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.check, color: Colors.green),
                ],
              ),
            if (needsTransport) ...[
              const SizedBox(height: 16),
              const Text(
                'Need help with transport?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Call $transportPhone ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: transportNote,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const TextSpan(
                            text: ' to change or request transport.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: MarkdownTooltip(
                      message: _isPlaying
                          ? '**Stop** audio'
                          : '**Play** audio explanation',
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.stop : Icons.volume_up,
                          color: _isPlaying ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                        onPressed: _toggleAudio,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Helper method to build consistent information rows.
  ///
  /// Creates a row with a label and value, maintaining consistent styling
  /// and layout across the card.

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
