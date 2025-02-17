import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

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
    // Combine responses with timestamp and any additional data
    final responseData = {
      'timestamp': DateTime.now().toIso8601String(),
      'responses': responses,
      if (additionalData != null) ...additionalData,
    };

    // Convert to JSON string with proper formatting and base64 encode
    final jsonString = const JsonEncoder.withIndent('  ').convert(responseData);
    final base64Content = base64Encode(utf8.encode(jsonString));

    // Generate filename using consistent format
    final timestamp = formatTimestampForFilename(DateTime.now());
    final defaultFileName = '${filePrefix}_$timestamp.json';

    // Show file picker for save location
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile == null) {
      throw Exception('Save cancelled by user');
    }

    // Ensure .json extension
    if (!outputFile.toLowerCase().endsWith('.json')) {
      outputFile = '$outputFile.json';
    }

    // Save the base64 encoded file
    final file = File(outputFile);
    await file.writeAsString(base64Content);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving survey: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    rethrow; // Rethrow to allow the calling function to handle the error
  }
}
