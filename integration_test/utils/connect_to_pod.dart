/// Integration tests for Solid POD connection functionality.
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:healthpod/main.dart' as app;
import 'package:healthpod/utils/create_solid_login.dart';
import 'package:healthpod/utils/fetch_web_id.dart';


/// Integration tests for Solid POD connection functionality in HealthPod app.
///
/// This file contains integration tests that verify the application's ability to:
/// - Connect to a Solid POD (Personal Online Datastore)
/// - Authenticate users through both external browser and WebView
/// - Handle the login/logout flow
/// - Manage WebID retrieval and storage
///
/// The tests can run in two modes:
/// 1. External Browser Mode (default): Uses system browser for authentication
/// 2. WebView Mode: Uses in-app WebView when INTEGRATION_TEST environment variable is set to 'true'
///
/// Test Structure:
/// - Main test runner that checks environment and launches appropriate test mode
/// - External browser connection test group
/// - WebView-specific connection test group
///
/// Mode Limitations:
/// External Browser Mode:
/// - Requires manual user interaction for login/logout
/// - Cannot be fully automated for CI/CD pipelines
/// - Tests may be flaky due to browser timing dependencies
///
/// WebView Mode:
/// - Bypasses proper OIDC authentication flow
/// - SolidPod library cannot detect/store valid session
/// - getWebId() and similar functions may fail
/// - Current implementation is a temporary solution for testing

void main() {
  // Initialise integration test environment.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Determine test mode based on environment variable.

  final integrationTestEnv =
      Platform.environment['INTEGRATION_TEST'] ?? 'false';
  final isIntegrationTest = integrationTestEnv.toLowerCase() == 'true';

  // Log the test environment configuration.

  debugPrint("🌍 INTEGRATION_TEST: $integrationTestEnv");
  ("🔍 isIntegrationTest: $isIntegrationTest");

  // Execute appropriate test suite based on mode.

  if (isIntegrationTest) {
    debugPrint("🌍 Running in WebView mode...");
    connectToPodWebView();
  } else {
    debugPrint("🌍 Running in external browser mode...");
    connectToPod();
  }
}

/// Main test suite for external browser-based POD connection.
///
/// Tests the complete authentication flow including:
/// - Initial app launch
/// - Login button interaction
/// - Authentication process
/// - Home screen verification
/// - WebID retrieval
/// - Logout process
/// - Post-logout state verification

void connectToPod() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HealthPod POD Connection:', () {
    testWidgets('Verify POD connection and authentication flow',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Launch and initialise app.

        app.main();
        await tester.pumpAndSettle();

        // Allow time for initial animations to complete.

        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify presence of essential login screen elements.

        expect(find.byType(SelectionArea), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);

        // Initiate login process.

        final loginButton = find.byType(ElevatedButton).first;
        expect(loginButton, findsOneWidget);
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Note: Browser interaction required from user to add Solid login details.

        // Allow time for external browser authentication.

        await Future.delayed(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Poll for AppBar presence to confirm successful login.

        int attempts = 0;
        while (find.byType(AppBar).evaluate().isEmpty && attempts < 10) {
          await tester.pump(const Duration(seconds: 1));
          attempts++;
        }

        // Verify successful navigation to home screen.

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Your Health - Your Data'), findsOneWidget);

        // Verify WebID is fetched.

        final webId = await fetchWebId();
        expect(webId, isNotNull);

        // Execute logout process.

        final logoutButton = find.byIcon(Icons.logout);
        expect(logoutButton, findsOneWidget);
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Handle logout confirmation.

        final okButton = find.text('OK');
        expect(okButton, findsOneWidget,
            reason:
                'OK button should be present in logout confirmation dialog');
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Note: browser interaction required from user to click 'Yes, sign me out'.

        // Allow time for logout cleanup.

        await Future.delayed(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // Verify successful logout.

        final webIdAfterLogout = await fetchWebId();
        expect(webIdAfterLogout, isNull,
            reason: 'WebID should be null after logout');
      });
    });
  });
}

/// WebView-specific test suite for POD connection.
///
/// Focuses on verifying WebID retrieval in WebView mode, which is designed
/// for automated testing scenarios. This test:
/// - Confirms WebView presence
/// - Attempts WebID extraction multiple times
/// - Validates successful WebID retrieval

void connectToPodWebView() {
  group('HealthPod POD Connection:', () {
    testWidgets('Verify we can retrieve WebID in WebView mode',
        (WidgetTester tester) async {
      // Initialise app in WebView mode.

      app.main();
      await tester.pumpAndSettle();

      // Verify WebView presence.

      expect(find.byType(InAppWebView), findsOneWidget);
      debugPrint("✅ WebView found, waiting for login to complete...");

      // Attempt WebID extraction with retry logic.

      const maxRetries = 5;
      int remaining = maxRetries;
      String? webId;

      while (webId == null && remaining > 0) {
        debugPrint("🔄 Checking for extracted WebID... "
            "Attempt ${maxRetries - remaining + 1}/$maxRetries");

        // Allow time for login process and JS injection.

        await Future.delayed(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        webId = SolidLoginTestHelper.extractedWebId;
        remaining--;
      }

      // Validate WebID extraction results.

      if (webId != null && webId.isNotEmpty) {
        debugPrint("✅ WebID retrieved from page: $webId");
      } else {
        debugPrint(
            "❌ WebID could not be retrieved after $maxRetries attempts!");
        fail('Unable to fetch WebID from HTML.');
      }
    });
  });
}
