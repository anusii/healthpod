/// Test configuration file for Solid Pod integration tests.
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

import 'dart:io';

import 'package:path/path.dart' as path;

/// Configuration class for test parameters.
///
/// Centralises test-specific configuration such as server URL,
/// login credentials, and timeout settings for easy management
/// and potential future modifications.

class TestConfig {
  /// The base URL of the Solid Pod server being tested.

  static const podServer = 'https://pods.dev.solidcommunity.au';

  /// Specific login path for authentication.

  static const loginPath = '/.account/login/password/';

  /// Test email used for authentication.

  static const testEmail = 'test@anu.edu.au';

  /// Test password used for authentication.

  static const testPassword = 'SuperSecure123';

  /// Maximum time allowed for the entire authentication process.

  static const timeout = Duration(seconds: 45);

  /// Port number for the ChromeDriver server.

  static const chromeDriverPort = 4444;

  /// Directory name where ChromeDriver binaries are stored.

  static const chromeDriverDirName = 'chromedriver';

  /// Get the ChromeDriver path based on the platform.

  static String get chromeDriverPath {
    // First check if ChromeDriver is available in system PATH.

    if (!Platform.isWindows) {
      final result = Process.runSync('which', ['chromedriver']);
      if (result.exitCode == 0) {
        return 'chromedriver';
      }
    }

    // If not in PATH, use local installation.

    final baseDir = Directory.current.path;
    final toolsDir = path.join(baseDir, 'tools');
    final driverDir = path.join(toolsDir, chromeDriverDirName);

    if (Platform.isWindows) {
      return path.join(driverDir, 'chromedriver.exe');
    } else if (Platform.isLinux) {
      return path.join(driverDir, 'chromedriver');
    } else if (Platform.isMacOS) {
      return path.join(driverDir, 'chromedriver');
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Verifies that ChromeDriver is properly configured and available.

  static Future<void> validateChromeDriver() async {
    final driverPath = chromeDriverPath;

    // Skip validation if using system ChromeDriver.

    if (driverPath == 'chromedriver') {
      return;
    }

    // Verify ChromeDriver file exists.

    final driverFile = File(driverPath);
    if (!await driverFile.exists()) {
      throw FileSystemException(
          'ChromeDriver not found at path: $driverPath\n'
          'Please ensure ChromeDriver is installed in the tools/chromedriver directory',
          driverPath,);
    }

    // On Unix-like systems, verify executable permissions.

    if (!Platform.isWindows) {
      final stat = await driverFile.stat();
      if ((stat.mode & 0x49) == 0) {
        // Add executable permission if missing.

        await Process.run('chmod', ['+x', driverPath]);
      }
    }
  }

  /// Get platform-specific ChromeDriver options.

  static List<String> get chromeDriverOptions {
    final baseOptions = ['--port=$chromeDriverPort'];

    if (Platform.isLinux) {
      // Add Linux-specific options if needed.

      baseOptions.addAll([
        '--no-sandbox',
        '--disable-dev-shm-usage',
      ]);
    }

    return baseOptions;
  }

  /// Environment-specific configuration for WebDriver capabilities.

  static Map<String, dynamic> get capabilities {
    return {
      'browserName': 'chrome',
      'goog:chromeOptions': {
        'args': [
          '--no-sandbox',
          '--headless',
          '--disable-gpu',
          if (Platform.isLinux) '--disable-dev-shm-usage',
        ],
        'w3c': true,
      },
    };
  }
}
