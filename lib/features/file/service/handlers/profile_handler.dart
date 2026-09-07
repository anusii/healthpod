/// Profile import/export handler for the file service provider.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/features/profile/exporter.dart';
import 'package:healthpod/features/profile/importer.dart';
import 'package:healthpod/providers/profile_provider.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles profile import and export operations for the file service.

class ProfileHandler {
  const ProfileHandler._();

  /// Handles the import of profile data from JSON format.

  static Future<void> handleProfileImport(
    BuildContext context, {
    required WidgetRef ref,
    required Function? refreshCallback,
  }) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file != null) {
        if (file.path != null) {
          if (!context.mounted) return;

          await ProfileImporter.importJson(
            file.path!,
            'profile',
            context,
            onSuccess: () {
              if (!context.mounted) return;

              // Show success message first.

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profile data imported successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );

              // Use microtask to ensure UI operations complete first.

              Future.microtask(() {
                if (!context.mounted) return;
                // Refresh profile data after successful import.

                ref.read(profileProvider.notifier).refreshProfileData(context);

                // Refresh file browser.

                refreshCallback?.call();
              });
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Failed to import profile data: ${e.toString()}');
      }
    }
  }

  /// Handles the export of profile data to JSON format.

  static Future<void> handleProfileExport(
    BuildContext context, {
    required String? currentPath,
  }) async {
    try {
      // Read the profile before offering the save dialogue: file_picker
      // writes the bytes itself now rather than handing back a path to write
      // to.

      final String? profile = await ProfileExporter.buildJson(
        currentPath ?? 'profile',
        context,
      );

      if (!context.mounted) return;

      if (profile == null) {
        showAlert(context, 'Failed to export profile data');

        return;
      }

      // Pretty-print the JSON and finish with a newline, as the saved file
      // used to be rewritten to do.

      var text = profile;
      try {
        text = const JsonEncoder.withIndent('  ').convert(jsonDecode(profile));
      } catch (_) {
        // Not JSON, so export it exactly as it came back from the Pod.
      }
      if (!text.endsWith('\n')) text = '$text\n';

      final Uri? savedUri = await FilePicker.saveFile(
        dialogTitle: 'Save Profile data as JSON:',
        fileName: 'profile_export.json',
        bytes: utf8.encode(text),
      );

      if (savedUri != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile data exported successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Failed to export profile data: ${e.toString()}');
      }
    }
  }
}
