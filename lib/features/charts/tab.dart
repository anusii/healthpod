/// Chart tab including various data visualizations.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:healthpod/features/charts/bp_combined_visualisation.dart';
import 'package:healthpod/features/charts/vaccination_visualisation.dart';

final List<Map<String, dynamic>> chartPanels = [
  {
    'title': 'Blood Pressure',
    'widget': BPCombinedVisualisation(),
  },
  {
    'title': 'Vaccinations',
    'widget': VaccinationVisualisation(),
  },
];

class ChartTab extends StatefulWidget {
  const ChartTab({super.key});

  @override
  State<ChartTab> createState() => _ChartTabState();
}

class _ChartTabState extends State<ChartTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: chartPanels.length, vsync: this);
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
