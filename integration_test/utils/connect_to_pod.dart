/// POD connection integration test.
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
import 'package:healthpod/utils/fetch_web_id.dart';

// Main entry point for the integration test.

void main() {
  connectToPod();
}

/// POD connection integration test.
///
/// This test verifies the basic POD connection functionality that other features
/// will depend on. Feature-specific tests (like bp/survey.dart) will build on
/// this base connection test.
///
/// Note: Currently, the test will still require manual browser interaction for both
/// login and logout since it's using external browser authentication.
/// To make it fully automated, we would need to refactor use WebView instead of
/// external browser or use mocking for authentication in test environment.

void connectToPod() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPod POD Connection:', () {
    testWidgets('Verify POD connection and authentication flow',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Launch app.

        app.main();
        await tester.pumpAndSettle();

        // Wait for initial animations.

        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify initial login screen elements.

        expect(find.byType(SelectionArea), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);

        // Find and tap Login button.

        final loginButton = find.byType(ElevatedButton).first;
        expect(loginButton, findsOneWidget);
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Note: Browser interaction required from user to add Solid login details.

        // Wait for auth flow to complete.

        await Future.delayed(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Keep pumping frames until we find the AppBar or timeout.

        int attempts = 0;
        while (find.byType(AppBar).evaluate().isEmpty && attempts < 10) {
          await tester.pump(const Duration(seconds: 1));
          attempts++;
        }

        // Verify home screen elements.

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Your Health - Your Data'), findsOneWidget);

        // Verify WebID is fetched.

        final webId = await fetchWebId();
        expect(webId, isNotNull);

        // Find and tap logout button.

        final logoutButton = find.byIcon(Icons.logout);
        expect(logoutButton, findsOneWidget);
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Find and tap OK on the confirmation dialog.

        final okButton = find.text('OK');
        expect(okButton, findsOneWidget,
            reason:
                'OK button should be present in logout confirmation dialog');
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Note: browser interaction required from user to click 'Yes, sign me out'.

        // Add a small delay to allow for async cleanup.

        await Future.delayed(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // Now verify WebID is cleared.

        final webIdAfterLogout = await fetchWebId();
        expect(webIdAfterLogout, isNull,
            reason: 'WebID should be null after logout');
      });
    });
  });
}
