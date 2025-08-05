/// Survey data widget.
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
      BuildContext context) async {
    List<Map<String, dynamic>> allData = [];

    // Fetch POD data.

    if (context.mounted) {
      final podData = await fetchPodSurveyData(context);
      allData.addAll(podData);
    }

    // Sort all data by timestamp.

    allData.sort((a, b) => DateTime.parse(a['timestamp'])
        .compareTo(DateTime.parse(b['timestamp'])));

    // Remove duplicate date entries - keeping only the latest entry for each day.

    final Map<String, Map<String, dynamic>> uniqueDayEntries = {};

    for (var entry in allData) {
      final dateTime = DateTime.parse(entry['timestamp']);
      final dateKey = '${dateTime.year}-${dateTime.month}-${dateTime.day}';

      // Only overwrite if it's a later time on the same day.

      if (!uniqueDayEntries.containsKey(dateKey) ||
          DateTime.parse(uniqueDayEntries[dateKey]!['timestamp'])
              .isBefore(dateTime)) {
        uniqueDayEntries[dateKey] = entry;
      }
    }

    // Convert back to list and re-sort.

    allData = uniqueDayEntries.values.toList();
    allData.sort((a, b) => DateTime.parse(a['timestamp'])
        .compareTo(DateTime.parse(b['timestamp'])));

    return allData;
  }

  /// Fetches survey data from POD storage.

  static Future<List<Map<String, dynamic>>> fetchPodSurveyData(
      BuildContext context) async {
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

        if (!context.mounted) break;

        // Read the file content.

        final result = await readPod(
          filePath,
          context,
          const Text('Reading survey data'),
        );

        // Handle the response based on its type.

        if (result != SolidFunctionCallStatus.fail.toString() &&
            result != SolidFunctionCallStatus.notLoggedIn.toString()) {
          try {
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
