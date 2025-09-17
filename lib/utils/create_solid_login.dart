/// Create Solid Login Widget.
//
// Time-stamp: <Friday 2025-08-08 08:29:49 +1000 Graham Williams>
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/home.dart';
import 'package:healthpod/providers/settings.dart';
import 'package:healthpod/services/chrome_login_service.dart';

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
  // debugPrint('❌ Using external browser for login');

  return Consumer(
    builder: (context, ref, child) {
      final serverUrl = ref.watch(serverURLProvider);
      final email = ref.watch(emailProvider);
      final password = ref.watch(passwordProvider);

      // Checking saved credentials.

      if (email.isEmpty || password.isEmpty) {
        // No saved credentials found.

        return _buildNormalLogin(serverUrl);
      }

      // Checking ChromeDriver availability for auto-login.

      return FutureBuilder<AutoLoginStatus>(
        future: _attemptAutoLogin(serverUrl, email, password),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Attempting auto-login...'),
                  ],
                ),
              ),
            );
          }

          final status = snapshot.data ?? AutoLoginStatus.generalFailure;

          switch (status) {
            case AutoLoginStatus.success:
              // Auto-login successful.

              return const HealthPodHome();

            case AutoLoginStatus.chromeDriverNotAvailable:
              // ChromeDriver not available.

              return _buildNormalLogin(serverUrl);

            case AutoLoginStatus.generalFailure:
              debugPrint('❌ Auto-login failed, showing manual login');
              return _buildNormalLogin(serverUrl);
          }
        },
      );
    },
  );
}

/// Perform automated login using ChromeDriver.

Future<AutoLoginStatus> _attemptAutoLogin(
  String serverUrl,
  String username,
  String password,
) async {
  final loginService = ChromeLoginService.instance;
  // Checking ChromeDriver availability.

  final bool chromeDriverReady = await loginService.initialize();

  // Attempting auto-login with saved credentials.

  if (!chromeDriverReady) {
    debugPrint(
      'ℹ️ ChromeDriver not available or failed to initialize. Auto-login via ChromeDriver will be skipped.',
    );
    await loginService.dispose();
    return AutoLoginStatus.chromeDriverNotAvailable;
  }

  try {
    final attemptLogicFuture = Future.any([
      _attemptLogin(serverUrl, username, password, loginService),
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
      '❌ Error during auto-login sequence (after ChromeDriver check): $e',
    );
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
  ChromeLoginService loginService,
) async {
  try {
    // No need to check chromeDriverReady here anymore, as _performAutoLogin handles it.

    final webId = await loginService.login(serverUrl, username, password);
    if (webId != null) {
      // Note: solidAuthenticate requires a BuildContext, but we don't have one here
      // This is a limitation of the current auto-login implementation
      // WebID obtained successfully.

      return true;
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
        image: const AssetImage('assets/images/app_image.png'),
        logo: const AssetImage('assets/images/app_icon.png'),
        link: 'https://github.com/anusii/healthpod/blob/main/README.md',
        child: const HealthPodHome(),
      );
    },
  );
}
