/// Utility functions for vaccination dialogs.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

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
      title: Text(record.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${DateFormat('MMMM dd, yyyy').format(record.date)}'),
            if (record.provider != null && record.provider!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Provider: ${record.provider}'),
              ),
            if (record.professional != null && record.professional!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Professional: ${record.professional}'),
              ),
            if (record.cost != null && record.cost!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Cost: ${record.cost}'),
              ),
            if (record.notes != null && record.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Notes: ${record.notes}'),
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
