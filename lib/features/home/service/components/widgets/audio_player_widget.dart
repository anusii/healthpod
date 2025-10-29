/// Audio player widget for transport eligibility information.
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

import 'package:audioplayers/audioplayers.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

// Global flag to track if transport audio is currently playing.

bool transportAudioIn = false;

/// Widget for playing transport eligibility audio with visual feedback.

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  // Flag indicating whether audio is currently playing.

  bool _isPlaying = false;

  // Audio player instance for handling transport eligibility audio.

  final AudioPlayer _audioPlayer = AudioPlayer();

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
    return SizedBox(
      width: 32,
      height: 32,
      child: MarkdownTooltip(
        message: _isPlaying ? '**Stop** audio' : '**Play** audio explanation',
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
    );
  }

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
    if (mounted) {
      setState(() {
        _isPlaying = false;
        transportAudioIn = false;
      });
    }
  }
}
