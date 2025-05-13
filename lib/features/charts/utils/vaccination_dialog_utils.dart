/// Utility functions for vaccination dialogs.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import 'package:healthpod/features/charts/models/vaccination_record.dart';

/// Shows a dialog with detailed vaccination information.
///
/// This function displays an alert dialog containing all available details
/// about the provided vaccination record.

void showVaccinationDetails(BuildContext context, VaccinationRecord record) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.vaccines,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(record.name),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data:
                  '**Date:** ${DateFormat('dd MMM yyyy').format(record.date)}',
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (record.provider != null && record.provider!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MarkdownBody(
                  data: '**Provider:** ${record.provider}',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (record.professional != null && record.professional!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MarkdownBody(
                  data: '**Professional:** ${record.professional}',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (record.cost != null && record.cost!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MarkdownBody(
                  data: '**Cost:** ${record.cost}',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (record.notes != null && record.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MarkdownBody(
                  data: '**Notes:** ${record.notes}',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
