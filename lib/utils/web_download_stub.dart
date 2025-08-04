/// Stub implementation for non-web platforms.
///
/// This file provides a stub implementation for file download functionality
/// that will be used on non-web platforms where browser APIs are not available.

library;

import 'package:flutter/foundation.dart';

/// Downloads a JSON file on non-web platforms (stub implementation).
///
/// This is a no-op implementation for non-web platforms since file downloads
/// are handled differently (via file picker).
void downloadJsonFile(String jsonContent, String fileName) {
  debugPrint('⚠️ downloadJsonFile: Stub called on non-web platform');
  // No-op on non-web platforms
}
