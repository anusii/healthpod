/// File operation handlers for SolidFile component callbacks.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/features/home/widgets/navigation/tab_coordinator.dart';
import 'package:healthpod/providers/tab_state.dart';
import 'package:healthpod/utils/resolve_pod_file_url.dart';

/// Handles file operations like selection, download, and deletion for
/// SolidFile.

class FileOperationHandler {
  final WidgetRef ref;
  final BuildContext context;
  final GlobalKey<SolidFileBrowserState> browserKey;
  final Function() onStateUpdate;

  const FileOperationHandler({
    required this.ref,
    required this.context,
    required this.browserKey,
    required this.onStateUpdate,
  });

  /// Handles file selection.

  void handleFileSelected(String fileName, String filePath) {
    ref.read(fileServiceProvider.notifier)
      ..setDownloadFile(filePath)
      ..setFilePreview(fileName)
      ..setRemoteFileName(path.basename(fileName));
  }

  /// Handles file download.

  Future<void> handleFileDownload(String fileName, String filePath) async {
    ref.read(fileServiceProvider.notifier)
      ..setDownloadFile(filePath)
      ..setRemoteFileName(path.basename(fileName))
      ..handleDownload(context);
  }

  /// Handles file deletion with confirmation.

  Future<void> handleFileDelete(String fileName, String filePath) async {
    // Show confirmation dialogue before deleting.

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$fileName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (confirm == true) {
      String actualPath = '$filePath/$fileName';

      // deleteFile parses its argument as a URI, so the relative pod path has
      // to be resolved to a full URL first.

      final fileUrl = await resolvePodFileUrl(actualPath);

      if (!context.mounted) return;

      try {
        // Delete the main file first.

        await deleteFile(fileUrl: fileUrl);

        // Try to delete the ACL file.

        try {
          await deleteFile(fileUrl: '$fileUrl.acl');
        } catch (e) {
          // ACL files are optional and may not exist.
        }

        // Show success message.

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );

          // Refresh the file browser.

          browserKey.currentState?.refreshFiles();
        }
      } catch (e) {
        if (context.mounted) {
          final message = e.toString().contains('404') ||
                  e.toString().contains('NotFoundHttpError')
              ? 'File not found or already deleted'
              : 'Delete failed: ${e.toString()}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Handles CSV import callback.

  void handleImportCsv(String fileName, String filePath) {
    // Import CSV functionality would be implemented here.

    debugPrint('Import CSV: $fileName at $filePath');
  }

  /// Handles directory change events.

  void handleDirectoryChanged(
    String path,
    String Function() getExpectedPath,
    Function(bool) setUserManuallyNavigated,
    Function(int?) setLastCoordinatedTabIndex,
  ) {
    final expectedPath = getExpectedPath();
    final isTabCoordinatedNavigation = (path == expectedPath);

    if (!isTabCoordinatedNavigation) {
      setUserManuallyNavigated(true);

      // Reverse-sync: update the shared tab index so that View / Add / Data
      // will show the matching tab when the user switches away from Files.

      final tabIndex = TabCoordinator.getTabIndexForPath(path);
      if (tabIndex != null) {
        ref.read(tabStateProvider.notifier).setSelectedIndex(tabIndex);
        setLastCoordinatedTabIndex(tabIndex);
      } else {
        setLastCoordinatedTabIndex(null);
      }
    }

    ref.read(fileServiceProvider.notifier).updateCurrentPath(path);
    onStateUpdate();
  }

  /// Handles closing file preview.

  void handleClosePreview() {
    final currentState = ref.read(fileServiceProvider);
    if (currentState.showPreview) {
      ref.read(fileServiceProvider.notifier).togglePreview();
    }
  }
}
