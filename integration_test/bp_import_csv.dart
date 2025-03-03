/// Integration test suite for the CSV import functionality.
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
/// 4. You have a valid BP CSV file ready for import with required columns:
///    - timestamp
///    - systolic
///    - diastolic
///    - heart_rate
///    Optional columns: feeling, notes

void main() {
  bpImportCSV();
}

/// Integration test for the complete CSV import flow.
///
/// Assumes:
/// - User has previously authenticated and saved security key
/// - A valid BP CSV file is available for import
/// - User is available to handle the browser auth and file selection dialogs
///
/// Flow:
/// - Navigates to the Files page
/// - Opens the 'blood_pressure' folder
/// - Taps the 'Import CSV' button
/// - Waits for manual file selection dialog interaction
/// - Verifies success message appears

void bpImportCSV() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CSV Import Flow:', () {
    testWidgets(
      'Navigate to Files, select blood_pressure folder, and import CSV',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          try {
            debugPrint('\n🚀 Starting CSV Import test...');

            // Launch the app and wait for it to stabilise.

            app.main();
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Login Phase.

            debugPrint('\n📱 App launched, looking for login button...');
            await verifyBasicAppStructure(tester);
            final loginButton = await findLoginButton(tester);

            debugPrint('\n🖱️ Tapping login button...');
            await tester.tap(loginButton);
            await tester.pumpAndSettle();

            // Authentication Phase.

            debugPrint(
                '\n⚠️ Please complete browser authentication manually...');
            await Future.delayed(const Duration(seconds: 15));
            await tester.pumpAndSettle();

            // Navigation Phase.

            debugPrint('\n🏠 Checking for home screen...');
            await verifyHomeScreen(tester);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            debugPrint('\n📁 Navigating to Files page...');
            await navigateToFiles(tester);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Folder selection phase.

            debugPrint('\n🔍 Locating blood_pressure folder...');
            final bpFolder = find.text('blood_pressure');
            expect(bpFolder, findsOneWidget,
                reason: 'blood_pressure folder not found in Files');
            await tester.tap(bpFolder);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Import CSV phase.

            debugPrint('\n🖱️ Tapping Import CSV button...');
            final importCsvButton = find.text('Import CSV');
            expect(importCsvButton, findsOneWidget,
                reason: 'Import CSV button not found');
            await tester.tap(importCsvButton);
            await tester.pumpAndSettle();

            // Manual file selection phase.

            debugPrint(
                '\n⚠️ Please select a valid BP CSV file in the dialog...');
            await Future.delayed(const Duration(seconds: 10));
            await tester.pumpAndSettle();

            // Import progress phase.
            // The importer shows progress for each row being processed.

            debugPrint('\n⏳ Waiting for import processing...');
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Success verification phase.

            debugPrint('\n✅ Verifying CSV import success message...');

            // Give just enough time for the SnackBar to appear.

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));

            // Verify the success message appears in the SnackBar.

            final messageFinder = find.text(
                'Blood pressure data imported and converted successfully');
            expect(messageFinder, findsOneWidget,
                reason: 'Success message not found');

            // Give UI time to settle before continuing.

            await tester.pumpAndSettle();

            // Also verify files were created.

            debugPrint('\n🔍 Verifying imported files appear in the folder...');
            final filePattern =
                RegExp(r'blood_pressure_\d{4}-\d{2}-\d{2}.*\.json\.enc\.ttl');
            final files = find.byWidgetPredicate(
              (widget) =>
                  widget is Text && filePattern.hasMatch(widget.data ?? ''),
            );
            expect(files, findsWidgets,
                reason: 'No imported blood pressure files found in folder');
            debugPrint('\n🔍 Verifying imported files appear in the folder...');
            expect(files, findsWidgets,
                reason: 'No imported blood pressure files found in folder');

            // Verify new files appeared.

            debugPrint('\n🔍 Verifying imported files appear in the folder...');
            expect(files, findsWidgets,
                reason: 'No imported blood pressure files found in folder');
          } catch (e) {
            debugPrint('\n❌ CSV Import test failed with error: $e');
            rethrow;
          }
        });
      },
    );
  });
}
