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

import 'package:solidpod/solidpod.dart'
    show
        SolidFunctionCallStatus,
        getResourcesInContainer,
        getDirUrl,
        readPod,
        writePod,
        getKeyFromUserIfRequired;

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/utils/delete_pod_file_with_fallback.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Handles loading/saving/deleting BP observations from the Pod.

class BPEditorService {
  /// The type of data being handled.

  static const String feature = 'blood_pressure';

  /// Load all BP observations from `healthpod/data/blood_pressure` directory.

  Future<List<BPObservation>> loadData(BuildContext context) async {
    final podDirPath = getFeaturePath(feature);
    final dirUrl = await getDirUrl(podDirPath);
    final resources = await getResourcesInContainer(dirUrl);

    final List<BPObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      // Use relative path for file operations to match writePod behaviour.

      final filePath = '$feature/$file';

      // Prompt for security key if needed.

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to access your health data'),
      );

      if (!context.mounted) continue;

      String content;
      try {
        content = await readPod(
          filePath,
          context,
          const Text('Loading file'),
        );
      } catch (e) {
        debugPrint('Error reading file $file (first attempt): $e');

        // Retry once for potential CSS v7.1.7 intermittent issues
        try {
          debugPrint('Retrying file read for $file...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (!context.mounted) continue;
          content = await readPod(
            filePath,
            context,
            const Text('Retrying file load'),
          );
          debugPrint('Retry successful for file $file');
        } catch (retryError) {
          debugPrint('Retry failed for file $file: $retryError');
          debugPrint('❌ Retry failed, file still encrypted');
          continue;
        }
      }

      if (content == SolidFunctionCallStatus.fail.toString() ||
          content == SolidFunctionCallStatus.notLoggedIn.toString()) {
        continue;
      }

      try {
        // Check if returns RDF instead of JSON.

        if (content.toString().startsWith('@prefix') ||
            content.toString().contains('<http')) {
          continue;
        }

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

      throw Exception('Failed to delete blood pressure observation: $e');
    }
  }

  /// Helper to generate the consistent file name from an observation's timestamp.

  String _filenameFromTimestamp(DateTime dt) {
    final formatted = formatTimestampForFilename(dt);
    return '${feature}_$formatted.json.enc.ttl';
  }
}
