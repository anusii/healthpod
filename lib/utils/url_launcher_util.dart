/// Utility class for launching URLs with error handling.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Utility class for launching URLs with error handling.
///
/// Provides a standardised way to launch URLs across the app
/// with consistent error handling and user feedback.

class UrlLauncherUtil {
  /// Launches a URL with error handling.
  ///
  /// Opens the specified [url] in an external application and shows error messages
  /// if the URL cannot be launched. The [websiteName] parameter is used in error messages
  /// to provide context about which site couldn't be opened.

  static Future<void> launchUrl({
    required BuildContext context,
    required String url,
    required String websiteName,
    url_launcher.LaunchMode mode = url_launcher.LaunchMode.externalApplication,
  }) async {
    final Uri uri = Uri.parse(url);

    try {
      if (!await url_launcher.launchUrl(uri, mode: mode)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $websiteName website')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching $websiteName: $e')),
        );
      }
    }
  }

  /// Pre-configured method to launch the American Heart Association website.
  ///
  /// Parameters:
  /// * [context] - The BuildContext for showing SnackBar messages

  static Future<void> launchAHA(BuildContext context) async {
    await launchUrl(
      context: context,
      url:
          'https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings',
      websiteName: 'AHA',
    );
  }
}
