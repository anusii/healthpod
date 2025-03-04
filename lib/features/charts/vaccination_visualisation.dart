import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';
import 'package:intl/intl.dart';

class VaccinationRecord {
  final DateTime date;
  final String name;

  VaccinationRecord({required this.date, required this.name});
}

class VaccinationVisualisation extends StatelessWidget {
  // Sample data - replace with actual data source
  final List<VaccinationRecord> records = [
    VaccinationRecord(
      date: DateTime.now().subtract(const Duration(days: 5)),
      name: 'COVID-19 Booster',
    ),
    VaccinationRecord(
      date: DateTime.now().subtract(const Duration(days: 180)),
      name: 'Flu Shot',
    ),
    VaccinationRecord(
      date: DateTime.now().subtract(const Duration(days: 365)),
      name: 'COVID-19 Second Dose',
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
      child: Timeline.tileBuilder(
        theme: TimelineThemeData(
          nodePosition: 0,
          color: Theme.of(context).primaryColor,
          connectorTheme: const ConnectorThemeData(
            thickness: 2.0,
          ),
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: sortedRecords.length,
          contentsBuilder: (_, index) {
            final record = sortedRecords[index];
            return Padding(
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
            );
          },
          indicatorBuilder: (_, index) => Indicator.dot(
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          connectorBuilder: (_, index, ___) => SolidLineConnector(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
