/// Verifies successful navigation to home screen.
//
// Time-stamp: <Wednesday 2025-02-19 16:44:33 +1100 Graham Williams>
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

import 'package:flutter_test/flutter_test.dart';

/// Verifies successful navigation to home screen.
///
/// Checks for elements that should be present on the home screen after login.

Future<void> verifyHomeScreen(WidgetTester tester) async {
  expect(find.byType(AppBar), findsOneWidget, reason: 'AppBar not found');
  expect(
    find.text('Your Health Data, Under Your Control'),
    findsOneWidget,
    reason: 'Home screen title not found',
  );
}
