/// Verifies the basic app structure is present.
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

import 'package:flutter_test/flutter_test.dart';

/// Verifies the basic app structure is present.
///
/// Checks for essential widgets that should be present in the initial app state.

Future<void> verifyBasicAppStructure(WidgetTester tester) async {
  final selectionArea = find.byType(SelectionArea);
  expect(selectionArea, findsOneWidget, reason: 'SelectionArea not found');

  final materialApp = find.byType(MaterialApp);
  expect(materialApp, findsOneWidget, reason: 'MaterialApp not found');
}
