/// Web implementation for file downloads using browser APIs.
///
/// This file provides the web-specific implementation for downloading files
/// using browser APIs like Blob and URL.createObjectURL.

library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Downloads a JSON file on web platforms using browser APIs.
/// 
/// Creates a blob with the JSON content and triggers a download.
void downloadJsonFile(String jsonContent, String fileName) {
  debugPrint('🌐 downloadJsonFile: Starting web download');
  debugPrint('🌐 downloadJsonFile: fileName = $fileName');
  debugPrint('🌐 downloadJsonFile: kIsWeb = $kIsWeb');
  
  if (kIsWeb) {
    try {
      debugPrint('🌐 downloadJsonFile: Encoding content to bytes...');
      // Create a blob with the JSON content
      final bytes = utf8.encode(jsonContent);
      debugPrint('🌐 downloadJsonFile: Content encoded, creating blob...');
      
      final blob = html.Blob([bytes], 'application/json');
      debugPrint('🌐 downloadJsonFile: Blob created, generating URL...');
      
      // Create a download URL
      final url = html.Url.createObjectUrlFromBlob(blob);
      debugPrint('🌐 downloadJsonFile: URL created = $url');
      
      // Create an anchor element and trigger download
      debugPrint('🌐 downloadJsonFile: Creating anchor element and triggering download...');
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      debugPrint('🌐 downloadJsonFile: Download triggered successfully');
      
      // Clean up the URL
      html.Url.revokeObjectUrl(url);
      debugPrint('🌐 downloadJsonFile: URL cleaned up');
    } catch (e) {
      debugPrint('💥 downloadJsonFile: ERROR during web download: $e');
      debugPrint('🔍 downloadJsonFile: Error type: ${e.runtimeType}');
      rethrow;
    }
  } else {
    debugPrint('⚠️ downloadJsonFile: Called on non-web platform');
  }
}