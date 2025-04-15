/// Profile data importer.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
///
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';

/// Class that handles the import of profile data from JSON file.
class ProfileImporter {
  /// Imports profile data from a JSON file.
  ///
  /// Returns true if import was successful.
  ///
  /// Parameters:
  /// - [filePath]: Path to the JSON file
  /// - [targetPath]: Target directory path on the POD
  /// - [context]: BuildContext for UI interactions
  /// - [onSuccess]: Optional callback for successful import
  
  static Future<bool> importJson(
    String filePath,
    String targetPath,
    BuildContext context, {
    void Function()? onSuccess,
  }) async {
    try {
      // Read the file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // Log the content being imported to debug
      debugPrint('Importing JSON profile content: ${jsonString.substring(0, min(200, jsonString.length))}...');
      
      // Attempt to parse the JSON
      Map<String, dynamic> profileData;
      try {
        profileData = jsonDecode(jsonString);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid JSON format: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
      
      // Validate the profile data
      final validationResult = _validateProfileData(profileData);
      
      if (!validationResult['isValid']) {
        // Show validation error dialog instead of a snackbar
        if (context.mounted) {
          await _showValidationErrorDialog(
            context, 
            'Invalid profile data: ${validationResult['message']}'
          );
        }
        return false;
      }
      
      // Show confirmation dialog with the validated data
      if (context.mounted) {
        final confirmImport = await _showConfirmationDialog(
          context,
          validationResult['data'] as Map<String, dynamic>,
        );
        
        if (!confirmImport) {
          return false;
        }
      }
      
      // Extract the validated data
      final finalData = validationResult['data'] as Map<String, dynamic>;
      
      // Add timestamp if not present
      if (!finalData.containsKey('timestamp')) {
        finalData['timestamp'] = DateTime.now().toIso8601String();
      }
      
      // Normalize the target path to always use the 'profile' subdirectory
      final normalizedPath = "profile"; // Just use the subdirectory name
      
      debugPrint('Uploading profile to path: $normalizedPath');
      
      // Create a formatted timestamp for the filename
      final timestamp = formatTimestampForFilename(DateTime.now());
      final filename = 'profile_$timestamp.json';
      
      // Prepare the JSON content
      final jsonContent = json.encode(finalData);
      debugPrint('Prepared JSON content for encryption: ${jsonContent.substring(0, min(100, jsonContent.length))}...');
      
      // Upload to POD with encryption
      if (!context.mounted) return false;
      
      // Use the same pattern as in SurveyData and BPObservation
      final fullPath = '$normalizedPath/$filename.enc.ttl';
      debugPrint('Saving encrypted profile to: $fullPath');
      
      final result = await writePod(
        fullPath,
        jsonContent,
        context,
        const Text('Saving profile data'),
        encrypted: true,
      );
      
      if (result == SolidFunctionCallStatus.success) {
        debugPrint('Profile saved successfully with encryption');
        onSuccess?.call();
        return true;
      } else {
        debugPrint('Error saving profile: $result');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error importing profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
  
  /// Validates profile JSON data against expected structure.
  /// 
  /// Returns a map with validation result, data, and error message if any.
  static Map<String, dynamic> _validateProfileData(Map<String, dynamic> jsonData) {
    // Define required profile fields
    final requiredFields = [
      'patientName',
      'address',
      'bestContactPhone',
      'alternativeContactNumber',
      'email',
      'dateOfBirth',
      'gender',
      'identifyAsIndigenous',
    ];
    
    // Check direct structure
    bool directStructureValid = _checkRequiredFields(jsonData, requiredFields);
    
    if (directStructureValid) {
      return {
        'isValid': true,
        'data': {
          'data': jsonData,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'message': 'Valid profile data'
      };
    }
    
    // Check data nested under 'data' key
    if (jsonData.containsKey('data') && jsonData['data'] is Map<String, dynamic>) {
      final nestedData = jsonData['data'] as Map<String, dynamic>;
      if (_checkRequiredFields(nestedData, requiredFields)) {
        return {
          'isValid': true,
          'data': jsonData,
          'message': 'Valid profile data structure'
        };
      }
    }
    
    // Check data nested under 'responses' key
    if (jsonData.containsKey('responses') && jsonData['responses'] is Map<String, dynamic>) {
      final nestedData = jsonData['responses'] as Map<String, dynamic>;
      if (_checkRequiredFields(nestedData, requiredFields)) {
        return {
          'isValid': true,
          'data': {
            'data': nestedData,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'message': 'Valid profile data under responses'
        };
      }
    }
    
    return {
      'isValid': false,
      'message': 'Invalid profile data structure - missing required fields'
    };
  }
  
  /// Helper function to check if all required fields exist in the data
  static bool _checkRequiredFields(Map<String, dynamic> data, List<String> requiredFields) {
    return requiredFields.every((field) => data.containsKey(field));
  }
  
  /// Returns the minimum of two integers (helper function)
  static int min(int a, int b) => a < b ? a : b;

  /// Shows a validation error dialog
  static Future<void> _showValidationErrorDialog(
    BuildContext context, 
    String message,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog with profile data preview
  static Future<bool> _showConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final profileData = data.containsKey('data') ? data['data'] as Map<String, dynamic> : data;
    
    // Get the key fields to display in the dialog
    final previewFields = [
      'patientName',
      'dateOfBirth',
      'gender',
      'email',
      'bestContactPhone',
    ];
    
    // Build preview items
    final previewItems = <Widget>[];
    
    for (final field in previewFields) {
      if (profileData.containsKey(field)) {
        previewItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    _formatFieldName(field),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${profileData[field]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Profile Import'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'You are about to import the following profile data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...previewItems,
                const SizedBox(height: 16),
                const Text(
                  'Importing this data will create a new profile record. Do you want to continue?',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Import'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  /// Format field names for display
  static String _formatFieldName(String field) {
    // Convert camelCase to Title Case with spaces
    final result = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }
}