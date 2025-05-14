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

import 'package:solidpod/solidpod.dart' show getWebId, checkLoggedIn;

/// Fetch the user's WebID from the Solid server.
///
/// Returns the WebID only if the user is actively logged in with a valid token.
/// Returns null if the user is not logged in or the token is invalid/expired.

Future<String?> fetchWebId() async {
  try {
    // First check if the user is actively logged in with a valid token.

    final isLoggedIn = await checkLoggedIn();

    if (!isLoggedIn) {
      debugPrint('User not actively logged in, returning null WebID');
      return null;
    }

    // If logged in, get the WebID.

    final webId = await getWebId();
    debugPrint('User is logged in, WebID: $webId');
    return webId;
  } catch (e) {
    debugPrint('Error fetching WebID: $e');
    return null;
  }
}
