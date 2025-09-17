/// Creates interactive text with consistent configuration.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Creates an interactive text widget with consistent styling and behavior.
///
/// This function generates a widget that allows for selectable and optionally
/// clickable text. When `isClickable` is true, the text will respond to user
/// taps by executing the provided `onTap` callback. The cursor will also change
/// to indicate interactivity.

Widget createInteractiveText({
  required BuildContext context,
  required String text,
  required VoidCallback onTap,
  required TextStyle style,
  bool isClickable = true,
}) {
  return MouseRegion(
    cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.text,
    child: SelectableText.rich(
      TextSpan(
        text: text,
        style: style,
        recognizer:
            isClickable ? (TapGestureRecognizer()..onTap = onTap) : null,
      ),
    ),
  );
}
