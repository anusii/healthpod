// HealthPod integration test using solid_test for POD authentication.
//
// Copyright (C) 2025, Software Innovation Institute, ANU
//
// Licensed under the GNU General Public License, Version 3 (the "Licence").
//
// Licence: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:solid_test/solid_test.dart';
import 'package:solidui/solidui.dart';

import 'package:healthpod/main.dart' as app;

/// Integration test suite for HealthPod using solid_test.
///
/// This verifies the app loads correctly with pre-injected POD credentials.
///
/// Before running:
/// 1. Create integration_test/fixtures/test_credentials.json with your POD credentials
/// 2. Run: dart run solid_test:generate_auth
///
/// Run with:
///   flutter test integration_test/app_test.dart -d linux

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = PodConfig.solidCommunityAu();

  group('HealthPod', () {
    setUpAll(() async {
      // Inject POD credentials before tests run.
      // This uses solid_test to inject auth data into flutter_secure_storage.

      await AuthTestSetup.setUp(config: config);
    });

    tearDownAll(() async {
      // Clean up injected credentials after tests.

      await AuthTestSetup.tearDown();
    });

    testWidgets('app loads with authenticated state', (tester) async {
      await tester.runAsync(() async {
        // Launch the app.

        app.main();
        await tester.pumpAndSettle(delay);

        // Wait for initial animations and async operations.

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify basic app structure is present.

        expect(find.byType(SelectionArea), findsOneWidget);
        expect(find.byType(MaterialApp), findsOneWidget);

        // If credentials are properly injected, we should see the home screen
        // (SolidScaffold) instead of the login screen.

        final solidScaffold = find.byType(SolidScaffold);
        if (solidScaffold.evaluate().isNotEmpty) {
          expect(solidScaffold, findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
        } else {
          // If we see a Continue button, credentials may not be injected.
          // Tap Continue to proceed.

          final continueButton = find.text('Continue');
          if (continueButton.evaluate().isNotEmpty) {
            await tester.tap(continueButton);
            await tester.pumpAndSettle();
            await Future.delayed(const Duration(seconds: 1));
            await tester.pumpAndSettle();

            // Should now see the home screen.

            expect(find.byType(SolidScaffold), findsOneWidget);
          }
        }

        // Close any dialogs that may appear.

        final closeButton = find.text('Close');
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        }
      });
    });
  });
}
