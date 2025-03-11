/// Utility for showing dialogs with height constraints.
///
// Time-stamp: <Friday 2025-02-21 16:58:42 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

/// This function creates an AlertDialog with a height-constrained content area.

Future<T?> showConstrainedDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required List<Widget> actions,
  double maxHeight = 200,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          child: content,
        ),
        actions: actions,
      );
    },
  );
}

/// Shows a confirmation dialog with constrained height.
///
/// A specialized version for confirmation dialogs with "Cancel" and "Confirm" buttons.

Future<bool> showConstrainedConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color confirmColor = Colors.blue,
  double maxHeight = 100,
}) async {
  final result = await showConstrainedDialog<bool>(
    context: context,
    title: Text(title),
    content: Text(message),
    maxHeight: maxHeight,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(cancelText),
      ),
      TextButton(
        onPressed: () {
          onConfirm();
          Navigator.of(context).pop(true);
        },
        child: Text(
          confirmText,
          style: TextStyle(color: confirmColor),
        ),
      ),
    ],
  );

  return result ?? false;
}
