/// Vaccination observation service.
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
/// Authors: Kevin Wang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/table/vaccination_editor/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Handles loading/saving/deleting vaccination observations from the Pod.

class VaccinationEditorService {
  /// Load all vaccination observations from `healthpod/data/vaccinations` directory.

  Future<List<VaccinationObservation>> loadData(BuildContext context) async {
    final dirUrl = await getDirUrl('healthpod/data/vaccination');
    final resources = await getResourcesInContainer(dirUrl);

    final List<VaccinationObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      final content = await readPod(
        'healthpod/data/vaccination/$file',
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
        loadedObservations.add(VaccinationObservation.fromJson(data));
      } catch (e) {
        debugPrint('Error parsing file $file: $e');
      }
    }

    return loadedObservations;
  }

  /// Save a vaccination observation to Pod. If this is an existing observation update,
  /// remove the old file first.

  Future<void> saveObservationToPod({
    required BuildContext context,
    required VaccinationObservation observation,
    required bool isNew,
    required VaccinationObservation? oldObservation,
  }) async {
    try {
      // Delete old file if not a new observation.

      if (!isNew && oldObservation != null) {
        try {
          final oldFilename = _filenameFromTimestamp(oldObservation.timestamp);

          // Check if the old file exists before attempting to delete it.

          final dirUrl = await getDirUrl('healthpod/data/vaccination');
          final resources = await getResourcesInContainer(dirUrl);

          if (resources.files.contains(oldFilename)) {
            await deleteFile('healthpod/data/vaccination/$oldFilename');
          } else {
            // Check if there's a file with a similar name.

            final baseFilename =
                'vaccination_${formatTimestampForFilename(oldObservation.timestamp).split('T')[0]}';
            final matchingFiles = resources.files
                .where((file) => file.startsWith(baseFilename))
                .toList();

            if (matchingFiles.isNotEmpty) {
              await deleteFile(
                  'healthpod/data/vaccination/${matchingFiles.first}');
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
        'vaccination/$newFilename',
        jsonData,
        context,
        const Text('Saving'),
        encrypted: true,
      );
    } catch (e) {
      debugPrint('Error saving observation: $e');
      throw Exception('Failed to save vaccination observation: $e');
    }
  }

  /// Delete an observation's file from Pod.

  Future<void> deleteObservationFromPod(
    BuildContext context,
    VaccinationObservation observation,
  ) async {
    try {
      // Log the resources in the directory for debugging.

      final dirUrl = await getDirUrl('healthpod/data/vaccination');
      final resources = await getResourcesInContainer(dirUrl);

      debugPrint('SubDirs: |${resources.subDirs.join(', ')}|');
      debugPrint('Files  : |${resources.files.join(', ')}|');

      // Try with the current format (T separator).

      final filename = _filenameFromTimestamp(observation.timestamp);

      // Also try with the old format (underscore separator) for backward compatibility.

      final filenameWithUnderscore =
          'vaccination_${formatTimestampForFilenameWithUnderscore(observation.timestamp)}.json.enc.ttl';

      // Check if either file exists.

      if (resources.files.contains(filename)) {
        await deleteFile('healthpod/data/vaccination/$filename');
        debugPrint('Deleted file: $filename');
        return;
      } else if (resources.files.contains(filenameWithUnderscore)) {
        await deleteFile('healthpod/data/vaccination/$filenameWithUnderscore');
        debugPrint('Deleted file with underscore: $filenameWithUnderscore');
        return;
      }

      // If neither exact match is found, try to find a file with a similar date part.

      debugPrint('File not found for deletion: $filename');

      // Extract just the date part (YYYY-MM-DD) from the timestamp.

      final datePart =
          formatTimestampForFilename(observation.timestamp).split('T')[0];
      final baseFilename = 'vaccination_$datePart';

      // Find any files that start with this date part.

      final matchingFiles = resources.files
          .where((file) => file.startsWith(baseFilename))
          .toList();

      if (matchingFiles.isNotEmpty) {
        // Delete the first matching file.

        await deleteFile('healthpod/data/vaccination/${matchingFiles.first}');
        debugPrint('Deleted alternative file: ${matchingFiles.first}');
      } else {
        // No matching files found, try a more flexible approach.

        // Look for any file that contains the date (without the time).

        final moreFlexibleMatches =
            resources.files.where((file) => file.contains(datePart)).toList();

        if (moreFlexibleMatches.isNotEmpty) {
          await deleteFile(
              'healthpod/data/vaccination/${moreFlexibleMatches.first}');
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

      throw Exception('Failed to delete vaccination observation: $e');
    }
  }

  /// Helper to generate the consistent file name from an observation's timestamp.

  String _filenameFromTimestamp(DateTime dt) {
    final formatted = formatTimestampForFilename(dt);
    return 'vaccination_$formatted.json.enc.ttl';
  }
}
