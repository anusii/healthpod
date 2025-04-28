/// Next appointment card widget.
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

// Add this global variable if it doesn't exist elsewhere
bool transportAudioIn = false;

/// A widget that displays the next medical appointment details.
///
/// This component shows information about the user's upcoming appointment,
/// including date, time, location, and transportation details.

class NextAppointment extends StatefulWidget {
  const NextAppointment({super.key});

  @override
  State<NextAppointment> createState() => _NextAppointmentState();
}

class _NextAppointmentState extends State<NextAppointment> {
  /// Status of playing of the audio.

  bool _isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Toggles the audio playback state.
  ///
  /// If the audio is currently playing, it stops the playback.
  /// If there is one audio is currently playing, it will not play.
  /// Otherwise, it starts playing the audio from the specified asset source.

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

  void _onAudioComplete() {
    setState(() {
      _isPlaying = false;
      transportAudioIn = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      _onAudioComplete();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    transportAudioIn = false;
    super.dispose();
  }

  // Appointment data
  String title = 'Reminder!';
  String subtitle = 'Next Appointment Details';
  DateTime appointmentDate = DateTime(2023, 3, 13, 14, 30);
  String location = 'Gurriny Yealamucka';
  bool needsTransport = true;
  String transportPhone = '(07) 4226 4100';
  String transportNote = '(only during office hours)';
  bool useClinicBus = true;

  /// Opens a dialog to edit the next appointment details.

  void _editAppointment() {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(appointmentDate));
    final timeController = TextEditingController(
        text: DateFormat('HH:mm').format(appointmentDate));
    final locationController = TextEditingController(text: location);
    final transportPhoneController =
        TextEditingController(text: transportPhone);
    final transportNoteController = TextEditingController(text: transportNote);

    bool tempNeedsTransport = needsTransport;
    bool tempUseClinicBus = useClinicBus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Appointment Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Date field.

                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: appointmentDate,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            dateController.text =
                                DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Time field.

                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time (HH:MM)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(appointmentDate),
                        );
                        if (picked != null) {
                          setState(() {
                            timeController.text =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Location field.

                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Transport section.

                    const Text(
                      'Transportation Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      title: const Text('Need transportation?'),
                      value: tempNeedsTransport,
                      onChanged: (bool value) {
                        setState(() {
                          tempNeedsTransport = value;
                        });
                      },
                    ),
                    if (tempNeedsTransport) ...[
                      SwitchListTile(
                        title: const Text('Use clinic bus?'),
                        value: tempUseClinicBus,
                        onChanged: (bool value) {
                          setState(() {
                            tempUseClinicBus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: transportPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Transport Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: transportNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Transport Note',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
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
                    // Parse date and time.

                    final date =
                        DateFormat('yyyy-MM-dd').parse(dateController.text);
                    final timeStr = timeController.text.split(':');
                    final hour = int.parse(timeStr[0]);
                    final minute = int.parse(timeStr[1]);

                    final newDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      hour,
                      minute,
                    );

                    // Update the appointment details.

                    setState(() {
                      // This setState refers to the parent StatefulBuilder.
                    });

                    Navigator.pop(context);

                    // Update the state in the card widget.

                    this.setState(() {
                      appointmentDate = newDate;
                      location = locationController.text;
                      needsTransport = tempNeedsTransport;
                      useClinicBus = tempUseClinicBus;
                      transportPhone = transportPhoneController.text;
                      transportNote = transportNoteController.text;
                    });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minHeight: 300,
      ),
      padding: const EdgeInsets.only(
          left: 16.0, top: 16.0, right: 24.0, bottom: 16.0),
      decoration: getHomeCardDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.minHeight,
                maxHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                        message: '**Edit** appointment details',
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _editAppointment,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date
                  _buildInfoRow(
                    'Date:',
                    'Monday, ${DateFormat('d MMMM').format(appointmentDate)}',
                  ),
                  const SizedBox(height: 8),
                  // Time
                  _buildInfoRow(
                    'Time:',
                    DateFormat('h:mm a').format(appointmentDate),
                  ),
                  const SizedBox(height: 8),
                  // Location.

                  _buildInfoRow('Where:', location),
                  const SizedBox(height: 16),
                  // Transport.

                  if (useClinicBus)
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Clinic Bus:',
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: transportNote,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper method to build consistent information rows.

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
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
