/// Save survey responses to a local file.
///
// Time-stamp: <Wednesday 2025-02-12 15:50:35 +1100 Graham Williams>
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:healthpod/utils/format_timestamp_for_filename.dart';

// Conditional import for web download functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';

/// Saves survey responses to a local file.
///
/// Parameters:
/// - context: BuildContext for showing error messages
/// - responses: Map of survey responses
/// - filePrefix: Prefix for the filename (e.g., 'blood_pressure', 'vaccine')
/// - dialogTitle: Title for the file save dialog
/// - additionalData: Optional additional data to include in the response

Future<void> saveResponseLocally({
  required BuildContext context,
  required Map<String, dynamic> responses,
  required String filePrefix,
  String dialogTitle = 'Save Survey Response',
  Map<String, dynamic>? additionalData,
}) async {
  try {
    // Combine responses with timestamp and any additional data.

    final responseData = {
      'timestamp': DateTime.now().toIso8601String(),
      'responses': responses,
      if (additionalData != null) ...additionalData,
    };

    // Convert to JSON string with proper formatting.

    final jsonString = const JsonEncoder.withIndent('  ').convert(responseData);

    // Generate filename using consistent format.

    final timestamp = formatTimestampForFilename(DateTime.now());
    final defaultFileName = '${filePrefix}_$timestamp.json';

    if (kIsWeb) {
      // On web, use the web download function.

      downloadJsonFile(jsonString, defaultFileName);
    } else {
      // On non-web platforms, show a message that local save is not supported.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Local file save is not supported on this platform. Please use "Save to POD" instead.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving survey: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Rethrow to allow the calling function to handle the error.

    rethrow;
  }
}
