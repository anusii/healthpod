/// Vaccination data table.
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

class VaccinationTable extends StatelessWidget {
  const VaccinationTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                    width: 200,
                    child: Text('Date',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                    width: 200,
                    child: Text('Vaccine',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Notes',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Table content will be added here when connected to data source
          Expanded(
            child: ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 200, child: Text('No data available')),
                      SizedBox(width: 200, child: Text('-')),
                      Expanded(child: Text('-')),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
