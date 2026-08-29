/// File deletion handler for the file service provider.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/resolve_pod_file_url.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles file deletion operations for the file service.

class FileDeleteHandler {
  const FileDeleteHandler._();

  /// Handles file deletion from the POD.

  static Future<bool> handleDelete(
    BuildContext context, {
    required String? remoteFileName,
    required String? currentPath,
    required Function? refreshCallback,
  }) async {
    if (remoteFileName == null || currentPath == null) return false;

    try {
      final baseDir = basePath;
      final filePath = currentPath == baseDir
          ? '$baseDir/$remoteFileName'
          : '$currentPath/$remoteFileName';

      // deleteFile parses its argument as a URI, so the relative pod path
      // has to be resolved to a full URL first.

      final fileUrl = await resolvePodFileUrl(filePath);

      if (!context.mounted) return false;

      // First try to delete the main file.

      bool mainFileDeleted = false;
      try {
        await deleteFile(fileUrl: fileUrl);
        mainFileDeleted = true;
      } catch (e) {
        debugPrint('Error deleting main file: $e');
        // Only rethrow if it's not a 404 error.

        if (!e.toString().contains('404') &&
            !e.toString().contains('NotFoundHttpError')) {
          rethrow;
        }
      }

      if (!context.mounted) return false;

      // If main file deletion succeeded, try to delete the ACL file.

      if (mainFileDeleted) {
        try {
          await deleteFile(fileUrl: '$fileUrl.acl');
        } catch (e) {
          // ACL files are optional and may not exist.

          if (e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')) {
            debugPrint('ACL file not found (safe to ignore)');
          } else {
            debugPrint('Error deleting ACL file: ${e.toString()}');
          }
        }

        if (!context.mounted) return false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );

          // Call the refresh callback to update the browser.

          refreshCallback?.call();
        }

        return true;
      }

      return false;
    } catch (e) {
      if (!context.mounted) return false;

      // Provide user-friendly error messages.

      final message = e.toString().contains('404') ||
              e.toString().contains('NotFoundHttpError')
          ? 'File not found or already deleted'
          : 'Delete failed: ${e.toString()}';

      showAlert(context, message);
      debugPrint('Delete error: $e');
      return false;
    }
  }
}
