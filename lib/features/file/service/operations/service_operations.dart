/// File service operations utility class.
///
/// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/is_text_file.dart';
import 'package:healthpod/utils/save_decrypted_content.dart';
import 'package:healthpod/utils/show_alert.dart';

/// A utility class for handling file operations in the service.
///
/// Provides methods for:
/// - File upload with encryption
/// - File download with decryption
/// - File deletion with ACL cleanup
/// - CSV import/export
///
/// All operations handle errors gracefully and provide progress feedback.

class ServiceOperations {
  /// Uploads a file to the POD with encryption.
  ///
  /// Parameters:
  /// - [filePath]: Path to the local file to upload.
  /// - [currentPath]: Current directory path in the POD.
  /// - [context]: Build context for UI operations.
  ///
  /// Returns a tuple of (success, remoteFileName) where:
  /// - success: Whether the upload was successful.
  /// - remoteFileName: The name of the file in the POD.

  static Future<(bool, String)> uploadFile({
    required String filePath,
    required String currentPath,
    required BuildContext context,
  }) async {
    try {
      final file = File(filePath);
      String fileContent;

      // Handle text vs binary files.
      if (isTextFile(filePath)) {
        fileContent = await file.readAsString();
      } else {
        final bytes = await file.readAsBytes();
        fileContent = base64Encode(bytes);
      }

      // Sanitize file name and append encryption extension.
      String sanitizedFileName = path
          .basename(filePath)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'\.enc\.ttl$'), '');

      final remoteFileName = '$sanitizedFileName.enc.ttl';

      // Extract subdirectory path.
      String? subPath = currentPath.replaceFirst('healthpod/data', '').trim();
      String uploadPath = subPath.isEmpty
          ? remoteFileName
          : '${subPath.startsWith("/") ? subPath.substring(1) : subPath}/$remoteFileName';

      if (!context.mounted) return (false, remoteFileName);

      // Upload file with encryption.
      final result = await writePod(
        uploadPath,
        fileContent,
        context,
        const Text('Upload'),
        encrypted: true,
      );

      if (!context.mounted) return (false, remoteFileName);

      if (result == SolidFunctionCallStatus.success) {
        return (true, remoteFileName);
      } else {
        showAlert(context,
            'Upload failed - please check your connection and permissions.');
        return (false, remoteFileName);
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (context.mounted) {
        showAlert(context, e.toString().replaceAll('Exception: ', ''));
      }
      return (false, '');
    }
  }

  /// Downloads a file from the POD with decryption.
  ///
  /// Parameters:
  /// - [fileName]: Name of the file to download.
  /// - [currentPath]: Current directory path in the POD.
  /// - [context]: Build context for UI operations.
  ///
  /// Returns whether the download was successful.

  static Future<bool> downloadFile({
    required String fileName,
    required String currentPath,
    required BuildContext context,
  }) async {
    try {
      final relativePath = '$currentPath/$fileName';

      if (!context.mounted) return false;

      final fileContent = await readPod(
        relativePath,
        context,
        const Text('Downloading'),
      );

      if (!context.mounted) return false;

      // Handle common error cases.
      if (fileContent == SolidFunctionCallStatus.fail ||
          fileContent == SolidFunctionCallStatus.notLoggedIn) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      // Save decrypted content.
      final saveFileName = fileName.replaceAll(RegExp(r'\.enc\.ttl$'), '');
      await saveDecryptedContent(fileContent, saveFileName);

      if (!context.mounted) return false;

      // Show success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        showAlert(context, e.toString().replaceAll('Exception: ', ''));
      }
      return false;
    }
  }

  /// Deletes a file from the POD.
  ///
  /// This method:
  /// - Deletes the main file
  /// - Deletes the associated ACL file
  /// - Handles errors gracefully
  ///
  /// Returns true if deletion was successful.
  static Future<bool> deletePodFile({
    required String fileName,
    required String currentPath,
    required BuildContext context,
  }) async {
    try {
      final basePath = '$currentPath/$fileName';
      await deleteFile(basePath);
      await deleteFile('$basePath.acl');
      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  /// Imports a CSV file into the POD.
  ///
  /// This method:
  /// - Reads the CSV file
  /// - Processes the data
  /// - Uploads to the POD
  ///
  /// Returns true if import was successful.
  static Future<bool> importCsv({
    required String filePath,
    required String currentPath,
    required BuildContext context,
  }) async {
    try {
      // TODO: Implement CSV import logic
      return true;
    } catch (e) {
      debugPrint('CSV import error: $e');
      return false;
    }
  }
}
