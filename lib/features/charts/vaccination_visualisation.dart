import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

class VaccinationRecord {
  final DateTime date;
  final String name;

  VaccinationRecord({required this.date, required this.name});
}

class VaccinationVisualisation extends StatelessWidget {
  // Sample data with various dates throughout the year
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
  ];

  VaccinationVisualisation({super.key});

  @override
  Widget build(BuildContext context) {
    // Sort records by date, most recent first
    final sortedRecords = [...records]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: sortedRecords.length,
        itemBuilder: (context, index) {
          final record = sortedRecords[index];

          // Calculate the line length based on time difference with next record
          double lineHeight = 50.0; // Default minimum height
          if (index < sortedRecords.length - 1) {
            final nextRecord = sortedRecords[index + 1];
            final daysDifference =
                record.date.difference(nextRecord.date).inDays;
            // Scale: 1 month ≈ 30 pixels
            lineHeight = (daysDifference / 30) * 30;
            // Ensure minimum height for readability
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
    );
  }
}
