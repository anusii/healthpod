/// Home screen for the health data app.
///
// Time-stamp: <Friday 2025-02-21 16:58:42 +1100 Graham Williams>
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

import 'package:healthpod/dialogs/alert.dart';
import 'package:healthpod/features/bp/editor/page.dart';
import 'package:healthpod/features/file/service.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/dialogs/show_about.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/fetch_web_id.dart';
import 'package:healthpod/utils/get_footer_height.dart';
import 'package:healthpod/utils/handle_logout.dart';
import 'package:healthpod/utils/initialise_feature_folders.dart';
import 'package:healthpod/widgets/footer.dart';
import 'package:healthpod/features/bp/combined_visualisation.dart';
import 'package:healthpod/widgets/home_page.dart';
import 'package:healthpod/features/survey/tab.dart';

/// The home screen for the HealthPod app.
///
/// This screen serves as the main entry point for the HealthPod application,
/// providing users with a dashboard of features, a footer with user-specific
/// information, and options to log out or view information about the app.

// Define the [NavigationRail] tabs for the home page.
final List<Map<String, dynamic>> homeTabs = [
  {
    'title': 'Home',
    'icon': Icons.home,
    'color': null,
    'tooltip': 'Go to Home Dashboard',
  },
  {
    'title': 'Diary',
    'icon': Icons.calendar_today,
    'color': Colors.blue,
    'message': '''

    Here you will be able to access and manage your
    appointments. You can enter historic information, update
    when you recieve a new appointment, and download
    appointments from other sources.

    ''',
    'dialogTitle': 'Coming Soon - Appointment',
    'tooltip': 'Manage your appointments',
  },
  {
    'title': 'Update',
    'icon': Icons.assignment,
    'color': Colors.blue,
    'content': const SurveyTab(),
    'tooltip': 'Update your health data',
  },
  {
    'title': 'Charts',
    'icon': Icons.show_chart,
    'color': Colors.blue,
    'content': const BPCombinedVisualisation(),
    'tooltip': 'View charts of your health data',
  },
  {
    'title': 'Table',
    'icon': Icons.table_chart,
    'color': Colors.blue,
    'content': const BPEditorPage(),
    'tooltip': 'Edit data in table view',
  },
  {
    'title': 'Files',
    'icon': Icons.folder,
    'color': Colors.blue,
    'content': const FileService(),
    'tooltip': 'Manage your files',
  },
  {
    'title': 'Resources',
    'icon': Icons.library_books,
    'color': Colors.blue,
    'message': '''

    Here you will be able to access a range of resources
    to help you manage your health. This includes links to
    external websites, articles, and other useful information.

    ''',
    'dialogTitle': 'Coming Soon - Resources',
    'tooltip': 'Access health resources',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health Data, Under Your Control'),
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
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey[350]),
          Expanded(
            child: Row(
              children: [
                ScrollConfiguration(
                  // Disable scrollbars for a cleaner look.

                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    // Allow scrolling of navigation rail when it overflows.

                    child: SizedBox(
                      // Set height to match screen height.
                      height: MediaQuery.of(context).size.height,
                      child: Container(
                        color: titleBackgroundColor,
                        child: NavigationRail(
                          backgroundColor: titleBackgroundColor,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (int index) async {
                            setState(() {
                              _selectedIndex = index;
                            });

                            final tab = homeTabs[index];

                            // Handle different types of navigation based on tab properties.

                            if (tab.containsKey('message')) {
                              alert(
                                  context, tab['message'], tab['dialogTitle']);
                            } else if (tab.containsKey('action')) {
                              await tab['action'](context);
                            }
                          },
                          // Show both icons and labels for all destinations.
                          labelType: NavigationRailLabelType.all,
                          destinations: homeTabs.map((tab) {
                            // Use a custom tooltip if provided; otherwise, default to the tab title.

                            final tooltipMessage = tab['tooltip'] ?? tab['title'];
                            return NavigationRailDestination(
                              icon: Tooltip(
                                message: tooltipMessage,
                                child: Icon(tab['icon'], color: tab['color']),
                              ),
                              label: Text(
                                tab['title'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                            );
                          }).toList(),
                          // Style for selected tab label.

                          selectedLabelTextStyle: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                          // Style for unselected tab labels.

                          unselectedLabelTextStyle:
                              TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child:
                      homeTabs[_selectedIndex]['content'] ?? const HomePage(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[350]),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: getFooterHeight(context),
        color: titleBackgroundColor,
        child: SizedBox(
          child: Footer(
            webId: _webId,
            isKeySaved: _isKeySaved,
            // Callback to update key status.
            
            onKeyStatusChanged: _updateKeyStatus,
          ),
        ),
      ),
    );
  }
}
