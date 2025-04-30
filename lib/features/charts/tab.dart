/// Chart tab including blood pressure and vaccination charts.
///
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
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
/// Authors: Kevin Wang
library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/features/charts/bp_combined_visualisation.dart';
import 'package:healthpod/features/charts/medication_visualisation.dart';
import 'package:healthpod/features/charts/vaccination_visualisation.dart';
import 'package:healthpod/providers/tab_state.dart';

final List<Map<String, dynamic>> chartPanels = [
  {
    'title': 'Blood Pressure',
    'widget': BPCombinedVisualisation(),
  },
  {
    'title': 'Medications',
    'widget': MedicationVisualisation(),
  },
  {
    'title': 'Vaccinations',
    'widget': VaccinationVisualisation(),
  },
];

class ChartTab extends ConsumerStatefulWidget {
  const ChartTab({super.key});

  @override
  ConsumerState<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends ConsumerState<ChartTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: chartPanels.length, vsync: this);
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
          tabs: chartPanels.map((tab) {
            return Tab(
              text: tab['title'],
            );
          }).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: chartPanels.map((tab) {
              return tab['widget'] as Widget;
            }).toList(),
          ),
        ),
      ],
    );
  }
}
