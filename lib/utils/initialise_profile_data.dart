/// Initialise profile data.
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

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/constants/profile.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// Initialises profile data in POD with blank values if it doesn't exist.
///
/// This function checks for the existence of any profile file in the profile folder.
/// If none exists, creates it with blank default values in encrypted format.
/// Returns a [Future<void>] that completes when initialisation is done.
///
/// Parameters:
/// - [context]: The BuildContext for showing progress indicators and error messages
/// - [onProgress]: Optional callback to track initialization progress
/// - [onComplete]: Optional callback triggered when initialization is complete

Future<void> initialiseProfileData({
  required BuildContext context,
  required void Function(bool) onProgress,
  required void Function() onComplete,
}) async {
  try {
    onProgress.call(true);

    // Check if any profile file exists.
    final dirUrl = await getDirUrl('$basePath/profile');
    final resources = await getResourcesInContainer(dirUrl);

    // Look for any file that starts with 'profile_' and ends with '.json.enc.ttl'.
    final hasProfileFile = resources.files.any((file) =>
        file.startsWith('profile_') && file.endsWith('.json.enc.ttl'));

    if (!hasProfileFile) {
      if (!context.mounted) return;

      // Save blank profile data.
      await saveResponseToPod(
        context: context,
        responses: defaultProfileData['data'],
        podPath: '/profile',
        filePrefix: 'profile',
        additionalData: {'timestamp': defaultProfileData['timestamp']},
      );

      debugPrint(
          '✅ Successfully created profile_{timestamp}.json with blank values');
    } else {
      // Even if profile exists, check if it has all required fields.

      if (context.mounted) {
        await _validateAndUpdateProfile(context);
      }
    }

    onComplete.call();
  } catch (e) {
    debugPrint('❌ Error initializing profile data: $e');
  } finally {
    onProgress.call(false);
  }
}

/// Validates the existing profile and updates it if missing fields are found.

Future<void> _validateAndUpdateProfile(BuildContext context) async {
  try {
    // Fetch the current profile data.

    final existingData = await fetchProfileData(context);
    bool needsUpdate = false;

    // Create a map with all required fields from default profile.

    final Map<String, dynamic> updatedData = {};

    // Check each field and use existing value if present, otherwise use default.

    for (final key in defaultProfileData['data'].keys) {
      if (!existingData.containsKey(key) || existingData[key] == null) {
        updatedData[key] = defaultProfileData['data'][key];
        needsUpdate = true;
      } else {
        updatedData[key] = existingData[key];
      }
    }

    // Only save if updates are needed.

    if (needsUpdate && context.mounted) {
      await saveResponseToPod(
        context: context,
        responses: updatedData,
        podPath: '/profile',
        filePrefix: 'profile',
      );
      debugPrint('✅ Updated profile with missing fields');
    }
  } catch (e) {
    debugPrint('❌ Error validating profile data: $e');
  }
}
