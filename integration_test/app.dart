/// Healthpod App integration test.
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

import 'package:integration_test/integration_test.dart';

import 'package:healthpod/main.dart' as app;

/// This integration test suite verifies the core functionality of HealthPod app.
///
/// It tests complete user flow from launch to logout including:
///
/// * Initial app launch and rendering
/// * Login screen verification
/// * Navigation using Continue button
/// * Home screen elements and layout
/// * Dialog interactions
/// * Logout functionality

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPod:', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Start the app.

      await tester.runAsync(() async {
        // Launch app.

        app.main();
        await tester.pumpAndSettle();

        // Wait for initial animations and async operations.

        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify SelectionArea and MaterialApp are present (from main.dart).

        expect(find.byType(SelectionArea), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);

        // Find and tap Continue button.

        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Wait for navigation and state initialisation.

        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify home screen elements.

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(BottomAppBar), findsOneWidget);

        // Verify icons.

        expect(find.byIcon(Icons.logout), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);

        // Test info dialog.

        await tester.tap(find.byIcon(Icons.info));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        // Close dialog.

        final closeButton = find.text('Close');
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        }

        // Test logout.

        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();
      });
    });
  });
}
