/// BP combined visualisation widget.
//
// Time-stamp: <Thursday 2025-06-26 17:00:52 +1000 Graham Williams>
//
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:healthpod/features/charts/widgets/bp_chart_app_bar.dart';
import 'package:healthpod/features/charts/widgets/bp_legend_stats.dart';
import 'package:healthpod/features/charts/widgets/bp_line_chart.dart';
import 'package:healthpod/features/survey/data.dart';

/// Combined blood pressure visualisation widget.
///
/// A widget for visualising both systolic and diastolic blood pressure
/// measurements on a single chart. This widget processes survey data to create an
/// interactive line chart showing blood pressure trends over time, with:
/// * Dual line visualisation for systolic and diastolic readings
/// * Interactive tooltips showing exact values
/// * Summary statistics including averages, minimums, and maximums
/// * Date-based X-axis and pressure-based Y-axis (mmHg)
/// * Color-coded lines and legend for easy differentiation
///
/// The widget expects survey data in a specific format with 'timestamp' and 'responses'
/// fields, where responses contain the blood pressure measurements.

class BPCombinedVisualisation extends StatefulWidget {
  const BPCombinedVisualisation({super.key});

  @override
  State<BPCombinedVisualisation> createState() =>
      _BPCombinedVisualisationState();
}

class _BPCombinedVisualisationState extends State<BPCombinedVisualisation> {
  List<Map<String, dynamic>> _surveyData = [];
  bool _isLoading = true;
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  Future<void> _loadData() async {
    // Show loading indicator.

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await SurveyData.fetchAllSurveyData(context);
      if (mounted) {
        setState(() {
          _surveyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_surveyData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const BPChartAppBar(),

          // Main chart area showing blood pressure trends.
          Expanded(child: BPLineChart(surveyData: _surveyData)),
          const SizedBox(height: 16),

          // Legend and statistics card.
          BPLegendStats(surveyData: _surveyData),
        ],
      ),
    );
  }
}
