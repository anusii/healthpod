/// Fetch profile data from pod.
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

import 'package:solidpod/solidpod.dart'
    show
        SolidFunctionCallStatus,
        getResourcesInContainer,
        getDirUrl,
        readPod,
        getKeyFromUserIfRequired;

import 'package:healthpod/constants/profile.dart';
import 'package:healthpod/utils/construct_pod_path.dart';

/// Fetches the most recent profile data from the pod.
///
/// Returns a [Future<Map<String, dynamic>>] with profile data.
/// If no profile data is found, returns default profile data.
///
/// Parameters:
/// - [context]: BuildContext for error handling and UI feedback

Future<Map<String, dynamic>> fetchProfileData(BuildContext context) async {
  try {
    // Get the directory URL for the profile folder.

    final podDirPath = constructPodPath('profile', '');
    debugPrint('Looking for profile data in: $podDirPath');

    final dirUrl = await getDirUrl(podDirPath);
    final resources = await getResourcesInContainer(dirUrl);
    debugPrint('Profile dir contents: ${resources.files}');

    final profileFiles = resources.files
        .where((file) =>
            file.startsWith('profile_') &&
            !file.startsWith('profile_photo_') && // Exclude photo files
            (file.endsWith('.enc.ttl') || file.endsWith('.json.enc.ttl')))
        .toList();

    debugPrint(
        'Found ${profileFiles.length} potential profile data files: $profileFiles');

    if (profileFiles.isEmpty) {
      debugPrint('No profile files found. Using default profile data.');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Sort files by name to get the most recent one (assuming timestamp in filename).

    profileFiles.sort((a, b) => b.compareTo(a));
    final latestProfileFile = profileFiles.first;
    debugPrint('Found latest profile file: $latestProfileFile');

    // Double-check that we're not using a photo file.

    if (latestProfileFile.startsWith('profile_photo_')) {
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Read the file contents.

    if (!context.mounted) {
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Use readPod with the full constructed path to the file.

    final filePath = constructPodPath('profile', latestProfileFile);
    debugPrint('Reading profile data from path: $filePath');

    // Prompt for security key if needed.

    await getKeyFromUserIfRequired(
      context,
      const Text('Please enter your security key to access your profile data'),
    );

    if (!context.mounted) {
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    final fileContent = await readPod(
      filePath,
      context,
      const Text('Reading profile data'),
    );

    // Check for errors or empty content.

    if (fileContent.isEmpty ||
        fileContent == SolidFunctionCallStatus.fail.toString() ||
        fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
      debugPrint('Failed to read profile data: $fileContent');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Log content details for debugging.

    debugPrint(
        'Successfully read encrypted profile data (length: ${fileContent.length})');

    // Try to parse the JSON directly - this should work if decryption is successful.

    try {
      // Check if content appears to be TTL format instead of JSON.

      if (fileContent.trim().startsWith('@prefix')) {
        debugPrint(
            'File appears to be in TTL format. This indicates the file is still encrypted.');
        debugPrint(
            'The file may be double-encrypted or the security key is incorrect.');

        // Return default profile data since we can't decrypt the TTL format directly.

        return defaultProfileData['data'] as Map<String, dynamic>;
      }

      final Map<String, dynamic> jsonData = jsonDecode(fileContent);
      debugPrint(
          'Successfully parsed profile JSON with keys: ${jsonData.keys.join(', ')}');

      // Check for nested data structures.
      Map<String, dynamic> profileData = <String, dynamic>{};

      if (jsonData.containsKey('data')) {
        debugPrint('Found data key in profile, returning data object');
        profileData = jsonData['data'] as Map<String, dynamic>;
      } else if (jsonData.containsKey('responses')) {
        // Most recent format - profile data is in 'responses'.

        debugPrint(
            'Found responses key in profile, returning responses object');
        final responses = jsonData['responses'] as Map<String, dynamic>;

        // Check if responses contains actual profile data or just imageData.
        // Filter out imageData and only keep actual profile fields.

        profileData = <String, dynamic>{};
        for (final key in responses.keys) {
          // Skip imageData, format or internal timestamp, but keep all profile fields.

          if (key != 'imageData' && key != 'format' && key != 'timestamp') {
            profileData[key] = responses[key];
          }
        }

        // If we've filtered everything out (only photo data was found),
        // check for profile fields in the main object.

        if (profileData.isEmpty) {
          for (final key in jsonData.keys) {
            if (key != 'responses' &&
                key != 'timestamp' &&
                key != 'imageData' &&
                key != 'format') {
              profileData[key] = jsonData[key];
            }
          }
        }
      } else if (jsonData.containsKey('timestamp') &&
          jsonData.containsKey('data')) {
        debugPrint('Found timestamp and data keys, returning data object');
        profileData = jsonData['data'] as Map<String, dynamic>;
      } else {
        // Check for direct profile fields at the top level.

        final profileKeys = [
          'name',
          'address',
          'bestContactPhone',
          'alternativeContactNumber',
          'email',
          'dateOfBirth',
          'gender'
        ];

        // Copy only profile-related fields.

        for (final key in profileKeys) {
          if (jsonData.containsKey(key)) {
            profileData[key] = jsonData[key];
          }
        }

        if (profileData.isEmpty) {
          // No profile data found at any level, return the whole object excluding photo data.

          profileData = Map<String, dynamic>.from(jsonData);
          profileData.remove('imageData');
          profileData.remove('format');
        }
      }

      // Ensure we have actual profile data.

      if (profileData.isEmpty) {
        debugPrint('No valid profile data found, using defaults');
        return defaultProfileData['data'] as Map<String, dynamic>;
      }

      return profileData;
    } catch (e) {
      debugPrint('Error parsing profile JSON: $e');
      debugPrint(
          'Content preview: ${fileContent.substring(0, min(100, fileContent.length))}...');

      // If content starts with @prefix, it's likely TTL format and the security key is incorrect.

      if (fileContent.trim().startsWith('@prefix')) {
        debugPrint(
            'File appears to be in TTL format. This indicates double encryption or incorrect security key.');
      }

      // Return default profile data.

      debugPrint('Using default profile data due to parsing error');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('Error fetching profile data: $e');
    return defaultProfileData['data'] as Map<String, dynamic>;
  }
}

/// Returns the minimum of two integers (helper function).

int min(int a, int b) => a < b ? a : b;
