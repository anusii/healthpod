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

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';

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
            context,
            'Invalid profile data: ${validationResult['message']}',
          );
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

      // Add timestamp if not present, otherwise use the existing one.

      String timestampString;
      if (!finalData.containsKey('timestamp')) {
        timestampString = DateTime.now().toIso8601String();
        finalData['timestamp'] = timestampString;
      } else {
        timestampString = finalData['timestamp'] as String;
      }

      // Check if timestamp is nested inside 'data' object.

      if (finalData.containsKey('data') &&
          finalData['data'] is Map<String, dynamic> &&
          (finalData['data'] as Map<String, dynamic>)
              .containsKey('timestamp')) {
        final nestedTimestamp =
            (finalData['data'] as Map<String, dynamic>)['timestamp'];
        if (nestedTimestamp is String) {
          timestampString = nestedTimestamp;
          // Update the top-level timestamp to match the nested one.

          finalData['timestamp'] = timestampString;
        }
      }

      // Parse the timestamp to ensure it's in a valid format.

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampString);
      } catch (e) {
        timestamp = DateTime.now();
        timestampString = timestamp.toIso8601String();
        finalData['timestamp'] = timestampString;
      }

      // Normalise the target path to always use the 'profile' subdirectory.

      final normalizedPath = 'profile';

      // Check for existing profiles and prompt for confirmation if found.

      if (context.mounted) {
        List<String> existingProfiles = [];
        try {
          existingProfiles =
              await _checkForExistingProfiles(context, timestampString);
        } catch (e) {
          // Log error but continue with the import process.

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: Could not check for existing profiles: ${e.toString()}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Only show the dialog if actual profiles were found.

        if (existingProfiles.isNotEmpty) {
          if (!context.mounted) return false;
          final shouldOverride =
              await _showOverrideConfirmationDialog(context, existingProfiles);

          if (!shouldOverride) {
            return false;
          }

          if (!context.mounted) return false;

          // Try to delete existing profiles but continue even if deletion fails.

          try {
            await _deleteExistingProfiles(context, existingProfiles);
          } catch (e) {
            // Show warning but continue with import.

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Warning: Could not delete existing profiles. The import will continue but you may have duplicate data. Error: ${e.toString()}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      // Create a formatted timestamp for the filename using the timestamp from the data.

      final formattedTimestamp = formatTimestampForFilename(timestamp);
      final filename = 'profile_$formattedTimestamp.json';

      // Prepare the JSON content.

      final jsonContent = json.encode(finalData);

      // Upload to POD with encryption.

      if (!context.mounted) return false;

      // Use the same pattern as in SurveyData and BPObservation.

      final fullPath = '$normalizedPath/$filename.enc.ttl';

      final result = await writePod(
        fullPath,
        jsonContent,
        context,
        const Text('Saving profile data'),
        encrypted: true,
      );

      if (result == SolidFunctionCallStatus.success) {
        onSuccess?.call();
        return true;
      } else {
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
    Map<String, dynamic> jsonData,
  ) {
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
        'message': 'Valid profile data',
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
          'message': 'Valid profile data structure',
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
          'message': 'Valid profile data under responses',
        };
      }
    }

    // Determine which missing fields to report.

    List<String> missingFieldsList = directMissingFields;

    // Try to get the most specific error (fewest missing fields).

    if (jsonData.containsKey('data') &&
        jsonData['data'] is Map<String, dynamic>) {
      final dataMissingFields = _checkRequiredFields(
        jsonData['data'] as Map<String, dynamic>,
        requiredFields,
      );
      if (dataMissingFields.length < missingFieldsList.length) {
        missingFieldsList = dataMissingFields;
      }
    }

    if (jsonData.containsKey('responses') &&
        jsonData['responses'] is Map<String, dynamic>) {
      final responsesMissingFields = _checkRequiredFields(
        jsonData['responses'] as Map<String, dynamic>,
        requiredFields,
      );
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
          'Invalid profile data structure - missing required fields: $formattedMissingFields',
    };
  }

  /// Helper function to check required fields and return list of missing fields.
  ///
  /// Returns a list of missing field names. Empty list means all required fields are present.

  static List<String> _checkRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        missingFields.add(field);
      }
    }

    return missingFields;
  }

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
    BuildContext context,
    String timestampString,
  ) async {
    try {
      // Parse the incoming timestamp.

      DateTime importTimestamp;
      try {
        importTimestamp = DateTime.parse(timestampString);
      } catch (e) {
        // If we can't parse the timestamp, just use the current time.

        importTimestamp = DateTime.now();
      }

      // Format the timestamp how it would appear in a filename.

      final formattedTimestamp = formatTimestampForFilename(importTimestamp);

      // Try different path approaches to find existing files.

      List<String> profileFiles = [];

      // Only check the known path where profile files are stored.

      final profilePath = '$basePath/profile';

      try {
        final dirUrl = await getDirUrl(profilePath);
        final resources = await getResourcesInContainer(dirUrl);

        profileFiles = resources.files
            .where(
              (file) =>
                  file.startsWith('profile_') && file.endsWith('.json.enc.ttl'),
            )
            .toList();
      } catch (e) {
        // Rethrow with more specific information for better troubleshooting.

        throw Exception('Failed to access profile directory: $e');
      }

      // Process the results.

      if (profileFiles.isNotEmpty) {
        // Check if any files match our expected filename pattern.

        final matchingFiles = profileFiles
            .where((file) => file.contains(formattedTimestamp))
            .toList();

        if (matchingFiles.isNotEmpty) {
          return matchingFiles;
        }

        // If no exact matches, return all profile files.

        return profileFiles;
      }

      return [];
    } catch (e) {
      // Log the error and rethrow to propagate to the calling method.

      throw Exception('Error checking for existing profiles: $e');
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
                          .map(
                            (filename) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
                            ),
                          )
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
    BuildContext context,
    List<String> existingProfiles,
  ) async {
    try {
      // Use the same path where the files are actually stored.

      final normalizedPath = '$basePath/profile';

      for (final filename in existingProfiles) {
        try {
          final filePath = '$normalizedPath/$filename';

          // Try to delete the file using SolidPod's deleteFile function.

          try {
            await deleteFile(filePath);
          } catch (deleteError) {
            // Check if it's a "not found" error (404).

            if (deleteError.toString().contains('404') ||
                deleteError.toString().contains('NotFoundHttpError')) {
              // Try alternative paths if needed.

              final alternativePaths = [
                'profile/$filename',
                filename,
                'profile/profile_$filename',
              ];

              bool deleted = false;
              for (final altPath in alternativePaths) {
                await deleteFile(altPath);
                deleted = true;
                break;
              }

              if (!deleted) {
                // If both paths fail, throw exception with both error details.

                throw Exception(
                  'Failed to delete profile using both paths. Primary error: $deleteError',
                );
              }
            } else {
              // For other errors, throw an exception.

              throw Exception('Failed to delete profile file: $deleteError');
            }
          }
        } catch (fileError) {
          // Throw to let calling code know about the failure.

          throw Exception(
            'Error processing profile file $filename: $fileError',
          );
        }
      }
    } catch (e) {
      // Rethrow with clear context about the operation that failed.

      throw Exception('Failed to delete existing profiles: $e');
    }
  }
}
