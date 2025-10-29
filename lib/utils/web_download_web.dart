/// Web implementation for file downloads using browser APIs.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'package:web/web.dart';

/// Downloads a JSON file on web platforms using browser APIs.
///
/// Creates a blob with the JSON content and triggers a download.
/// This function is only used on web platforms via conditional imports.

void downloadJsonFile(String jsonContent, String fileName) {
  if (kIsWeb) {
    try {
      // Create a blob with the JSON content
      final bytes = utf8.encode(jsonContent);

      // Create blob options
      final blobOptions = BlobPropertyBag(type: 'application/json');

      // Create blob with the content
      final blob = Blob([bytes.toJS].toJS, blobOptions);

      // Create a download URL
      final url = URL.createObjectURL(blob);

      // Create an anchor element and trigger download
      final anchor = HTMLAnchorElement();
      anchor.href = url;
      anchor.download = fileName;

      // Add to document, click, and remove
      document.body!.appendChild(anchor);
      anchor.click();
      document.body!.removeChild(anchor);

      // Clean up the URL
      URL.revokeObjectURL(url);
    } catch (e) {
      debugPrint('💥 downloadJsonFile: ERROR during web download: $e');
      debugPrint('🔍 downloadJsonFile: Error type: ${e.runtimeType}');
      rethrow;
    }
  } else {
    debugPrint('⚠️ downloadJsonFile: Called on non-web platform');
  }
}
