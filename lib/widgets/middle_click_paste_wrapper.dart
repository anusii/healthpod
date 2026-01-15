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

class MiddleClickPasteWrapper extends StatefulWidget {
  /// The child widget (typically a TextFormField or TextField).

  final Widget child;

  /// The TextEditingController associated with the text field.

  final TextEditingController? controller;

  /// The FocusNode associated with the text field.

  final FocusNode? focusNode;

  /// Creates a [MiddleClickPasteWrapper] widget.

  const MiddleClickPasteWrapper({
    super.key,
    required this.child,
    this.controller,
    this.focusNode,
  });

  @override
  State<MiddleClickPasteWrapper> createState() =>
      _MiddleClickPasteWrapperState();
}

class _MiddleClickPasteWrapperState extends State<MiddleClickPasteWrapper> {
  /// Tracks the previous selection to detect selection changes.

  TextSelection? _previousSelection;

  /// Checks if the current platform is Linux desktop (not web).

  static bool get _isLinuxDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  @override
  void initState() {
    super.initState();
    if (_isLinuxDesktop) {
      widget.controller?.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    if (_isLinuxDesktop) {
      widget.controller?.removeListener(_onSelectionChanged);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MiddleClickPasteWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLinuxDesktop && oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onSelectionChanged);
      widget.controller?.addListener(_onSelectionChanged);
    }
  }

  /// Handles selection changes to copy selected text to clipboard.
  ///
  /// This simulates X11 primary selection behaviour where selecting text
  /// automatically copies it to the primary selection buffer.

  void _onSelectionChanged() {
    final controller = widget.controller;
    if (controller == null) return;

    final selection = controller.selection;
    final text = controller.text;

    // Only copy to clipboard when:
    // 1. There is a valid, non-collapsed selection (user has selected text)
    // 2. The selection has changed from the previous state

    if (selection.isValid &&
        !selection.isCollapsed &&
        selection != _previousSelection) {
      final selectedText = text.substring(selection.start, selection.end);
      if (selectedText.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: selectedText));
      }
    }

    _previousSelection = selection;
  }

  /// Handles the middle mouse button click event.
  ///
  /// Pastes clipboard content at the current cursor position without
  /// replacing any selected text.

  Future<void> _handleMiddleClick() async {
    final controller = widget.controller;
    if (controller == null) return;

    // Request focus for the text field.

    widget.focusNode?.requestFocus();

    // Retrieve text from the clipboard.

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final pasteText = clipboardData?.text;

    if (pasteText == null || pasteText.isEmpty) return;

    // Get the current text and selection.

    final currentText = controller.text;
    final selection = controller.selection;

    // Calculate the insertion point at the cursor position.

    final int insertionPoint;

    if (selection.isValid && selection.extentOffset >= 0) {
      insertionPoint = selection.extentOffset;
    } else {
      insertionPoint = currentText.length;
    }

    // Build the new text by inserting paste content at cursor position.

    final newText = currentText.substring(0, insertionPoint) +
        pasteText +
        currentText.substring(insertionPoint);

    // Update the controller with the new text.

    controller.value = TextEditingValue(
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
      return widget.child;
    }

    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // Check if the middle mouse button was pressed.

        if (event.buttons == kMiddleMouseButton) {
          _handleMiddleClick();
        }
      },
      child: widget.child,
    );
  }
}
