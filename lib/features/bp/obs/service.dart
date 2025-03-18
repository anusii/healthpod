/// Blood pressure observation service.
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Handles loading/saving/deleting BP observations from the Pod.

class BPEditorService {
  /// The data type identifier for blood pressure records.

  static const String dataType = 'blood_pressure';

  /// Load all BP observations from `healthpod/data/blood_pressure` directory.

  Future<List<BPObservation>> loadData(BuildContext context) async {
    final dirPath = getFeaturePath(dataType);
    final dirUrl = await getDirUrl(dirPath);
    final resources = await getResourcesInContainer(dirUrl);

    final List<BPObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      final filePath = getFeaturePath(dataType, file);
      final content = await readPod(
        filePath,
        context,
        const Text('Loading file'),
      );
      if (content == null ||
          content == SolidFunctionCallStatus.fail ||
          content == SolidFunctionCallStatus.notLoggedIn) {
        continue;
      }

      try {
        final data = json.decode(content.toString());
        loadedObservations.add(BPObservation.fromJson(data));
      } catch (e) {
        debugPrint('Error parsing file $file: $e');
      }
    }

    return loadedObservations;
  }

  /// Save a BP observation to Pod. If this is an existing observation update,
  /// remove the old file first.

  Future<void> saveObservationToPod({
    required BuildContext context,
    required BPObservation observation,
    required bool isNew,
    required BPObservation? oldObservation,
  }) async {
    try {
      // Delete old file if not a new observation.

      if (!isNew && oldObservation != null) {
        try {
          final oldFilename = _filenameFromTimestamp(oldObservation.timestamp);

          // Check if the old file exists before attempting to delete it.

          final dirPath = getFeaturePath(dataType);
          final dirUrl = await getDirUrl(dirPath);
          final resources = await getResourcesInContainer(dirUrl);

          if (resources.files.contains(oldFilename)) {
            final oldFilePath = getFeaturePath(dataType, oldFilename);
            await deleteFile(oldFilePath);
          } else {
            // Check if there's a file with a similar name.

            final baseFilename =
                '${dataType}_${formatTimestampForFilename(oldObservation.timestamp).split('T')[0]}';
            final matchingFiles = resources.files
                .where((file) => file.startsWith(baseFilename))
                .toList();

            if (matchingFiles.isNotEmpty) {
              final matchingFilePath =
                  getFeaturePath(dataType, matchingFiles.first);
              await deleteFile(matchingFilePath);
              debugPrint(
                  'Deleted alternative old file: ${matchingFiles.first}');
            }
          }
        } catch (e) {
          // Log the error but continue with saving the new file.

          debugPrint('Error deleting old observation file: $e');
        }
      }

      // Write new file.

      final newFilename = _filenameFromTimestamp(observation.timestamp);
      final jsonData = json.encode(observation.toJson());

      if (!context.mounted) return;

      await writePod(
        '$dataType/$newFilename',
        jsonData,
        context,
        const Text('Saving'),
        encrypted: true,
      );
    } catch (e) {
      debugPrint('Error saving observation: $e');
      throw Exception('Failed to save blood pressure observation: $e');
    }
  }

  /// Delete an observation's file from Pod.

  Future<void> deleteObservationFromPod(
    BuildContext context,
    BPObservation observation,
  ) async {
    try {
      // Log the resources in the directory for debugging.

      final dirPath = getFeaturePath(dataType);
      final dirUrl = await getDirUrl(dirPath);
      final resources = await getResourcesInContainer(dirUrl);

      debugPrint('SubDirs: |${resources.subDirs.join(', ')}|');
      debugPrint('Files  : |${resources.files.join(', ')}|');

      // Try with the current format (T separator).

      final filename = _filenameFromTimestamp(observation.timestamp);

      // Also try with the old format (underscore separator) for backward compatibility.

      final filenameWithUnderscore =
          '${dataType}_${formatTimestampForFilenameWithUnderscore(observation.timestamp)}.json.enc.ttl';

      // Check if either file exists.

      if (resources.files.contains(filename)) {
        final filePath = getFeaturePath(dataType, filename);
        await deleteFile(filePath);
        debugPrint('Deleted file: $filename');
        return;
      } else if (resources.files.contains(filenameWithUnderscore)) {
        final filePathWithUnderscore =
            getFeaturePath(dataType, filenameWithUnderscore);
        await deleteFile(filePathWithUnderscore);
        debugPrint('Deleted file with underscore: $filenameWithUnderscore');
        return;
      }

      // If neither exact match is found, try to find a file with a similar date part.

      debugPrint('File not found for deletion: $filename');

      // Extract just the date part (YYYY-MM-DD) from the timestamp.

      final datePart =
          formatTimestampForFilename(observation.timestamp).split('T')[0];
      final baseFilename = '${dataType}_$datePart';

      // Find any files that start with this date part.

      final matchingFiles = resources.files
          .where((file) => file.startsWith(baseFilename))
          .toList();

      if (matchingFiles.isNotEmpty) {
        // Delete the first matching file.

        final matchingFilePath = getFeaturePath(dataType, matchingFiles.first);
        await deleteFile(matchingFilePath);
        debugPrint('Deleted alternative file: ${matchingFiles.first}');
      } else {
        // No matching files found, try a more flexible approach.
        // Look for any file that contains the date (without the time).

        final moreFlexibleMatches =
            resources.files.where((file) => file.contains(datePart)).toList();

        if (moreFlexibleMatches.isNotEmpty) {
          final flexibleMatchPath =
              getFeaturePath(dataType, moreFlexibleMatches.first);
          await deleteFile(flexibleMatchPath);
          debugPrint(
              'Deleted file with flexible matching: ${moreFlexibleMatches.first}');
        } else {
          // No matching files found.

          debugPrint(
              'No matching files found for deletion with base: $baseFilename');
        }
      }
    } catch (e) {
      debugPrint('Error deleting observation: $e');
      // Rethrow with more context to help debugging.

      throw Exception('Failed to delete blood pressure observation: $e');
    }
  }

  /// Helper to generate the consistent file name from an observation's timestamp.

  String _filenameFromTimestamp(DateTime dt) {
    final formatted = formatTimestampForFilename(dt);
    return '${dataType}_$formatted.json.enc.ttl';
  }
}
