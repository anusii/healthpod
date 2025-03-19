/// Tab state management using Riverpod.
//
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class to manage tab selections across features.

class TabState {
  /// The selected index shared across all features.

  final int selectedIndex;

  /// The maximum number of tabs across all features.

  static const int maxTabs = 2;

  /// Creates a new [TabState] with the given index.

  const TabState({
    this.selectedIndex = 0,
  });

  /// Creates a copy of this [TabState] with the given fields replaced with new values.

  TabState copyWith({
    int? selectedIndex,
  }) {
    return TabState(
      selectedIndex: selectedIndex != null
          ? _normalizeIndex(selectedIndex)
          : this.selectedIndex,
    );
  }

  /// Normalizes the index to ensure it's within valid range.

  static int _normalizeIndex(int index) {
    if (index < 0) return 0;
    if (index >= maxTabs) return maxTabs - 1;
    return index;
  }
}

/// Provider for the tab state.

final tabStateProvider =
    StateNotifierProvider<TabStateNotifier, TabState>((ref) {
  return TabStateNotifier();
});

/// Notifier class for managing tab state changes.

class TabStateNotifier extends StateNotifier<TabState> {
  /// Creates a new [TabStateNotifier] with initial state.

  TabStateNotifier() : super(const TabState());

  /// Updates the selected index for all features.

  void setSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: TabState._normalizeIndex(index));
  }
}
