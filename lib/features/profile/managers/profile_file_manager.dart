/// File management utilities for profile operations.
///
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Utility class for managing profile files.

class ProfileFileManager {
  const ProfileFileManager._();

  /// Checks for existing profiles and returns a list of profile files.
  ///
  /// This method checks the profile directory for any existing profile files
  /// that would be overridden by a new import.

  static Future<List<String>> checkForExistingProfiles(
    BuildContext context,
    String timestampString,
  ) async {
    try {
      // Parse the incoming timestamp.

      DateTime importTimestamp;
      try {
        importTimestamp = DateTime.parse(timestampString);
      } catch (e) {
        // If we can't parse the timestamp, just use the current time.

        importTimestamp = DateTime.now();
      }

      // Format the timestamp how it would appear in a filename.

      final formattedTimestamp = formatTimestampForFilename(importTimestamp);

      // Try different path approaches to find existing files.

      List<String> profileFiles = [];

      // Only check the known path where profile files are stored.

      final profilePath = '$basePath/profile';

      try {
        final dirUrl = await getDirUrl(profilePath);
        final resources = await getResourcesInContainer(dirUrl);

        profileFiles = resources.files
            .where(
              (file) =>
                  file.startsWith('profile_') && file.endsWith('.json.enc.ttl'),
            )
            .toList();
      } catch (e) {
        // Rethrow with more specific information for better troubleshooting.

        throw Exception('Failed to access profile directory: $e');
      }

      // Process the results.

      if (profileFiles.isNotEmpty) {
        // Check if any files match our expected filename pattern.

        final matchingFiles = profileFiles
            .where((file) => file.contains(formattedTimestamp))
            .toList();

        if (matchingFiles.isNotEmpty) {
          return matchingFiles;
        }

        // If no exact matches, return all profile files.

        return profileFiles;
      }

      return [];
    } catch (e) {
      // Log the error and rethrow to propagate to the calling method.

      throw Exception('Error checking for existing profiles: $e');
    }
  }

  /// Deletes existing profile files.

  static Future<void> deleteExistingProfiles(
    BuildContext context,
    List<String> existingProfiles,
  ) async {
    try {
      // Use the same path where the files are actually stored.

      final normalizedPath = '$basePath/profile';

      for (final filename in existingProfiles) {
        try {
          final filePath = '$normalizedPath/$filename';

          // Try to delete the file using SolidPod's deleteFile function.

          try {
            await deleteFile(filePath);
          } catch (deleteError) {
            // Check if it's a "not found" error (404).

            if (deleteError.toString().contains('404') ||
                deleteError.toString().contains('NotFoundHttpError')) {
              // Try alternative paths if needed.

              final alternativePaths = [
                'profile/$filename',
                filename,
                'profile/profile_$filename',
              ];

              bool deleted = false;
              for (final altPath in alternativePaths) {
                await deleteFile(altPath);
                deleted = true;
                break;
              }

              if (!deleted) {
                // If both paths fail, throw exception with both error details.

                throw Exception(
                  'Failed to delete profile using both paths. Primary error: $deleteError',
                );
              }
            } else {
              // For other errors, throw an exception.

              throw Exception('Failed to delete profile file: $deleteError');
            }
          }
        } catch (fileError) {
          // Throw to let calling code know about the failure.

          throw Exception(
            'Error processing profile file $filename: $fileError',
          );
        }
      }
    } catch (e) {
      // Rethrow with clear context about the operation that failed.

      throw Exception('Failed to delete existing profiles: $e');
    }
  }
}
