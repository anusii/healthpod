/// Dialog components for profile import operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/profile/validators/profile_validator.dart';

/// Utility class for profile import dialogs.

class ProfileImportDialogs {
  const ProfileImportDialogs._();

  /// Shows a validation error dialog.

  static Future<void> showValidationErrorDialog(
    BuildContext context,
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(message)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog with profile data preview.

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final profileData =
        data.containsKey('data') ? data['data'] as Map<String, dynamic> : data;

    // Get the key fields to display in the dialog.

    final previewFields = [
      'name',
      'dateOfBirth',
      'gender',
      'email',
      'bestContactPhone',
    ];

    // Build preview items.

    final previewItems = <Widget>[];

    for (final field in previewFields) {
      if (profileData.containsKey(field)) {
        previewItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    ProfileValidator.formatFieldName(field),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${profileData[field]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Profile Import'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                      'You are about to import the following profile data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...previewItems,
                    const SizedBox(height: 16),
                    const Text(
                      'Importing this data will create a new profile record. '
                      'Do you want to continue?',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Import'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Shows a confirmation dialog for overriding existing profiles.
  ///
  /// This method displays a dialog with a list of profile files that would be
  /// overridden and asks the user to confirm the override.

  static Future<bool> showOverrideConfirmationDialog(
    BuildContext context,
    List<String> existingProfiles,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Existing Profile Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You already have a profile saved. Importing a new profile '
                  'will replace your existing profile data.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Existing profile files:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: existingProfiles
                          .map(
                            (filename) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      filename,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Warning: This action cannot be undone. Your existing '
                  'profile will be permanently replaced.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Replace Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ) ??
        false;
  }
}
