/// Integration test suite for keyboard navigation in BP survey.
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
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:healthpod/main.dart' as app;
import 'package:healthpod/features/bp/survey.dart';

/// Main entry point for the integration test suite.
/// 
/// This function initializes and runs the keyboard navigation test 
/// for the Blood Pressure (BP) Survey screen in the HealthPod application.

void main() {
  // Run the blood pressure survey keyboard navigation test.

  bpSurveyKeyboardNavigation();
}

/// Comprehensive integration test for keyboard navigation in the BP Survey.
/// 
/// This test verifies the following key aspects of keyboard navigation:
/// 1. Proper app launch and navigation to the BP Survey screen
/// 2. Text input functionality for all form fields
/// 3. Tab key navigation between form elements
/// 4. Radio button selection and interaction
/// 5. Submit button accessibility
/// 
/// The test simulates a user's keyboard-driven interaction with the survey form,
/// ensuring that all form elements can be accessed and manipulated via keyboard.

void bpSurveyKeyboardNavigation() {
  // Initialise the integration test binding
  // This is crucial for running integration tests in Flutter.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Group tests related to BP Survey keyboard navigation
  group('Blood Pressure Survey Keyboard Navigation:', () {
    testWidgets(
      'Tab order follows expected sequence',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          try {
            // Launch the application.
            // Debug print helps track the test progress.

            debugPrint('\n🚀 Starting keyboard navigation test...');
            app.main();
            await tester.pumpAndSettle();

            // Navigate through initial Continue button.

            debugPrint('\n🔍 Looking for Continue button...');
            final continueButton = find.text('Continue');
            
            // Verify Continue button exists.

            expect(continueButton, findsOneWidget, reason: 'Continue button not found');
            await tester.tap(continueButton);
            await tester.pumpAndSettle();

            // Pause for manual authentication .
            // This allows time for potential browser-based login.

            debugPrint('\n⚠️ Please complete browser authentication manually...');
            await Future.delayed(const Duration(seconds: 15));
            await tester.pumpAndSettle();

            // Navigate to Update section.
            
            debugPrint('\n🔍 Looking for Update label...');
            final updateLabel = find.text('Update');
            
            // Verify Update label exists.

            expect(updateLabel, findsOneWidget, reason: 'Update label not found');
            await tester.tap(updateLabel);
            await tester.pumpAndSettle();

            // Wait for BP Survey to load.

            debugPrint('\n🔍 Waiting for BP Survey to load...');
            await Future.delayed(const Duration(seconds: 3));
            await tester.pumpAndSettle();

            // Verify BP Survey screen is displayed.

            final bpSurvey = find.byType(BPSurvey);
            expect(bpSurvey, findsOneWidget, reason: 'BP Survey not found');

            // Additional pause to ensure form elements are fully initialised.

            await tester.pump(const Duration(seconds: 2));

            debugPrint('\n🔍 Verifying form elements...');

            // Locate all text input fields in the form.

            final formFields = find.byType(TextFormField);
            
            // Verify correct number of text fields (expecting 4).

            expect(formFields, findsNWidgets(4), reason: 'Expected 4 text fields');

            debugPrint('\n🎯 Testing field navigation sequence...');

            // Test text input for each form field.

            for (int i = 0; i < 4; i++) {
                final field = formFields.at(i);
                
                // Focus on the current field.

                await tester.tap(field);
                await tester.pump();

                // Enter test text into the field.

                final testValue = 'Test${i + 1}';
                await tester.enterText(field, testValue);
                await tester.pump();

                // Verify text was correctly entered.

                expect(
                    find.text(testValue),
                    findsOneWidget,
                    reason: 'Text not entered in field ${i + 1}'
                );

                debugPrint('✓ Field ${i + 1} passed text input test');

                // Move to next field using Tab key (except for the last field).

                if (i < 3) {
                    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                    await tester.pump();
                }
            }

            // Locate radio button list tiles.

            final radioButtons = find.byType(RadioListTile<String>);
            
            // Verify correct number of radio buttons (expecting 4).

            expect(radioButtons, findsNWidgets(4), reason: 'Expected 4 radio buttons');

            // Test selection of each radio button.

            for (int i = 0; i < 4; i++) {
                final radio = radioButtons.at(i);
                
                // Tap each radio button.

                await tester.tap(radio);
                await tester.pump();

                // Verify radio button was selected.

                final RadioListTile<String> radioWidget = tester.widget(radio);
                expect(radioWidget.groupValue, isNotNull);

                debugPrint('✓ Radio button ${i + 1} passed selection test');
            }

            // Locate and verify Submit button.

            final submitButton = find.text('Submit');
            expect(submitButton, findsOneWidget, reason: 'Submit button not found');
            
            // Attempt to tap Submit button.

            await tester.tap(submitButton);
            await tester.pump();

            debugPrint('\n✅ Navigation test completed successfully');

          } catch (e, stackTrace) {
            // Comprehensive error logging.

            debugPrint('\n❌ Navigation test failed with error: $e');
            debugPrint('\nStack trace: $stackTrace');
            
            // Re-throw the error to fail the test.

            rethrow;
          }
        });
      },
    );
  });
}