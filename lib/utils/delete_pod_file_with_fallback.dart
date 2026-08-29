/// Utility function for deleting Pod files with fallback options.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/resolve_pod_file_url.dart';

/// Deletes a file from the Pod with fallback options for finding similar files.
///
/// This function attempts to delete a file using the following strategy:
/// 1. First tries to delete the exact file specified by the filename
/// 2. If not found, tries with an alternative timestamp format (underscore separator)
/// 3. If still not found, looks for files with the same date part
/// 4. If still not found, uses a more flexible approach to find any file containing the date
///
/// Parameters:
/// - [dataType]: The type of data (e.g., 'blood_pressure', 'vaccination')
/// - [filename]: The primary filename to delete
/// - [timestamp]: The DateTime associated with the file, used for fallback searches
/// - [resources]: The container listing returned by [getResourcesInContainer]
///
/// Returns a boolean indicating whether any file was successfully deleted.
///
/// Example:
/// ```dart
/// final success = await deletePodFileWithFallback(
///   dataType: 'blood_pressure',
///   filename: 'blood_pressure_2023-05-15T14-30-22.json.enc.ttl',
///   timestamp: observation.timestamp,
///   resources: resources,
/// );
/// ```

Future<bool> deletePodFileWithFallback({
  required String dataType,
  required String filename,
  required DateTime timestamp,
  required ({List<String> subDirs, List<String> files}) resources,
}) async {
  final files = resources.files;

  // The candidates are collected in the order they should be tried, from the
  // exact filename through to the loosest date match, so that the first
  // successful delete is always the closest match to the record asked for.

  final candidates = <String>[];

  void addCandidate(String? name) {
    if (name != null && name.isNotEmpty && !candidates.contains(name)) {
      candidates.add(name);
    }
  }

  // The exact filename.

  if (files.contains(filename)) {
    addCandidate(filename);
  }

  // The older underscore format, kept for backward compatibility.

  final filenameWithUnderscore =
      '${dataType}_${formatTimestampForFilenameWithUnderscore(timestamp)}'
      '.json.enc.ttl';

  if (files.contains(filenameWithUnderscore)) {
    addCandidate(filenameWithUnderscore);
  }

  // Failing an exact match, any file recorded on the same date. The date part
  // (YYYY-MM-DD) is all that is compared, so a file written with a different
  // time format is still found.

  final datePart = formatTimestampForFilename(timestamp).split('T')[0];
  final baseFilename = '${dataType}_$datePart';

  final matchingFiles =
      files.where((file) => file.startsWith(baseFilename)).toList();

  if (matchingFiles.isNotEmpty) {
    addCandidate(matchingFiles.first);
  }

  // Looser still: any file in this container carrying the date.

  final flexibleMatches =
      files.where((file) => file.contains(datePart)).toList();

  if (flexibleMatches.isNotEmpty) {
    addCandidate(flexibleMatches.first);
  }

  if (candidates.isEmpty) {
    debugPrint('File not found for deletion: $filename');
  }

  for (final candidate in candidates) {
    if (await _deletePodFile(dataType, candidate)) {
      return true;
    }
  }

  // No matching files found.

  debugPrint('No matching files found for deletion with base: $baseFilename');

  return false;
}

/// Deletes a single file from the [dataType] container.
///
/// Returns true when the file is gone from the Pod, which includes the case of
/// the server reporting it as missing: on the web a delete can succeed and
/// still raise a not-found error.

Future<bool> _deletePodFile(String dataType, String filename) async {
  // deleteFile parses its argument as a URI, so the relative Pod path has to
  // be resolved to a full URL first.

  final fileUrl = await resolvePodFileUrl(constructPodPath(dataType, filename));

  try {
    await deleteFile(fileUrl: fileUrl);

    return true;
  } catch (e) {
    final message = e.toString();

    if (message.contains('404') ||
        message.contains('NotFoundHttpError') ||
        message.contains('not found')) {
      debugPrint(
        'File deletion succeeded (404 indicates file was deleted): $filename',
      );

      return true;
    }

    debugPrint('Error deleting file $filename: $e');

    return false;
  }
}
