import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';

/// Saves survey responses directly to POD.
///
/// Uses uploadJsonToPod utility which:
/// 1. Creates a properly formatted JSON file
/// 2. Uses uploadFileToPod internally for consistent file handling
/// 3. Ensures proper encryption and file naming
/// 4. Manages temporary file cleanup
///
/// Parameters:
/// - context: BuildContext for showing error messages
/// - responses: Map of survey responses
/// - podPath: Target directory path in POD (e.g., '/bp', '/vaccine')
/// - filePrefix: Prefix for the filename (e.g., 'blood_pressure', 'vaccine')
/// - additionalData: Optional additional data to include in the response
Future<void> saveResponseToPod({
  required BuildContext context,
  required Map<String, dynamic> responses,
  required String podPath,
  required String filePrefix,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    // Prepare response data with timestamp and any additional data
    final responseData = {
      'timestamp': DateTime.now().toIso8601String(),
      'responses': responses,
      if (additionalData != null) ...additionalData,
    };

    // Use utility to handle the upload process
    final result = await uploadJsonToPod(
      data: responseData,
      targetPath: podPath,
      fileNamePrefix: filePrefix,
      context: context,
    );

    if (result != SolidFunctionCallStatus.success) {
      throw Exception('Failed to save survey responses (Status: $result)');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving survey to POD: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    rethrow; // Rethrow to allow the calling function to handle the error
  }
}
