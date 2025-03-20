/// A card widget for displaying health resource information.
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

/// A card widget that displays a health resource with title, description, and icon.

class ResourceCard extends StatelessWidget {
  /// The title of the resource.

  final String title;

  /// A brief description of the resource.

  final String description;

  /// The icon to display next to the title.

  final IconData icon;

  /// Callback function when the card is tapped.

  final VoidCallback onTap;

  /// Whether this resource opens in an external browser.
  /// If true, displays an external link icon.

  final bool isExternalLink;

  /// Creates a resource card.
  ///
  /// All parameters except [isExternalLink] are required.
  /// * [title] - The title of the resource
  /// * [description] - A brief description of the resource
  /// * [icon] - The icon to display next to the title
  /// * [onTap] - Callback function when the card is tapped
  /// * [isExternalLink] - Whether this resource opens externally (defaults to false)

  const ResourceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.isExternalLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MarkdownTooltip(
      message: '''
      **$title**
      
      $description
      ${isExternalLink ? '\n\n*Opens in external browser*' : ''}
      ''',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isExternalLink)
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
