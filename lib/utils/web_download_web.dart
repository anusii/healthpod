/// Web implementation for file downloads using browser APIs.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Downloads a JSON file on web platforms using browser APIs.
///
/// Creates a blob with the JSON content and triggers a download.
/// This function is only used on web platforms via conditional imports.
void downloadJsonFile(String jsonContent, String fileName) {
  if (kIsWeb) {
    try {
      // Create a blob with the JSON content
      final bytes = utf8.encode(jsonContent);

      final blob = html.Blob([bytes], 'application/json');

      // Create a download URL
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create an anchor element and trigger download
      final anchor = html.AnchorElement(href: url);
      anchor.download = fileName;
      anchor.click();

      // Clean up the URL
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('💥 downloadJsonFile: ERROR during web download: $e');
      debugPrint('🔍 downloadJsonFile: Error type: ${e.runtimeType}');
      rethrow;
    }
  } else {
    debugPrint('⚠️ downloadJsonFile: Called on non-web platform');
  }
}
