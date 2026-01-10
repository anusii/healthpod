/// Data management for profile details including loading and saving.
///
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/appointment.dart';
import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/is_logged_in.dart';

/// Manages profile data operations including loading and saving.

class ProfileDataManager {
  /// Loads profile data from the POD and returns it.

  static Future<Map<String, dynamic>> loadProfileData(
    BuildContext context,
  ) async {
    try {
      // First check if user is logged in.

      final loggedIn = await isLoggedIn();

      if (loggedIn) {
        if (!context.mounted) return {};
        // Fetch profile data using utility function.

        final profileData = await fetchProfileData(context);
        return profileData;
      } else {
        // User not logged in, return empty data.

        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Saves profile data to the POD.

  static Future<SolidFunctionCallStatus> saveProfileData(
    Map<String, dynamic> updatedData,
    BuildContext context,
  ) async {
    try {
      // Try to update existing profile file first, create new one only if none
      // exists.

      final result = await _updateOrCreateProfileFile(updatedData, context);
      return result;
    } catch (e) {
      debugPrint('Exception saving profile: $e');
      return SolidFunctionCallStatus.fail;
    }
  }

  /// Updates existing profile file or creates a new one if none exists.

  static Future<SolidFunctionCallStatus> _updateOrCreateProfileFile(
    Map<String, dynamic> updatedData,
    BuildContext context,
  ) async {
    try {
      // First, try to find an existing profile file.

      final existingFile = await _findExistingProfileFile();

      String filename;
      if (existingFile != null) {
        // Use the existing filename to update the file.

        filename = existingFile;
      } else {
        // Create new filename only if no existing file found.

        final timestamp = formatTimestampForFilename(DateTime.now());
        filename = 'profile_$timestamp.json.enc.ttl';
      }

      // Create JSON data structure matching other successful implementations.
      final profileData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': updatedData,
      };

      // Check if context is still valid before using it.

      if (!context.mounted) {
        debugPrint('❌ Context no longer mounted during save');
        return SolidFunctionCallStatus.fail;
      }

      // Use direct writePod call with relative path to match read operations.

      await writePod(
        'profile/$filename',
        json.encode(profileData),
        encrypted: true,
      );

      return SolidFunctionCallStatus.success;
    } on Exception catch (e) {
      debugPrint('Exception saving profile: $e');
      return SolidFunctionCallStatus.fail;
    } catch (e) {
      debugPrint('Unexpected error saving profile: $e');
      return SolidFunctionCallStatus.fail;
    }
  }

  /// Finds an existing profile file to update, or returns null if none exists.

  static Future<String?> _findExistingProfileFile() async {
    try {
      // Get all files in the profile directory.

      final dirUrl = await getDirUrl('$basePath/profile');
      final resources = await getResourcesInContainer(dirUrl);

      // Find all profile files with the expected extension.

      final profileFiles = resources.files
          .where(
            (file) =>
                file.startsWith('profile_') &&
                !file.startsWith('profile_photo_') &&
                file.endsWith('.json.enc.ttl'),
          )
          .toList();

      if (profileFiles.isEmpty) {
        return null;
      }

      // Return the most recent profile file (sorted by filename).

      profileFiles.sort((a, b) => b.compareTo(a));
      return profileFiles.first;
    } catch (e) {
      debugPrint('Error finding existing profile file: $e');
      return null;
    }
  }

  /// Checks if any profile data has been changed compared to stored data.

  static bool hasDataChanged(
    Map<TextEditingController, String> controllers,
    Map<String, dynamic> profileData,
  ) {
    return controllers.entries.any((entry) {
      final controller = entry.key;
      final fieldName = entry.value;
      return controller.text.trim() != (profileData[fieldName] ?? '');
    });
  }

  /// Gets the user's default name or a fallback.

  static String getDefaultName() {
    return userName;
  }
}
