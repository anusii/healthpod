/// The row action buttons used by every tab of the Data page.
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

import 'package:healthpod/theme/app_colors.dart';

/// The spacing between the action buttons of a row.

const double actionButtonSpacing = 8.0;

/// A solid, coloured icon button for one of the actions on a record.
///
/// Every tab of the Data page acts on its records in the same few ways, so the
/// buttons are built here rather than in each tab, keeping the colour, size
/// and shape of an action the same wherever the user meets it. The colour
/// carries the meaning: the app's own blue for editing, red for removing,
/// green for saving and grey for backing out.

class ActionButton extends StatelessWidget {
  /// The icon naming the action.

  final IconData icon;

  /// What the button does, said in full for the tooltip.
  ///
  /// Null where the button already sits inside a tooltip of its own.

  final String? tooltip;

  /// The solid colour the button is filled with.

  final Color colour;

  /// Called when the button is tapped. A null callback disables the button.

  final VoidCallback? onPressed;

  const ActionButton({
    required this.icon,
    required this.tooltip,
    required this.colour,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: colour,

        // White throughout, since each of the fills is dark enough to carry
        // it in either theme.

        foregroundColor: Colors.white,
        disabledBackgroundColor: colour.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

/// Opens a record for editing.

class EditButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Names what is being edited, e.g. 'reading', for the tooltip.

  final String record;

  /// Whether the button carries its own tooltip. Set false where the caller
  /// wraps the button in a tooltip of its own.

  final bool showTooltip;

  const EditButton({
    required this.onPressed,
    this.record = 'record',
    this.showTooltip = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: Icons.edit,
      tooltip: showTooltip ? 'Edit this $record' : null,
      colour: Theme.of(context).colorScheme.primary,
      onPressed: onPressed,
    );
  }
}

/// Removes a record from the pod.

class DeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Names what is being deleted, e.g. 'reading', for the tooltip.

  final String record;

  /// Whether the button carries its own tooltip. Set false where the caller
  /// wraps the button in a tooltip of its own.

  final bool showTooltip;

  const DeleteButton({
    required this.onPressed,
    this.record = 'record',
    this.showTooltip = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: Icons.delete,
      tooltip: showTooltip ? 'Delete this $record from your pod' : null,
      colour: Theme.of(context).colorScheme.error,
      onPressed: onPressed,
    );
  }
}

/// Keeps the changes made to a record being edited.

class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SaveButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionButton(
      icon: Icons.save,
      tooltip: 'Save these changes to your pod',
      colour: isDark ? AppColors.successDark : AppColors.success,
      onPressed: onPressed,
    );
  }
}

/// Backs out of editing a record, leaving it as it was.

class CancelButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CancelButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionButton(
      icon: Icons.close,
      tooltip: 'Discard these changes',
      colour: isDark ? AppColors.navUnselectedDark : AppColors.navUnselected,
      onPressed: onPressed,
    );
  }
}
