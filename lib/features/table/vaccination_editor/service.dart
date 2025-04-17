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

import 'package:healthpod/utils/delete_pod_file_with_fallback.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Handles loading/saving/deleting vaccination observations from the Pod.

class VaccinationEditorService {
  /// The type of data being handled.
  static const String feature = 'vaccination';

  /// Load all vaccination observations from `healthpod/data/vaccinations` directory.

  Future<List<VaccinationObservation>> loadData(BuildContext context) async {
    final podDirPath = getFeaturePath(feature);
    final dirUrl = await getDirUrl(podDirPath);
    final resources = await getResourcesInContainer(dirUrl);

    final List<VaccinationObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      final filePath = getFeaturePath(feature, file);
      final content = await readPod(
        filePath,
        context,
        const Text('Loading file'),
      );
      if (content == SolidFunctionCallStatus.fail.toString() ||
          content == SolidFunctionCallStatus.notLoggedIn.toString()) {
        continue;
      }

      try {
        final data = json.decode(content.toString());
        // Convert null values to empty strings in the responses map
        if (data['responses'] != null) {
          final responses = data['responses'] as Map<String, dynamic>;
          responses.forEach((key, value) {
            if (value == null) {
              responses[key] = '';
            }
          });
        }
        loadedObservations.add(VaccinationObservation.fromJson(data));
      } catch (e) {
        debugPrint('Error parsing file $file: $e');
        // Continue with next file instead of stopping
        continue;
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

          final podDirPath = getFeaturePath(feature);
          final dirUrl = await getDirUrl(podDirPath);
          final resources = await getResourcesInContainer(dirUrl);

          // Use the utility function to handle file deletion with fallback options.

          await deletePodFileWithFallback(
            dataType: feature,
            filename: oldFilename,
            timestamp: oldObservation.timestamp,
            resources: resources,
          );
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
        '$feature/$newFilename',
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

      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      // Try with the current format (T separator).

      final filename = _filenameFromTimestamp(observation.timestamp);

      // Use the utility function to handle file deletion with fallback options.

      final deleted = await deletePodFileWithFallback(
        dataType: feature,
        filename: filename,
        timestamp: observation.timestamp,
        resources: resources,
      );

      if (!deleted) {
        // If no file was deleted, throw an exception.

        throw Exception('No matching file found for deletion');
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
    return '${feature}_$formatted.json.enc.ttl';
  }
}
