/// Utility to check if the user is logged in.
//
// Time-stamp: <Thursday 2024-05-16 13:33:06 +1100 Ashley Tang>
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

import 'package:solidpod/solidpod.dart';

/// Checks if the user is currently logged in
///
/// Returns true if the user has a valid WebID and is logged in, false otherwise.
/// This function should be used before accessing any pod data that requires authentication.

Future<bool> isLoggedIn() async {
  try {
    // Check for a WebID.

    final webId = await getWebId();
    if (webId == null || webId.isEmpty) {
      //debugPrint('⚠️ No WebID found, user is not logged in');
      return false;
    }

    // Check if the user is logged in.

    final loggedIn = await checkLoggedIn();

    return loggedIn;
  } catch (e) {
    //debugPrint('⚠️ Error checking login status: $e');
    return false;
  }
}
