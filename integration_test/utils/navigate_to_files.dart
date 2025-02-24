/// Helper function to navigate to the Files page.
//
// Time-stamp: <Sunday 2025-01-26 08:55:54 +1100 Graham Williams>
//
/// Copyright (C) 2023-2024, Togaware Pty Ltd
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

import 'package:flutter_test/flutter_test.dart';

/// Helper function to navigate to the Files page.
///
/// Locates and taps the folder icon in the navigation bar to access
/// the Files section of the app. This is a common action needed
/// for file-related tests.

Future<void> navigateToFiles(WidgetTester tester) async {
  // Look for the folder icon that represents the Files section.

  debugPrint('\n🔍 Looking for files icon...');
  final filesIcon = find.byIcon(Icons.folder);
  expect(filesIcon, findsWidgets, reason: 'Files icon not found');

  // Tap the first instance of the folder icon (in case there are multiple matches).

  debugPrint('\n🖱️ Tapping Files icon...');
  await tester.tap(filesIcon.first);
  await tester.pumpAndSettle();

  // Note: No wait for security key is needed here because we're assuming.
  // it's already stored in shared preferences.
}
