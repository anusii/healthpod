/// Profile import service.
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

import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/validate_profile.dart';
import 'package:healthpod/utils/construct_pod_path.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';

/// Service for importing profile data from JSON files.
class ProfileImportService {
  /// Imports profile data from a JSON file.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs and error messages
  /// - [filePath]: Path to the JSON file in the POD
  /// - [onSuccess]: Callback function called after successful import
  ///
  /// Returns true if import was successful, false otherwise.
  static Future<bool> importProfileFromJson({
    required BuildContext context,
    required String filePath,
    required VoidCallback onSuccess,
  }) async {
    try {
      // Read the JSON file
      final fileContent = await readPod(
        filePath,
        context,
        const Text('Reading JSON file'),
      );

      if (fileContent.isEmpty) {
        if (!context.mounted) return false;
        _showError(context, 'Failed to read JSON file');
        return false;
      }

      // Parse and validate JSON
      final Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(fileContent) as Map<String, dynamic>;
      } catch (e) {
        if (!context.mounted) return false;
        _showError(context, 'Invalid JSON format');
        return false;
      }

      // Validate profile data
      final validationResult = validateProfileJson(jsonData);
      if (!validationResult.isValid) {
        if (!context.mounted) return false;
        _showError(context, validationResult.error ?? 'Invalid profile data');
        return false;
      }

      // Show confirmation dialog
      if (!context.mounted) return false;
      final shouldProceed = await _showConfirmationDialog(context);
      if (!shouldProceed) return false;

      // Save the profile data
      if (!context.mounted) return false;

      // Ensure profile data is properly typed
      final Map<String, dynamic> profileData = Map<String, dynamic>.from(validationResult.data ?? {});
      
      final success = await _saveProfileData(
        context, 
        profileData,
        onSuccess
      );

      if (success) {
        if (!context.mounted) return true;
        _showSuccess(context);
        return true;
      }
      
      if (!success) {
        if (!context.mounted) return false;
        _showError(context, 'Failed to save profile data');
      }

      return success;
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, 'An error occurred: $e');
      return false;
    }
  }

  /// Shows an error dialog with the given message.
  static void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a success dialog.
  static void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Profile data imported successfully'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before importing.
  static Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: const Text(
          'This will create a new profile from the imported data. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Saves profile data using the upload utility
  static Future<bool> _saveProfileData(
    BuildContext context,
    Map<String, dynamic> profileData,
    VoidCallback onSuccess,
  ) async {
    try {
      // Capture the actual onSuccess we want to call
      void handleSuccess() {
        onSuccess();
      }
      
      final result = await uploadJsonToPod(
        data: profileData,
        targetPath: 'healthpod/data/profile',
        fileNamePrefix: 'profile',
        context: context,
        onSuccess: handleSuccess,
      );

      return result == SolidFunctionCallStatus.success;
    } catch (e) {
      debugPrint('Error saving profile data: $e');
      return false;
    }
  }
} 