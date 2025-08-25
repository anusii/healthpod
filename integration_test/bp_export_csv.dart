/// Integration test suite for the CSV export functionality.
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

import 'utils/find_login_button.dart';
import 'utils/navigate_to_files.dart';
import 'utils/verify_basic_app_structure.dart';
import 'utils/verify_home_screen.dart';

/// ⚠️IMPORTANT: Before running this test, ensure that:
///
/// 1. You've previously launched the app manually and saved your security key
/// 2. The app's shared preferences contain the stored security key
/// 3. You're ready to handle the browser authentication when prompted
/// 4. There is at least one CSV file in the blood_pressure folder
///    (the test expects the folder to contain exportable data)

void main() {
  bpExportCSV();
}

/// Integration test for the complete CSV export flow.
///
/// Assumes:
/// - User has previously authenticated and saved security key
/// - The blood_pressure folder exists and contains data
/// - User is available to handle the browser auth and file save dialogs
///
/// Flow:
/// - Navigates to the Files page
/// - Opens the 'blood_pressure' folder
/// - Taps the 'Export CSV' button
/// - Waits for manual file save dialog interaction
/// - Verifies success message appears

void bpExportCSV() {
  // Initialise the integration test binding.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CSV Export Flow:', () {
    testWidgets(
      'Navigate to Files, select blood_pressure folder, and export CSV',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          try {
            debugPrint('\n🚀 Starting CSV Export test...');

            // Launch the app and wait for it to stabilise.
            // This ensures we're starting from a clean state.

            app.main();
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Login Phase.
            // Find and tap the login button to initiate authentication.

            debugPrint('\n📱 App launched, looking for login button...');
            await verifyBasicAppStructure(tester);
            final loginButton = await findLoginButton(tester);

            debugPrint('\n🖱️ Tapping login button...');
            await tester.tap(loginButton);
            await tester.pumpAndSettle();

            // Authentication Phase.
            // This requires manual interaction in an external browser window.
            // The test will wait for a reasonable time for this to complete.

            debugPrint(
              '\n⚠️ Please complete browser authentication manually...',
            );
            await Future.delayed(const Duration(seconds: 15));
            await tester.pumpAndSettle();

            // Navigation Phase.
            // Verify we're on the home screen after authentication.

            debugPrint('\n🏠 Checking for home screen...');
            await verifyHomeScreen(tester);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Navigate to the Files section of the app.

            debugPrint('\n📁 Navigating to Files page...');
            await navigateToFiles(tester);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Note: Security key should already be saved in shared preferences.
            // If the security key prompt appears, the test will fail as expected
            // since we're not handling manual input during the test.

            // Folder selection phase.
            // Find and tap on the `blood_pressure` folder.

            debugPrint('\n🔍 Locating blood_pressure folder...');
            final bpFolder = find.text('blood_pressure');
            expect(
              bpFolder,
              findsOneWidget,
              reason: 'blood_pressure folder not found in Files',
            );
            await tester.tap(bpFolder);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Export CSV phase.
            // Find and tap the 'Export CSV' button.

            debugPrint('\n🖱️ Tapping Export CSV button...');
            final exportCsvButton = find.text('Export CSV');
            expect(
              exportCsvButton,
              findsOneWidget,
              reason: 'Export CSV button not found',
            );
            await tester.tap(exportCsvButton);
            await tester.pumpAndSettle();

            // Manual save dialog phase.
            // Wait for user to handle system's native file save dialog.
            // This cannot be automated and requires manual intervention.

            debugPrint(
              '\n⚠️ Please handle the native file save dialog manually...',
            );
            await Future.delayed(const Duration(seconds: 10));
            await tester.pumpAndSettle();

            // Success verification phase.
            // Verify that the CSV export success message appears.

            debugPrint('\n✅ Verifying CSV export success message...');
            final successMessage =
                find.text('Blood pressure data exported successfully');
            expect(
              successMessage,
              findsOneWidget,
              reason: 'CSV export success message not displayed',
            );
          } catch (e) {
            debugPrint('\n❌ CSV Export test failed with error: $e');
            rethrow;
          }
        });
      },
    );
  });
}
