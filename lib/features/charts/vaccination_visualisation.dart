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
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

class VaccinationRecord {
  final DateTime date;
  final String name;

  VaccinationRecord({required this.date, required this.name});
}

class VaccinationVisualisation extends StatelessWidget {
  // Sample data with various dates throughout the year.

  final List<VaccinationRecord> records = [
    VaccinationRecord(
      date: DateTime(2024, 3, 1),
      name: 'COVID-19 Booster',
    ),
    VaccinationRecord(
      date: DateTime(2024, 2, 15),
      name: 'Flu Shot',
    ),
    VaccinationRecord(
      date: DateTime(2023, 12, 1),
      name: 'Hepatitis B',
    ),
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
    // 10 additional vaccination records
    VaccinationRecord(
      date: DateTime(2021, 1, 10),
      name: 'Pneumococcal Vaccine',
    ),
    VaccinationRecord(
      date: DateTime(2020, 11, 5),
      name: 'Shingles Vaccine',
    ),
    VaccinationRecord(
      date: DateTime(2020, 8, 20),
      name: 'HPV Vaccine (Dose 3)',
    ),
    VaccinationRecord(
      date: DateTime(2020, 2, 15),
      name: 'HPV Vaccine (Dose 2)',
    ),
    VaccinationRecord(
      date: DateTime(2019, 8, 10),
      name: 'HPV Vaccine (Dose 1)',
    ),
    VaccinationRecord(
      date: DateTime(2019, 5, 22),
      name: 'Meningococcal Vaccine',
    ),
    VaccinationRecord(
      date: DateTime(2018, 10, 15),
      name: 'Seasonal Flu Shot',
    ),
    VaccinationRecord(
      date: DateTime(2018, 3, 7),
      name: 'Hepatitis A',
    ),
    VaccinationRecord(
      date: DateTime(2017, 9, 12),
      name: 'Yellow Fever Vaccine',
    ),
    VaccinationRecord(
      date: DateTime(2017, 4, 5),
      name: 'Typhoid Vaccine',
    ),
  ];

  VaccinationVisualisation({super.key});

  @override
  Widget build(BuildContext context) {
    // Sort records by date, most recent first.
    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    // Wrap the entire widget in a SingleChildScrollView for vertical scrolling
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vaccination History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              // Make the ListView non-scrollable since the parent SingleChildScrollView will handle scrolling
              physics: const NeverScrollableScrollPhysics(),
              // Shrink the ListView to fit its content
              shrinkWrap: true,
              itemCount: sortedRecords.length,
              itemBuilder: (context, index) {
                final record = sortedRecords[index];

                // Calculate the line length based on time difference with next record.
                // Default minimum height.
                double lineHeight = 50.0;
                if (index < sortedRecords.length - 1) {
                  final nextRecord = sortedRecords[index + 1];
                  final daysDifference =
                      record.date.difference(nextRecord.date).inDays;
                  // Scale: 1 month ≈ 30 pixels.
                  lineHeight = (daysDifference / 30) * 30;
                  // Ensure minimum height for readability.
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
                  endChild: Container(
                    height: lineHeight,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(record.date),
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
