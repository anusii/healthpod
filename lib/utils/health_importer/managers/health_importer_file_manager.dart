/// File management utilities for health data importer operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
/// Authors: Kevin Wang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';

/// Utility class for managing health data importer files.

class HealthImporterFileManager {
  const HealthImporterFileManager._();

  /// Check for existing files that would be overridden by this import.
  ///
  /// This method checks if there are existing files with the same timestamps
  /// in the specified directory.

  static Future<List<String>> checkForExistingFiles(
    String dataType,
    String dirPath,
    List<String> timestamps,
  ) async {
    try {
      // Only check the known working path where health data files are stored.

      final String dataPath = '$basePath/$dataType';

      try {
        final dirUrl = await getDirUrl(dataPath);
        final resources = await getResourcesInContainer(dirUrl);

        // Extract date parts from existing files for comparison.

        final existingFiles = resources.files
            .where(
              (file) =>
                  file.startsWith('${dataType}_') &&
                  file.endsWith('.json.enc.ttl'),
            )
            .toList();

        // Create date-based lookup index for faster comparison.

        final Map<String, List<String>> existingFileDateIndex = {};

        for (final file in existingFiles) {
          // Extract date part from filename (everything between dataType_ and T).
          // Use string operations instead of RegExp to avoid web compatibility
          // issues.

          final prefix = '${dataType}_';
          if (file.startsWith(prefix) && file.contains('T')) {
            final afterPrefix = file.substring(prefix.length);
            final tIndex = afterPrefix.indexOf('T');

            // Ensure we have at least YYYY-MM-DD format.

            if (tIndex >= 10) {
              final dateStr = afterPrefix.substring(0, tIndex);

              // Validate the date format (YYYY-MM-DD).

              if (dateStr.length >= 10 &&
                  dateStr[4] == '-' &&
                  dateStr[7] == '-') {
                final datePart = dateStr.substring(
                  0,
                  10,
                ); // Take only YYYY-MM-DD
                if (!existingFileDateIndex.containsKey(datePart)) {
                  existingFileDateIndex[datePart] = [];
                }
                existingFileDateIndex[datePart]!.add(file);
              }
            }
          }
        }

        // Create a list to store the duplicate file names.

        final duplicateFiles = <String>[];

        // Extract just the date part from each timestamp (YYYY-MM-DD).

        for (final timestamp in timestamps) {
          // Extract the date part before any 'T' character.

          final datePart = timestamp.split('T')[0];

          // Check if we have any files with this date.

          if (existingFileDateIndex.containsKey(datePart)) {
            // Add all files with this date to duplicates.

            duplicateFiles.addAll(existingFileDateIndex[datePart]!);
          }
        }

        // Return unique list of duplicate files.

        return duplicateFiles.toSet().toList();
      } catch (resourceError) {
        throw Exception(
          'Failed to access resources in $dataPath: $resourceError',
        );
      }
    } catch (e) {
      throw Exception('Error checking for existing files: $e');
    }
  }

  /// Helper method to check if a file exists in the POD.
  ///
  /// This is a check that attempts to determine if a file exists
  /// by checking the file listing from the directory or using a direct method.

  static Future<bool> fileExistsInPod(String dataType, String filePath) async {
    try {
      // Extract file name from path.
      final parts = filePath.split('/');
      final fileName = parts.last;

      // Try to access the directory containing the file.
      final dirPath =
          parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';

      try {
        // Try to get directory listing.
        final dirUrl = await getDirUrl(dirPath);
        final resources = await getResourcesInContainer(dirUrl);

        // Check if file exists in directory.
        final exists = resources.files.contains(fileName);

        if (exists) {
          return true;
        } else {
          // Try alternative path formats.
          final alternativePaths = [
            dataType,
            '$dataType/$fileName',
            '$basePath/$dataType',
            '$basePath/$dataType/$fileName',
          ];

          for (final altPath in alternativePaths) {
            final altDirUrl = await getDirUrl(altPath);
            final altResources = await getResourcesInContainer(altDirUrl);

            if (altResources.files.contains(fileName)) {
              return true;
            }
          }
          return false;
        }
      } catch (e) {
        throw Exception('Failed to access directory $dirPath: $e');
      }
    } catch (e) {
      throw Exception('Error checking if file exists: $e');
    }
  }

  /// Deletes existing files before importing new ones.
  ///
  /// This method deletes files that would be overridden by the import operation.

  static Future<void> deleteExistingFiles(
    BuildContext context,
    String dataType,
    String dirPath,
    List<String> filesToDelete,
  ) async {
    try {
      final String dataPath = '$basePath/$dataType';

      // Attempt to delete each file.

      for (final fileName in filesToDelete) {
        try {
          // Construct the full path.

          final fullPath = '$dataPath/$fileName';

          try {
            if (context.mounted) {
              await deleteFile(fullPath);
            }
          } catch (deleteError) {
            throw Exception('Failed to delete file $fullPath: $deleteError');
          }
        } catch (e) {
          throw Exception('Error processing file $fileName: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to delete existing files: $e');
    }
  }
}
