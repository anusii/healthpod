/// UI components for profile details display.
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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/utils/profile_photo_handler.dart';

/// Provides UI components for profile details display.

class ProfileUIComponents {
  /// Builds the profile header with avatar, name, and notifications.

  static Widget buildProfileHeader(
    BuildContext context,
    ImageProvider? profilePhoto,
    String userName,
    bool isLoadingPhoto,
    bool isUploadingPhoto,
    VoidCallback onPhotoTap,
  ) {
    final theme = Theme.of(context);
    const int notificationCount = 2;

    return Row(
      children: [
        // User avatar with lock icon.

        Stack(
          clipBehavior: Clip.none,
          children: [
            // Profile photo with loading indicator or initials.

            ProfilePhotoHandler.buildProfileAvatar(
              context: context,
              photo: profilePhoto,
              name: userName,
              radius: 24,
              isLoading: isLoadingPhoto || isUploadingPhoto,
              onTap: onPhotoTap,
            ),

            // Security lock indicator.
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: theme.colorScheme.onTertiary,
                  size: 16,
                ),
              ),
            ),

            // Edit photo indicator.

            if (!isLoadingPhoto && !isUploadingPhoto)
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: theme.colorScheme.primary,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Display user name.

        Expanded(
          child: Text(
            userName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Notification bell with notification count badge.

        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            // Notification counter badge.

            if (notificationCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Builds the title row with edit button.

  static Widget buildTitleRow(
    BuildContext context,
    bool showEditButton,
    bool isLoading,
    bool isSaving,
    VoidCallback onEditPressed,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Profile Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showEditButton)
          MarkdownTooltip(
            message: '''

**Edit Profile Details**

Click to modify your personal information:

- Name
- Address
- Contact information
- Personal details

Your data is securely stored in your personal pod.

''',
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: isLoading || isSaving ? null : onEditPressed,
            ),
          ),
      ],
    );
  }

  /// Builds a single data row with label and value.

  static Widget buildDataRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              color: value.isEmpty
                  ? Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// Creates placeholder loading rows during data fetch.

  static List<Widget> buildLoadingRows(BuildContext context) {
    return List.generate(
      6,
      (index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading/saving overlay.

  static Widget buildLoadingOverlay(
    BuildContext context,
    bool isLoading,
    bool isSaving,
  ) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: theme.cardTheme.color?.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                isLoading
                    ? 'Loading profile data...'
                    : 'Saving profile data...',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
