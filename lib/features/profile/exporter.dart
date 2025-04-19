/// Profile data exporter.
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

import 'package:healthpod/utils/save_decrypted_content.dart';

/// Class that handles the export of profile data to JSON file.

class ProfileExporter {
  /// Exports profile data from POD to a local JSON file.
  ///
  /// This method finds the most recent profile file and exports it.
  ///
  /// Parameters:
  /// - [outputPath]: Path where the file will be saved
  /// - [podPath]: Path on the POD where profile files are stored
  /// - [context]: BuildContext for UI interactions
  ///
  /// Returns true if export was successful, false otherwise.

  static Future<bool> exportJson(
    String outputPath,
    String podPath,
    BuildContext context,
  ) async {
    try {
      // Get list of files from profile directory.

      if (!context.mounted) return false;

      // Get directory URL and resources in container.

      final dirUrl = await getDirUrl(podPath);
      final resources = await getResourcesInContainer(dirUrl);

      final List<String> files = [];

      // Filter for profile files with .enc.ttl extension.

      for (var fileName in resources.files) {
        if (fileName.startsWith('profile_') && fileName.endsWith('.enc.ttl')) {
          files.add(fileName);
        }
      }

      if (files.isEmpty) {
        throw Exception('No profile files found in the directory');
      }

      // Sort files by timestamp in filename.

      files.sort((a, b) {
        // Extract timestamp from filename (profile_YYYY-MM-DDTHH-MM-SS.json.enc.ttl).

        final aTimestamp = a.substring(8, a.indexOf('.json'));
        final bTimestamp = b.substring(8, b.indexOf('.json'));
        // Descending order.

        return bTimestamp.compareTo(aTimestamp);
      });

      // Get the most recent file.

      final mostRecentFile = files.first;
      final filePath = '$podPath/$mostRecentFile';

      debugPrint('Exporting most recent profile file: $filePath');

      if (!context.mounted) return false;

      // Prompt for security key if needed.

      await getKeyFromUserIfRequired(
        context,
        const Text('Please enter your security key to export profile data'),
      );

      if (!context.mounted) return false;

      // Read the file content.

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Downloading profile data'),
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception(
            'Download failed - please check your connection and permissions');
      }

      // Save the decrypted content to the specified output path.

      await saveDecryptedContent(fileContent, outputPath);

      return true;
    } catch (e) {
      debugPrint('Error exporting profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
