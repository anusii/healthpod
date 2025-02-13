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
}
