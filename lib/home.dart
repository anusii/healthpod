/// Home screen for the health data app.
///
// Time-stamp: <Sunday 2025-03-09 11:50:04 +1100 Graham Williams>
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

import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/dialogs/show_about.dart';
import 'package:healthpod/features/charts/tab.dart';
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
    'tooltip': 'Return to your main HealthPod overview and dashboard.',
  },
  {
    'title': 'Diary',
    'icon': Icons.calendar_today,
    'color': null,
    'message': '''

    Here you will be able to access and manage your
    appointments. You can enter historic information, update
    when you recieve a new appointment, and download
    appointments from other sources.
    ''',
    'dialogTitle': 'Coming Soon - Appointment',
  },
  {
    'title': 'Update',
    'icon': Icons.assignment,
    'color': null,
    'content': const SurveyTab(),
    'tooltip': '''

    Log your Blood Pressure (systolic, diastolic, heart rate),
    how you are feeling, and vaccination records.
    ''',
  },
  {
    'title': 'Charts',
    'icon': Icons.show_chart,
    'color': null,
    'content': const ChartTab(),
    'tooltip':
        'Visualize your Blood Pressure trends and other health metrics with interactive charts.Vaccination timeline charts are also available.',
  },
  {
    'title': 'Table',
    'icon': Icons.table_chart,
    'color': null,
    'content': const TableTab(),
    'tooltip':
        'View and manage your Blood Pressure and Vaccination records in a detailed table view.',
  },
  {
    'title': 'Files',
    'icon': Icons.folder,
    'color': null,
    'content': const FileService(),
    'tooltip': '''

    Tap here to access file management features.
    This allows you to:

          - Browse your POD storage
          - Upload files to your POD
          - Download files from your POD
          - Delete files from your POD
    ''',
  },
  {
    'title': 'Resources',
    'icon': Icons.library_books,
    'color': null,
    'content': const ResourcesTab(),
    'tooltip': '''

    Access a comprehensive collection of health resources including:
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? homeTabs[_selectedIndex]['title']
              : homeTabs[_selectedIndex]['title'],
        ),
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        actions: [
          MarkdownTooltip(
            message: '''

            **Settings:** Tap here to view and manage your HealthPod account settings.

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
            This will clear your current session and return you to the login screen.

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
                          onDestinationSelected: (int index) async {
                            setState(() {
                              _selectedIndex = index;
                            });

                            final tab = homeTabs[index];

                            if (tab.containsKey('message')) {
                              alert(
                                  context, tab['message'], tab['dialogTitle']);
                            } else if (tab.containsKey('action')) {
                              await tab['action'](context);
                            }
                          },
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
                  child:
                      homeTabs[_selectedIndex]['content'] ?? const HomePage(),
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
