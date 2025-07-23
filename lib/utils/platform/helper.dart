/// Platform helper class to safely check platform and environment variables.
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

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:healthpod/utils/platform/io.dart'
    if (dart.library.html) 'package:healthpod/utils/platform/web.dart';

/// Helper class to safely check platform and environment variables.

class PlatformHelper {
  /// Safely gets an environment variable across platforms.

  static String? getEnvironmentVariable(String name) {
    if (kIsWeb) {
      // For now, return null or a default value for web.

      return null;
    } else {
      // For non-web platforms, use PlatformWrapper.

      return PlatformWrapper.getEnvironmentVariable(name);
    }
  }

  /// Checks if running in integration test mode.

  static bool isIntegrationTest() {
    if (kIsWeb) {
      // For web, we might want to:
      // 1. Always return false for production
      // 2. Use a compile-time constant
      // 3. Check URL parameters
      // 4. Check localStorage

      return false;
    } else {
      return PlatformWrapper.isIntegrationTest();
    }
  }

  /// Checks if running on web platform.

  static bool get isWeb => kIsWeb;
}
