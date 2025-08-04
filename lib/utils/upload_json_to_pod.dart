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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Uploads JSON data directly to POD.
///
/// Useful for saving structured data like survey responses.
/// This version works on both web and non-web platforms by using writePod directly.

Future<SolidFunctionCallStatus> uploadJsonToPod({
  required Map<String, dynamic> data,
  required String targetPath,
  required String fileNamePrefix,
  required BuildContext context,
  void Function(bool)? onProgressChange,
  void Function()? onSuccess,
}) async {
  try {
    onProgressChange?.call(true);

    // Create the JSON content.
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Create filename with timestamp.
    final timestamp = formatTimestampForFilename(DateTime.now());
    final fileName = '${fileNamePrefix}_$timestamp.json.enc.ttl';

    // Clean target path - remove leading slash if present.
    String cleanTargetPath = targetPath.startsWith('/') ? targetPath.substring(1) : targetPath;
    
    // Construct the full file path.
    final filePath = cleanTargetPath.isEmpty ? fileName : '$cleanTargetPath/$fileName';

    debugPrint('🌐 uploadJsonToPod: Starting upload');
    debugPrint('🌐 uploadJsonToPod: fileName = $fileName');
    debugPrint('🌐 uploadJsonToPod: filePath = $filePath');
    debugPrint('🌐 uploadJsonToPod: kIsWeb = $kIsWeb');
    debugPrint('🌐 uploadJsonToPod: jsonString length = ${jsonString.length}');

    // Guard against using context across async gaps.
    if (!context.mounted) {
      debugPrint('Widget is no longer mounted, skipping upload.');
      return SolidFunctionCallStatus.fail;
    }

    // Use writePod directly with encryption - this works on all platforms.
    debugPrint('🌐 uploadJsonToPod: Calling writePod...');
    final result = await writePod(
      filePath,
      jsonString,
      context,
      const Text('Saving data'),
      encrypted: true,
    );

    debugPrint('🌐 uploadJsonToPod: writePod result = $result');

    if (result == SolidFunctionCallStatus.success) {
      onSuccess?.call();
    }

    return result;
  } catch (e) {
    debugPrint('💥 uploadJsonToPod: ERROR during upload: $e');
    debugPrint('💥 uploadJsonToPod: Error type: ${e.runtimeType}');
    debugPrint('Error uploading JSON to POD: $e');
    return SolidFunctionCallStatus.fail;
  } finally {
    onProgressChange?.call(false);
  }
}
