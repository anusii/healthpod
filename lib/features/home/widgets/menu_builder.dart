/// Menu builder for the HealthPod home screen.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:healthpod/features/charts/tab.dart';
import 'package:healthpod/features/home/widgets/file_management_content.dart';
import 'package:healthpod/features/resources/tab.dart';
import 'package:healthpod/features/table/tab.dart';
import 'package:healthpod/features/update/tab.dart';
import 'package:healthpod/widgets/home_page.dart';

/// Utility class for building HealthPod navigation menu items.

class HealthPodMenuBuilder {
  const HealthPodMenuBuilder._();

  /// Builds the basic HealthPod menu items.

  static List<SolidMenuItem> buildBasicHealthPodMenu() => [
        SolidMenuItem(
          title: 'Home',
          icon: Icons.home,
          tooltip: '''

    **Home:** Tap here to view your HealthPod overview and dashboard.

    ''',
          child: HomePage(
            onNavigateToProfile: () {},
          ),
        ),
        SolidMenuItem(
          title: 'View',
          icon: Icons.show_chart,
          tooltip: '''

    **View:** Tap here to visualise your health data that is stored in your
      pod. Your **blood pressure** observations will show trends over time and
      other health metrics. Your **vaccinations** will be shown as a timeline.

    ''',
          child: const ChartTab(),
        ),
        SolidMenuItem(
          title: 'Entry',
          icon: Icons.assignment,
          tooltip: '''

    **Add:** Tap here to directly enter new data. This could be new observations
    of your **Blood Pressure** (systolic, diastolic, heart rate) or a new
    **Vaccination**. To upload new data from a *CSV* file vist the **Files**
    tab.

    ''',
          child: const SurveyTab(),
        ),
        SolidMenuItem(
          title: 'Data',
          icon: Icons.table_chart,
          tooltip: '''

    **Data:** Tap here to view, modify, add, or remove your saved health data
      through a tabular form. All of your health data from your pod is
      accessible here.

    ''',
          child: const TableTab(),
        ),
        SolidMenuItem(
          title: 'Files',
          icon: Icons.folder,
          tooltip: '''

    **Files:** Tap here to access file management features.  Here you can load
    your health data from any local *CSV* files you may have created into your
    Health Pod.

    The **Files** tab allows you to **browse** your pod storage, **upload**
    files to your pod, **download** files from your pod to you local device, and
    to **delete** files from your pod storage.

    ''',
          child: const FileManagementContent(
            hasUserSelectedFeatureTab: false,
          ),
        ),
        SolidMenuItem(
          title: 'Support',
          icon: Icons.library_books,
          tooltip: '''

    **Support:** Tap here to access a comprehensive collection of health
    resources including:

    - Health information and guides

    - External trusted resources

    - Useful health calculators and tools

    ''',
          child: const ResourcesTab(),
        ),
      ];

  /// Builds the HealthPod menu with callbacks for file management.

  static List<SolidMenuItem> buildHealthPodMenuWithCallbacks({
    required Function(String importType)? onImportSuccess,
    required bool hasUserSelectedFeatureTab,
  }) {
    final basicMenu = buildBasicHealthPodMenu();

    // Find the Files menu item and replace it with one that has the callback.

    return basicMenu.map((item) {
      if (item.title == 'Files') {
        return SolidMenuItem(
          title: item.title,
          icon: item.icon,
          tooltip: item.tooltip,
          child: FileManagementContent(
            onImportSuccess: onImportSuccess,
            hasUserSelectedFeatureTab: hasUserSelectedFeatureTab,
          ),
        );
      }
      return item;
    }).toList();
  }
}
