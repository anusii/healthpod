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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/constants/profile.dart';

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

    final dirUrl = await getDirUrl('$basePath/profile');
    final resources = await getResourcesInContainer(dirUrl);

    // Look for profile files.

    final profileFiles = resources.files
        .where((file) =>
            file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
        .toList();

    if (profileFiles.isEmpty) {
      debugPrint('No profile files found. Using default profile data.');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Sort files by name to get the most recent one (assuming timestamp in filename).

    profileFiles.sort((a, b) => b.compareTo(a));
    final latestProfileFile = profileFiles.first;

    // Read the file contents.

    if (!context.mounted) {
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    final fileContent = await readPod(
      '$basePath/profile/$latestProfileFile',
      context,
      const Text('Reading profile data'),
    );

    if (fileContent.isEmpty) {
      debugPrint('Failed to read profile data. Using default profile data.');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Parse the JSON data.

    final Map<String, dynamic> jsonData = jsonDecode(fileContent);

    // Check for responses key (profile data might be stored under 'responses').

    if (jsonData.containsKey('responses')) {
      return jsonData['responses'] as Map<String, dynamic>;
    } else if (jsonData.containsKey('data')) {
      return jsonData['data'] as Map<String, dynamic>;
    }

    return jsonData;
  } catch (e) {
    debugPrint('Error fetching profile data: $e');
    // Return default profile data in case of error.

    return defaultProfileData['data'] as Map<String, dynamic>;
  }
}
