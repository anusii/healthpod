/// Initialise feature folders.
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
import 'package:healthpod/utils/create_feature_folder.dart';
import 'package:healthpod/utils/initialise_health_plan_data.dart';
import 'package:healthpod/utils/initialise_profile_data.dart';

/// Initialises required feature folders in the user's POD.
///
/// This function checks for the existence of essential feature folders and creates
/// them if they don't exist. Currently handles 'profile', 'blood_pressure', 'pathology',
/// 'vaccination', 'medication', 'diary', and 'health_plan' folders.
/// Returns a [Future<void>] that completes when all folders are verified/created.
///
/// Parameters:
/// - [context]: The BuildContext for showing progress indicators and error messages
/// - [onProgress]: Optional callback to track initialisation progress
/// - [onComplete]: Optional callback triggered when initialisation is complete

Future<void> initialiseFeatureFolders({
  required BuildContext context,
  required void Function(bool) onProgress,
  required void Function() onComplete,
}) async {
  try {
    onProgress.call(true);

    // List of required feature folders.
    final requiredFolders = [
      'profile',
      'bp',
      'pathology',
      'vaccination',
      'medication',
      'diary',
      'health_plan',
    ];

    // Check current resources.

    final dirUrl = await getDirUrl(basePath);
    final resources = await getResourcesInContainer(dirUrl);

    // Create each missing folder.

    for (final folder in requiredFolders) {
      if (!resources.subDirs.contains(folder)) {
        if (!context.mounted) return;

        final result = await createFeatureFolder(
          featureName: folder,
          context: context,
          onProgressChange: (inProgress) {
            // Only propagate progress changes if the callback is provided.

            onProgress.call(inProgress);
          },
          onSuccess: () {
            debugPrint('Successfully created $folder folder');
          },
        );

        if (result != SolidFunctionCallStatus.success) {
          debugPrint('Failed to create $folder folder');
          // Continue with other folders even if one fails.
        }
      }
    }

    // Initialise profile data with blank values if needed.

    if (!context.mounted) return;
    await initialiseProfileData(
      context: context,
      onProgress: onProgress,
      onComplete: () {
        debugPrint('Successfully initialised profile data');
      },
    );

    // Initialise health plan data with default values if needed.

    if (!context.mounted) return;
    await initialiseHealthPlanData(
      context: context,
      onProgress: onProgress,
      onComplete: () {
        debugPrint('Successfully initialised health plan data');
      },
    );

    onComplete.call();
  } catch (e) {
    debugPrint('Error initializing feature folders: $e');
  } finally {
    onProgress.call(false);
  }
}
