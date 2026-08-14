/// Survey data widget.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Ashley Tang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';

/// Survey data widget.
///
/// This service handles the retrieval of survey data from remote POD storage.
/// Ensures all data is fetched, sorted and ready for use.

class SurveyData {
  // Fetch from directory where blood pressure-related survey data resides.

  static const String bpDir = '$basePath/blood_pressure';

  /// Fetches survey data from POD, ensuring it is sorted by timestamp.
  ///
  /// Can potentially fetch from local storage as well, but this is omitted for now,
  /// as we assume all relevant bp data is stored in POD or uploaded from local already.
  /// Acts as main entry point.

  static Future<List<Map<String, dynamic>>> fetchAllSurveyData(
    BuildContext context,
  ) async {
    List<Map<String, dynamic>> allData = [];

    // Fetch POD data.

    if (context.mounted) {
      final podData = await fetchPodSurveyData();
      allData.addAll(podData);
    }

    return sortAndDeduplicate(allData);
  }

  /// Sorts entries by timestamp and drops entries sharing a timestamp.
  ///
  /// Every observation is kept, including several on the same day - only an
  /// exact repeat of a timestamp (the same observation read twice) is dropped.

  static List<Map<String, dynamic>> sortAndDeduplicate(
    List<Map<String, dynamic>> data,
  ) {
    final Map<String, Map<String, dynamic>> uniqueEntries = {};

    for (var entry in data) {
      uniqueEntries[DateTime.parse(entry['timestamp']).toIso8601String()] =
          entry;
    }

    final entries = uniqueEntries.values.toList();
    entries.sort(
      (a, b) => DateTime.parse(
        a['timestamp'],
      ).compareTo(DateTime.parse(b['timestamp'])),
    );

    return entries;
  }

  /// Fetches survey data from POD storage.

  static Future<List<Map<String, dynamic>>> fetchPodSurveyData() async {
    List<Map<String, dynamic>> podData = [];
    try {
      // Get the directory URL for the bp folder.

      final dirUrl = await getDirUrl(bpDir);

      // Get resources in the container.

      final resources = await getResourcesInContainer(dirUrl);

      // Process each file in the directory.

      for (var fileName in resources.files) {
        if (!fileName.endsWith('.enc.ttl')) continue;

        // Construct the full path including healthpod/data/blood_pressure.

        final filePath = '$bpDir/$fileName';

        // Read the file content.

        String result;
        try {
          result = await readPod(
            filePath,
            pathType: PathType.relativeToPod,
          );
        } catch (e) {
          // File might not exist anymore (deleted, moved, or corrupted).

          debugPrint('Error reading survey file $fileName: $e');
          continue;
        }

        // Handle the response based on its type.

        if (result != SolidFunctionCallStatus.fail.toString() &&
            result != SolidFunctionCallStatus.notLoggedIn.toString()) {
          try {
            // Check if returns RDF instead of JSON.

            if (result.toString().startsWith('@prefix') ||
                result.toString().contains('<http')) {
              continue;
            }

            // The result is the JSON string directly.
            final data = json.decode(result.toString());
            podData.add(data);
          } catch (e) {
            debugPrint('Error parsing file $fileName: $e');
            debugPrint('Content: $result');
          }
        } else {
          debugPrint('Failed to read file $fileName: $result');
        }
      }
    } catch (e) {
      debugPrint('Error fetching POD survey data: $e');
      debugPrint('Error details: ${e.toString()}');
    }
    return podData;
  }
}
