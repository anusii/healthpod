/// State management utilities for the HealthPod home screen.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:healthpod/utils/initialise_feature_folders.dart';
import 'package:healthpod/utils/is_logged_in.dart';

/// Utility class for managing HealthPod home screen state and initialisation.

class HomeStateManager {
  const HomeStateManager._();

  /// Initialises all required data including footer data and feature folders.

  static Future<void> initialiseData(
    BuildContext context,
    String? webId,
    Function(String? webId, bool isKeySaved) onStateUpdate,
  ) async {
    // First initialise footer data.

    final footerData = await initialiseFooterData(context);
    onStateUpdate(footerData.webId, footerData.isKeySaved);

    // Then initialise feature folders if user is logged in.
    // webId will only be non-null if the user is actively logged in
    // thanks to our updated fetchWebId function

    if (footerData.webId != null) {
      // Check security key once for the entire session.

      if (context.mounted) {
        await SolidSecurityKeyCentralManager.instance.ensureSecurityKey(
          context,
          const Text('Security verification is required to access your data'),
        );
      }

      if (context.mounted) {
        await initialiseFeatureFolders(
          context: context,
          onProgress: (inProgress) {
            // Progress updates can be handled by the calling widget
          },
          onComplete: () {
            // Feature folders initialized
          },
        );
      }
    }
  }

  /// Initialises the footer data by fetching the Web ID and encryption key
  /// status.

  static Future<FooterData> initialiseFooterData(BuildContext context) async {
    // Check if user is logged in with valid session.

    final loggedIn = await isLoggedIn();
    final webId = loggedIn ? await fetchWebId() : null;

    // Only fetch key status if webId is not null (user is logged in)
    // This prevents the login prompt for users who clicked CONTINUE.

    bool isKeySaved = false;
    if (webId != null && context.mounted) {
      // Let the central key manager check for security key status.
      // This prevents multiple prompts across the app.

      isKeySaved =
          await SolidSecurityKeyCentralManager.instance.ensureSecurityKey(
        context,
        const Text('Security verification is required for Health Pod'),
      );
    }

    return FooterData(webId: webId, isKeySaved: isKeySaved);
  }

  /// Extracts the server URL from a WebID.

  static String extractServerFromWebId(String webId) {
    try {
      final uri = Uri.parse(webId);
      return '${uri.scheme}://${uri.host}'
          '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    } catch (e) {
      final parts = webId.split('/');
      if (parts.length >= 3) {
        return '${parts[0]}//${parts[2]}';
      }
      return webId;
    }
  }
}

/// Data class for footer initialisation results.

class FooterData {
  final String? webId;
  final bool isKeySaved;

  const FooterData({required this.webId, required this.isKeySaved});
}
