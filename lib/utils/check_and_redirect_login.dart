/// Checks if the user is logged in and navigates appropriately.
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

import 'package:healthpod/utils/create_solid_login.dart';

/// Checks if the user is logged in and navigates appropriately.

Future<void> checkAndRedirectLogin(BuildContext context) async {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      final webId = await getWebId();
      if (webId == null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => createSolidLogin(context)),
        );
      }
    } catch (e) {
      debugPrint('Error in checkAndRedirectLogin: $e');
    }
  });
}
