/// Integration test suite for the blood pressure survey feature.
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

/// Main entry point for the test suite.

void main() {
  bpSurvey();
}

/// Helper function to dump current widgets for debugging.
///
/// Prints the entire widget tree to help diagnose widget hierarchy issues
/// and verify the current state of the UI. Each widget's runtime type is
/// included in the output.
///
/// Parameters:
///   tester: The WidgetTester instance used for the current test

void dumpWidgetTree(WidgetTester tester) {
  debugPrint('\n🔍 Current widget tree:');
  debugPrint('${tester.allWidgets.map((w) => w.runtimeType).toList()}');
}

/// Blood Pressure Survey integration test suite.
///
/// Tests the complete flow of recording blood pressure measurements, including:
/// - User authentication
/// - Navigation to survey
/// - Form completion with valid data
/// - File saving functionality
/// - Success verification
///
/// The test requires manual interaction at two points:
/// 1. Browser-based authentication
/// 2. Native file save dialog handling
///
/// Test data used:
/// - Systolic: 120 mmHg
/// - Diastolic: 80 mmHg
/// - Heart Rate: 72 bpm
/// - Feeling: Good
/// - Notes: Test measurement after morning walk

void bpSurvey() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Pressure Survey Flow:', () {
    testWidgets('Complete survey form with valid data',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        debugPrint('\n🚀 Starting test...');

        // Initialise application and wait for it to settle.

        app.main();
        await tester.pumpAndSettle();

        // Login Phase.

        debugPrint('\n📱 App launched, looking for login button...');

        // Verify basic app structure is present.

        final selectionArea = find.byType(SelectionArea);
        expect(selectionArea, findsOneWidget,
            reason: 'SelectionArea not found');

        final materialApp = find.byType(MaterialApp);
        expect(materialApp, findsOneWidget, reason: 'MaterialApp not found');

        // Try multiple approaches to find the login button.
        // This improves test reliability across UI changes.

        final loginButtonByText = find.text('Login');
        final loginButtonByType = find.byType(ElevatedButton);
        final loginButtonByWidget =
            find.widgetWithText(ElevatedButton, 'Login');

        debugPrint('\n🔍 Login button search results:');
        debugPrint('By text: ${loginButtonByText.evaluate().length}');
        debugPrint('By type: ${loginButtonByType.evaluate().length}');
        debugPrint('By widget text: ${loginButtonByWidget.evaluate().length}');

        // Use the first successful finder method.

        Finder loginButton;
        if (loginButtonByText.evaluate().isNotEmpty) {
          loginButton = loginButtonByText;
        } else if (loginButtonByType.evaluate().isNotEmpty) {
          loginButton = loginButtonByType.first;
        } else if (loginButtonByWidget.evaluate().isNotEmpty) {
          loginButton = loginButtonByWidget;
        } else {
          throw Exception('No login button found using any method');
        }

        // Initiate login process.

        debugPrint('\n🖱️ Tapping login button...');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Authentication Phase.

        debugPrint('\n⚠️ Please complete browser authentication manually...');
        // Allow time for manual browser authentication
        await Future.delayed(const Duration(seconds: 15));
        await tester.pumpAndSettle();

        // Navigation Phase.

        debugPrint('\n🏠 Checking for home screen...');

        // Verify successful login by checking home screen elements.

        expect(find.byType(AppBar), findsOneWidget, reason: 'AppBar not found');
        expect(find.text('Your Health - Your Data'), findsOneWidget,
            reason: 'Home screen title not found');

        // Find and navigate to survey.

        debugPrint('\n🔍 Looking for quiz icon...');
        final surveyButton = find.ancestor(
          of: find.byIcon(Icons.quiz),
          matching: find.byType(Container),
        );
        expect(surveyButton, findsOneWidget,
            reason: 'Quiz icon container not found');

        debugPrint('\n🖱️ Tapping quiz icon...');
        await tester.tap(surveyButton);
        await tester.pumpAndSettle();

        // Form Completion Phase.

        debugPrint('\n📋 Verifying survey page...');
        expect(find.text('Health Survey'), findsOneWidget,
            reason: 'Survey page title not found');

        // Locate form fields.

        debugPrint('\n✍️ Filling form fields...');
        final formFields = find.byType(TextFormField);
        expect(formFields, findsWidgets, reason: 'No form fields found');

        // Fill numerical measurements.

        await tester.enterText(formFields.at(0), '120'); // Systolic.
        await tester.pumpAndSettle();

        await tester.enterText(formFields.at(1), '80'); // Diastolic.
        await tester.pumpAndSettle();

        await tester.enterText(formFields.at(2), '72'); // Heart rate.
        await tester.pumpAndSettle();

        // Select feeling from radio options.

        final goodOption = find.text('Good');
        expect(goodOption, findsOneWidget, reason: 'Good option not found');
        await tester.tap(goodOption);
        await tester.pumpAndSettle();

        // Add additional notes.

        await tester.enterText(
            formFields.last, 'Test measurement after morning walk');
        await tester.pumpAndSettle();

        // Form Submission Phase.

        debugPrint('\n💾 Submitting form...');
        // Try to find submit button by text first, fall back to type.

        final submitButtonText = find.text('Submit');
        if (submitButtonText.evaluate().isNotEmpty) {
          await tester.tap(submitButtonText);
        } else {
          final submitButton = find.byType(ElevatedButton).last;
          expect(submitButton, findsOneWidget,
              reason: 'Submit button not found');
          await tester.tap(submitButton);
        }
        await tester.pumpAndSettle();

        // Save Dialog Phase.

        debugPrint('\n📝 Handling save dialog...');
        expect(find.text('Save Survey Results'), findsOneWidget,
            reason: 'Save dialog not found');

        final localSaveButton = find.text('Save Locally');
        expect(localSaveButton, findsOneWidget,
            reason: 'Save Locally button not found');
        await tester.tap(localSaveButton);
        await tester.pumpAndSettle();

        // Native File Save Phase.

        debugPrint('\n⚠️ Please handle the native file save dialog...');

        // Allow time for user to handle native file picker.

        await Future.delayed(const Duration(seconds: 15));
        await tester.pumpAndSettle();

        // === Success Verification Phase.

        debugPrint('\n✅ Checking for success message...');
        bool foundSuccessMessage = false;
        int attempts = 0;
        while (!foundSuccessMessage && attempts < 10) {
          final successMessage =
              find.text('Survey submitted and saved successfully!');
          if (successMessage.evaluate().isNotEmpty) {
            foundSuccessMessage = true;
          } else {
            await Future.delayed(const Duration(seconds: 1));
            await tester.pumpAndSettle();
            attempts++;
          }
        }
        expect(foundSuccessMessage, isTrue,
            reason: 'Success message never appeared');
      });
    });
  });
}
