/// Appointment details dialog for the appointments calendar.
///
/// Copyright (C) 2024-2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';

/// Shows a dialog with the full details of [appointment], rendered as markdown.

void showAppointmentDetails(BuildContext context, Appointment appointment) {
  final markdownContent = '''

**Date:** ${DateFormat('dd MMM, yyyy').format(appointment.date)}
**Time:** ${DateFormat('hh:mm a').format(appointment.date)}

## Description
${appointment.description}

## Status
${appointment.isPast ? 'Past' : 'Upcoming'}

''';

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.vaccines,
            color: Theme.of(dialogContext).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(appointment.title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: MarkdownBody(
            data: markdownContent,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 15),
              strong: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
