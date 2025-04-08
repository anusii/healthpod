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
    // Note: constructPodPath already includes basePath in its implementation
    final dirUrl = await getDirUrl(constructPodPath('profile', ''));
    debugPrint(
        "Looking for profile data in: ${constructPodPath('profile', '')}");

    final resources = await getResourcesInContainer(dirUrl);
    debugPrint("Profile dir contents: ${resources.files}");

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
    debugPrint("Found latest profile file: $latestProfileFile");

    // Read the file contents.
    if (!context.mounted) {
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Use readPod with the full constructed path to the file
    final fileContent = await readPod(
      constructPodPath('profile', latestProfileFile),
      context,
      const Text('Reading profile data'),
    );

    if (fileContent is! String || fileContent.isEmpty) {
      debugPrint('Failed to read profile data. Using default profile data.');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }

    // Print raw content for debugging
    debugPrint('Raw decrypted profile data length: ${fileContent.length}');

    // Try to parse the JSON data.
    try {
      // First check if we have Turtle format data (starts with @prefix)
      if (fileContent.trim().startsWith('@prefix')) {
        debugPrint('Detected Turtle format data instead of JSON');

        // Extract data from Turtle using regex - looking for our profile properties
        Map<String, dynamic> extractedData = {};

        // Extract common fields we care about
        extractedData['patientName'] =
            _extractTurtleValue(fileContent, 'patientName');
        extractedData['address'] = _extractTurtleValue(fileContent, 'address');
        extractedData['bestContactPhone'] =
            _extractTurtleValue(fileContent, 'bestContactPhone');
        extractedData['alternativeContactNumber'] =
            _extractTurtleValue(fileContent, 'alternativeContactNumber');
        extractedData['email'] = _extractTurtleValue(fileContent, 'email');
        extractedData['dateOfBirth'] =
            _extractTurtleValue(fileContent, 'dateOfBirth');
        extractedData['gender'] = _extractTurtleValue(fileContent, 'gender');

        // Handle boolean field differently
        final indigenousMatch = RegExp(r'identifyAsIndigenous\s+"(true|false)"')
            .firstMatch(fileContent);
        if (indigenousMatch != null && indigenousMatch.group(1) != null) {
          extractedData['identifyAsIndigenous'] =
              indigenousMatch.group(1) == 'true';
        } else {
          extractedData['identifyAsIndigenous'] = false;
        }

        debugPrint('Extracted data from Turtle: $extractedData');
        return extractedData;
      }

      final Map<String, dynamic> jsonData = jsonDecode(fileContent);
      debugPrint('Successfully parsed profile JSON');

      // Check for responses key (profile data might be stored under 'responses').
      if (jsonData.containsKey('responses')) {
        return jsonData['responses'] as Map<String, dynamic>;
      } else if (jsonData.containsKey('data')) {
        return jsonData['data'] as Map<String, dynamic>;
      }

      return jsonData;
    } catch (e) {
      debugPrint('Error parsing profile data JSON: $e');
      // Try to extract just the data part if the whole file can't be parsed
      final dataMatch =
          RegExp(r'"data":\s*(\{[^}]+\})').firstMatch(fileContent);
      if (dataMatch != null && dataMatch.group(1) != null) {
        try {
          return jsonDecode('{${dataMatch.group(1)}}') as Map<String, dynamic>;
        } catch (e2) {
          debugPrint('Failed to extract data segment: $e2');
        }
      }

      debugPrint('Using default profile data.');
      return defaultProfileData['data'] as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('Error fetching profile data: $e');
    // Return default profile data in case of error.
    return defaultProfileData['data'] as Map<String, dynamic>;
  }
}

String _extractTurtleValue(String content, String propertyName) {
  final regex = RegExp('$propertyName\\s+"([^"]+)"');
  final match = regex.firstMatch(content);
  if (match != null && match.groupCount >= 1) {
    final value = match.group(1);
    return value ?? '';
  }
  return '';
}
