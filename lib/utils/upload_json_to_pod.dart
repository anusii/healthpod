/// Upload JSON file to POD.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/upload_file_to_pod.dart';

/// Creates a temporary JSON file and uploads it to POD.
///
/// Useful for saving structured data like survey responses.

Future<SolidFunctionCallStatus> uploadJsonToPod({
  required Map<String, dynamic> data,
  required String targetPath,
  required String fileNamePrefix,
  required BuildContext context,
  void Function(bool)? onProgressChange,
  void Function()? onSuccess,
}) async {
  Directory? tempDir;
  File? tempFile;

  try {
    // Create temp file with JSON content.

    final timestamp = formatTimestampForFilename(
        DateTime.now()); // Format timestamp for file name.
    final fileName = '${fileNamePrefix}_$timestamp.json';

    tempDir = await Directory.systemTemp.createTemp('healthpod_temp');
    tempFile = File('${tempDir.path}/$fileName');

    // Write formatted JSON.

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await tempFile.writeAsString(jsonString);

    // Guard against using context across async gaps.

    if (!context.mounted) {
      debugPrint('Widget is no longer mounted, skipping upload.');
      return SolidFunctionCallStatus.fail;
    }

    // Upload the file.

    return await uploadFileToPod(
      filePath: tempFile.path,
      targetPath: targetPath,
      context: context,
      onProgressChange: onProgressChange,
      onSuccess: onSuccess,
    );
  } finally {
    // Clean up temp files.

    try {
      if (tempFile != null && tempFile.existsSync()) await tempFile.delete();
      if (tempDir != null && tempDir.existsSync()) await tempDir.delete();
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}
