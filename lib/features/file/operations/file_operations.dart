/// File operations utility class for handling file system interactions.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/file/models/item.dart';

/// A utility class for performing file system operations in the POD.
///
/// This class provides static methods for:
/// - Retrieving and processing files from directories.
/// - Counting files in directories.
/// - Managing file metadata and validation.
///
/// All operations are performed asynchronously and handle errors gracefully.

class FileOperations {
  /// Retrieves and processes files from the specified directory.
  ///
  /// This method:
  /// - Fetches all files from the given directory.
  /// - Filters for files ending with '.enc.ttl'.
  /// - Validates each file's accessibility.
  /// - Creates [FileItem] objects with metadata.
  ///
  /// Parameters:
  /// - [currentPath]: The directory path to process.
  /// - [context]: Build context for UI operations.
  ///
  /// Returns a list of processed [FileItem] objects.

  static Future<List<FileItem>> getFiles(
      String currentPath, BuildContext context) async {
    // Get directory URL and contents.

    final dirUrl = await getDirUrl(currentPath);
    final resources = await getResourcesInContainer(dirUrl);

    // Process each file in the directory.

    final processedFiles = <FileItem>[];
    for (var fileName in resources.files) {
      // Skip non-encrypted TTL files.

      if (!fileName.endsWith('.enc.ttl')) continue;

      // Construct full path.

      final relativePath = '$currentPath/$fileName';

      if (!context.mounted) continue;

      // Read file metadata.

      final metadata = await readPod(
        relativePath,
        context,
        const Text('Reading file info'),
      );

      // Add valid files to the processed list.

      if (metadata != SolidFunctionCallStatus.fail &&
          metadata != SolidFunctionCallStatus.notLoggedIn) {
        processedFiles.add(FileItem(
          name: fileName,
          path: relativePath,
          dateModified: DateTime.now(),
        ));
      }
    }
    return processedFiles;
  }

  /// Gets the file count for each subdirectory.
  ///
  /// This method:
  /// - Processes each directory in the provided list.
  /// - Counts files ending with '.enc.ttl' in each directory.
  /// - Returns a map of directory names to their file counts.
  ///
  /// Parameters:
  /// - [currentPath]: The parent directory path.
  /// - [directories]: List of subdirectory names to process.
  ///
  /// Returns a map of directory names to their file counts.

  static Future<Map<String, int>> getDirectoryCounts(
    String currentPath,
    List<String> directories,
  ) async {
    // Count files in each subdirectory.

    final counts = <String, int>{};
    for (var dir in directories) {
      counts[dir] = await getDirectoryFileCount('$currentPath/$dir');
    }
    return counts;
  }

  /// Counts the number of files in a directory.
  ///
  /// This method:
  /// - Retrieves the directory contents.
  /// - Counts files ending with '.enc.ttl'.
  /// - Handles errors gracefully.
  ///
  /// Parameters:
  /// - [dirPath]: The directory path to count files in.
  ///
  /// Returns the number of files in the directory, or 0 if an error occurs.

  static Future<int> getDirectoryFileCount(String dirPath) async {
    try {
      // Get directory contents and count files.

      final dirUrl = await getDirUrl(dirPath);
      final resources = await getResourcesInContainer(dirUrl);
      return resources.files.where((f) => f.endsWith('.enc.ttl')).length;
    } catch (e) {
      debugPrint('Error counting files in directory: $e');
      return 0;
    }
  }
}
