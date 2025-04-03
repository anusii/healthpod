/// A path bar widget for file browser navigation.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

/// A path bar widget that displays the current directory path and provides
/// navigation controls.
///
/// The path bar shows:
/// - Current directory path.
/// - Back button for navigation.
/// - Refresh button to update the view.
/// - File count in the current directory.
///
/// The widget adapts its display based on the navigation state and loading
/// status of the file browser.

class PathBar extends StatelessWidget {
  /// The current directory path being displayed.

  final String currentPath;

  /// History of visited directories for navigation.

  final List<String> pathHistory;

  /// Callback when the user wants to navigate up one directory.

  final VoidCallback onNavigateUp;

  /// Callback when the user wants to refresh the current directory.

  final VoidCallback onRefresh;

  /// Whether the file browser is currently loading.

  final bool isLoading;

  /// Number of files in the current directory.

  final int currentDirFileCount;

  const PathBar({
    super.key,
    required this.currentPath,
    required this.pathHistory,
    required this.onNavigateUp,
    required this.onRefresh,
    required this.isLoading,
    required this.currentDirFileCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Show back button if we're not at the root directory.

              if (pathHistory.length > 1)
                IconButton(
                  icon: MarkdownTooltip(
                    message: '''
                    
                    **Navigate Up:** Tap here to go back to the parent directory.
                    
                    ''',
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onPressed: onNavigateUp,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withAlpha(10),
                    padding: const EdgeInsets.all(8),
                  ),
                ),

              const SizedBox(width: 8),

              // Display current path with ellipsis if too long.

              Expanded(
                child: Text(
                  currentPath,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Spacer(),

              // Refresh button to update the current directory.

              IconButton(
                icon: MarkdownTooltip(
                  message: '''
                  
                  **Refresh:** Tap here to reload the current directory contents.
                  
                  ''',
                  child: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(10),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),

          // Show file count when not loading.

          if (!isLoading) ...[
            const SizedBox(height: 8),
            Text(
              'Files in current directory: $currentDirFileCount',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
