/// Blood pressure observation service.
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/bp/obs/model.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/get_secret_key.dart';

/// Handles loading/saving/deleting BP observations from the Pod.

class BPEditorService {
  /// Load all BP observations from `healthpod/data/blood_pressure` directory.

  Future<List<BPObservation>> loadData(
      BuildContext context, WidgetRef ref) async {
    final dirUrl = await getDirUrl('healthpod/data/blood_pressure');
    final resources = await getResourcesInContainer(dirUrl);

    final List<BPObservation> loadedObservations = [];

    for (final file in resources.files) {
      if (!file.endsWith('.enc.ttl')) continue;

      if (!context.mounted) continue;

      // Get the secret key for decryption, showing a dialog if needed
      final secretKey = await getSecretKey(
        context,
        ref,
        operation: 'Decryption',
      );

      // If the user cancelled, skip this file
      if (secretKey == null || secretKey.isEmpty) {
        continue;
      }

      // Initialize the Pod keys with the provided secret key
      await KeyManager.initPodKeys(secretKey);

      final content = await readPod(
        'healthpod/data/blood_pressure/$file',
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
        loadedObservations.add(BPObservation.fromJson(data));
      } catch (e) {
        debugPrint('Error parsing file $file: $e');
      }
    }

    return loadedObservations;
  }

  /// Save a BP observation to Pod. If this is an existing observation update,
  /// remove the old file first.

  Future<void> saveObservationToPod({
    required BuildContext context,
    required WidgetRef ref,
    required BPObservation observation,
    required bool isNew,
    required BPObservation? oldObservation,
  }) async {
    // Get the secret key for encryption, showing a dialog if needed
    final secretKey = await getSecretKey(
      context,
      ref,
      operation: 'Encryption',
    );

    // If the user cancelled, return
    if (secretKey == null || secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save without a security key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Initialize the Pod keys with the provided secret key
    await KeyManager.initPodKeys(secretKey);

    // Delete old file if not a new observation.

    if (!isNew && oldObservation != null) {
      final oldFilename = _filenameFromTimestamp(oldObservation.timestamp);
      await deleteFile('healthpod/data/blood_pressure/$oldFilename');
    }

    // Write new file.

    final newFilename = _filenameFromTimestamp(observation.timestamp);
    final jsonData = json.encode(observation.toJson());

    if (!context.mounted) return;

    await writePod(
      'blood_pressure/$newFilename',
      jsonData,
      context,
      const Text('Saving'),
      encrypted: true,
    );
  }

  /// Delete an observation's file from Pod.

  Future<void> deleteObservationFromPod(
    BuildContext context,
    BPObservation observation,
  ) async {
    final filename = _filenameFromTimestamp(observation.timestamp);
    await deleteFile('healthpod/data/blood_pressure/$filename');
  }

  /// Helper to generate the consistent file name from an observation's timestamp.

  String _filenameFromTimestamp(DateTime dt) {
    final formatted = formatTimestampForFilename(dt);
    return 'blood_pressure_$formatted.json.enc.ttl';
  }
}
