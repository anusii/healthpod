/// Pod storage for the health profile measurements.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Graham Williams

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/health_profile.dart';
import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/utils/delete_pod_file_with_fallback.dart';

/// Reads and removes the health profile records held on the pod.
///
/// Each record is a separate encrypted file, as for the other health data, so
/// the history is kept in full and nothing is overwritten.

class HealthProfileService {
  const HealthProfileService._();

  /// The pod directory the records are kept in.

  static const String dirPath = '$basePath/${HealthProfileConstants.folder}';

  /// Every record held on the pod, oldest first.
  ///
  /// A missing directory means nothing has been recorded yet, which reads as
  /// an empty history rather than an error.

  static Future<List<HealthProfileEntry>> fetchAll() async {
    final entries = <HealthProfileEntry>[];

    try {
      final dirUrl = await getDirUrl(dirPath);
      final resources = await getResourcesInContainer(dirUrl);

      for (final fileName in resources.files) {
        if (!fileName.endsWith('.enc.ttl')) continue;

        String result;
        try {
          result = await readPod(
            '$dirPath/$fileName',
            pathType: PathType.relativeToPod,
          );
        } catch (e) {
          // The file may have been deleted or moved since it was listed.

          debugPrint('Error reading health profile file $fileName: $e');
          continue;
        }

        if (result == SolidFunctionCallStatus.fail.toString() ||
            result == SolidFunctionCallStatus.notLoggedIn.toString()) {
          debugPrint('Failed to read health profile file $fileName');
          continue;
        }

        try {
          final decoded = json.decode(result);
          if (decoded is! Map<String, dynamic>) continue;
          final entry = HealthProfileEntry.fromJson(decoded, fileName);
          if (entry != null) entries.add(entry);
        } catch (e) {
          debugPrint('Error parsing health profile file $fileName: $e');
        }
      }
    } catch (e) {
      debugPrint('Error fetching health profile data: $e');
    }

    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return entries;
  }

  /// The most recent value recorded for each measurement, with its date.

  static Map<String, DatedValue> latestValues(
    List<HealthProfileEntry> entries,
  ) {
    final latest = <String, DatedValue>{};

    for (final entry in entries) {
      entry.values.forEach((field, value) {
        final recorded = latest[field];
        if (recorded == null || recorded.updated.isBefore(entry.timestamp)) {
          latest[field] = (value: value, updated: entry.timestamp);
        }
      });
    }

    return latest;
  }

  /// Removes a single record from the pod.

  static Future<bool> delete(HealthProfileEntry entry) async {
    final dirUrl = await getDirUrl(dirPath);
    final resources = await getResourcesInContainer(dirUrl);

    return deletePodFileWithFallback(
      dataType: HealthProfileConstants.folder,
      filename: entry.filename,
      timestamp: entry.timestamp,
      resources: resources,
    );
  }
}
