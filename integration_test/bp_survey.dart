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
///
/// Initialises and runs the blood pressure survey integration test.

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
///   tester: The WidgetTester instance used for the current test.

void dumpWidgetTree(WidgetTester tester) {
  debugPrint('\n🔍 Current widget tree:');
  debugPrint('${tester.allWidgets.map((w) => w.runtimeType).toList()}');
}

/// Helper function to find widgets with retry logic.
///
/// Attempts to find a widget multiple times with delays between attempts.
///
/// Parameters:
///   finder: The Finder to use for locating the widget.
///   maxAttempts: Maximum number of retry attempts.
///   delaySeconds: Delay between attempts in seconds.
///
/// Returns:
///   bool: True if widget is found, false otherwise.

Future<bool> findWidgetWithRetry(
  Finder finder,
  WidgetTester tester, {
  int maxAttempts = 5,
  int delaySeconds = 1,
}) async {
  int attempts = 0;
  while (attempts < maxAttempts) {
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
    await Future.delayed(Duration(seconds: delaySeconds));
    await tester.pumpAndSettle();
    attempts++;
  }
  return false;
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
/// - Notes: Test measurement after morning walk.

void bpSurvey() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Pressure Survey Flow:', () {
    testWidgets(
      'Complete survey form with valid data',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          try {
            // Test Initialisation Phase.

            debugPrint('\n🚀 Starting test...');
            app.main();
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Login Phase.

            debugPrint('\n📱 App launched, looking for login button...');
            await _verifyBasicAppStructure(tester);
            final loginButton = await _findLoginButton(tester);

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
            await _verifyHomeScreen(tester);
            await _navigateToSurvey(tester);

            // Form Completion Phase.

            debugPrint('\n📋 Verifying survey page...');
            await _verifySurveyPage(tester);
            await _fillSurveyForm(tester);

            // Form Submission Phase.

            debugPrint('\n💾 Submitting form...');
            await _submitForm(tester);

            // Save Dialog Phase.

            debugPrint('\n📝 Handling save dialog...');
            await _handleSaveDialog(tester);

            // Native File Save Phase.

            debugPrint('\n⚠️ Please handle the native file save dialog...');
            await Future.delayed(const Duration(seconds: 15));
            await tester.pumpAndSettle();

            // Success Verification Phase.

            debugPrint('\n✅ Checking for success message...');
            await _verifySuccess(tester);
          } catch (e) {
            debugPrint('\n❌ Test failed with error: $e');
            rethrow;
          }
        });
      },
    );
  });
}

/// Verifies the basic app structure is present.
///
/// Checks for essential widgets that should be present in the initial app state.

Future<void> _verifyBasicAppStructure(WidgetTester tester) async {
  final selectionArea = find.byType(SelectionArea);
  expect(selectionArea, findsOneWidget, reason: 'SelectionArea not found');

  final materialApp = find.byType(MaterialApp);
  expect(materialApp, findsOneWidget, reason: 'MaterialApp not found');
}

/// Finds the login button using multiple approaches.
///
/// Attempts different methods to locate the login button to improve test reliability.
///
/// Returns:
///   Finder: The first successful button finder.
///
/// Throws:
///   Exception: If no login button is found using any method.

Future<Finder> _findLoginButton(WidgetTester tester) async {
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

/// Verifies successful navigation to home screen.
///
/// Checks for elements that should be present on the home screen after login.

Future<void> _verifyHomeScreen(WidgetTester tester) async {
  expect(find.byType(AppBar), findsOneWidget, reason: 'AppBar not found');
  expect(
    find.text('Your Health - Your Data'),
    findsOneWidget,
    reason: 'Home screen title not found',
  );
}

/// Navigates to the survey page.
///
/// Locates and taps the survey icon to navigate to the survey form.

Future<void> _navigateToSurvey(WidgetTester tester) async {
  debugPrint('\n🔍 Looking for quiz icon...');
  final surveyButton = find.ancestor(
    of: find.byIcon(Icons.quiz),
    matching: find.byType(Container),
  );
  expect(surveyButton, findsOneWidget, reason: 'Quiz icon container not found');

  debugPrint('\n🖱️ Tapping quiz icon...');
  await tester.tap(surveyButton);
  await tester.pumpAndSettle();
}

/// Verifies the survey page is loaded correctly.
///
/// Checks for essential elements on the survey page.

Future<void> _verifySurveyPage(WidgetTester tester) async {
  expect(
    find.text('Health Survey'),
    findsOneWidget,
    reason: 'Survey page title not found',
  );
}

/// Fills out the survey form with test data.
///
/// Enters blood pressure measurements, heart rate, feeling, and notes.

Future<void> _fillSurveyForm(WidgetTester tester) async {
  debugPrint('\n✍️ Filling form fields...');
  final formFields = find.byType(TextFormField);
  expect(formFields, findsWidgets, reason: 'No form fields found');

  // Fill numerical measurements.
  await tester.enterText(formFields.at(0), '120');
  await tester.pumpAndSettle();

  await tester.enterText(formFields.at(1), '80');
  await tester.pumpAndSettle();

  await tester.enterText(formFields.at(2), '72');
  await tester.pumpAndSettle();

  // Select feeling.
  final goodOption = find.text('Good');
  expect(goodOption, findsOneWidget, reason: 'Good option not found');
  await tester.tap(goodOption);
  await tester.pumpAndSettle();

  // Add notes.
  await tester.enterText(
    formFields.last,
    'Test measurement after morning walk',
  );
  await tester.pumpAndSettle();
}

/// Submits the completed survey form.
///
/// Locates and taps the submit button using multiple approaches.

Future<void> _submitForm(WidgetTester tester) async {
  final submitButtonText = find.text('Submit');
  if (submitButtonText.evaluate().isNotEmpty) {
    await tester.tap(submitButtonText);
  } else {
    final submitButton = find.byType(ElevatedButton).last;
    expect(submitButton, findsOneWidget, reason: 'Submit button not found');
    await tester.tap(submitButton);
  }
  await tester.pumpAndSettle();
}

/// Handles the save dialog interaction.
///
/// Verifies and interacts with the save dialog elements.

Future<void> _handleSaveDialog(WidgetTester tester) async {
  expect(
    find.text('Save Survey Results'),
    findsOneWidget,
    reason: 'Save dialog not found',
  );

  final localSaveButton = find.text('Save Locally');
  expect(
    localSaveButton,
    findsOneWidget,
    reason: 'Save Locally button not found',
  );
  await tester.tap(localSaveButton);
  await tester.pumpAndSettle();
}

/// Verifies successful form submission.
///
/// Checks for the success message with retry logic.

Future<void> _verifySuccess(WidgetTester tester) async {
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

  expect(
    foundSuccessMessage,
    isTrue,
    reason: 'Success message never appeared',
  );
}
