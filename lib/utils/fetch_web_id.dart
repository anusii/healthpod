/// Fetch the user's WebID from the Solid server.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:healthpod/utils/is_logged_in.dart';

/// Fetch the user's WebID from the SolidPod package.
///
/// Returns the WebID if the user is actively logged in, otherwise returns null.
/// This ensures that the CONTINUE flow doesn't try to access pod resources.

Future<String?> fetchWebId() async {
  try {
    // First check if the user is actively logged in.

    final userLoggedIn = await isLoggedIn();

    if (!userLoggedIn) {
      // User is not logged in, so return null to indicate CONTINUE flow.

      debugPrint('⚠️ User not actively logged in, treating as CONTINUE flow');
      return null;
    }

    // User is logged in, fetch the WebID.

    final webId = await getWebId();
    debugPrint('WebID webId: $webId');

    // Only return the WebID if it exists and the user is logged in.

    if (webId != null && webId.isNotEmpty) {
      return webId;
    } else {
      return null;
    }
  } catch (e) {
    // Return null if there's an error.

    debugPrint('Error fetching WebID: $e');
    return null;
  }
}
