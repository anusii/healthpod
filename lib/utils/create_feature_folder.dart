/// Create feature folder.
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

/// Creates or verifies a feature folder in POD.

/// Creates a feature folder in POD with initialisation file.
///
/// Returns a [Future<SolidFunctionCallStatus>] indicating the creation result.
/// The [featureName] parameter specifies which feature folder to create (e.g. 'bp').
/// If [createInitFile] is true, creates an initialisation file in the folder.

Future<SolidFunctionCallStatus> createFeatureFolder({
  required String featureName,
  required BuildContext context,
  bool createInitFile = true,
  required void Function(bool) onProgressChange,
  required void Function() onSuccess,
}) async {
  try {
    onProgressChange.call(true);

    // Check current resources.

    final dirUrl = await getDirUrl(basePath);
    final resources = await getResourcesInContainer(dirUrl);

    // Check if exists as directory.

    bool existsAsDir = resources.subDirs.contains(featureName);
    if (existsAsDir) {
      debugPrint('Feature folder $featureName already exists as directory');
      onSuccess.call();
      return SolidFunctionCallStatus.success;
    }

    // Check if exists as file and delete if necessary.

    bool existsAsFile = resources.files.contains(featureName);
    if (existsAsFile) {
      debugPrint(
          'Removing existing file $featureName before creating directory');
      if (!context.mounted) return SolidFunctionCallStatus.fail;

      // Full path for deletion needs to include healthpod/data.

      await deleteFile(
        '$basePath/$featureName',
      );
    }

    if (!context.mounted) {
      debugPrint('Widget is no longer mounted, skipping folder creation.');
      return SolidFunctionCallStatus.fail;
    }

    // Create the feature folder structure.

    final result = await writePod(
      '$featureName/.init',
      '',
      context,
      const Text('Creating folder'),
      encrypted: false,
    );

    // If folder creation was successful and initialization file is requested.

    if (result == SolidFunctionCallStatus.success && createInitFile) {
      final initContent = '''
{
  "feature": "$featureName",
  "created": "${DateTime.now().toIso8601String()}",
  "version": "1.0"
}''';

      if (!context.mounted) return result;

      final initResult = await writePod(
        '$featureName/init.json',
        initContent,
        context,
        const Text('Creating initialization file'),
        encrypted: true,
      );

      if (initResult == SolidFunctionCallStatus.success) {
        onSuccess.call();
        return SolidFunctionCallStatus.success;
      }
    }

    return result;
  } catch (e) {
    debugPrint('Error creating feature folder: $e');
    return SolidFunctionCallStatus.fail;
  } finally {
    onProgressChange.call(false);
  }
}
