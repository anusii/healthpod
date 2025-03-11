/// Vaccination timeline chart.
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

import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'package:healthpod/features/charts/vaccination_data.dart';
import 'package:healthpod/features/charts/models/vaccination_record.dart';
import 'package:healthpod/features/charts/utils/vaccination_dialog_utils.dart';

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
        date: DateTime(2024, 2, 15),
        name: 'Flu Shot',
        provider: 'Community Clinic',
        professional: 'Nurse Johnson',
        cost: '\$25.00',
        notes: 'Seasonal vaccination',
      ),
      VaccinationRecord(
        date: DateTime(2023, 12, 1),
        name: 'Hepatitis B',
        provider: 'University Hospital',
        professional: 'Dr. Garcia',
        cost: '\$75.00',
        notes: 'Final dose in series',
      ),
      // More sample records
      VaccinationRecord(
        date: DateTime(2023, 9, 15),
        name: 'Tetanus Booster',
      ),
      VaccinationRecord(
        date: DateTime(2023, 6, 1),
        name: 'MMR Vaccine',
      ),
      VaccinationRecord(
        date: DateTime(2023, 3, 15),
        name: 'COVID-19 Second Dose',
      ),
      VaccinationRecord(
        date: DateTime(2021, 3, 15),
        name: 'COVID-19 First Dose',
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
                  const Text(
                    'Vaccination History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh data',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              sortedRecords.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No vaccination records found',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      /// Make the ListView non-scrollable since the parent SingleChildScrollView will handle scrolling.

                      physics: const NeverScrollableScrollPhysics(),

                      /// Shrink the ListView to fit its content.

                      shrinkWrap: true,
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];

                        /// Calculate the line length based on time difference with next record.
                        /// Default minimum height.

                        double lineHeight = 50.0;
                        if (index < sortedRecords.length - 1) {
                          final nextRecord = sortedRecords[index + 1];
                          final daysDifference =
                              record.date.difference(nextRecord.date).inDays;

                          /// Scale: 1 month ≈ 30 pixels.

                          lineHeight = (daysDifference / 30) * 30;

                          /// Ensure minimum height for readability.

                          lineHeight = lineHeight.clamp(50.0, 300.0);
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
                              /// Show details in a dialog when tapped.

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
                                      DateFormat('MMM dd, yyyy')
                                          .format(record.date),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      record.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  if (record.provider != null ||
                                      record.professional != null ||
                                      record.notes != null)
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey,
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
