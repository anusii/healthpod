/// Tab state management using Riverpod.
//
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class to manage tab selections across features.

class TabState {
  /// The selected index shared across all features.

  final int selectedIndex;

  /// The maximum number of tabs across all features.

  static const int maxTabs = 5;

  /// Creates a new [TabState] with the given index.

  const TabState({this.selectedIndex = -1});

  /// Creates a copy of this [TabState] with the given fields replaced with new values.

  TabState copyWith({int selectedIndex = -1}) {
    return TabState(
      selectedIndex: selectedIndex != -1
          ? _normalizeIndex(selectedIndex)
          : this.selectedIndex,
    );
  }

  /// Normalizes the index to ensure it's within valid range.

  static int _normalizeIndex(int index) {
    if (index < -1) return -1;
    if (index >= maxTabs) return maxTabs - 1;
    return index;
  }
}

/// Tracks the currently selected sidebar menu index so that child widgets
/// (e.g. FileManagementContent) can react to page switches.

final menuIndexProvider = NotifierProvider<MenuIndexNotifier, int>(
  MenuIndexNotifier.new,
);

/// Notifier for the sidebar menu index.

class MenuIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Updates the selected menu index.

  void setIndex(int index) {
    state = index;
  }
}

/// Provider for the tab state.

final tabStateProvider = NotifierProvider<TabStateNotifier, TabState>(
  TabStateNotifier.new,
);

/// Notifier class for managing tab state changes.

class TabStateNotifier extends Notifier<TabState> {
  /// Builds the initial state.

  @override
  TabState build() => const TabState();

  /// Updates the selected index for all features.

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: TabState._normalizeIndex(index));
  }
}
