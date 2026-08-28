/// Snackbars reporting the outcome of removing a record from the pod.
//
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

import 'package:flutter/material.dart';

/// Reports a record having been removed from the pod.
///
/// Green for a delete that worked, red for one that did not, so that the
/// outcome reads the same way whichever tab the user is on.

void showDeleteSuccess(BuildContext context, String message) =>
    _showResult(context, message, Colors.green);

/// Reports a delete that did not happen, [message] saying why.

void showDeleteFailure(BuildContext context, String message) =>
    _showResult(context, message, Colors.red);

/// Shows [message] in a snackbar coloured by the outcome.
///
/// The text colour is set alongside the background rather than left to the
/// theme, which would otherwise pick a colour meant for the theme's own
/// snackbar background.

void _showResult(BuildContext context, String message, Color background) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: background,
    ),
  );
}
