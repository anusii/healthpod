import 'package:flutter/material.dart';
import 'package:healthpod/features/bp/survey.dart';
import 'package:healthpod/features/vaccination/survey.dart';

final List<Map<String, dynamic>> surveyPanels = [
  {
    'title': 'Overview',
    'widget': const SurveyOverviewPanel(),
  },
  {
    'title': 'Blood Pressure',
    'widget': BPSurvey(),
  },
  {
    'title': 'Vaccinations',
    'widget': const VaccinationSurvey(),
  },
];

class SurveyChooser extends StatefulWidget {
  const SurveyChooser({super.key});

  @override
  State<SurveyChooser> createState() => _SurveyChooserState();
}

class _SurveyChooserState extends State<SurveyChooser>
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
        TabBar(
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          tabs: surveyPanels.map((tab) {
            return Tab(
              text: tab['title'],
            );
          }).toList(),
        ),
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

/// A placeholder panel for the Overview tab
class SurveyOverviewPanel extends StatelessWidget {
  const SurveyOverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Survey Overview',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
