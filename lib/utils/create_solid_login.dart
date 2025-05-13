/// Create Solid Login Widget.
//
// Time-stamp: <Thursday 2025-04-17 10:52:11 +1000 Graham Williams>
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
import 'package:healthpod/services/chrome_login_service.dart';
import 'package:healthpod/utils/platform/helper.dart';

/// Enum to represent the outcome of an auto-login attempt.

enum AutoLoginStatus {
  success,
  chromeDriverNotAvailable,
  generalFailure,
}

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
  debugPrint('🔥 INTEGRATION_TEST: $isIntegrationTest');

  if (isIntegrationTest) {
    debugPrint('✅ Using WebView for login');
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Solid Login - WebView Mode')),
        body: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://pods.dev.solidcommunity.au/'),
          ),
          initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
          onLoadStop: (controller, url) async {
            debugPrint('🌍 WebView Loaded: $url');

            // Automated login flow:
            // Step 1: Initial navigation to login page.

            if (url.toString() == 'https://pods.dev.solidcommunity.au/') {
              debugPrint('🔄 Redirecting to login page...');
              await controller.loadUrl(
                urlRequest: URLRequest(
                  url: WebUri(
                    'https://pods.dev.solidcommunity.au/.account/login/password/',
                  ),
                ),
              );
            }

            // Step 2: Credential injection on login page.

            if (url.toString().contains('/.account/login/password')) {
              debugPrint('✍️ Injecting login credentials...');
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

            if (url.toString().contains('/account/oidc/consent')) {
              debugPrint("🔍 Detected consent screen, clicking 'Yes'...");
              await controller.evaluateJavascript(source: '''
                let yesButton = document.querySelector("button#authorize");
                if (yesButton) {
                  setTimeout(() => {
                    yesButton.click();
                  }, 2000);
                }
              ''');
            }

            // Step 4: Extract WebID from account page.

            if (url.toString().contains('/.account/account')) {
              debugPrint(
                  '✅ Login detected at /.account/account/, waiting a bit for DOM...');
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
                debugPrint('🔑 Extracted WebID from HTML: $extractedWebId');
                SolidLoginTestHelper.extractedWebId = extractedWebId;
              } else {
                debugPrint('❌ Could not find WebID under #webIdEntries li a!');
              }
            }
          },
        ),
      ),
    );
  } else {
    debugPrint('❌ Using external browser for login');

    return Consumer(
      builder: (context, ref, child) {
        final serverUrl = ref.watch(serverURLProvider);
        final email = ref.watch(emailProvider);
        final password = ref.watch(passwordProvider);

        debugPrint('🔍 Checking saved credentials...');
        debugPrint('📡 Server URL: $serverUrl');
        debugPrint('👤 Email present: ${email.isNotEmpty}');
        debugPrint('🔑 Password present: ${password.isNotEmpty}');

        // If we have saved credentials, try auto-login.

        if (email.isNotEmpty && password.isNotEmpty) {
          // The _performAutoLogin future will now internally handle minimum splash time
          // if a real attempt is made.

          final autoLoginFuture =
              _performAutoLogin(serverUrl, email, password, context);

          return FutureBuilder<AutoLoginStatus>(
            // Wait for autoLoginFuture which now incorporates necessary delays.

            future: autoLoginFuture,
            builder: (context, AsyncSnapshot<AutoLoginStatus> snapshot) {
              // Changed snapshot type
              // Always show the splash screen while waiting.

              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('⏳ Auto-login process initiated...');
                // Show an elegant splash screen with app logo and subtle loading indicator.

                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo with larger size.

                        Image(
                          image: const AssetImage(
                              'assets/images/healthpod_icon.png'),
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 24),
                        // Subtle loading indicator.

                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Attempting auto-login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 0.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Once the future completes, check login result.

              if (snapshot.hasData) {
                final autoLoginStatus = snapshot.data!;
                if (autoLoginStatus == AutoLoginStatus.success) {
                  debugPrint('✅ Auto-login successful!');
                  return const HealthPodHome();
                } else {
                  // Auto-login did not succeed.
                  // Only print generic failure if it wasn't a ChromeDriver-specific skip,
                  // as that case is already logged in detail by _performAutoLogin.

                  if (autoLoginStatus == AutoLoginStatus.generalFailure) {
                    debugPrint('⚠️ Auto-login failed, showing login screen');
                  }
                  // For AutoLoginStatus.chromeDriverNotAvailable, _performAutoLogin has logged enough.
                  // Fall through to show normal login screen.
                }
              } else if (snapshot.hasError) {
                // Handle errors from Future.wait itself or from one of the futures.

                debugPrint('❌ Auto-login process error: ${snapshot.error}');
              }
              // For all other cases (error or failed login), show normal login screen.

              return _buildNormalLogin(serverUrl);
            },
          );
        }

        debugPrint('ℹ️ No saved credentials found, showing login screen');
        return _buildNormalLogin(serverUrl);
      },
    );
  }
}

