/// Home screen for the health data app.
///
// Time-stamp: <Tuesday 2025-04-29 08:50:09 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart' show getAppNameVersion;
import 'package:version_widget/version_widget.dart';

import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/dialogs/show_about.dart';
import 'package:healthpod/features/charts/tab.dart';
import 'package:healthpod/features/diary/tab.dart';
import 'package:healthpod/features/file/service/page.dart';
import 'package:healthpod/features/resources/tab.dart';
import 'package:healthpod/features/table/tab.dart';
import 'package:healthpod/features/update/tab.dart';
import 'package:healthpod/settings/dialog.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:healthpod/utils/get_footer_height.dart';
import 'package:healthpod/utils/handle_logout.dart';
import 'package:healthpod/utils/initialise_feature_folders.dart';
import 'package:healthpod/widgets/footer.dart';
import 'package:healthpod/widgets/home_page.dart';
import 'package:healthpod/widgets/theme_toggle.dart';

/// The home screen for the HealthPod app.
///
/// This screen serves as the main entry point for the HealthPod application,
/// providing users with a dashboard of features, a footer with user-specific
/// information, and options to log out or view information about the app.

// Define the [NavigationRail] tabs for the home page.
// Color is set to null to use the default color from the theme.

final List<Map<String, dynamic>> homeTabs = [
  {
    'title': 'Home',
    'icon': Icons.home,
    'color': null,
    'tooltip': '''

    **Home:** Tap here to view your HealthPod overview and dashboard.

    ''',
  },
  {
    'title': 'Diary',
    'icon': Icons.calendar_today,
    'color': null,
    'content': const DiaryTab(),
    'tooltip': '''

    **Diary:** Tap here to access and manage your appointments. You can enter
    previous appointments for the record and update the calendar when you
    recieve a new appointment. To load appointments from other sources via a
    *CSV* file into your calendar visit the **Files** tab.

    ''',
  },
  {
    'title': 'New',
    'icon': Icons.assignment,
    'color': null,
    'content': const SurveyTab(),
    'tooltip': '''

    **New:** Tap here to directly enter new data. This could be new observations
    of your **Blood Pressure** (systolic, diastolic, heart rate) or a new
    **Vaccination**. To upload new data from a *CSV* file vist the **Files**
    tab.

    ''',
  },
  {
    'title': 'Visuals',
    'icon': Icons.show_chart,
    'color': null,
    'content': const ChartTab(),
    'tooltip': '''

    **Visuals:** Tap here to visualise your health data that is stored in your
      pod. Your **blood pressure** observations will show trends over time and
      other health metrics. Your **vaccinations** will be shown as a timeline.

    ''',
  },
  {
    'title': 'Tables',
    'icon': Icons.table_chart,
    'color': null,
    'content': const TableTab(),
    'tooltip': '''

    **Tables:** Tap here to view, modify, add, or remove your saved health data
      through a tabular form. All of your health data from your pod is
      accessible here.

    ''',
  },
  {
    'title': 'Files',
    'icon': Icons.folder,
    'color': null,
    'content': const FileService(),
    'tooltip': '''

    **Files:** Tap here to access file management features.  Here you can load
    your health data from any local *CSV* files you may have created into your
    Health Pod.

    The **Files** tab allows you to **browse** your pod storage, **upload**
    files to your pod, **download** files from your pod to you local device, and
    to **delete** files from your pod storage.

    ''',
  },
  {
    'title': 'Resources',
    'icon': Icons.library_books,
    'color': null,
    'content': const ResourcesTab(),
    'tooltip': '''

    **Resources:** Tap here to access a comprehensive collection of health
    resources including:

    - Health information and guides

    - External trusted resources

    - Useful health calculators and tools

    ''',
  },
];

class HealthPodHome extends StatefulWidget {
  const HealthPodHome({super.key});

  @override
  HealthPodHomeState createState() => HealthPodHomeState();
}

class HealthPodHomeState extends State<HealthPodHome> {
  String? _webId;
  bool _isKeySaved = false;
  int _selectedIndex = 0;
  String _appVersion = '';
  bool _isVersionLoaded = false;
  // Key to force rebuilds when profile is updated.

  final GlobalKey<State> _homePageKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _initialiseFooterData(context);
    _initialiseData(context);
  }

  /// Loads the app name and version from package_info_plus.

  Future<void> _loadAppInfo() async {
    final appInfo = await getAppNameVersion();
    if (mounted) {
      setState(() {
        _appVersion = appInfo.version;
        _isVersionLoaded = true;
      });
    }
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
            // debugPrint('Feature folder initialization complete');
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

  void _handleTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final tab = homeTabs[index];

    if (tab.containsKey('message')) {
      alert(context, tab['message'], tab['dialogTitle']);
    } else if (tab.containsKey('action')) {
      tab['action'](context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(homeTabs[_selectedIndex]['title']),
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        actions: [
          // Add version widget.

          if (_isVersionLoaded)
            MarkdownTooltip(
              message: '''

              **Version:** This is the current version of the HealthPod app. If
              the version is out of date then the text will be red. You can tap on
              the version to view the app's Change Log to determine if it is worth
              updating your version.

              ''',
              child: VersionWidget(
                version: _appVersion,
                changelogUrl:
                    'https://github.com/anusii/healthpod/blob/dev/CHANGELOG.md',
                showDate: true,
              ),
            ),

          const SizedBox(width: 50),

          const ThemeToggle(),

          MarkdownTooltip(
            message: '''

            **Settings:** Tap here to view and manage your HealthPod account
              settings.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              ),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **Logout:** Tap here to securely log out of your HealthPod account.
            This will clear your current session and return you to the login
            screen.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: theme.colorScheme.primary,
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
              icon: Icon(
                Icons.info,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: Row(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Container(
                        color: theme.colorScheme.surface,
                        child: NavigationRail(
                          backgroundColor: theme.colorScheme.surface,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _handleTabChange,
                          labelType: NavigationRailLabelType.all,
                          destinations: homeTabs.map((tab) {
                            final tooltipMessage =
                                tab['tooltip'] ?? tab['message'];

                            return NavigationRailDestination(
                              icon: MarkdownTooltip(
                                message: tooltipMessage,
                                child: Icon(
                                  tab['icon'],
                                  color:
                                      tab['color'] ?? theme.colorScheme.primary,
                                ),
                              ),
                              label: Text(
                                tab['title'],
                                style: theme.textTheme.bodyLarge,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.0),
                            );
                          }).toList(),
                          selectedLabelTextStyle:
                              theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          unselectedLabelTextStyle: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(color: theme.dividerColor),
                Expanded(
                  child: homeTabs[_selectedIndex]['content'] ??
                      HomePage(
                        key: _homePageKey,
                        onNavigateToProfile: () {},
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: getFooterHeight(context),
        color: theme.colorScheme.surface,
        child: SizedBox(
          child: Footer(
            webId: _webId,
            isKeySaved: _isKeySaved,
            onKeyStatusChanged: _updateKeyStatus,
          ),
        ),
      ),
    );
  }
}
