/// Profile photo upload and retrieval utility.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_filename.dart';

/// Handles the uploading, retrieval, and management of profile photos.

class ProfilePhotoHandler {
  // Directory name for profile data (relative path only).

  static const String _profileDirectoryRelative = 'profile';

  // Full path to the profile directory in the pod (for directory operations).

  static const String _profileDirectoryFull = 'healthpod/data/profile';

  /// Build the correct pod path for profile data.
  ///
  /// This ensures we use the correct path structure for file operations.

  static String _buildProfilePath(String filename) {
    // For writePod/readPod we only use the relative path (SolidPod adds the prefix).

    return '$_profileDirectoryRelative/$filename';
  }

  /// Gets the directory URL for the profile directory.

  static Future<String> _getProfileDirectoryUrl() async {
    // For directory operations we need the full path.

    return await getDirUrl(_profileDirectoryFull);
  }

  /// Opens a file picker to select an image file for profile photo.
  ///
  /// Returns a File object representing the selected image file, or null if no file was selected.

  static Future<File?> pickProfilePhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (result.files.first.path != null) {
          return File(result.files.first.path!);
        }
      }
      return null;
    } catch (e) {
      //debugPrint('Error picking profile photo: $e');
      return null;
    }
  }

  /// Uploads a profile photo to the user's Solid Pod.
  ///
  /// Parameters:
  /// - [imageFile]: File object of the image to upload
  /// - [context]: BuildContext for UI interactions and Pod operations
  ///
  /// Returns true if upload was successful, false otherwise.

  static Future<bool> uploadProfilePhoto(
    File imageFile,
    BuildContext context,
  ) async {
    try {
      // Create a timestamped filename.

      final timestamp = DateTime.now();
      final formattedTimestamp = formatTimestampForFilename(timestamp);

      // Use a distinct prefix for photo files to differentiate from profile data.

      final filename = 'profile_photo_$formattedTimestamp.photo.enc.ttl';

      // Convert image to base64 for storage.

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create JSON data - only photo-related data, no profile fields.

      final jsonData = {
        'timestamp': timestamp.toIso8601String(),
        'imageData': base64Image,
        'format': imageFile.path.split('.').last.toLowerCase(),
        // Add a type marker to clearly identify this as a photo file.

        'type': 'profile_photo'
      };

      // Convert to JSON string.

      final jsonString = jsonEncode(jsonData);

      // Upload to Pod - use the relative path.

      final filePath = _buildProfilePath(filename);

      if (!context.mounted) return false;

      // Upload with encryption.

      final status = await writePod(
        filePath,
        jsonString,
        context,
        const Text('Uploading profile photo'),
        encrypted: true,
      );

      return status == SolidFunctionCallStatus.success;
    } catch (e) {
      //debugPrint('Error uploading profile photo: $e');
      return false;
    }
  }

  /// Gets the most recent profile photo from the user's Solid Pod.
  ///
  /// Parameters:
  /// - [context]: BuildContext for UI interactions and Pod operations
  ///
  /// Returns ImageProvider object for use in widgets, or null if no photo is found.

  static Future<ImageProvider?> getProfilePhoto(BuildContext context) async {
    try {
      // Get directory URL and list files using the full path.

      final dirUrl = await _getProfileDirectoryUrl();

      final resources = await getResourcesInContainer(dirUrl);

      final List<String> photoFiles = [];

      // Filter specifically for profile photo files.
      // The key is to only process files that start with profile_photo_ prefix
      // and not just any profile_ files.

      for (var file in resources.files) {
        if (file.startsWith('profile_photo_') &&
            (file.endsWith('.photo.enc.ttl') || file.endsWith('.enc.ttl'))) {
          photoFiles.add(file);
        }
      }

      if (photoFiles.isEmpty) {
        // No profile photo found.

        return null;
      }

      // Sort by timestamp (newest first).

      photoFiles.sort((a, b) => b.compareTo(a));

      // Get the most recent photo.

      final mostRecentPhoto = photoFiles.first;

      // For reading, we need to use the full path.

      final filePath = '$_profileDirectoryFull/$mostRecentPhoto';

      // Read the file content.

      if (!context.mounted) return null;

      final fileContent = await readPod(
        filePath,
        context,
        const Text('Loading profile photo'),
      );

      if (fileContent == SolidFunctionCallStatus.fail.toString() ||
          fileContent == SolidFunctionCallStatus.notLoggedIn.toString()) {
        throw Exception('Failed to load profile photo');
      }

      // Parse the JSON content.

      final jsonData = jsonDecode(fileContent);

      // Verify this is indeed a photo file by checking for imageData.

      if (!jsonData.containsKey('imageData')) {
        return null;
      }

      // Extract and decode base64 image data.

      final base64Image = jsonData['imageData'] as String;
      final imageBytes = base64Decode(base64Image);

      // Return as memory image.

      return MemoryImage(Uint8List.fromList(imageBytes));
    } catch (e) {
      return null;
    }
  }

  /// Removes all but the most recent profile photo to save space.
  ///
  /// Parameters:
  /// - [context]: BuildContext for UI interactions and Pod operations
  ///
  /// Returns true if cleanup was successful, false otherwise.

  static Future<bool> cleanupOldProfilePhotos(BuildContext context) async {
    try {
      // Get directory URL and list files using the full path.

      final dirUrl = await _getProfileDirectoryUrl();

      final resources = await getResourcesInContainer(dirUrl);

      final List<String> photoFiles = [];

      // Filter specifically for profile photo files using the unique prefix.

      for (var file in resources.files) {
        if (file.startsWith('profile_photo_') &&
            (file.endsWith('.photo.enc.ttl') || file.endsWith('.enc.ttl'))) {
          photoFiles.add(file);
        }
      }

      if (photoFiles.length <= 1) {
        // No cleanup needed.

        return true;
      }

      // Sort by timestamp (newest first).

      photoFiles.sort((a, b) => b.compareTo(a));

      // Keep the most recent, remove others.

      int deleteCount = 0;
      for (int i = 1; i < photoFiles.length; i++) {
        // For deleting, we need to use the full path.

        final filePath = '$_profileDirectoryFull/${photoFiles[i]}';
        await deleteFile(filePath);
        deleteCount++;
      }

      return true;
    } catch (e) {
      //debugPrint('Error cleaning up old profile photos: $e');
      return false;
    }
  }

  /// Delete the current profile photo.
  ///
  /// Parameters:
  /// - [context]: BuildContext for UI interactions and Pod operations
  ///
  /// Returns true if deletion was successful, false otherwise.

  static Future<bool> deleteProfilePhoto(BuildContext context) async {
    try {
      // Get directory URL and list files using the full path.

      final dirUrl = await _getProfileDirectoryUrl();

      final resources = await getResourcesInContainer(dirUrl);

      final List<String> photoFiles = [];

      // Filter specifically for profile photo files using the unique prefix.

      for (var file in resources.files) {
        if (file.startsWith('profile_photo_') &&
            (file.endsWith('.photo.enc.ttl') || file.endsWith('.enc.ttl'))) {
          photoFiles.add(file);
        }
      }

      if (photoFiles.isEmpty) {
        // No photo to delete.

        return true;
      }

      // Sort by timestamp (newest first).

      photoFiles.sort((a, b) => b.compareTo(a));

      // Delete the most recent photo using the full path.

      final filePath = '$_profileDirectoryFull/${photoFiles.first}';
      await deleteFile(filePath);

      return true;
    } catch (e) {
      //debugPrint('Error deleting profile photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Create a widget that shows either the profile photo or a default avatar with initials.
  ///
  /// Parameters:
  /// - [context]: BuildContext for UI interactions
  /// - [photo]: Optional ImageProvider for a pre-loaded profile photo
  /// - [name]: User's name to extract initials from
  /// - [radius]: Radius of the avatar circle
  /// - [isLoading]: Whether the photo is currently loading
  ///
  /// Returns a CircleAvatar with the appropriate content.

  static Widget buildProfileAvatar({
    required BuildContext context,
    ImageProvider? photo,
    required String name,
    double radius = 24,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    // Extract initials from name.

    final initials = _getInitials(name);
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundImage: photo,
      backgroundColor: photo == null ? theme.colorScheme.primary : null,
      child: photo == null
          ? (isLoading
              ? const CircularProgressIndicator()
              : Text(
                  initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.8,
                  ),
                ))
          : (isLoading ? const CircularProgressIndicator() : null),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }

    return avatar;
  }

  /// Extract initials from a name.
  ///
  /// Returns up to 2 uppercase initials from the name.

  static String _getInitials(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }

    // Get first letter of first and last parts.

    final firstInitial =
        parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final lastInitial =
        parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';

    return '$firstInitial$lastInitial';
  }
}
