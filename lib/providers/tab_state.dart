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
  /// The selected tab index for charts feature.
  final int chartsTabIndex;

  /// The selected tab index for tables feature.
  final int tablesTabIndex;

  /// The selected tab index for survey feature.
  final int surveyTabIndex;

  /// Creates a new [TabState] with the given tab indices.
  const TabState({
    this.chartsTabIndex = 0,
    this.tablesTabIndex = 0,
    this.surveyTabIndex = 0,
  });

  /// Creates a copy of this [TabState] with the given fields replaced with new values.
  TabState copyWith({
    int? chartsTabIndex,
    int? tablesTabIndex,
    int? surveyTabIndex,
  }) {
    return TabState(
      chartsTabIndex: chartsTabIndex ?? this.chartsTabIndex,
      tablesTabIndex: tablesTabIndex ?? this.tablesTabIndex,
      surveyTabIndex: surveyTabIndex ?? this.surveyTabIndex,
    );
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

  /// Updates the charts tab index.
  void setChartsTabIndex(int index) {
    state = state.copyWith(chartsTabIndex: index);
  }

  /// Updates the tables tab index.
  void setTablesTabIndex(int index) {
    state = state.copyWith(tablesTabIndex: index);
  }

  /// Updates the survey tab index.
  void setSurveyTabIndex(int index) {
    state = state.copyWith(surveyTabIndex: index);
  }
}
