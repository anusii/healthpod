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

// TODO(github/issue): We are currently using a local copy of the solidpod package
// because the solidAuthenticate function is not exposed in the public API. This
// function is essential for implementing auto-login with saved credentials, as it
// handles the authentication flow with the Solid server, including token management
// and WebID retrieval. Once the solidpod package exposes this functionality in its
// public API, we should update to use the published package version instead.

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart';
// ignore: implementation_imports
import 'package:solidpod/src/solid/authenticate.dart' show solidAuthenticate;

import 'package:healthpod/home.dart';
import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/utils/platform/helper.dart';
import 'package:healthpod/services/chrome_login_service.dart';

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
  final bool isIntegrationTest = PlatformHelper.isIntegrationTest();
  debugPrint("🔥 INTEGRATION_TEST: $isIntegrationTest");

  if (isIntegrationTest) {
    debugPrint("✅ Using WebView for login");
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text("Solid Login - WebView Mode")),
        body: InAppWebView(
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
              await Future.delayed(const Duration(seconds: 3));

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

              if (extractedWebId.isNotEmpty) {
                debugPrint("🔑 Extracted WebID from HTML: $extractedWebId");
                SolidLoginTestHelper.extractedWebId = extractedWebId;
              } else {
                debugPrint("❌ Could not find WebID under #webIdEntries li a!");
              }
            }
          },
        ),
      ),
    );
  } else {
    debugPrint("❌ Using external browser for login");

    return Consumer(
      builder: (context, ref, child) {
        final serverUrl = ref.watch(serverURLProvider);
        final username = ref.watch(usernameProvider);
        final password = ref.watch(passwordProvider);

        debugPrint("🔍 Checking saved credentials...");
        debugPrint("📡 Server URL: $serverUrl");
        debugPrint("👤 Username present: ${username.isNotEmpty}");
        debugPrint("🔑 Password present: ${password.isNotEmpty}");

        // If we have saved credentials, try auto-login.

        if (username.isNotEmpty && password.isNotEmpty) {
          debugPrint("✨ Attempting auto-login with saved credentials");
          return FutureBuilder(
            future: _performAutoLogin(serverUrl, username, password, context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint("⏳ Auto-login in progress...");
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Logging in with saved credentials...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                debugPrint("❌ Auto-login failed: ${snapshot.error}");
                // Fall back to normal login screen.

                return _buildNormalLogin(serverUrl);
              }

              if (snapshot.hasData && snapshot.data == true) {
                debugPrint("✅ Auto-login successful!");
                return const HealthPodHome();
              }

              // If auto-login failed, show normal login screen.

              debugPrint("⚠️ Auto-login failed, showing login screen");
              return _buildNormalLogin(serverUrl);
            },
          );
        }

        debugPrint("ℹ️ No saved credentials found, showing login screen");
        return _buildNormalLogin(serverUrl);
      },
    );
  }
}

/// Perform automated login using ChromeDriver.

Future<bool> _performAutoLogin(
  String serverUrl,
  String username,
  String password,
  BuildContext context,
) async {
  try {
    final loginService = ChromeLoginService.instance;
    await loginService.initialize();

    final webId = await loginService.login(serverUrl, username, password);
    if (webId != null) {
      if (context.mounted) {
        final result = await solidAuthenticate(webId, context);
        return result != null;
      }
    }
    return false;
  } catch (e) {
    debugPrint("❌ Auto-login error: $e");
    return false;
  } finally {
    await ChromeLoginService.instance.dispose();
  }
}

/// Build the normal login widget.

Widget _buildNormalLogin(String serverUrl) {
  return SolidLogin(
    required: false,
    title: 'HEALTH POD',
    appDirectory: 'healthpod',
    webID:
        serverUrl.isNotEmpty ? serverUrl : 'https://pods.dev.solidcommunity.au',
    image: const AssetImage('assets/images/healthpod_image.png'),
    logo: const AssetImage('assets/images/healthpod_icon.png'),
    link: 'https://github.com/anusii/healthpod/blob/main/README.md',
    child: const HealthPodHome(),
  );
}
