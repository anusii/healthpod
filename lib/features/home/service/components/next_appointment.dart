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

import 'package:healthpod/constants/appointment.dart';
import 'package:healthpod/features/home/service/home_utils.dart';
import 'package:healthpod/theme/card_style.dart';
import 'package:healthpod/utils/address_link.dart';
import 'package:healthpod/utils/audio_tooltip.dart';
import 'package:healthpod/utils/call_icon.dart';
import 'package:healthpod/utils/touch_finger_oval.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(16.0),
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
                  const Text(
                    'Reminder!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Next Appointment Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date.

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          appointmentDate,
                          // Ensure the text is wrapped to the next line if it's too long.

                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Time.

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          appointmentTime,
                          // Ensure the text is wrapped to the next line if it's too long.

                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location.

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Where: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SelectableText.rich(
                          addressLink(appointmentLocation, context,
                              fontSize: 14),
                          maxLines: 2,
                          style: const TextStyle(height: 1.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Clinic bus info.

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            text: 'Clinic Bus: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      touchFingerOval(
                        'Call the Clinic reception for more\ninformation about transport services.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transport help section.

                  Row(
                    children: [
                      const Expanded(
                        child: SelectableText.rich(
                          TextSpan(
                            text: 'Need help with transport?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      AudioWithTooltip(
                        isPlaying: _isPlaying,
                        toggleAudio: _toggleAudio,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Phone number and info.

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CallIcon(contactNumber: phoneNumber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style.copyWith(
                                  fontSize: 13,
                                ),
                            children: [
                              TextSpan(
                                text: 'Call $phoneNumber ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: '(only during office hours) ',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              const TextSpan(
                                text: 'to change or request transport.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
