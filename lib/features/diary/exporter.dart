/// Diary data exporter.
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

import 'package:healthpod/utils/health_data_exporter_base.dart';

/// Handles exporting diary data from JSON format to CSV files.
///
/// This class extends HealthDataExporterBase to provide specific implementation
/// for diary data export functionality.

class DiaryExporter extends HealthDataExporterBase {
  @override
  String get dataType => 'diary';

  @override
  String get timestampField => 'date';

  @override
  List<String> get csvHeaders => [
        'date',
        'title',
        'description',
      ];

  @override
  Map<String, dynamic> processRecord(Map<String, dynamic> jsonData) {
    // Get the appointment data, either from responses or directly.

    final appointmentData = jsonData['responses'] ?? jsonData;

    // Safely extract values with null checks.
    // Get date from root level like service.dart.

    final dateStr = jsonData['date']?.toString();
    final title = appointmentData['title']?.toString() ?? '';
    final description = appointmentData['description']?.toString() ?? '';

    // Parse date.

    DateTime? date;

    if (dateStr != null) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return {
      'date': date?.toIso8601String() ?? '',
      'title': title,
      'description': description,
    };
  }

  /// Static method to maintain backward compatibility with existing code.

  static Future<bool> exportCsv(
    String filePath,
    String dirPath,
    BuildContext context,
  ) async {
    return DiaryExporter().exportToCsv(filePath, dirPath, context);
  }
}
