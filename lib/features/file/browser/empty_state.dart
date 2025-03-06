/// An empty state widget for the file browser.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

/// A widget that displays when a directory is empty.
///
/// The empty state includes:
/// - A large folder icon.
/// - A descriptive message.
///
/// The widget uses theme colors to maintain visual consistency
/// with the rest of the application.

class EmptyDirectoryView extends StatelessWidget {
  const EmptyDirectoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display a large folder icon with reduced opacity.

          Icon(
            Icons.folder_open,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
          ),

          const SizedBox(height: 16),

          // Display empty state message.

          Text(
            'This folder is empty',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
