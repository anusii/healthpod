/// Create Solid Login Widget.
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

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/home.dart';
import 'package:healthpod/utils/platform/helper.dart';

/// Solid POD Authentication Widget Creator
///
/// This file provides functionality to create authentication widgets for Solid POD
/// connections in both testing and production environments. It supports two modes:
///
/// 1. WebView Mode (Testing):
///    - Activated when INTEGRATION_TEST=true
///    - Provides automated login via InAppWebView
///    - Handles credential injection, consent flows, and WebID extraction
///    - Used primarily for integration testing
///
/// 2. External Browser Mode (Production):
///    - Default mode for regular app usage
///    - Uses the SolidLogin widget for authentication
///    - Supports optional Pod connectivity
///    - Maintains session persistence
///
/// The file also includes a helper class for storing WebIDs during testing sessions.

/// Global navigator key for managing navigation state.

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Helper class for storing WebID during integration tests
///
/// Provides a static storage mechanism for the WebID extracted during
/// automated WebView authentication flows. This is specifically used
/// in integration testing scenarios.

class SolidLoginTestHelper {
  static String? extractedWebId;
}

/// Creates the appropriate Solid login widget based on environment.
///
/// Returns either a WebView-based login interface for integration testing
/// or a standard SolidLogin widget for production use.
///
/// Parameters:
///   context: BuildContext for widget creation
///
/// Returns:
///   A Widget configured for the appropriate authentication mode

Widget createSolidLogin(BuildContext context) {
  // Determine if running in integration test mode.

  final bool isIntegrationTest = PlatformHelper.isIntegrationTest();

  debugPrint("🔥 INTEGRATION_TEST: $isIntegrationTest");

  if (isIntegrationTest) {
    debugPrint("✅ Using WebView for login");
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text("Solid Login - WebView Mode")),
        body: InAppWebView(
          // Configure initial POD server URL.

          initialUrlRequest: URLRequest(
            url: WebUri("https://pods.dev.solidcommunity.au/"),
          ),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
          onLoadStop: (controller, url) async {
            debugPrint("🌍 WebView Loaded: $url");

            // Automated login flow:

            // Step 1: Initial navigation to login page.

            if (url.toString() == "https://pods.dev.solidcommunity.au/") {
              debugPrint("🔄 Redirecting to login page...");
              await controller.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    "https://pods.dev.solidcommunity.au/.account/login/password/",
                  ),
                ),
              );
            }

            // Step 2: Credential injection on login page.

            if (url.toString().contains("/.account/login/password")) {
              debugPrint("✍️ Injecting login credentials...");
              await controller.evaluateJavascript(source: """

                let emailInput = document.querySelector('input[name="email"]');
                let passwordInput = document.querySelector('input[name="password"]');
                let loginButton = document.querySelector('button[type="submit"]');

                if (emailInput && passwordInput && loginButton) {
                  emailInput.value = 'test@anu.edu.au';
                  passwordInput.value = 'SuperSecure123';
                  setTimeout(() => {
                    loginButton.click();
                  }, 2000);
                }

              """);
            }

            // Step 3: Handle OAuth consent screen if present.

            if (url.toString().contains("/account/oidc/consent")) {
              debugPrint("🔍 Detected consent screen, clicking 'Yes'...");
              await controller.evaluateJavascript(source: """

                let yesButton = document.querySelector("button#authorize");
                if (yesButton) {
                  setTimeout(() => {
                    yesButton.click();
                  }, 2000);
                }

              """);
            }

            // Step 4: Extract WebID from account page.
            if (url.toString().contains("/.account/account")) {
              debugPrint(
                  "✅ Login detected at /.account/account/, waiting a bit for DOM...");

              // Allow time for DOM to fully render.

              await Future.delayed(const Duration(seconds: 3));

              // Extract WebID using JavaScript DOM manipulation.

              final extractedWebId =
                  await controller.evaluateJavascript(source: """

                    (function() {
                      const anchor = document.querySelector('#webIdEntries li a');
                      if (anchor) {
                        return anchor.href;
                      }
                      return '';
                    })();

                  """) as String;

              // Store or log the extracted WebID.

              if (extractedWebId.isNotEmpty) {
                debugPrint("🔑 Extracted WebID from HTML: $extractedWebId");
                SolidLoginTestHelper.extractedWebId = extractedWebId;
              } else {
                debugPrint("❌ Could not find WebID under #webIdEntries li a!");
              }

              // Note: Intentionally not navigating away to preserve WebView state.
            }
          },
        ),
      ),
    );
  } else {
    // Production mode: Use standard SolidLogin widget.

    debugPrint("❌ Using external browser for login");
    return const SolidLogin(
      // If the app has functionality that does not require access to Pod
      // data then [required] can be `false`. If the user connects to their
      // Pod then their session information will be saved to save having to
      // log in everytime. The login token and the security key are (optionally)
      // cached so that the login information is not required every time.
      //
      // In this demo app we allow the CONTINUE button so as to demonstrate
      // the use of [SolidLoginPopup] during the app session. If we want to
      // save the data to the Pod or view data from the Pod, then if the
      // user did not log in during startup we can call [SolidLoginPopup] to
      // establish the connection at that time.

      required: false, // Allow app functionality without Pod access.
      title: 'HEALTH POD',
      appDirectory: 'healthpod',
      webID: 'https://pods.dev.solidcommunity.au', // Set default server to dev.
      image: AssetImage('assets/images/healthpod_image.png'),
      logo: AssetImage('assets/images/healthpod_icon.png'),
      link: 'https://github.com/anusii/healthpod/blob/main/README.md',
      child: HealthPodHome(),
    );
  }
}
