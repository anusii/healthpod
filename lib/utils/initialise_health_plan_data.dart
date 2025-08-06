/// Initialise health plan data.
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

import 'package:healthpod/utils/create_feature_folder.dart';

/// Initialises health plan folder in POD without creating any default data.
///
/// This function only creates the health_plan folder if it doesn't exist.
/// Unlike other initialization functions, it doesn't create any default data file.
///
/// Parameters:
/// - [context]: The BuildContext for showing progress indicators and error messages
/// - [onProgress]: Optional callback to track initialization progress
/// - [onComplete]: Optional callback triggered when initialization is complete

Future<void> initialiseHealthPlanData({
  required BuildContext context,
  required void Function(bool) onProgress,
  required void Function() onComplete,
}) async {
  try {
    onProgress.call(true);

    // Create health_plan folder if it doesn't exist.

    final folderResult = await createFeatureFolder(
      featureName: 'health_plan',
      context: context,
      onProgressChange: (_) {},
      onSuccess: () {
        // Health plan folder created or already exists.
      },
    );

    if (folderResult != SolidFunctionCallStatus.success) {
      debugPrint('❌ Failed to create health_plan folder');
      return;
    }

    // Health plan folder initialized successfully.

    onComplete.call();
  } catch (e) {
    debugPrint('❌ Error initializing health plan folder: $e');
  } finally {
    onProgress.call(false);
  }
}
