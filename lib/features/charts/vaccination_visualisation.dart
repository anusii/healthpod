/// Vaccination timeline chart.
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

import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'package:healthpod/features/charts/models/vaccination_record.dart';
import 'package:healthpod/features/charts/utils/vaccination_dialog_utils.dart';
import 'package:healthpod/features/charts/vaccination_data.dart';

/// Widget for displaying vaccination history in a timeline format.

class VaccinationVisualisation extends StatefulWidget {
  const VaccinationVisualisation({super.key});

  @override
  State<VaccinationVisualisation> createState() =>
      _VaccinationVisualisationState();
}

/// State for the VaccinationVisualisation widget.
class _VaccinationVisualisationState extends State<VaccinationVisualisation> {
  List<VaccinationRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads vaccination data from the server.

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch data from the server.

      final data = await VaccinationData.fetchAllVaccinationData(context);

      if (mounted) {
        // If no data is found, use sample data.

        if (data.isEmpty) {
          setState(() {
            _records = _getSampleData();
            _isLoading = false;
          });
        } else {
          // Convert JSON data to VaccinationRecord objects.

          setState(() {
            _records =
                data.map((item) => VaccinationRecord.fromJson(item)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading vaccination data: $e';
          _isLoading = false;
          // Fall back to sample data on error.

          _records = _getSampleData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  /// Provides sample data to use as fallback when server data is unavailable.

  List<VaccinationRecord> _getSampleData() {
    return [
      VaccinationRecord(
        date: DateTime(2024, 3, 1),
        name: 'COVID-19 Booster',
        provider: 'City Medical Center',
        professional: 'Dr. Smith',
        cost: '\$45.00',
        notes: 'Annual booster',
      ),
      VaccinationRecord(
        date: DateTime(2023, 12, 1),
        name: 'Flu Shot',
        provider: 'Community Clinic',
        professional: 'Nurse Johnson',
        cost: '\$25.00',
        notes: 'Seasonal vaccination',
      ),
      VaccinationRecord(
        date: DateTime(2023, 6, 15),
        name: 'Hepatitis B',
        provider: 'University Hospital',
        professional: 'Dr. Garcia',
        cost: '\$75.00',
        notes: 'Final dose in series',
      ),
      VaccinationRecord(
        date: DateTime(2023, 3, 1),
        name: 'Tetanus Booster',
        provider: 'City Medical Center',
        professional: 'Dr. Smith',
        cost: '\$35.00',
        notes: '10-year booster',
      ),
      VaccinationRecord(
        date: DateTime(2022, 12, 15),
        name: 'MMR Vaccine',
        provider: 'Community Clinic',
        professional: 'Nurse Johnson',
        cost: '\$30.00',
        notes: 'Adult booster',
      ),
      VaccinationRecord(
        date: DateTime(2022, 6, 1),
        name: 'COVID-19 Second Dose',
        provider: 'University Hospital',
        professional: 'Dr. Garcia',
        cost: '\$0.00',
        notes: 'Government funded',
      ),
      VaccinationRecord(
        date: DateTime(2021, 3, 15),
        name: 'COVID-19 First Dose',
        provider: 'City Medical Center',
        professional: 'Dr. Smith',
        cost: '\$0.00',
        notes: 'Government funded',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _records.isEmpty) {
      return Center(
        child: Text(_error!),
      );
    }

    /// Sort records by date, most recent first.

    final sortedRecords = [..._records]
      ..sort((a, b) => b.date.compareTo(a.date));

    /// Calculate the total date range for scaling.

    final DateTime latestDate = sortedRecords.first.date;
    final DateTime earliestDate = sortedRecords.last.date;
    final int totalDays = latestDate.difference(earliestDate).inDays;

    /// Wrap the entire widget in a SingleChildScrollView for vertical scrolling.

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MarkdownBody(
                    data: 'Vaccination History',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: MarkdownTooltip(
                      message: '''
                      
                      **Refresh:** Tap here to reload your vaccination history data.
                      
                      ''',
                      child: const Icon(Icons.refresh),
                    ),
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              sortedRecords.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: MarkdownBody(
                          data: 'No vaccination records found',
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];

                        // Calculate proportional line height based on date differences.
                        // Minimum height.

                        double lineHeight = 50.0;
                        if (index < sortedRecords.length - 1) {
                          final nextRecord = sortedRecords[index + 1];
                          final daysDifference =
                              record.date.difference(nextRecord.date).inDays;

                          // Scale the height proportionally to the total date range.
                          // Max total height.

                          lineHeight = (daysDifference / totalDays) * 600;

                          // Clamp between min and max.

                          lineHeight = lineHeight.clamp(50.0, 300.0);
                        }

                        // Get appropriate emoji based on vaccination type.
                        String emoji = '';
                        final nameLower = record.name.toLowerCase();
                        if (nameLower.contains('flu')) {
                          emoji = '💉';
                        } else if (nameLower.contains('covid')) {
                          emoji = '🦠';
                        } else if (nameLower.contains('hepatitis')) {
                          emoji = '🫁';
                        } else if (nameLower.contains('tetanus')) {
                          emoji = '🔒';
                        } else if (nameLower.contains('mmr')) {
                          emoji = '🦠';
                        } else {
                          emoji = '💊'; // Default emoji for other vaccinations
                        }

                        return TimelineTile(
                          isFirst: index == 0,
                          isLast: index == sortedRecords.length - 1,
                          indicatorStyle: IndicatorStyle(
                            width: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          beforeLineStyle: LineStyle(
                            color: Theme.of(context).primaryColor,
                            thickness: 2,
                          ),
                          afterLineStyle: LineStyle(
                            color: Theme.of(context).primaryColor,
                            thickness: 2,
                          ),
                          hasIndicator: true,
                          endChild: InkWell(
                            onTap: () {
                              showVaccinationDetails(context, record);
                            },
                            child: Container(
                              height: lineHeight,
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      // Australian date format.

                                      DateFormat('dd/MM/yyyy')
                                          .format(record.date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (emoji.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Text(emoji,
                                                style: const TextStyle(
                                                    fontSize: 16)),
                                          ),
                                        Text(
                                          record.name,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
