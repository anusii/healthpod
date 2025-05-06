/// Table tab including blood pressure, medications, and vaccination tables.
///
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
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
/// Authors: Kevin Wang
library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/features/table/bp_editor/page.dart';
import 'package:healthpod/features/table/medication_editor/page.dart';
import 'package:healthpod/features/table/vaccination_editor/page.dart';
import 'package:healthpod/features/diary/editor_page.dart';
import 'package:healthpod/providers/tab_state.dart';

final List<Map<String, dynamic>> tablePanels = [
  {
    'title': 'Appointments',
    'widget': const AppointmentEditorPage(),
  },
  {
    'title': 'Blood Pressure',
    'widget': const BPEditorPage(),
  },
  {
    'title': 'Medications',
    'widget': const MedicationEditorPage(),
  },
  {
    'title': 'Vaccinations',
    'widget': const VaccinationEditorPage(),
  },
];

class TableTab extends ConsumerStatefulWidget {
  const TableTab({super.key});

  @override
  ConsumerState<TableTab> createState() => _TableTabState();
}

class _TableTabState extends ConsumerState<TableTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tablePanels.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabState = ref.watch(tabStateProvider);
    if (_tabController.index != tabState.selectedIndex) {
      _tabController.animateTo(tabState.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          onTap: (index) {
            if (index != ref.read(tabStateProvider).selectedIndex) {
              ref.read(tabStateProvider.notifier).setSelectedIndex(index);
            }
          },
          tabs: tablePanels.map((tab) {
            return Tab(
              text: tab['title'],
            );
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tablePanels.map((tab) {
              return tab['widget'] as Widget;
            }).toList(),
          ),
        ),
      ],
    );
  }
}
