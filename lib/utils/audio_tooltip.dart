/// A widget displaying audio icon with a tooltip.
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

import 'package:healthpod/constants/colours.dart';

/// The widget creates an icon that represents a audio and provides a tooltip
/// when the icon is long-pressed. The tooltip message is customizable through
/// the [title] parameter, which allows for dynamic content. The tooltip message
/// is prefixed with "Coming soon: a audio by Gurriny staff explaining", followed
/// by the provided [title].

class AudioWithTooltip extends StatelessWidget {
  /// The status if whether the audio is playing.

  final bool isPlaying;

  /// Function of clicking the icon.

  final Future<void> Function() toggleAudio;

  /// Constructs a `AudioWithTooltip` widget.

  const AudioWithTooltip(
      {super.key, required this.isPlaying, required this.toggleAudio});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Click here to understand more',
      showDuration: Duration(seconds: 2),
      child: IconButton(
        icon: Icon(
          Icons.audiotrack_rounded,
          color: isPlaying ? anuGold : iconGreen,
        ),
        onPressed: toggleAudio,
      ),
    );
  }
}
