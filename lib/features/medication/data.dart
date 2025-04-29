/// Medication data service.
///
// Time-stamp: <Tuesday 2025-04-29 10:15:00 +1000 Graham Williams>
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

import 'package:healthpod/constants/paths.dart';

/// Medication data service.
///
/// This service handles the retrieval of medication data from remote POD storage.
/// Ensures all data is fetched, sorted and ready for use.

class MedicationData {
  /// Directory where medication-related data resides.

  static const String medicationDir = '$basePath/medication';

  /// Fetches medication data from POD, ensuring it is sorted by timestamp.
  ///
  /// Can potentially fetch from local storage as well, but this is omitted for now,
  /// as we assume all relevant medication data is stored in POD or uploaded from local already.
  /// Acts as main entry point.

  static Future<List<Map<String, dynamic>>> fetchAllMedicationData(
      BuildContext context) async {
    List<Map<String, dynamic>> allData = [];

    // Fetch POD data.

    try {
      final dirUrl = await getDirUrl(medicationDir);
      final resources = await getResourcesInContainer(dirUrl);

      for (final item in resources.files) {
        if (item.endsWith('.json') || item.endsWith('.enc.ttl')) {
          final filePath = '$medicationDir/$item';
          if (!context.mounted) continue;

          final content = await readPod(
            filePath,
            context,
            const Text('Reading medication data'),
          );

          if (content != SolidFunctionCallStatus.fail.toString() &&
              content != SolidFunctionCallStatus.notLoggedIn.toString()) {
            try {
              final data = jsonDecode(content.toString());
              if (data is Map<String, dynamic>) {
                allData.add(data);
              }
            } catch (e) {
              debugPrint('Error parsing medication JSON from $filePath: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching medication data from POD: $e');
    }

    // Sort by timestamp (most recent first).

    allData.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp'].toString());
      final bTime = DateTime.parse(b['timestamp'].toString());
      return bTime.compareTo(aTime);
    });

    return allData;
  }
}
