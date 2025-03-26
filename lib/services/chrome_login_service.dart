import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:webdriver/sync_io.dart';

/// A service class that handles automated login using ChromeDriver.

class ChromeLoginService {
  /// Singleton instance.

  static ChromeLoginService? _instance;
  WebDriver? _driver;

  /// Private constructor.

  ChromeLoginService._();

  /// Get singleton instance.

  static ChromeLoginService get instance {
    _instance ??= ChromeLoginService._();
    return _instance!;
  }

  /// Initialise ChromeDriver.

  Future<void> initialize() async {
    try {
      _driver = createDriver(
        spec: WebDriverSpec.W3c,
        uri: Uri.parse('http://localhost:9515'),
        desired: {
          'browserName': 'chrome',
          'goog:chromeOptions': {
            'args': [
              '--no-sandbox',
              '--disable-dev-shm-usage',
              // Run in headless mode (no UI).

              '--headless',
            ],
          },
        },
      );
      debugPrint('✅ ChromeDriver initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize ChromeDriver: $e');
      rethrow;
    }
  }

  /// Perform automated login.

  Future<String?> login(
      String serverUrl, String username, String password) async {
    if (_driver == null) {
      throw Exception('ChromeDriver not initialized');
    }

    try {
      // Navigate to login page.

      debugPrint('🌐 Navigating to: $serverUrl/.account/login/password/');
      _driver!.get('$serverUrl/.account/login/password/');

      // Add a delay to ensure page loads.

      await Future.delayed(const Duration(seconds: 2));

      debugPrint('🔍 Current URL: ${_driver!.currentUrl}');

      // Check if we're already on the account page (already logged in).

      if (_driver!.currentUrl.contains('/.account/account')) {
        debugPrint('✅ Already logged in, extracting WebID');
        return await _extractWebId();
      }

      // Check if we're on the login page.

      if (!_driver!.currentUrl.contains('/.account/login/password')) {
        debugPrint('❌ Not on login page, current URL: ${_driver!.currentUrl}');
        return null;
      }

      debugPrint('🔎 Looking for login form elements...');

      // Wait and retry strategy for finding elements.

      WebElement? emailInput;
      WebElement? passwordInput;
      WebElement? submitButton;

      for (var i = 0; i < 3; i++) {
        try {
          emailInput = _driver!.findElement(
            const By.cssSelector('input[name="email"]'),
          );
          passwordInput = _driver!.findElement(
            const By.cssSelector('input[name="password"]'),
          );
          submitButton = _driver!.findElement(
            const By.cssSelector('button[type="submit"]'),
          );
          break;
        } catch (e) {
          if (i == 2) {
            debugPrint('❌ Failed to find login form elements after retries');
            return null;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (emailInput == null || passwordInput == null || submitButton == null) {
        debugPrint('❌ Login form elements not found');
        return null;
      }

      debugPrint('✅ Found all login form elements');
      debugPrint('📝 Filling in credentials...');

      // Clear existing values and fill in credentials.

      try {
        await Future.wait([
          Future(() => emailInput!.clear()),
          Future(() => passwordInput!.clear()),
        ]);

        await Future.wait([
          Future(() => emailInput!.sendKeys(username)),
          Future(() => passwordInput!.sendKeys(password)),
        ]);
      } catch (e) {
        debugPrint('❌ Error filling in credentials: $e');
        return null;
      }

      // Check "remember me" if present.

      try {
        final rememberMe = _driver!.findElement(
          const By.cssSelector('input[name="remember"]'),
        );
        if (!rememberMe.selected) {
          rememberMe.click();
          debugPrint('✅ Checked remember me');
        }
      } catch (e) {
        debugPrint('ℹ️ Remember checkbox not found');
      }

      // Submit form.

      debugPrint('🚀 Submitting login form...');
      submitButton.click();

      // Wait for navigation with timeout.

      var timeout = 10;
      while (timeout > 0 &&
          _driver!.currentUrl.contains('/.account/login/password')) {
        await Future.delayed(const Duration(seconds: 1));
        timeout--;
      }

      if (timeout == 0) {
        debugPrint(
            '❌ Login timeout - page did not change after form submission');
        return null;
      }

      debugPrint('📍 Post-login URL: ${_driver!.currentUrl}');

      // Handle consent page if it appears.

      await _handleConsentPage();

      // Wait for potential redirects.

      await Future.delayed(const Duration(seconds: 2));

      // Extract WebID from account page.

      final webId = await _extractWebId();
      debugPrint('🆔 Extracted WebID: $webId');
      return webId;
    } catch (e, stackTrace) {
      debugPrint('❌ Login failed with error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Handle the consent page if it appears.

  Future<void> _handleConsentPage() async {
    try {
      debugPrint('🔍 Checking for consent page...');
      final url = _driver!.currentUrl;
      debugPrint('📍 Current URL while checking consent: $url');

      if (url.contains('/account/oidc/consent')) {
        debugPrint('🔐 Consent page detected');

        // Add delay to ensure page loads.

        await Future.delayed(const Duration(seconds: 2));

        final authorizeButton = _driver!.findElement(
          const By.cssSelector('button#authorize'),
        );
        debugPrint('✅ Found authorize button');

        // Check remember checkbox if present.

        try {
          final rememberConsent = _driver!.findElement(
            const By.cssSelector('input[name="remember"]'),
          );
          if (!rememberConsent.selected) {
            rememberConsent.click();
            debugPrint('✅ Checked remember consent');
          }
        } catch (e) {
          debugPrint('ℹ️ Remember consent checkbox not found');
        }

        debugPrint('🚀 Clicking authorize button');
        authorizeButton.click();

        // Wait for consent processing.

        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('ℹ️ No consent page found or error handling consent: $e');
    }
  }

  /// Extract WebID from account page.

  Future<String?> _extractWebId() async {
    try {
      debugPrint('🔍 Attempting to extract WebID...');
      final url = _driver!.currentUrl;
      debugPrint('📍 Current URL while extracting WebID: $url');

      if (url.contains('/.account/account')) {
        // Add delay to ensure page loads.

        await Future.delayed(const Duration(seconds: 2));

        debugPrint('🔎 Looking for WebID element...');
        final webIdElement = _driver!.findElement(
          const By.cssSelector('#webIdEntries li a'),
        );
        final webId = webIdElement.text;
        debugPrint('✅ Found WebID: $webId');
        return webId;
      } else {
        debugPrint('❌ Not on account page, current URL: $url');
      }
    } catch (e) {
      debugPrint('❌ Failed to extract WebID: $e');
    }
    return null;
  }

  /// Clean up resources.

  Future<void> dispose() async {
    if (_driver != null) {
      _driver!.quit();
      _driver = null;
    }
  }
}
