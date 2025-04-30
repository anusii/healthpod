/// Diary data exporter.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html

library;

import 'dart:convert';
import 'dart:io';

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
    // Get the appointment data, either from responses or directly
    final appointmentData = jsonData['responses'] ?? jsonData;

    // Safely extract values with null checks
    final dateStr = jsonData['date']
        ?.toString(); // Get date from root level like service.dart
    final title = appointmentData['title']?.toString() ?? '';
    final description = appointmentData['description']?.toString() ?? '';

    // Parse date
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
