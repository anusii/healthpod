/// Utility function for deleting Pod files with fallback options.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

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
/// - [resources]: The container resources with a 'files' list property
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
  required dynamic resources,
}) async {
  // Try with the exact filename first.

  if (resources.files.contains(filename)) {
    final filePath = constructPodPath(dataType, filename);
    await deleteFile(filePath);
    // debugPrint('Deleted file: $filename');
    return true;
  }

  // Try with the underscore format.
  final filenameWithUnderscore =
      '${dataType}_${formatTimestampForFilenameWithUnderscore(timestamp)}.json.enc.ttl';

  if (resources.files.contains(filenameWithUnderscore)) {
    final filePathWithUnderscore =
        constructPodPath(dataType, filenameWithUnderscore);
    await deleteFile(filePathWithUnderscore);
    // debugPrint('Deleted file with underscore: $filenameWithUnderscore');
    return true;
  }

  // If neither exact match is found, try to find a file with a similar date part.

  debugPrint('File not found for deletion: $filename');

  // Extract just the date part (YYYY-MM-DD) from the timestamp.

  final datePart = formatTimestampForFilename(timestamp).split('T')[0];
  final baseFilename = '${dataType}_$datePart';

  // Find any files that start with this date part.

  final matchingFiles =
      resources.files.where((file) => file.startsWith(baseFilename)).toList();

  if (matchingFiles.isNotEmpty) {
    // Delete the first matching file.

    final matchingFilePath = constructPodPath(dataType, matchingFiles.first);
    await deleteFile(matchingFilePath);
    // debugPrint('Deleted alternative file: ${matchingFiles.first}');
    return true;
  }

  // No matching files found, try a more flexible approach.
  // Look for any file that contains the date (without the time).

  final moreFlexibleMatches =
      resources.files.where((file) => file.contains(datePart)).toList();

  if (moreFlexibleMatches.isNotEmpty) {
    final flexibleMatchPath =
        constructPodPath(dataType, moreFlexibleMatches.first);
    await deleteFile(flexibleMatchPath);
    // debugPrint(
    //     'Deleted file with flexible matching: ${moreFlexibleMatches.first}');
    return true;
  }

  // No matching files found.

  debugPrint('No matching files found for deletion with base: $baseFilename');
  return false;
}
