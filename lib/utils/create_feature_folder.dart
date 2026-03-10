/// Create feature folder.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';

/// Creates or verifies a feature folder in POD.

/// Creates a feature folder in POD with initialisation file.
///
/// Returns a [Future<SolidFunctionCallStatus>] indicating the creation result.
/// The [featureName] parameter specifies which feature folder to create (e.g. 'profile').
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

    // Check whether the folder already exists. The listing may fail when
    // the parent container is empty or has not been fully created yet; in
    // that case we proceed to create the folder regardless.

    try {
      final dirUrl = await getDirUrl(basePath);
      final resources = await getResourcesInContainer(dirUrl);

      if (resources.subDirs.contains(featureName)) {
        onSuccess.call();
        return SolidFunctionCallStatus.success;
      }

      if (resources.files.contains(featureName)) {
        debugPrint(
          'Removing existing file $featureName before creating directory',
        );
        if (!context.mounted) return SolidFunctionCallStatus.fail;
        await deleteFile(fileUrl: '$basePath/$featureName');
      }
    } catch (e) {
      debugPrint(
        'Could not list $basePath while checking $featureName: $e – '
        'will attempt to create the folder anyway.',
      );
    }

    if (!context.mounted) {
      debugPrint('Widget is no longer mounted, skipping folder creation.');
      return SolidFunctionCallStatus.fail;
    }

    await createContainer(basePath, featureName);

    if (createInitFile) {
      final initContent = '''
          {
            "feature": "$featureName",
            "created": "${DateTime.now().toIso8601String()}",
            "version": "1.0"
          }
          ''';

      if (!context.mounted) return SolidFunctionCallStatus.success;

      await writePod(
        '$featureName/init.json',
        initContent,
        encrypted: true,
      );
    }

    onSuccess.call();
    return SolidFunctionCallStatus.success;
  } catch (e) {
    debugPrint('Error creating feature folder $featureName: $e');
    return SolidFunctionCallStatus.fail;
  } finally {
    onProgressChange.call(false);
  }
}
