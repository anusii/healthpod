/// Fetch health plan data from pod.
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

import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/security_key/central_key_manager.dart';

/// Fetches the most recent health plan data from the pod.
///
/// Returns a [Future<Map<String, dynamic>>] with health plan data.
/// If no health plan data is found, returns an empty map with just the title.
///
/// Parameters:
/// - [context]: BuildContext for error handling and UI feedback

Future<Map<String, dynamic>> fetchHealthPlanData(BuildContext context) async {
  try {
    // Replace the direct call with our central key manager.

    await CentralKeyManager.instance.ensureSecurityKey(
      context,
      const Text(
          'Security verification is required to access your health plan'),
    );

    // Get the directory URL for the health_plan folder.

    final podDirPath = constructPodPath('health_plan', '');
    // Looking for health plan data.

    final dirUrl = await getDirUrl(podDirPath);
    final resources = await getResourcesInContainer(dirUrl);
    // Retrieved health plan directory contents.

    // Look for health plan files with .enc.ttl extension (encrypted files).

    final healthPlanFiles = resources.files
        .where((file) =>
            file.startsWith('health_plan_') && file.endsWith('.enc.ttl'))
        .toList();

    if (healthPlanFiles.isEmpty) {
      // No health plan files found.

      return {'title': 'My Health Management Plan', 'planItems': <String>[]};
    }

    // Sort files by name to get the most recent one (assuming timestamp in filename).

    healthPlanFiles.sort((a, b) => b.compareTo(a));
    final latestHealthPlanFile = healthPlanFiles.first;
    // Found latest health plan file.

    // Read the file contents.

    if (!context.mounted) {
      return {'title': 'My Health Management Plan', 'planItems': <String>[]};
    }

    // Use readPod with the full constructed path to the file.

    final filePath = constructPodPath('health_plan', latestHealthPlanFile);
    // Reading health plan data.

    // Prompt for security key if needed.

    await getKeyFromUserIfRequired(
      context,
      const Text(
          'Please enter your security key to access your health plan data'),
    );

    if (!context.mounted) {
      return {'title': 'My Health Management Plan', 'planItems': <String>[]};
    }

    final fileContent = await readPod(
      filePath,
      context,
      const Text('Reading health plan data'),
    );

    // Check for errors or empty content.

    if (fileContent.isEmpty ||
        fileContent == SolidFunctionCallStatus.fail.toString() ||
        fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
      debugPrint('Failed to read health plan data: $fileContent');
      return {'title': 'My Health Management Plan', 'planItems': <String>[]};
    }

    // Log content details for debugging.

    debugPrint(
        'Successfully read encrypted health plan data (length: ${fileContent.length})');

    // Try to parse the JSON directly - this should work if decryption is successful.

    try {
      // Check if content appears to be TTL format instead of JSON.

      if (fileContent.trim().startsWith('@prefix')) {
        debugPrint(
            'File appears to be in TTL format. This indicates the file is still encrypted.');
        debugPrint(
            'The file may be double-encrypted or the security key is incorrect.');

        // Return empty data since we can't decrypt the TTL format directly.

        return {'title': 'My Health Management Plan', 'planItems': <String>[]};
      }

      final Map<String, dynamic> jsonData = jsonDecode(fileContent);
      debugPrint(
          'Successfully parsed health plan JSON with keys: ${jsonData.keys.join(', ')}');

      // Check for nested data structures.

      if (jsonData.containsKey('data')) {
        // Found data key in health plan.

        return jsonData['data'] as Map<String, dynamic>;
      } else if (jsonData.containsKey('timestamp') &&
          jsonData.containsKey('responses')) {
        debugPrint(
            'Found timestamp and responses keys, returning responses object');
        return jsonData['responses'] as Map<String, dynamic>;
      }

      // Return the whole object if it doesn't have the expected structure.

      return jsonData;
    } catch (e) {
      debugPrint('Error parsing health plan JSON: $e');
      debugPrint(
          'Content preview: ${fileContent.substring(0, min(100, fileContent.length))}...');

      // If content starts with @prefix, it's likely TTL format and the security key is incorrect.

      if (fileContent.trim().startsWith('@prefix')) {
        debugPrint(
            'File appears to be in TTL format. This indicates double encryption or incorrect security key.');
      }

      // Return empty data.

      debugPrint('Using empty data due to parsing error');
      return {'title': 'My Health Management Plan', 'planItems': <String>[]};
    }
  } catch (e) {
    debugPrint('Error fetching health plan data: $e');
    return {'title': 'My Health Management Plan', 'planItems': <String>[]};
  }
}

/// Returns the minimum of two integers (helper function).

int min(int a, int b) => a < b ? a : b;
