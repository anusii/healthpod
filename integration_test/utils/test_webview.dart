/// TestWebView widget for Solid Pod authentication testing.
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solidpod/src/widgets/webview_auth.dart';

import 'test_config.dart';

/// A custom WebView widget designed for Solid Pod authentication testing.
///
/// This widget manages the entire authentication flow including:
/// 1. Navigating to the login page
/// 2. Injecting credentials
/// 3. Handling consent pages
/// 4. Extracting the user's WebID

class TestWebView extends StatefulWidget {
  /// Callback function to handle the extracted WebID.

  final void Function(String?) onWebIdExtracted;

  const TestWebView({super.key, required this.onWebIdExtracted});

  @override
  State<TestWebView> createState() => _TestWebViewState();
}

class _TestWebViewState extends State<TestWebView> {
  /// Tracks the current URL being loaded.

  String _currentUrl = '';

  /// Indicates whether the page is currently loading.

  bool _isLoading = true;

  /// Prevents multiple credential injection attempts.

  bool _hasInjectedCredentials = false;

  /// Handles different stages of the authentication process.
  ///
  /// This method is called on each page load and manages:
  /// - Credential injection on login page
  /// - Consent page handling
  /// - WebID extraction

  Future<void> _handlePage(InAppWebViewController controller) async {
    // Retrieve the current URL.

    final currentUrl = (await controller.getUrl())?.toString() ?? '';
    debugPrint('🔍 Handling page: $currentUrl');

    // Login page handling.

    if (currentUrl.contains('/.account/login/password') &&
        !_hasInjectedCredentials) {
      debugPrint('🔑 Found login page, attempting to inject credentials...');

      // Add a small delay to ensure page is fully loaded.

      await Future.delayed(const Duration(seconds: 1));

      // Attempt to inject login credentials.

      final success = await SolidWebViewAuth.injectCredentials(
        controller,
        TestConfig.testEmail,
        TestConfig.testPassword,
      );

      if (success) {
        setState(() {
          _hasInjectedCredentials = true;
        });
        debugPrint('✅ Login form submitted');
      } else {
        debugPrint('❌ Failed to submit login form');
      }
    }

    // Consent page handling.

    else if (currentUrl.contains('/account/oidc/consent')) {
      debugPrint('🔐 Found consent page, attempting to handle...');
      final clicked = await SolidWebViewAuth.handleConsentPage(controller);
      if (clicked) {
        debugPrint('✅ Consent handled successfully');
      } else {
        debugPrint('❌ Failed to handle consent page');
      }
    }

    // Account page handling and WebID extraction.

    else if (currentUrl.contains('/.account/account')) {
      debugPrint('📝 Found account page, attempting to extract WebID...');
      final webId = await SolidWebViewAuth.extractWebId(controller);
      if (webId != null) {
        debugPrint('✅ WebID extracted: $webId');
        widget.onWebIdExtracted(webId);
      } else {
        debugPrint('❌ Failed to extract WebID');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // InAppWebView for handling the authentication process.

        InAppWebView(
          // Initial URL request to the login page.

          initialUrlRequest: URLRequest(
            url: WebUri(TestConfig.podServer + TestConfig.loginPath),
          ),
          // WebView settings for a clean, controlled authentication environment.

          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            clearCache: true,
            cacheEnabled: false,
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          ),
          // Callback when WebView is initially created.

          onWebViewCreated: (controller) {
            debugPrint('✅ WebView created');
          },
          // Tracks the loading state when a page starts loading.

          onLoadStart: (controller, url) {
            if (url != null) {
              setState(() {
                _currentUrl = url.toString();
                _isLoading = true;
              });
              debugPrint('🌍 Loading: $_currentUrl');
            }
          },
          // Handles page load completion and authentication flow.

          onLoadStop: (controller, url) async {
            if (url != null) {
              setState(() {
                _currentUrl = url.toString();
                _isLoading = false;
              });
              debugPrint('📍 Loaded: $_currentUrl');

              await _handlePage(controller);
            }
          },
          // Error handling for page load failures.

          onReceivedError: (controller, request, error) {
            debugPrint('❌ Load error:');
            debugPrint('URL: ${request.url}');
            debugPrint('Error type: ${error.type}');
            debugPrint('Description: ${error.description}');
          },
          // Captures and logs console messages from the WebView.

          onConsoleMessage: (controller, consoleMessage) {
            // debugPrint('🌐 Console: ${consoleMessage.message}');
          },
        ),
        // Loading indicator while authentication is in progress.

        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
