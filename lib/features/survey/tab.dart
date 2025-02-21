/// Survey tab including blood pressure and vaccination surveys.
///
// Time-stamp: <Friday 2025-02-21 16:56:22 +1100 Graham Williams>
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
import 'package:healthpod/features/bp/survey.dart';
import 'package:healthpod/features/vaccination/survey.dart';
import 'package:healthpod/features/survey/overview_panel.dart';

final List<Map<String, dynamic>> surveyPanels = [
  // {
  //   'title': 'Overview',
  //   'widget': const SurveyOverviewPanel(),
  // },
  {
    'title': 'Blood Pressure',
    'widget': BPSurvey(),
  },
  {
    'title': 'Vaccinations',
    'widget': const VaccinationSurvey(),
  },
];

class SurveyTab extends StatefulWidget {
  const SurveyTab({super.key});

  @override
  State<SurveyTab> createState() => _SurveyTabState();
}

class _SurveyTabState extends State<SurveyTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: surveyPanels.length, vsync: this);
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
        // Tab Bar. Like what we have in the RattleNG app.

        TabBar(
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          tabs: surveyPanels.map((tab) {
            return Tab(
              text: tab['title'],
            );
          }).toList(),
        ),

        // Tab Bar View with the survey panels.

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: surveyPanels.map((tab) {
              return tab['widget'] as Widget;
            }).toList(),
          ),
        ),
      ],
    );
  }
}
