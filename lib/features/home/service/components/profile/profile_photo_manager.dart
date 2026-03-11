/// Photo management for profile details including upload and deletion.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/home/service/components/profile/'
    'profile_photo_crop_dialog.dart';
import 'package:healthpod/utils/profile_photo_handler.dart';

/// Manages profile photo operations including loading, uploading, and deleting.

class ProfilePhotoManager {
  /// Shows dialog for selecting profile photo options.

  static Future<void> showPhotoOptionsDialog(
    BuildContext context,
    ImageProvider? profilePhoto,
    String userName,
    Function(ImageProvider?) onPhotoChanged,
    Function() onDataChanged,
    void Function(bool) onUploadingChange,
    bool isLoading,
    bool isSaving,
    bool isLoadingPhoto,
    bool isUploadingPhoto,
  ) async {
    if (isLoading || isSaving || isLoadingPhoto || isUploadingPhoto) {
      return;
    }

    final parentContext = context;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Profile Photo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display current photo or avatar in circular frame.

                SizedBox(
                  height: 100,
                  width: 100,
                  child: ProfilePhotoHandler.buildProfileAvatar(
                    context: dialogContext,
                    photo: profilePhoto,
                    name: userName,
                    radius: 50,
                  ),
                ),
                const SizedBox(height: 20),

                // Photo action buttons: upload (JPG/PNG, max 2 MB) or remove.

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _handlePhotoUpload(
                          parentContext,
                          onPhotoChanged,
                          onDataChanged,
                          onUploadingChange,
                        );
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Upload New'),
                    ),
                    if (profilePhoto != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _handlePhotoDelete(
                            parentContext,
                            onPhotoChanged,
                            onDataChanged,
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(dialogContext).colorScheme.error,
                          foregroundColor: Theme.of(
                            dialogContext,
                          ).colorScheme.onError,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Handles photo upload process.

  static Future<void> _handlePhotoUpload(
    BuildContext context,
    Function(ImageProvider?) onPhotoChanged,
    Function() onDataChanged,
    void Function(bool) onUploadingChange,
  ) async {
    try {
      // Pick image with validation.

      final picked = await ProfilePhotoHandler.pickProfilePhoto(context);

      if (picked == null || !context.mounted) {
        return;
      }

      // Show crop dialog for user to select square region.

      final croppedBytes = await ProfilePhotoCropDialog.show(
        context,
        picked.bytes,
      );

      if (croppedBytes == null || !context.mounted) {
        return;
      }

      onUploadingChange(true);

      // Upload cropped image to pod (stored in data/profile folder).

      final success = await ProfilePhotoHandler.uploadProfilePhoto(
        croppedBytes,
        'png',
        context,
      );

      onUploadingChange(false);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (context.mounted) {
          await ProfilePhotoHandler.cleanupOldProfilePhotos(context);
        }

        if (context.mounted) {
          final newPhoto = await ProfilePhotoHandler.getProfilePhoto();
          onPhotoChanged(newPhoto);
        }

        onDataChanged();
      }
    } catch (e) {
      onUploadingChange(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles photo deletion.

  static Future<void> _handlePhotoDelete(
    BuildContext context,
    Function(ImageProvider?) onPhotoChanged,
    Function() onDataChanged,
  ) async {
    try {
      if (context.mounted) {
        final success = await ProfilePhotoHandler.deleteProfilePhoto(context);

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset the photo.

          onPhotoChanged(null);

          // Notify parent of data change.

          onDataChanged();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Loads profile photo from POD.

  static Future<ImageProvider?> loadProfilePhoto(BuildContext context) async {
    try {
      return await ProfilePhotoHandler.getProfilePhoto();
    } catch (e) {
      return null;
    }
  }
}
