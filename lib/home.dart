/// Home screen for the health data app.
///
// Time-stamp: <Friday 2025-09-19 17:08:41 +1000 Graham Williams>
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:solidui/solidui.dart'
    show
        SolidAboutConfig,
        SolidAppBarAction,
        SolidAppBarConfig,
        SolidLoginStatus,
        SolidMenuItem,
        SolidNavUserInfo,
        SolidScaffold,
        SolidSecurityKeyStatus,
        SolidServerInfo,
        SolidStatusBarConfig,
        SolidThemeToggleConfig,
        SolidVersionConfig;

import 'package:healthpod/features/home/managers/home_state_manager.dart';
import 'package:healthpod/features/home/widgets/menu_builder.dart';
import 'package:healthpod/providers/tab_state.dart';
import 'package:healthpod/settings/dialog.dart';

/// The home screen for the HealthPod app.
///
/// This screen serves as the main entry point for the HealthPod application,
/// providing users with a dashboard of features, a footer with user-specific
/// information, and options to log out or view information about the app.

class HealthPodHome extends ConsumerStatefulWidget {
  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends ConsumerState<HealthPodHome> {
  String? _webId;
  bool _isKeySaved = false;
  String _appVersion = '';
  int _selectedMenuIndex = 0;
  bool _hasUserSelectedFeatureTab = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _initialiseData();
  }

  /// Loads the app name and version from package_info_plus.

  Future<void> _loadAppInfo() async {
    final appInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = appInfo.version;
      });
    }
  }

  /// Initialises all required data including footer data and feature folders.

  Future<void> _initialiseData() async {
    await HomeStateManager.initialiseData(
      context,
      _webId,
      (webId, isKeySaved) {
        if (mounted) {
          setState(() {
            _webId = webId;
            _isKeySaved = isKeySaved;
          });
        }
      },
    );
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

  /// Sets the selected menu index and triggers a rebuild.

  void setSelectedMenuIndex(int index) {
    setState(() {
      _selectedMenuIndex = index;
    });
  }

  /// Handles menu selection in the SolidScaffold.

  void _onMenuSelected(int index) {
    setSelectedMenuIndex(index);
    // Mark that the user has actively selected a feature tab.

    _hasUserSelectedFeatureTab = true;

    // Only set tabStateProvider selectedIndex to 0 when user clicks View,
    // Entry, or Data AND the current selected index is -1 (initial state).
    // This preserves tab synchronisation whilst ensuring proper initialisation.

    if (index == 1 || index == 2 || index == 3) {
      // View, Entry, Data.

      final currentTabIndex = ref.read(tabStateProvider).selectedIndex;
      if (currentTabIndex == -1) {
        ref.read(tabStateProvider.notifier).setSelectedIndex(0);
      }
    }
  }

  /// Handles successful CSV import.

  void _onImportSuccess(String importType) {
    if (mounted) {
      // Show a success message.

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${importType.replaceAll('_', ' ').toUpperCase()} data imported '
            'successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Builds the menu items for SolidScaffold navigation with callbacks.

  List<SolidMenuItem> _buildHealthPodMenu() {
    return HealthPodMenuBuilder.buildHealthPodMenuWithCallbacks(
      onImportSuccess: _onImportSuccess,
      hasUserSelectedFeatureTab: _hasUserSelectedFeatureTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SolidScaffold(
      menu: _buildHealthPodMenu(),
      selectedIndex: _selectedMenuIndex,
      onMenuSelected: _onMenuSelected,
      appBar: SolidAppBarConfig(
        title: 'HealthPod',
        versionConfig: const SolidVersionConfig(
          showDate: true,
          changelogUrl:
              'https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md',
          tooltip: '''
Version information for HealthPod

Tap to view the complete changelog on GitHub with release notes, bug fixes, and new features.
''',
        ),
        actions: [
          SolidAppBarAction(
            icon: Icons.settings,
            tooltip: '''

            **Settings:** Tap here to view and manage your HealthPod account
              settings.

            ''',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const SettingsDialog(),
            ),
          ),
        ],
        overflowItems: [],
      ),
      themeToggle: const SolidThemeToggleConfig(),
      statusBar: SolidStatusBarConfig(
        serverInfo: _webId != null
            ? SolidServerInfo.fromWebId(
                _webId!,
                tooltip: '''

**WebID:** This is your complete WebID including both server and username
where your health data is stored securely.

Tap to visit your server in the browser.

''',
              )
            : null,
        loginStatus: SolidLoginStatus(
          webId: _webId,
        ),
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          onKeyStatusChanged: _updateKeyStatus,
        ),
      ),
      aboutConfig: SolidAboutConfig(
        applicationName: 'HealthPod',
        applicationVersion: _appVersion,
        applicationIcon: Image.asset(
          'assets/images/app_logo.png',
          width: 100,
          height: 100,
        ),
        applicationLegalese: '© 2025 Software Innovation Institute ANU',
        text: '''

        **A Health and Medical Record Manager.**

        HealthPod is an app for managing your health data and medical records,
        keeping all data stored in your personal online dataset (Pod). Medical
        documents as well as a health diary can be maintained.

        The app is written in Flutter and the open source code is available from
        [github](https://github.com/gjwgit/healthpod). You can try it out online
        at the [AU Solid Community](https://healthpod.solidcommunity.au).

        The images for the app were generated by ChatGPT.

        *Authors: Graham Williams, Ashley Tang, Kevin Wang, Zheyuan Xu.*

        *Contributors: .*

        **Web ID:** ${_webId ?? 'Web ID is not available and need to login first.'}

        ''',
      ),
      userInfo: SolidNavUserInfo(
        webId: _webId,
        showWebId: true,
        avatarIcon: Icons.account_circle,
        versionConfig: const SolidVersionConfig(
          changelogUrl:
              'https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md',
          showDate: true,
          tooltip: '''
Version information for HealthPod

Tap to view the complete changelog on GitHub with release notes, bug fixes, and new features.
''',
        ),
      ),
    );
  }
}
