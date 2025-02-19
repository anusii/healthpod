/// Integration test suite for Solid Pod authentication flow for Linux.
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

import 'package:test/test.dart';
import 'package:webdriver/async_io.dart';
import 'package:webdriver/support/async.dart';

import 'utils/chrome_driver_process.dart';
import 'utils/logger.dart';
import 'utils/test_config.dart';

/// Integration test suite for Solid Pod authentication flow.
///
/// This test suite automates the authentication process for a Solid Pod,
/// verifying that users can successfully:
/// - Launch a headless Chrome browser
/// - Navigate to the login page
/// - Input credentials
/// - Handle consent pages if present
/// - Reach the account dashboard
///
/// The suite uses Chrome WebDriver for browser automation and includes
/// proper setup/teardown of browser instances.
///
/// Requirements:
/// - Chrome browser installed
/// - Valid Solid Pod credentials configured in TestConfig
/// - ChromeDriver matching Chrome version
/// - Network access to Pod server

void main() {
  // Reference to the ChromeDriver process that will be started/stopped.

  ChromeDriverProcess? chromeDriver;

  // Reference to WebDriver instance for browser control.

  WebDriver? driver;

  setUp(() async {
    try {
      // Initialise and start ChromeDriver process.

      chromeDriver = ChromeDriverProcess();
      await chromeDriver!.start();

      // Configure Chrome capabilities for headless testing.

      final capabilities = {
        Capabilities.chromeOptions: {
          'args': [
            '--no-sandbox', // Required for running in containers.
            '--headless', // Run browser in headless mode.
            '--disable-gpu', // Recommended for headless mode.
            '--disable-dev-shm-usage' // Prevent crashes in containers.
          ]
        }
      };

      // Create WebDriver instance with configured capabilities.

      driver = await createDriver(
          uri: Uri.parse('http://localhost:${TestConfig.chromeDriverPort}'),
          desired: capabilities);
      Logger.info('✅ WebDriver initialized successfully');
    } catch (e, stackTrace) {
      // Log any setup failures and ensure cleanup.

      Logger.error('❌ Setup failed: $e');
      Logger.error('📜 Stack trace: $stackTrace');
      if (chromeDriver != null) await chromeDriver!.stop();
      rethrow;
    }
  });

  tearDown(() async {
    // Clean up WebDriver session if it exists.
    if (driver != null) {
      try {
        await driver!.quit();
      } catch (e) {
        Logger.error('⚠️ Error quitting WebDriver: $e');
      }
    }

    // Stop ChromeDriver process if it exists.

    if (chromeDriver != null) {
      await chromeDriver!.stop();
    }
  });

  test('🔐 Solid Pod Authentication Test', () async {
    try {
      // Verify WebDriver is properly initialised.

      if (driver == null) {
        fail('❌ WebDriver not initialized');
      }

      // Navigate to the login page.

      await driver!.get(TestConfig.podServer + TestConfig.loginPath);
      Logger.info('🌐 Navigated to login page');

      // Fill in login credentials.

      var emailInput = await driver!.findElement(const By.name('email'));
      await emailInput.sendKeys(TestConfig.testEmail);
      Logger.info('✉️ Filled email input');

      var passwordInput = await driver!.findElement(const By.name('password'));
      await passwordInput.sendKeys(TestConfig.testPassword);
      Logger.info('🔑 Filled password input');

      // Submit login form.

      var loginButton = await driver!
          .findElement(const By.cssSelector('button[type="submit"]'));
      await loginButton.click();
      Logger.info('🚀 Submitted login form');

      // Handle consent page if it appears.

      try {
        await waitFor(() async {
          var consentButton =
              await driver!.findElement(const By.id('consent-btn'));
          await consentButton.click();
          return true;
        }, timeout: const Duration(seconds: 5));
        Logger.info('🛑 Handled consent page');
      } catch (e) {
        Logger.warn('✔️ No consent page found or already consented');
      }

      // Verify successful navigation to account page.

      await waitFor(() async {
        final currentUrl = await driver!.currentUrl;
        Logger.info('🌍 Current URL: $currentUrl');
        return currentUrl.contains('/.account/account');
      }, timeout: TestConfig.timeout);
      Logger.info('🎉 Reached account page');

      Logger.info(
          '✅ Successfully authenticated and navigated to the account page!');
    } catch (e, stackTrace) {
      // Log any test failures with stack trace.

      Logger.error('❌ Test failed: $e');
      Logger.error('📜 Stack trace: $stackTrace');
      fail('❌ Test failed: ${e.toString()}');
    }
  });
}
