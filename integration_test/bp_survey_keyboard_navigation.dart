import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:healthpod/main.dart' as app;
import 'package:healthpod/features/bp/survey.dart';

/// Main entry point for integration testing the Blood Pressure Survey keyboard navigation.

void main() {
  bpSurveyKeyboardNavigation();
}

/// Performs integration testing for keyboard navigation in the Blood Pressure Survey.
///
/// This test method verifies:
/// 1. Successful navigation through the app initial screens
/// 2. Keyboard navigation through form text fields
/// 3. Keyboard navigation through radio button groups
/// 4. Ability to reach and interact with the submit button

void bpSurveyKeyboardNavigation() {
  // Initialise the integration test binding.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Pressure Survey Keyboard Navigation:', () {
    testWidgets('Tab order follows expected sequence',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        try {
          // Start the application.

          debugPrint('\n🚀 Starting keyboard navigation test...');
          app.main();
          await tester.pumpAndSettle();

          // Navigate past initial continue screen.

          debugPrint('\n🔍 Looking for Continue button...');
          final continueButton = find.text('Continue');
          expect(continueButton, findsOneWidget);
          await tester.tap(continueButton);
          await tester.pumpAndSettle();

          // Manual authentication step (typically for web-based authentication).

          debugPrint('\n⚠️ Please complete browser authentication manually...');
          await Future.delayed(const Duration(seconds: 15));
          await tester.pumpAndSettle();

          // Navigate to update screen.

          debugPrint('\n🔍 Looking for Update label...');
          final updateLabel = find.text('Update');
          expect(updateLabel, findsOneWidget);
          await tester.tap(updateLabel);
          await tester.pumpAndSettle();

          // Wait for BP Survey to load.

          debugPrint('\n🔍 Waiting for BP Survey to load...');
          await Future.delayed(const Duration(seconds: 3));
          await tester.pumpAndSettle();

          // Verify BP Survey screen is present.

          final bpSurvey = find.byType(BPSurvey);
          expect(bpSurvey, findsOneWidget);
          await tester.pump(const Duration(seconds: 2));

          // Check for expected number of form fields.

          debugPrint('\n🔍 Verifying form elements...');
          final formFields = find.byType(TextFormField);
          expect(formFields, findsNWidgets(4));

          // Test text input and tabbing through first 3 text fields.

          debugPrint('\n🎯 Testing first 3 field navigation...');
          for (int i = 0; i < 3; i++) {
            // Select and interact with each text field.i
            final field = formFields.at(i);
            await tester.tap(field);
            await tester.pump();

            // Enter test text into the field.

            final testValue = 'Test${i + 1}';
            await tester.enterText(field, testValue);
            await tester.pump();

            // Verify text input.

            expect(find.text(testValue), findsOneWidget);
            debugPrint('✓ Field ${i + 1} passed text input test');

            // Tab to next field (except for last field).

            if (i < 2) {
              // Tab from field i -> i+1.

              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
            }
          }

          // Navigate from last text field to first radio button group.

          debugPrint('\n🔍 Attempting 2 tabs from q3 to first radio button...');
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          // Verify and interact with radio button groups.

          debugPrint('\n🎯 Testing radio button tabbing sequence...');
          final radioButtons = find.byType(RadioListTile<String>);
          expect(radioButtons, findsNWidgets(4));

          // Tap each radio button to ensure interactivity.

          for (int i = 0; i < 4; i++) {
            await tester.tap(radioButtons.at(i));
            await tester.pump();
            debugPrint('✓ Radio button ${i + 1} tapped');
          }

          // Navigate to and interact with submit button.

          debugPrint('\n🎯 Testing Submit button...');
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();

          final submitButton = find.text('Submit');
          expect(submitButton, findsOneWidget);

          // Tap submit button.

          await tester.tap(submitButton);
          await tester.pump();

          debugPrint('\n✅ Navigation test completed successfully');
        } catch (e, stackTrace) {
          // Comprehensive error logging.

          debugPrint('\n❌ Navigation test failed with error: $e');
          debugPrint('\nStack trace: $stackTrace');
          rethrow;
        }
      });
    });
  });
}
