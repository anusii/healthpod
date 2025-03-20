/// A dialog that displays markdown-formatted content with interactive elements.
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

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:healthpod/features/resources/service/resource_service.dart';

/// Shows an alert dialog with markdown content.
///
/// Parameters:
/// * [context] - The build context
/// * [markdownContent] - The markdown-formatted content to display
/// * [title] - Optional title for the dialog (defaults to 'Notice')
///
/// The dialog includes:
/// * Responsive width based on screen size
/// * Scrollable content area
/// * Theme-aware styling
/// * Interactive link handling

Future<void> markdownAlert(
  BuildContext context,
  String markdownContent, [
  String title = 'Notice',
]) async {
  // Calculate responsive dialog width.

  final screenWidth = MediaQuery.of(context).size.width;
  final dialogWidth = screenWidth * 0.8 > 600 ? 600.0 : screenWidth * 0.8;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: markdownContent,
            selectable: true,
            // Handle link taps by opening them in external browser
            onTapLink: (text, href, title) {
              if (href != null) {
                ResourceService.openExternalLink(context, href);
              }
            },
            // Configure markdown styling to match app theme.

            styleSheet: MarkdownStyleSheet(
              // Text styles.

              h1: Theme.of(context).textTheme.headlineMedium,
              h2: Theme.of(context).textTheme.titleLarge,
              p: Theme.of(context).textTheme.bodyMedium,
              strong: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              // Blockquote styles.

              blockquote: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              // Table styles.

              tableHead: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              tableBorder: TableBorder.all(
                color: Theme.of(context).dividerColor,
                width: 1,
                borderRadius: BorderRadius.circular(4),
              ),
              tableColumnWidth: const FlexColumnWidth(),
              tableBody: Theme.of(context).textTheme.bodyMedium,
              // List and link styles.

              listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              a: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
