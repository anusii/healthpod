/// Tab coordination utilities for file management navigation.
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/file/service/providers/file_service_provider.dart';
import 'package:healthpod/providers/tab_state.dart';

/// Utility class for coordinating tab navigation with file browsing.

class TabCoordinator {
  /// Gets the expected path for the current tab selection.

  static String getExpectedPathForCurrentTab(WidgetRef ref) {
    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    return featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
  }

  /// Navigates to the feature-specific folder based on the current tab
  /// selection.

  static void navigateToFeatureFolder(
    WidgetRef ref,
    bool userHasManuallyNavigated,
    Function(String) onNavigate,
  ) {
    // If the user has manually navigated, don't override their choice.

    if (userHasManuallyNavigated) {
      return;
    }

    // Read the selected tab index from the provider to coordinate with other
    // tabs.

    final selectedIndex = ref.read(tabStateProvider).selectedIndex;

    // Map the tab index to the corresponding directory name.
    // Index 0: Appointments → diary
    // Index 1: Blood Pressure → blood_pressure
    // Index 2: Medications → medication
    // Index 3: Vaccinations → vaccination

    String featureDir;
    switch (selectedIndex) {
      case 0:
        featureDir = 'diary'; // Appointments
        break;
      case 1:
        featureDir = 'blood_pressure'; // Blood Pressure
        break;
      case 2:
        featureDir = 'medication'; // Medications
        break;
      case 3:
        featureDir = 'vaccination'; // Vaccinations
        break;
      default:
        featureDir = ''; // Default to home
        break;
    }

    final targetPath =
        featureDir.isNotEmpty ? '$basePath/$featureDir' : basePath;
    final currentPath = ref.read(fileServiceProvider).currentPath ?? basePath;
    if (currentPath != targetPath) {
      ref.read(fileServiceProvider.notifier).updateCurrentPath(targetPath);
      onNavigate(targetPath);
    }
  }

  /// Gets the initial path based on current tab selection and user
  /// preferences.

  static String getInitialPath(
    WidgetRef ref,
    bool userHasManuallyNavigated,
    bool hasUserSelectedFeatureTab,
  ) {
    final currentTabIndex = ref.read(tabStateProvider).selectedIndex;
    String initialPath = basePath;

    // Map tab index to directory only if we're coordinating with other tabs
    // and the user has actually selected a feature tab.

    if (!userHasManuallyNavigated && hasUserSelectedFeatureTab) {
      switch (currentTabIndex) {
        case 0:
          initialPath = '$basePath/diary'; // Appointments
          break;
        case 1:
          initialPath = '$basePath/blood_pressure'; // Blood Pressure
          break;
        case 2:
          initialPath = '$basePath/medication'; // Medications
          break;
        case 3:
          initialPath = '$basePath/vaccination'; // Vaccinations
          break;
        default:
          initialPath = basePath; // Default to home
          break;
      }
    }

    return initialPath;
  }
}
