/// Profile data importer.
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
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/security_key/manager.dart';

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
      // Read the file.

      final file = File(filePath);
      final jsonString = await file.readAsString();

      // Log the content being imported to debug.

      debugPrint(
          'Importing JSON profile content: ${jsonString.substring(0, min(200, jsonString.length))}...');

      // Attempt to parse the JSON.

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

      // Validate the profile data.

      final validationResult = _validateProfileData(profileData);

      if (!validationResult['isValid']) {
        // Show validation error dialog instead of a snackbar.

        if (context.mounted) {
          await _showValidationErrorDialog(
              context, 'Invalid profile data: ${validationResult['message']}');
        }
        return false;
      }

      // Show confirmation dialog with the validated data.

      if (context.mounted) {
        final confirmImport = await _showConfirmationDialog(
          context,
          validationResult['data'] as Map<String, dynamic>,
        );

        if (!confirmImport) {
          return false;
        }
      }

      // Extract the validated data.

      final finalData = validationResult['data'] as Map<String, dynamic>;
      debugPrint(
          'Validated profile data: ${json.encode(finalData).substring(0, min(100, json.encode(finalData).length))}...');

      // Add timestamp if not present, otherwise use the existing one.
      String timestampString;
      if (!finalData.containsKey('timestamp')) {
        debugPrint('No timestamp found in profile data, using current time');
        timestampString = DateTime.now().toIso8601String();
        finalData['timestamp'] = timestampString;
      } else {
        timestampString = finalData['timestamp'] as String;
        debugPrint('Found timestamp in profile data: $timestampString');
      }

      // Check if timestamp is nested inside 'data' object
      if (finalData.containsKey('data') &&
          finalData['data'] is Map<String, dynamic> &&
          (finalData['data'] as Map<String, dynamic>)
              .containsKey('timestamp')) {
        final nestedTimestamp =
            (finalData['data'] as Map<String, dynamic>)['timestamp'];
        if (nestedTimestamp is String) {
          debugPrint(
              'Found nested timestamp in profile data["data"]: $nestedTimestamp');
          timestampString = nestedTimestamp;
          // Update the top-level timestamp to match the nested one
          finalData['timestamp'] = timestampString;
        }
      }

      // Parse the timestamp to ensure it's in a valid format
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampString);
        debugPrint('Successfully parsed timestamp: $timestamp');
      } catch (e) {
        debugPrint(
            'Invalid timestamp format: $timestampString, using current time');
        timestamp = DateTime.now();
        timestampString = timestamp.toIso8601String();
        finalData['timestamp'] = timestampString;
      }

      // Normalise the target path to always use the 'profile' subdirectory.

      final normalizedPath = 'profile';

      debugPrint('Uploading profile to path: $normalizedPath');

      // Check for existing profiles and prompt for confirmation if found
      if (context.mounted) {
        debugPrint(
            'Checking for existing profiles with timestamp: $timestampString');
        final existingProfiles =
            await _checkForExistingProfiles(context, timestampString);

        // Only show the dialog if actual profiles were found
        if (existingProfiles.isNotEmpty) {
          debugPrint(
              'Found ${existingProfiles.length} existing profiles. Showing override dialog.');
          final shouldOverride =
              await _showOverrideConfirmationDialog(context, existingProfiles);

          if (!shouldOverride) {
            debugPrint('Profile import cancelled by user');
            return false;
          }

          debugPrint(
              'User confirmed profile override, deleting existing profiles');

          // Delete the existing profile files before saving the new one
          await _deleteExistingProfiles(context, existingProfiles);
        } else {
          debugPrint('No existing profiles found matching the timestamp.');
        }
      }

      // Create a formatted timestamp for the filename using the timestamp from the data.
      final formattedTimestamp = formatTimestampForFilename(timestamp);
      final filename = 'profile_$formattedTimestamp.json';

      debugPrint(
          'Using timestamp from profile data for filename: $formattedTimestamp');

      // Prepare the JSON content.

      final jsonContent = json.encode(finalData);
      debugPrint(
          'Prepared JSON content for encryption: ${jsonContent.substring(0, min(100, jsonContent.length))}...');

      // Upload to POD with encryption.

      if (!context.mounted) return false;

      // Use the same pattern as in SurveyData and BPObservation.

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

  static Map<String, dynamic> _validateProfileData(
      Map<String, dynamic> jsonData) {
    // Define required profile fields.

    final requiredFields = [
      'name',
      'address',
      'bestContactPhone',
      'alternativeContactNumber',
      'email',
      'dateOfBirth',
      'gender',
    ];

    // Check direct structure.

    final directMissingFields = _checkRequiredFields(jsonData, requiredFields);
    if (directMissingFields.isEmpty) {
      return {
        'isValid': true,
        'data': {
          'data': jsonData,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'message': 'Valid profile data'
      };
    }

    // Check data nested under 'data' key.

    if (jsonData.containsKey('data') &&
        jsonData['data'] is Map<String, dynamic>) {
      final nestedData = jsonData['data'] as Map<String, dynamic>;
      final dataMissingFields =
          _checkRequiredFields(nestedData, requiredFields);
      if (dataMissingFields.isEmpty) {
        return {
          'isValid': true,
          'data': jsonData,
          'message': 'Valid profile data structure'
        };
      }
    }

    // Check data nested under 'responses' key.

    if (jsonData.containsKey('responses') &&
        jsonData['responses'] is Map<String, dynamic>) {
      final nestedData = jsonData['responses'] as Map<String, dynamic>;
      final responsesMissingFields =
          _checkRequiredFields(nestedData, requiredFields);
      if (responsesMissingFields.isEmpty) {
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

    // Determine which missing fields to report.

    List<String> missingFieldsList = directMissingFields;

    // Try to get the most specific error (fewest missing fields).

    if (jsonData.containsKey('data') &&
        jsonData['data'] is Map<String, dynamic>) {
      final dataMissingFields = _checkRequiredFields(
          jsonData['data'] as Map<String, dynamic>, requiredFields);
      if (dataMissingFields.length < missingFieldsList.length) {
        missingFieldsList = dataMissingFields;
      }
    }

    if (jsonData.containsKey('responses') &&
        jsonData['responses'] is Map<String, dynamic>) {
      final responsesMissingFields = _checkRequiredFields(
          jsonData['responses'] as Map<String, dynamic>, requiredFields);
      if (responsesMissingFields.length < missingFieldsList.length) {
        missingFieldsList = responsesMissingFields;
      }
    }

    // Format missing fields for display.

    final formattedMissingFields =
        missingFieldsList.map(_formatFieldName).join(', ');

    return {
      'isValid': false,
      'message':
          'Invalid profile data structure - missing required fields: $formattedMissingFields'
    };
  }

  /// Helper function to check required fields and return list of missing fields.
  ///
  /// Returns a list of missing field names. Empty list means all required fields are present.

  static List<String> _checkRequiredFields(
      Map<String, dynamic> data, List<String> requiredFields) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        missingFields.add(field);
      }
    }

    return missingFields;
  }

  /// Returns the minimum of two integers (helper function).

  static int min(int a, int b) => a < b ? a : b;

  /// Shows a validation error dialog.

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

  /// Shows a confirmation dialog with profile data preview.

  static Future<bool> _showConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final profileData =
        data.containsKey('data') ? data['data'] as Map<String, dynamic> : data;

    // Get the key fields to display in the dialog.

    final previewFields = [
      'name',
      'dateOfBirth',
      'gender',
      'email',
      'bestContactPhone',
    ];

    // Build preview items.

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
        ) ??
        false;
  }

  /// Format field names for display.

  static String _formatFieldName(String field) {
    // Convert camelCase to Title Case with spaces.

    final result = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );

    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  /// Checks for existing profiles and returns a list of profile files.
  ///
  /// This method checks the profile directory for any existing profile files
  /// that would be overridden by a new import.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  /// - [timestampString]: The timestamp from the profile being imported
  ///
  /// Returns a list of existing profile file names.

  static Future<List<String>> _checkForExistingProfiles(
      BuildContext context, String timestampString) async {
    try {
      // Parse the incoming timestamp
      DateTime importTimestamp;
      try {
        importTimestamp = DateTime.parse(timestampString);
        debugPrint('Parsed import timestamp: $importTimestamp');
      } catch (e) {
        debugPrint('Error parsing timestamp: $e');
        // If we can't parse the timestamp, just use the current time
        importTimestamp = DateTime.now();
      }

      // Format the timestamp how it would appear in a filename
      final formattedTimestamp = formatTimestampForFilename(importTimestamp);
      final expectedFilename = 'profile_$formattedTimestamp.json.enc.ttl';

      debugPrint('Looking for any profile file matching: $expectedFilename');

      // Try different path approaches to find existing files
      List<String> profileFiles = [];

      // First try with the standard path
      try {
        debugPrint('Trying standard path: profile');
        final dirUrl = await getDirUrl('profile');
        final resources = await getResourcesInContainer(dirUrl);

        // Get all files in directory for debugging
        debugPrint('All files in directory: ${resources.files.join(', ')}');
        debugPrint('All subdirs in directory: ${resources.subDirs.join(', ')}');

        profileFiles = resources.files
            .where((file) =>
                file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
            .toList();

        debugPrint(
            'Found ${profileFiles.length} profile files with standard path');
      } catch (e) {
        debugPrint('Error accessing with standard path: $e');
      }

      // If first approach didn't work, try with healthpod/data prefix
      if (profileFiles.isEmpty) {
        try {
          debugPrint(
              'Trying with healthpod/data prefix: healthpod/data/profile');
          final dirUrl = await getDirUrl('healthpod/data/profile');
          final resources = await getResourcesInContainer(dirUrl);

          profileFiles = resources.files
              .where((file) =>
                  file.startsWith('profile_') && file.endsWith('.json.enc.ttl'))
              .toList();

          debugPrint(
              'Found ${profileFiles.length} profile files with healthpod/data prefix');
        } catch (e) {
          debugPrint('Error accessing with healthpod/data prefix: $e');
        }
      }

      // Process the results
      if (profileFiles.isNotEmpty) {
        debugPrint('Existing profile files: ${profileFiles.join(', ')}');

        // Check if any files match our expected filename pattern
        final matchingFiles = profileFiles
            .where((file) => file.contains(formattedTimestamp))
            .toList();

        if (matchingFiles.isNotEmpty) {
          debugPrint(
              'Found exact matching profile files: ${matchingFiles.join(', ')}');
          return matchingFiles;
        }

        // If no exact matches, return all profile files
        debugPrint(
            'No exact matches, but returning all profile files for confirmation');
        return profileFiles;
      }

      debugPrint('No profile files found in directory');
      return [];
    } catch (e) {
      debugPrint('Error checking for existing profiles: $e');
      return [];
    }
  }

  /// Shows a confirmation dialog for overriding existing profiles.
  ///
  /// This method displays a dialog with a list of profile files that would be overridden
  /// and asks the user to confirm the override.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  /// - [existingProfiles]: List of profile file names that would be overridden
  ///
  /// Returns a boolean indicating whether the user confirmed the override.

  static Future<bool> _showOverrideConfirmationDialog(
    BuildContext context,
    List<String> existingProfiles,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Existing Profile Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You already have a profile saved. Importing a new profile will replace your existing profile data.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Existing profile files:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 150,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: existingProfiles
                          .map((filename) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        filename,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Warning: This action cannot be undone. Your existing profile will be permanently replaced.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Replace Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ) ??
        false;
  }

  /// Deletes existing profile files.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  /// - [existingProfiles]: List of profile file names to delete
  ///
  /// Returns a Future that completes when all files are deleted.

  static Future<void> _deleteExistingProfiles(
      BuildContext context, List<String> existingProfiles) async {
    try {
      // Define the normalized path to use for deleting files
      final normalizedPath = 'profile';

      for (final filename in existingProfiles) {
        try {
          final filePath = '$normalizedPath/$filename';
          debugPrint('Attempting to delete profile file: $filePath');

          // Try to delete the file using SolidPod's deleteFile function
          try {
            await deleteFile(filePath);
            debugPrint('Successfully deleted profile file: $filename');
          } catch (deleteError) {
            // Check if it's a "not found" error (404)
            if (deleteError.toString().contains('404') ||
                deleteError.toString().contains('NotFoundHttpError')) {
              // Try alternative path
              final alternativePath = filename;
              debugPrint(
                  'File not found at $filePath, trying alternative path: $alternativePath');

              try {
                await deleteFile(alternativePath);
                debugPrint(
                    'Successfully deleted profile file with alternative path: $alternativePath');
              } catch (alternativeError) {
                // If both paths fail, just log and continue
                debugPrint(
                    'Could not delete profile file with either path. Error: $alternativeError');
              }
            } else {
              // For other errors, just log and continue
              debugPrint('Error deleting profile file: $deleteError');
            }
          }
        } catch (fileError) {
          debugPrint('Error processing profile file $filename: $fileError');
          // Continue trying to delete other files
        }
      }
    } catch (e) {
      debugPrint('Error deleting existing profiles: $e');
    }
  }
}
