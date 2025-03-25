/// Avatar image card widget.
//
// Time-stamp: <Sunday 2025-03-09 11:43:18 +1100 Graham Williams>
//
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
/// Authors: Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/appointment.dart';

/// A widget that displays the user's avatar, name, patient ID,
/// and a notification bell with the number of notifications.
///
/// This widget is typically used at the top of a user dashboard
/// to provide quick identification and notifications status.

class AvatarName extends StatefulWidget {
  const AvatarName({super.key});

  @override
  State<AvatarName> createState() => _AvatarNameState();
}

class _AvatarNameState extends State<AvatarName> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 400,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            spreadRadius: 3,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // User avatar with lock icon indicator.
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage:
                    AssetImage('assets/images/sample_avatar_image.png'),
              ),
              // Positioned lock icon at bottom-right.
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
            ],
          ),

          const SizedBox(width: 12),

          // User's name and patient ID.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Patient ID: $patientID',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Notification bell with notification count badge.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              // Show notification count badge only if notifications exist.
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
      ),
    );
  }
}
