/// Dump widget tree utility for debugging.
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

/// Helper function to dump current widgets for debugging.
///
/// Prints the entire widget tree to help diagnose widget hierarchy issues
/// and verify the current state of the UI. Each widget's runtime type is
/// included in the output.
///
/// Parameters:
///   tester: The WidgetTester instance used for the current test.

void dumpWidgetTree(WidgetTester tester) {
  debugPrint('\n🔍 Current widget tree:');
  debugPrint('${tester.allWidgets.map((w) => w.runtimeType).toList()}');
}
