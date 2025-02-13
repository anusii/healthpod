/// Integration test for the Solid pod connection.
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_config.dart';
import 'utils/test_webview.dart';

/// Main integration test for Solid Pod authentication.
///
/// This test verifies the entire authentication flow:
/// 1. Launches the WebView
/// 2. Navigates through login and consent pages
/// 3. Extracts the user's WebID
/// 4. Validates the extracted WebID

void main() {
  // Initialises the integration test binding.

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pod Connection Tests:', () {
    testWidgets('WebView login test', (tester) async {
      // Completer to handle asynchronous WebID extraction.

      final webIdCompleter = Completer<String>();

      // Build the test widget.

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TestWebView(
            // Callback to complete the WebID when extracted.

            onWebIdExtracted: (webId) {
              if (webId != null && !webIdCompleter.isCompleted) {
                webIdCompleter.complete(webId);
              }
            },
          ),
        ),
      ));

      debugPrint('✅ Test widget built');
      await tester.pumpAndSettle();

      try {
        // Wait for WebID extraction with a timeout.

        final webId = await webIdCompleter.future.timeout(TestConfig.timeout);

        // Validate the extracted WebID.

        expect(webId, isNotNull);
        expect(webId.startsWith(TestConfig.podServer), isTrue);
        debugPrint('✅ Test completed successfully');
      } on TimeoutException {
        // Handle test timeout.

        debugPrint('❌ Test timed out waiting for WebID');
        fail('Authentication timed out');
      }
    });
  });
}
