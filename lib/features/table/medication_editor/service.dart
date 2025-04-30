/// Medication editor service.
///
// Time-stamp: <Tuesday 2025-04-29 15:45:00 +1000 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/utils/get_feature_path.dart';

/// Service for loading, saving, and deleting medication observations from POD storage.
///
/// This service handles the data operations for the medication editor, including
/// fetching data from POD, saving edited observations, and deleting observations.

class MedicationEditorService {
  /// The type of data being handled.

  static const String feature = 'medication';

  /// Loads medication observations from POD storage.
  ///
  /// Fetches all medication records from the medication directory, decrypts them,
  /// and parses them into MedicationObservation objects.
  ///
  /// @param context The build context for POD operations.
  /// @returns A list of MedicationObservation objects.

  Future<List<MedicationObservation>> loadData(BuildContext context) async {
    List<MedicationObservation> observations = [];

    try {
      // Get the directory URL for the medication folder.

      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);

      // Get resources in the container.

      final resources = await getResourcesInContainer(dirUrl);

      // Process each file in the directory.

      for (final fileName in resources.files) {
        if (!fileName.endsWith('.enc.ttl')) continue;

        // Construct the full path.

        final filePath = getFeaturePath(feature, fileName);
        if (!context.mounted) break;

        // Read the file content.

        final result = await readPod(
          filePath,
          context,
          const Text('Reading medication data'),
        );

        // Parse data if read was successful.

        if (result != SolidFunctionCallStatus.fail.toString() &&
            result != SolidFunctionCallStatus.notLoggedIn.toString()) {
          try {
            // The result is a JSON string.

            final data = json.decode(result.toString());

            // Create a MedicationObservation from JSON.

            final observation = MedicationObservation.fromJson(data);

            observations.add(observation);
          } catch (e) {
            debugPrint('Error parsing file $fileName: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading medication data: $e');
      rethrow;
    }

    return observations;
  }

  /// Saves a medication observation to POD storage.
  ///
  /// Converts the observation to JSON and saves it as an encrypted file in the
  /// medication directory. Uses a timestamp-based filename to ensure uniqueness.
  /// When editing an existing record, the old record is deleted first.
  ///
  /// @param context The build context for POD operations.
  /// @param observation The medication observation to save.
  /// @param isEdit Whether this is an edit of an existing record (true) or a new record (false).
  /// @param oldObservation The original observation being edited, if applicable.
  /// @returns A Future that completes when the save operation is done.

  Future<void> saveObservationToPod(
      BuildContext context, MedicationObservation observation,
      {bool isEdit = false, MedicationObservation? oldObservation}) async {
    try {
      // Check valid logged in status.

      final webID = await getWebId();
      if (webID == null || webID == 'NO_WEBID' || webID.isEmpty) {
        throw Exception('Not logged in to a POD');
      }

      // If this is an edit of an existing observation, delete the old file first.

      if (isEdit && oldObservation != null) {
        try {
          // Get directory contents.

          final podDirPath = getFeaturePath(feature);
          final dirUrl = await getDirUrl(podDirPath);
          final resources = await getResourcesInContainer(dirUrl);

          if (!context.mounted) return;

          // Try to find and delete the old file.

          await _findAndDeleteObservation(context, oldObservation, resources);
        } catch (e) {
          // Log the error but continue with saving the new version.

          debugPrint('Error deleting old medication record: $e');
        }
      }

      // Generate a timestamp-based filename.

      final now = DateTime.now();
      final timestamp = now.toIso8601String().replaceAll(':', '-');
      final filename = 'medication_$timestamp.json.enc.ttl';

      // Convert observation to JSON.

      final jsonString = json.encode(observation.toJson());

      if (!context.mounted) return;

      // Save to POD.

      await writePod(
        '$feature/$filename',
        jsonString,
        context,
        const Text('Saving medication data'),
        encrypted: true,
      );

      // Show success feedback.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving medication observation: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      rethrow;
    }
  }

  /// Helper method to find and delete an existing medication observation.
  ///
  /// Iterates through files in the medication directory to find a matching observation,
  /// then deletes the corresponding file.
  ///
  /// @param context The build context for POD operations.
  /// @param observation The observation to find and delete.
  /// @param resources Container resources with the list of files.
  /// @returns A Future that completes when the delete operation is done.

  Future<void> _findAndDeleteObservation(
    BuildContext context,
    MedicationObservation observation,
    dynamic resources,
  ) async {
    for (final fileName in resources.files) {
      if (!fileName.endsWith('.enc.ttl')) continue;

      final filePath = getFeaturePath(feature, fileName);
      if (!context.mounted) return;

      // Read each file.

      final result = await readPod(
        filePath,
        context,
        const Text('Checking medication data'),
      );

      if (result != SolidFunctionCallStatus.fail.toString() &&
          result != SolidFunctionCallStatus.notLoggedIn.toString()) {
        try {
          final data = json.decode(result.toString());
          final fileObs = MedicationObservation.fromJson(data);

          // Check if this is the observation we want to delete.

          if (fileObs.name == observation.name &&
              fileObs.dosage == observation.dosage &&
              fileObs.frequency == observation.frequency &&
              fileObs.startDate.day == observation.startDate.day &&
              fileObs.startDate.month == observation.startDate.month &&
              fileObs.startDate.year == observation.startDate.year) {
            // Delete the file.

            await deleteFile(filePath);
            debugPrint('Successfully deleted old medication record: $fileName');
            return;
          }
        } catch (e) {
          debugPrint('Error parsing file $fileName for deletion: $e');
        }
      }
    }

    debugPrint('No matching file found for old medication record');
  }

  /// Deletes a medication observation from POD storage.
  ///
  /// Finds the file corresponding to the observation and deletes it from POD.
  /// This operation cannot be undone.
  ///
  /// @param context The build context for POD operations.
  /// @param observation The medication observation to delete.
  /// @returns A Future that completes when the delete operation is done.

  Future<void> deleteObservationFromPod(
    BuildContext context,
    MedicationObservation observation,
  ) async {
    try {
      // Get all files from medication directory.

      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      if (!context.mounted) return;

      // Try to find and delete the observation.

      await _findAndDeleteObservation(context, observation, resources);

      // Show success feedback.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting medication observation: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      rethrow;
    }
  }
}
