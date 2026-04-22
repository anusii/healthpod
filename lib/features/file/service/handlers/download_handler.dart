/// File download handler for the file service provider.
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

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart'
    show readPod, SolidFunctionCallStatus, PathType;
import 'package:solidui/solidui.dart' show getKeyFromUserIfRequired;

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/save_decrypted_content.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Handles file download operations for the file service.

class FileDownloadHandler {
  const FileDownloadHandler._();

  /// Handles the download and decryption of files from the POD.

  static Future<bool> handleDownload(
    BuildContext context, {
    required String? remoteFileName,
    required String? currentPath,
    required String? cleanFileName,
  }) async {
    if (remoteFileName == null || currentPath == null) return false;

    try {
      // Let user choose where to save the file.

      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save file as:',
        fileName: cleanFileName ?? remoteFileName.replaceAll('.enc.ttl', ''),
      );

      if (outputFile == null) {
        return false;
      }

      final baseDir = basePath;
      final relativePath = currentPath == baseDir
          ? '$baseDir/$remoteFileName'
          : '$currentPath/$remoteFileName';

      if (!context.mounted) return false;

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to download the file'),
      );

      if (!context.mounted) return false;

      final fileContent = await readPod(
        relativePath,
        pathType: PathType.relativeToPod,
      );

      if (!context.mounted) return false;

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception(
          'Download failed - please check your connection and permissions',
        );
      }

      await saveDecryptedContent(fileContent, outputFile);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File downloaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Download error: ${e.toString()}');
        debugPrint('Download error: $e');
      }
      return false;
    }
  }
}
