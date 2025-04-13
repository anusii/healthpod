/// Fetch the key saved status.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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

import 'package:solidpod/solidpod.dart'
    show KeyManager, SolidFunctionCallStatus, getEncKeyPath, readPod;

import 'package:healthpod/utils/security_key/manager.dart';

/// This function verifies if an encryption key is available for the user by:
///
/// 1. Checking the encrypted key file in the POD
/// 2. Verifying if a key exists in local storage
///
/// If a key exists, it triggers a callback to update the UI.

Future<bool> fetchKeySavedStatus(context,
    [Function(bool)? onKeyStatusChanged]) async {
  try {
    // Get the path to the encrypted key file.

    final filePath = await getEncKeyPath();

    // Read the file content from the POD using the security key manager

    final fileContent = await readPod(
      filePath,
      context,
      SecurityKeyManager(
        onKeyStatusChanged:
            onKeyStatusChanged ?? (_) {}, // Callback to update key status.
      ),
    );

    // Check if the file content is valid.

    bool hasLocalKey = ![
      SolidFunctionCallStatus.notLoggedIn.toString(),
      SolidFunctionCallStatus.fail.toString()
    ].contains(fileContent);

    // Return true if the key is saved locally or in the POD.

    return await KeyManager.hasSecurityKey() || hasLocalKey;
  } catch (e) {
    return false;
  }
}
