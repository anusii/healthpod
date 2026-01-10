/// File upload handler for the file service provider.
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
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/is_text_file.dart' as utils;
import 'package:healthpod/utils/show_alert.dart';

/// Handles file upload operations for the file service.

class FileUploadHandler {
  const FileUploadHandler._();

  /// Handles file upload by reading its contents and encrypting it for upload.

  static Future<FileUploadResult> handleUpload(
    BuildContext context, {
    required String uploadFile,
    required String? currentPath,
    required Function? refreshCallback,
  }) async {
    try {
      final file = File(uploadFile);
      String fileContent;

      // For text files, we directly read the content.
      // For binary files, we encode them into base64 format.

      if (utils.isTextFile(uploadFile)) {
        fileContent = await file.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        fileContent = base64Encode(bytes);
      }

      // Sanitise file name and append encryption extension.

      String sanitizedFileName = path
          .basename(uploadFile)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '');

      final remoteFileName = '$sanitizedFileName.enc.ttl';
      final cleanFileName = sanitizedFileName;

      // Extract the subdirectory path.

      String? subPath = currentPath?.replaceFirst(basePath, '').trim();
      String uploadPath = subPath == null || subPath.isEmpty
          ? remoteFileName
          : '${subPath.startsWith("/") ? subPath.substring(1) : subPath}/$remoteFileName';

      if (!context.mounted) {
        return FileUploadResult(
          success: false,
          remoteFileName: remoteFileName,
          cleanFileName: cleanFileName,
        );
      }

      // Upload file with encryption.

      await writePod(
        uploadPath,
        fileContent,
        encrypted: true,
      );

      // Show success message.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File uploaded successfully'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        // Call the refresh callback to update the browser.

        refreshCallback?.call();
      }

      return FileUploadResult(
        success: true,
        remoteFileName: remoteFileName,
        cleanFileName: cleanFileName,
      );
    } catch (e) {
      if (context.mounted) {
        showAlert(context, 'Upload error: ${e.toString()}');
        debugPrint('Upload error: $e');
      }
      return const FileUploadResult(
        success: false,
        remoteFileName: null,
        cleanFileName: null,
      );
    }
  }
}

/// Result of a file upload operation.

class FileUploadResult {
  final bool success;
  final String? remoteFileName;
  final String? cleanFileName;

  const FileUploadResult({
    required this.success,
    required this.remoteFileName,
    required this.cleanFileName,
  });
}
