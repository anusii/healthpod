/// Profile data importer.
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/profile/dialogs/profile_import_dialogs.dart';
import 'package:healthpod/features/profile/managers/profile_file_manager.dart';
import 'package:healthpod/features/profile/validators/profile_validator.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Class that handles the import of profile data from JSON file.

class ProfileImporter {
  /// Imports profile data from a JSON file.
  ///
  /// Returns true if import was successful.
  ///
  /// Parameters:
  /// - [filePath]: Path to the JSON file
  /// - [targetPath]: Target directory path on the POD
  /// - [context]: BuildContext for UI interactions
  /// - [onSuccess]: Optional callback for successful import

  static Future<bool> importJson(
    String filePath,
    String targetPath,
    BuildContext context, {
    void Function()? onSuccess,
  }) async {
    try {
      // Read the file.

      final file = File(filePath);
      final jsonString = await file.readAsString();

      // Attempt to parse the JSON.

      Map<String, dynamic> profileData;
      try {
        profileData = jsonDecode(jsonString);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid JSON format: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      // Validate the profile data.

      final validationResult =
          ProfileValidator.validateProfileData(profileData);

      if (!validationResult['isValid']) {
        // Show validation error dialog instead of a snackbar.

        if (context.mounted) {
          await ProfileImportDialogs.showValidationErrorDialog(
            context,
            'Invalid profile data: ${validationResult['message']}',
          );
        }
        return false;
      }

      // Show confirmation dialog with the validated data.

      if (context.mounted) {
        final confirmImport = await ProfileImportDialogs.showConfirmationDialog(
          context,
          validationResult['data'] as Map<String, dynamic>,
        );

        if (!confirmImport) {
          return false;
        }
      }

      // Extract the validated data.

      final finalData = validationResult['data'] as Map<String, dynamic>;

      // Add timestamp if not present, otherwise use the existing one.

      String timestampString;
      if (!finalData.containsKey('timestamp')) {
        timestampString = DateTime.now().toIso8601String();
        finalData['timestamp'] = timestampString;
      } else {
        timestampString = finalData['timestamp'] as String;
      }

      // Check if timestamp is nested inside 'data' object.

      if (finalData.containsKey('data') &&
          finalData['data'] is Map<String, dynamic> &&
          (finalData['data'] as Map<String, dynamic>)
              .containsKey('timestamp')) {
        final nestedTimestamp =
            (finalData['data'] as Map<String, dynamic>)['timestamp'];
        if (nestedTimestamp is String) {
          timestampString = nestedTimestamp;
          // Update the top-level timestamp to match the nested one.

          finalData['timestamp'] = timestampString;
        }
      }

      // Parse the timestamp to ensure it's in a valid format.

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampString);
      } catch (e) {
        timestamp = DateTime.now();
        timestampString = timestamp.toIso8601String();
        finalData['timestamp'] = timestampString;
      }

      // Normalise the target path to always use the 'profile' subdirectory.

      final normalizedPath = 'profile';

      // Check for existing profiles and prompt for confirmation if found.

      if (context.mounted) {
        List<String> existingProfiles = [];
        try {
          existingProfiles = await ProfileFileManager.checkForExistingProfiles(
            context,
            timestampString,
          );
        } catch (e) {
          // Log error but continue with the import process.

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: Could not check for existing profiles: ${e.toString()}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Only show the dialog if actual profiles were found.

        if (existingProfiles.isNotEmpty) {
          if (!context.mounted) return false;
          final shouldOverride =
              await ProfileImportDialogs.showOverrideConfirmationDialog(
            context,
            existingProfiles,
          );

          if (!shouldOverride) {
            return false;
          }

          if (!context.mounted) return false;

          // Try to delete existing profiles but continue even if deletion fails.

          try {
            await ProfileFileManager.deleteExistingProfiles(
              context,
              existingProfiles,
            );
          } catch (e) {
            // Show warning but continue with import.

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Warning: Could not delete existing profiles. The import will continue but you may have duplicate data. Error: ${e.toString()}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      // Create a formatted timestamp for the filename using the timestamp from the data.

      final formattedTimestamp = formatTimestampForFilename(timestamp);
      final filename = 'profile_$formattedTimestamp.json';

      // Prepare the JSON content.

      final jsonContent = json.encode(finalData);

      // Upload to POD with encryption.

      if (!context.mounted) return false;

      // Use the same pattern as in SurveyData and BPObservation.

      final fullPath = '$normalizedPath/$filename.enc.ttl';

      final result = await writePod(
        fullPath,
        jsonContent,
        context,
        const Text('Saving profile data'),
        encrypted: true,
      );

      if (result == SolidFunctionCallStatus.success) {
        onSuccess?.call();
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
