/// Home screen for the health data app.
///
// Time-stamp: <Monday 2025-01-13 14:59:27 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/show_about.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:healthpod/utils/get_footer_height.dart';
import 'package:healthpod/utils/handle_logout.dart';
import 'package:healthpod/utils/initialise_feature_folders.dart';
import 'package:healthpod/widgets/footer.dart';
import 'package:healthpod/widgets/icon_grid_page.dart';

/// The home screen for the HealthPod app.
///
/// This screen serves as the main entry point for the HealthPod application,
/// providing users with a dashboard of features, a footer with user-specific
/// information, and options to log out or view information about the app.

class HealthPodHome extends StatefulWidget {
  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends State<HealthPodHome> {
  String? _webId;
  bool _isKeySaved = false;

  @override
  void initState() {
    super.initState();
    _initialiseFooterData(context);
    _initialiseData(context);
  }

  /// Initialises all required data including footer data and feature folders.

  Future<void> _initialiseData(BuildContext context) async {
    // First initialise footer data.

    await _initialiseFooterData(context);

    // Then initialise feature folders if user is logged in.

    if (_webId != null) {
      setState(() {});

      if (context.mounted) {
        await initialiseFeatureFolders(
          context: context,
          onProgress: (inProgress) {
            if (mounted) {
              setState(() {});
            }
          },
          onComplete: () {
            debugPrint('Feature folder initialization complete');
          },
        );
      }
    }
  }

  /// Initialises the footer data by fetching the Web ID and encryption key status.

  Future<void> _initialiseFooterData(context) async {
    final webId = await fetchWebId();
    final isKeySaved = await fetchKeySavedStatus(context);

    setState(() {
      _webId = webId;
      _isKeySaved = isKeySaved;
    });
  }

  /// Updates the key saved status in the state and triggers a rebuild.
  ///
  /// This method is passed as a callback to child widgets to notify the home screen
  /// when the encryption key status changes.

  void _updateKeyStatus(bool status) {
    setState(() {
      _isKeySaved = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health - Your Data'),
        backgroundColor: titleBackgroundColor,
        automaticallyImplyLeading: false,
        actions: [
          MarkdownTooltip(
            message: '''

            **Logout:** Tap here to securely log out of your HealthPod account.
            This will clear your current session and return you to the login screen.

            ''',
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.blue,
              ),
              onPressed: () => handleLogout(context),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **About:** Tap here to view information about the HealthPod app.
            This includes a list of contributers and the extensive list of
            open-source packages that the HealthPod app is built on and their
            licenses.

            ''',
            child: IconButton(
              onPressed: () {
                showAbout(context);
              },
              icon: const Icon(
                Icons.info,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: titleBackgroundColor,
      body: IconGridPage(),
      bottomNavigationBar: BottomAppBar(
        height: getFooterHeight(context),
        color: Colors.grey[200],
        child: SizedBox(
          child: Footer(
            webId: _webId,
            isKeySaved: _isKeySaved,
            onKeyStatusChanged:
                _updateKeyStatus, // Callback to update key status.
          ),
        ),
      ),
    );
  }
}
