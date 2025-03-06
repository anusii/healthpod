/// Vaccination data service.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

/// Vaccination data service.
///
/// This service handles the retrieval of vaccination data from remote POD storage.
/// Ensures all data is fetched, sorted and ready for use.

class VaccinationData {
  /// Directory where vaccination-related data resides.

  static const String vaccinationDir = 'healthpod/data/vaccination';

  /// Fetches vaccination data from POD, ensuring it is sorted by timestamp.
  ///
  /// Can potentially fetch from local storage as well, but this is omitted for now,
  /// as we assume all relevant vaccination data is stored in POD or uploaded from local already.
  /// Acts as main entry point.

  static Future<List<Map<String, dynamic>>> fetchAllVaccinationData(
      BuildContext context) async {
    List<Map<String, dynamic>> allData = [];

    /// Fetch POD data.

    if (context.mounted) {
      final podData = await fetchPodVaccinationData(context);
      allData.addAll(podData);
    }

    /// Sort all data by timestamp (most recent first).

    allData.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));

    return allData;
  }

  /// Fetches vaccination data from POD storage.

  static Future<List<Map<String, dynamic>>> fetchPodVaccinationData(
      BuildContext context) async {
    List<Map<String, dynamic>> podData = [];
    try {
      /// Get the directory URL for the vaccination folder.

      final dirUrl = await getDirUrl(vaccinationDir);

      /// Get resources in the container.

      final resources = await getResourcesInContainer(dirUrl);

      debugPrint('SubDirs: |${resources.subDirs.join('|')}|');
      debugPrint('Files  : |${resources.files.join('|')}|');

      /// Process each file in the directory.

      for (var fileName in resources.files) {
        if (!fileName.endsWith('.enc.ttl')) continue;

        /// Construct the full path including healthpod/data/vaccination.

        final filePath = '$vaccinationDir/$fileName';

        if (!context.mounted) break;

        /// Read the file content.

        final result = await readPod(
          filePath,
          context,
          const Text('Reading vaccination data'),
        );

        /// Handle the response based on its type.

        if (result != SolidFunctionCallStatus.fail &&
            result != SolidFunctionCallStatus.notLoggedIn) {
          try {
            /// Parse the JSON string result.

            final data = json.decode(result.toString());
            podData.add(data);
            debugPrint('Vaccination data loaded: ${data['timestamp']}');
          } catch (e) {
            debugPrint('Error parsing vaccination file $fileName: $e');
            debugPrint('Content: $result');
          }
        } else {
          debugPrint('Failed to read vaccination file $fileName: $result');
        }
      }
    } catch (e) {
      debugPrint('Error fetching POD vaccination data: $e');
      debugPrint('Error details: ${e.toString()}');
    }
    return podData;
  }
}
