/// Diary data importer.
///
// Time-stamp: <Wednesday 2025-03-26 09:39:04 +1100 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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

import 'package:healthpod/utils/health_data_importer_base.dart';

/// Handles importing diary data from CSV files into JSON format.
///
/// This class extends HealthDataImporterBase to provide specific implementation
/// for diary data import functionality.

class DiaryImporter extends HealthDataImporterBase {
  @override
  String get dataType => 'diary';

  @override
  String get timestampField => 'date';

  @override
  List<String> get requiredColumns => [
        'date',
        'title',
        'description',
      ];

  @override
  List<String> get optionalColumns => [];

  @override
  Map<String, dynamic> createDefaultResponseMap() {
    return {
      'title': '',
      'description': '',
      'isPast': false,
    };
  }

  @override
  bool processField(
    String header,
    String value,
    Map<String, dynamic> responses,
    int rowIndex,
  ) {
    switch (header.toLowerCase()) {
      case 'date':
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required date');
          return false;
        }
        try {
          final date = DateTime.parse(value);
          responses['date'] = date.toIso8601String();
          responses['isPast'] = date.isBefore(DateTime.now());
        } catch (e) {
          debugPrint('Row $rowIndex: Invalid date format: $value');
          return false;
        }
        return true;

      case 'title':
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required title');
          return false;
        }
        responses['title'] = value;
        return true;

      case 'description':
        if (value.isEmpty) {
          debugPrint('Row $rowIndex: Missing required description');
          return false;
        }
        responses['description'] = value;
        return true;

      default:
        return true;
    }
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> importCsv(
    String filePath,
    String dirPath,
    BuildContext context,
  ) async {
    return DiaryImporter().importFromCsv(filePath, dirPath, context);
  }
}
