/// The heading row widgets shared by the tabs of the Data page.
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

/// A small pill-shaped badge showing how many records a tab holds, such as
/// "1 observation" or "5 observations".
///
/// Intended for an [AppBar]'s actions. It carries its own trailing gap so that
/// it sits clear of whatever follows it.

class RecordCountBadge extends StatelessWidget {
  const RecordCountBadge({
    super.key,
    required this.count,
    required this.singular,
    required this.plural,
  });

  /// The number of records to show.

  final int count;

  /// The unit used when [count] is exactly one.

  final String singular;

  /// The unit used for any other [count].

  final String plural;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: ShapeDecoration(
            color: colorScheme.secondaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Text(
            '$count ${count == 1 ? singular : plural}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
          ),
        ),
      ),
    );
  }
}

/// The "Add New ..." button at the right of a Data tab's heading row.
///
/// On narrow screens it collapses to an icon so the heading still fits.

class AddRecordButton extends StatelessWidget {
  const AddRecordButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// The button text, such as "Add New Reading".

  final String label;

  /// Called when the button is pressed.

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNarrowScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: isNarrowScreen
              ? const EdgeInsets.all(12)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isNarrowScreen ? 12 : 8),
          ),
          minimumSize: isNarrowScreen ? const Size(46, 46) : null,
        ),
        onPressed: onPressed,
        child: isNarrowScreen
            ? Tooltip(message: label, child: const Icon(Icons.add_circle))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
