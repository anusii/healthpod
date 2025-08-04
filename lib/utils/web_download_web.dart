/// Web implementation for file downloads using browser APIs.
///
/// This file provides the web-specific implementation for downloading files
/// using browser APIs like Blob and URL.createObjectURL.

library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Downloads a JSON file on web platforms using browser APIs.
/// 
/// Creates a blob with the JSON content and triggers a download.
void downloadJsonFile(String jsonContent, String fileName) {
  if (kIsWeb) {
    try {
      // Create a blob with the JSON content
      final bytes = utf8.encode(jsonContent);
      
      final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
      
      // Create a download URL
      final url = web.URL.createObjectURL(blob);
      
      // Create an anchor element and trigger download
      final anchor = web.HTMLAnchorElement();
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      
      // Clean up the URL
      web.URL.revokeObjectURL(url);
    } catch (e) {
      debugPrint('💥 downloadJsonFile: ERROR during web download: $e');
      debugPrint('🔍 downloadJsonFile: Error type: ${e.runtimeType}');
      rethrow;
    }
  } else {
    debugPrint('⚠️ downloadJsonFile: Called on non-web platform');
  }
}
