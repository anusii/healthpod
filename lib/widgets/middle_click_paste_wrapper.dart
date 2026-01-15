/// Middle-click paste wrapper widget for Linux X11 primary selection support.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Tony Chen

library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:universal_io/io.dart' show Platform;

/// A wrapper widget that provides middle-click paste functionality on Linux.
///
/// On Linux systems with X11, users commonly use middle-click to paste from
/// the primary selection clipboard. This wrapper intercepts middle mouse button
/// events and pastes clipboard content into the associated text field.
///
/// The wrapper only activates on Linux desktop platforms; on other platforms,
/// it simply renders the child widget without modification.

class MiddleClickPasteWrapper extends StatelessWidget {
  /// The child widget (typically a TextFormField or TextField).

  final Widget child;

  /// The TextEditingController associated with the text field.
  ///
  /// Required to insert pasted text at the current cursor position.

  final TextEditingController? controller;

  /// The FocusNode associated with the text field.
  ///
  /// Used to request focus before pasting and determine cursor position.

  final FocusNode? focusNode;

  /// Creates a [MiddleClickPasteWrapper] widget.

  const MiddleClickPasteWrapper({
    super.key,
    required this.child,
    this.controller,
    this.focusNode,
  });

  /// Checks if the current platform is Linux desktop (not web).

  static bool get _isLinuxDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Handles the middle mouse button click event.
  ///
  /// When a middle-click is detected on Linux, this method:
  /// 1. Requests focus for the text field
  /// 2. Retrieves text from the system clipboard
  /// 3. Inserts the text at the current cursor position

  Future<void> _handleMiddleClick(BuildContext context) async {
    if (controller == null) return;

    // Request focus for the text field.

    focusNode?.requestFocus();

    // Retrieve text from the clipboard.

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final pasteText = clipboardData?.text;

    if (pasteText == null || pasteText.isEmpty) return;

    // Get the current text and selection.

    final currentText = controller!.text;
    final selection = controller!.selection;

    // Calculate the insertion point.
    // If there's a valid selection, use it; otherwise, append to the end.

    final int insertionPoint;
    final int replacementEnd;

    if (selection.isValid && selection.baseOffset >= 0) {
      insertionPoint = selection.baseOffset;
      replacementEnd = selection.extentOffset;
    } else {
      insertionPoint = currentText.length;
      replacementEnd = currentText.length;
    }

    // Build the new text with the pasted content.

    final newText = currentText.substring(0, insertionPoint) +
        pasteText +
        currentText.substring(replacementEnd);

    // Update the controller with the new text.

    controller!.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: insertionPoint + pasteText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap with Listener on Linux desktop platforms.

    if (!_isLinuxDesktop) {
      return child;
    }

    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // Check if the middle mouse button was pressed.

        if (event.buttons == kMiddleMouseButton) {
          _handleMiddleClick(context);
        }
      },
      child: child,
    );
  }
}
