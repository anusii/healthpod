/// Vaccination observation service.
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
/// Authors: Kevin Wang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/table/vaccination_editor/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Handles loading/saving/deleting vaccination observations from the Pod.

class VaccinationEditorService {
  /// Load all vaccination observations from `healthpod/data/vaccinations` directory.

  Future<List<VaccinationObservation>> loadData(BuildContext context) async {
    final dirUrl = await getDirUrl('healthpod/data/vaccination');
    final resources = await getResourcesInContainer(dirUrl);

    final List<VaccinationObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      final content = await readPod(
        'healthpod/data/vaccination/$file',
        context,
        const Text('Loading file'),
      );
      if (content == null ||
          content == SolidFunctionCallStatus.fail ||
          content == SolidFunctionCallStatus.notLoggedIn) {
        continue;
      }

      try {
        final data = json.decode(content.toString());
        loadedObservations.add(VaccinationObservation.fromJson(data));
      } catch (e) {
        debugPrint('Error parsing file $file: $e');
      }
    }

    return loadedObservations;
  }

  /// Save a vaccination observation to Pod. If this is an existing observation update,
  /// remove the old file first.

  Future<void> saveObservationToPod({
    required BuildContext context,
    required VaccinationObservation observation,
    required bool isNew,
    required VaccinationObservation? oldObservation,
  }) async {
    // Delete old file if not a new observation.

    if (!isNew && oldObservation != null) {
      final oldFilename = _filenameFromTimestamp(oldObservation.timestamp);
      await deleteFile('healthpod/data/vaccination/$oldFilename');
    }

    // Write new file.

    final newFilename = _filenameFromTimestamp(observation.timestamp);
    final jsonData = json.encode(observation.toJson());

    if (!context.mounted) return;

    await writePod(
      'vaccination/$newFilename',
      jsonData,
      context,
      const Text('Saving'),
      encrypted: true,
    );
  }

  /// Delete an observation's file from Pod.

  Future<void> deleteObservationFromPod(
    BuildContext context,
    VaccinationObservation observation,
  ) async {
    final filename = _filenameFromTimestamp(observation.timestamp);
    await deleteFile('healthpod/data/vaccination/$filename');
  }

  /// Helper to generate the consistent file name from an observation's timestamp.

  String _filenameFromTimestamp(DateTime dt) {
    final formatted = formatTimestampForFilename(dt);
    return 'vaccination_$formatted.json.enc.ttl';
  }
}
