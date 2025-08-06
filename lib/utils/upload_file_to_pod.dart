/// Upload file to POD.
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

import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/is_text_file.dart';

/// Handles file upload to POD with encryption.
///
/// Returns a [Future<SolidFunctionCallStatus>] indicating the upload result.

Future<SolidFunctionCallStatus> uploadFileToPod({
  required String filePath,
  required String targetPath,
  required BuildContext context,
  String? customFileName,
  void Function(bool)? onProgressChange,
  void Function()? onSuccess,
}) async {
  try {
    onProgressChange?.call(true);

    final file = File(filePath);
    String fileContent;

    // Handle text vs binary files.

    if (isTextFile(filePath)) {
      fileContent = await file.readAsString();
    } else {
      final bytes = await file.readAsBytes();
      fileContent = base64Encode(bytes);
    }

    // Sanitise filename and handle custom name if provided.

    String sanitizedFileName = customFileName ?? path.basename(filePath);
    sanitizedFileName = sanitizedFileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'\.enc\.ttl$'), '');

    final remoteFileName = '$sanitizedFileName.enc.ttl';

    // Construct upload path.

    String uploadPath = '$targetPath/$remoteFileName';
    uploadPath =
        uploadPath.replaceAll(RegExp(r'^/+'), ''); // Remove leading slashes

    // Guard against using context across async gaps.

    if (!context.mounted) {
      // Widget no longer mounted, skipping upload.

      return SolidFunctionCallStatus.fail;
    }

    // Upload file with encryption.

    final result = await writePod(
      uploadPath,
      fileContent,
      context,
      const Text('Upload'),
      encrypted: true,
    );

    if (result == SolidFunctionCallStatus.success) {
      onSuccess?.call();
    }

    return result;
  } finally {
    onProgressChange?.call(false);
  }
}
