/// Profile import/export handler for the file service provider.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'dart:io';

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
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
                  content: Text('Profile data imported successfully'),
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
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Profile data as JSON:',
        fileName: 'profile_export.json',
      );

      if (outputFile != null) {
        if (!context.mounted) return;

        final success = await ProfileExporter.exportJson(
          outputFile,
          currentPath ?? 'profile',
          context,
        );

        // Add a newline character at the end of the file if export was successful.

        if (success) {
          final file = File(outputFile);
          if (await file.exists()) {
            final content = await file.readAsString();
            if (!content.endsWith('\n')) {
              await file.writeAsString('$content\n');
            }
          }
        }

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile data exported successfully'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            );
          } else {
            showAlert(context, 'Failed to export profile data');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Failed to export profile data: ${e.toString()}');
      }
    }
  }
}
