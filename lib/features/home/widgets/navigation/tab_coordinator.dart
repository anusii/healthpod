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
  /// The feature folders, in the order of the tabs that show them.
  ///
  /// The View, Add and Data tabs share a selected index, so this is the one
  /// place the tab order and the pod folders are tied together.

  static const List<String> _tabDirs = [
    'diary', // Appointments.
    'health_profile', // Health Profile.
    'blood_pressure', // Blood Pressure.
    'medication', // Medications.
    'vaccination', // Vaccinations.
    'pathology', // Pathology.
  ];

  /// Returns the tab index that corresponds to [path], or null if [path]
  /// does not match any known feature folder.

  static int? getTabIndexForPath(String path) {
    for (var index = 0; index < _tabDirs.length; index++) {
      final dir = _tabDirs[index];
      if (path == '$basePath/$dir' || path.endsWith('/$dir')) return index;
    }
    return null;
  }

  /// The pod folder shown by tab [index], or the data root for anything that
  /// is not a feature tab.

  static String _pathForTab(int index) => index >= 0 && index < _tabDirs.length
      ? '$basePath/${_tabDirs[index]}'
      : basePath;

  /// Gets the expected path for the current tab selection.

  static String getExpectedPathForCurrentTab(WidgetRef ref) =>
      _pathForTab(ref.read(tabStateProvider).selectedIndex);

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

    final targetPath = _pathForTab(ref.read(tabStateProvider).selectedIndex);
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
      initialPath = _pathForTab(currentTabIndex);
    }

    return initialPath;
  }
}
