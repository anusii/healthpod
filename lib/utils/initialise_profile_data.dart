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

    debugPrint('Profile dir contents: ${resources.files}');

    // Look for any profile data file (profile_*.json.enc.ttl)
    final profileFiles = resources.files
        .where((file) =>
            file.startsWith('profile_') &&
            !file.startsWith('profile_photo_') && // Exclude photo files
            file.endsWith('.json.enc.ttl'))
        .toList();

    // Also look for photo files to check for potential confusion
    final photoFiles = resources.files
        .where((file) =>
            file.startsWith('profile_photo_') &&
            (file.endsWith('.photo.enc.ttl') || file.endsWith('.enc.ttl')))
        .toList();

    if (photoFiles.isNotEmpty) {
      debugPrint('Found ${photoFiles.length} profile photo files');
    }

    // Check for existence of properly formatted profile data file
    if (profileFiles.isNotEmpty) {
      debugPrint('Found ${profileFiles.length} existing profile data files');

      // If we have profile data, check if it has all required fields.
      if (context.mounted) {
        // Here we only want to add missing fields, never replace existing data
        await _ensureRequiredFields(context);
      }
    } else {
      debugPrint('No profile data file found - will create initial profile');
      debugPrint('Default profile data: ${defaultProfileData['data']}');

      if (!context.mounted) return;

      // Create initial profile only if no profile exists
      // Use the structure expected by fetchProfileData - profile data is the responses
      await saveResponseToPod(
        context: context,
        responses: defaultProfileData['data'],
        podPath: '/profile',
        filePrefix: 'profile',
        additionalData: {'timestamp': defaultProfileData['timestamp']},
      );

      debugPrint(
          '✅ Successfully created initial profile_{timestamp}.json.enc.ttl with blank values');
    }

    debugPrint('Successfully initialised profile data');
    onComplete.call();
  } catch (e) {
    debugPrint('❌ Error initializing profile data: $e');
  } finally {
    onProgress.call(false);
  }
}

/// Ensures the profile has all required fields without overwriting existing data.
/// Only adds missing fields from the default profile template.

Future<void> _ensureRequiredFields(BuildContext context) async {
  try {
    // Fetch the current profile data.
    debugPrint('Validating existing profile data for missing fields');
    final existingData = await fetchProfileData(context);

    debugPrint(
        'Existing profile data contains keys: ${existingData.keys.join(', ')}');

    // Check if the data contains imageData - this shouldn't happen but let's check
    if (existingData.containsKey('imageData')) {
      debugPrint(
          'WARNING: Profile data contains imageData - this indicates data mixing');
    }

    // Keep track of any fields that are completely missing
    final missingFields = <String>[];

    // Create a map that starts with the existing data
    final Map<String, dynamic> updatedData =
        Map<String, dynamic>.from(existingData);

    // Only add fields that don't exist at all
    for (final key in defaultProfileData['data'].keys) {
      if (!existingData.containsKey(key) || existingData[key] == null) {
        // Add the default for this missing field
        updatedData[key] = defaultProfileData['data'][key];
        missingFields.add(key);
        debugPrint('Adding missing field to profile: $key');
      }
      // NEVER replace existing values with defaults
    }

    // Only save if we added missing fields
    if (missingFields.isNotEmpty && context.mounted) {
      debugPrint(
          'Saving profile with ${missingFields.length} added fields: ${missingFields.join(", ")}');

      // Ensure we don't include any photo data that might have gotten mixed in
      updatedData.remove('imageData');
      updatedData.remove('format');

      // When saving, make sure we use the correct structure
      // The data itself is the responses, not wrapped in a 'data' field
      await saveResponseToPod(
        context: context,
        responses: updatedData, // This is the data object
        podPath: '/profile',
        filePrefix: 'profile',
        additionalData: {'timestamp': DateTime.now().toIso8601String()},
      );
      debugPrint(
          '✅ Updated profile with missing fields while preserving existing data');
    } else {
      debugPrint('No missing fields found in profile - no update needed');
    }
  } catch (e) {
    debugPrint('❌ Error validating profile data: $e');
  }
}