/// Perform automated login using ChromeDriver.

Future<AutoLoginStatus> _performAutoLogin(
  String serverUrl,
  String username,
  String password,
  BuildContext context,
) async {
  final loginService = ChromeLoginService.instance;
  debugPrint('ℹ️ Checking ChromeDriver availability for auto-login...');

  final bool chromeDriverReady = await loginService.initialize();

  debugPrint(
      '✨ Attempting auto-login with saved credentials (ChromeDriver ready: $chromeDriverReady)');

  if (!chromeDriverReady) {
    debugPrint(
        'ℹ️ ChromeDriver not available or failed to initialize. Auto-login via ChromeDriver will be skipped.');
    await loginService.dispose();
    return AutoLoginStatus.chromeDriverNotAvailable;
  }

  if (!context.mounted) return AutoLoginStatus.generalFailure;

  // ChromeDriver IS ready. Proceed with attempt and ensure minimum display time for this path.

  try {
    final attemptLogicFuture = Future.any([
      _attemptLogin(serverUrl, username, password, context, loginService),
      // Timeout for login attempt after 5 seconds.

      Future.delayed(const Duration(seconds: 5), () => false),
    ]);

    // Minimum splash screen duration, runs in parallel with attemptLogicFuture.

    final minDisplayFuture =
        Future.delayed(const Duration(seconds: 1), () => true);

    // Wait for both the attempt (which includes its own timeout) and the minimum display duration.

    final results = await Future.wait([attemptLogicFuture, minDisplayFuture]);
    final bool attemptSuccess = results[0]; // Result of attemptLogicFuture

    // _attemptLogin disposes the loginService instance it's given.

    return attemptSuccess
        ? AutoLoginStatus.success
        : AutoLoginStatus.generalFailure;
  } catch (e) {
    debugPrint(
        '❌ Error during auto-login sequence (after ChromeDriver check): $e');
    // Ensure disposal if an error occurred before _attemptLogin could dispose it,
    // or if Future.wait itself threw. loginService.dispose() is idempotent.

    await loginService.dispose();
    return AutoLoginStatus.generalFailure;
  }
}

/// Actual login attempt implementation.

Future<bool> _attemptLogin(
  String serverUrl,
  String username,
  String password,
  BuildContext context,
  ChromeLoginService loginService,
) async {
  try {
    // No need to check chromeDriverReady here anymore, as _performAutoLogin handles it.

    final webId = await loginService.login(serverUrl, username, password);
    if (webId != null) {
      if (context.mounted) {
        final result = await solidAuthenticate(webId, context);
        return result != null;
      }
    }
    return false;
  } catch (e) {
    debugPrint('❌ Error during specific login attempt execution: $e');
    return false;
  } finally {
    await loginService.dispose();
    debugPrint('ℹ️ ChromeLoginService disposed after login attempt.');
  }
}

/// Build the normal login widget.

Widget _buildNormalLogin(String serverUrl) {
  return Builder(
    builder: (context) {
      return SolidLogin(
        required: false,
        title: 'HEALTH POD',
        appDirectory: 'healthpod',
        webID: serverUrl.isNotEmpty
            ? serverUrl
            : 'https://pods.dev.solidcommunity.au',
        image: const AssetImage('assets/images/healthpod_image.png'),
        logo: const AssetImage('assets/images/healthpod_icon.png'),
        link: 'https://github.com/anusii/healthpod/blob/main/README.md',
        child: const HealthPodHome(),
      );
    },
  );
}
