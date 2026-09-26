/// Switch to a tab of the Add page from elsewhere in the app.
//
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Tony Chen

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/features/update/tab.dart';
import 'package:healthpod/providers/tab_state.dart';

/// Position of the **Add** page in the sidebar menu.

const int addMenuIndex = 2;

/// Opens the **Add** page at the feature tab titled [tabTitle], such as
/// "Appointments".
///
/// The feature tabs share one selected index across the View, Add and Data
/// pages, so the tab is selected first and the sidebar page switched after.
/// The home screen listens to [menuIndexProvider] and follows the change.

void openAddTab(WidgetRef ref, String tabTitle) {
  final tabIndex = surveyPanels.indexWhere((p) => p['title'] == tabTitle);
  assert(tabIndex >= 0, 'No Add tab titled "$tabTitle".');

  if (tabIndex >= 0) {
    ref.read(tabStateProvider.notifier).setSelectedIndex(tabIndex);
  }
  ref.read(menuIndexProvider.notifier).setIndex(addMenuIndex);
}
