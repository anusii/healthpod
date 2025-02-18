/// Finds the login button using multiple approaches.
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

/// Finds the login button using multiple approaches.
///
/// Attempts different methods to locate the login button to improve test reliability.
///
/// Returns:
///   Finder: The first successful button finder.
///
/// Throws:
///   Exception: If no login button is found using any method.

Future<Finder> findLoginButton(WidgetTester tester) async {
  final loginButtonByText = find.text('Login');
  final loginButtonByType = find.byType(ElevatedButton);
  final loginButtonByWidget = find.widgetWithText(ElevatedButton, 'Login');

  debugPrint('\n🔍 Login button search results:');
  debugPrint('By text: ${loginButtonByText.evaluate().length}');
  debugPrint('By type: ${loginButtonByType.evaluate().length}');
  debugPrint('By widget text: ${loginButtonByWidget.evaluate().length}');

  if (loginButtonByText.evaluate().isNotEmpty) {
    return loginButtonByText;
  } else if (loginButtonByType.evaluate().isNotEmpty) {
    return loginButtonByType.first;
  } else if (loginButtonByWidget.evaluate().isNotEmpty) {
    return loginButtonByWidget;
  }

  throw Exception('No login button found using any method');
}
