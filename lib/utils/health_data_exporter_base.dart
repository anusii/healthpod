/// Base class for health data exporters.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
/// Authors: Kevin Wang.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

/// Abstract base class for health data exporters.
///
/// This class provides common functionality for exporting health data to CSV files,
/// including file reading, data extraction, and CSV generation.
/// Specific health data exporters should extend this class and implement the abstract methods.

abstract class HealthDataExporterBase {
  /// The data type identifier (e.g., 'blood_pressure', 'vaccination').

  String get dataType;

  /// The field name for timestamp in the data model.

  String get timestampField;

  /// Get the list of column headers for the CSV file.

  List<String> get csvHeaders;

  /// Process a JSON record into a map of field values.
  ///
  /// This method should extract the relevant fields from the JSON data
  /// and return a map with keys matching the CSV headers.
  ///
  /// Parameters:
  /// - [jsonData]: The parsed JSON data from the file
  ///
  /// Returns a map with keys matching the CSV headers.

  Map<String, dynamic> processRecord(Map<String, dynamic> jsonData);

  /// Export health data to a CSV file.
  ///
  /// This method builds the CSV content with [buildCsv] and writes it to
  /// [savePath].
  ///
  /// Parameters:
  /// - [savePath]: Path where the CSV file will be saved
  /// - [dirPath]: Directory path where the health data files are stored
  ///
  /// Returns a boolean indicating whether the export was successful.

  Future<bool> exportToCsv(
    String savePath,
    String dirPath,
  ) async {
    final csv = await buildCsv(dirPath);
    if (csv == null) return false;

    await File(savePath).writeAsString(csv);

    return true;
  }

  /// Build the CSV content for the health data stored under [dirPath].
  ///
  /// This method reads all health data files from the directory, processes
  /// them, and renders them as a single CSV document. It does no file I/O of
  /// its own so that callers can hand the content straight to a save dialog.
  ///
  /// Returns the CSV text, or null if the data could not be read. Failures
  /// are logged rather than thrown.

  Future<String?> buildCsv(String dirPath) async {
    try {
      // Get the directory URL for the health data folder.

      final dirUrl = await getDirUrl(dirPath);

      // Get all resources in the container.

      final resources = await getResourcesInContainer(dirUrl);

      // Filter for only encrypted files with .enc.ttl extension.

      final files =
          resources.files.where((file) => file.endsWith('.enc.ttl')).toList();

      // Throw error if no files are found.

      if (files.isEmpty) {
        throw Exception('No $dataType data files found in directory');
      }

      // Initialise list to store all health records.

      List<Map<String, dynamic>> allRecords = [];

      // Process each file one by one.

      for (var fileName in files) {
        try {
          // Read and decrypt the file contents.

          final content = await readPod(
            '$dirPath/$fileName',
            pathType: PathType.relativeToPod,
          );

          // Skip file if read operation failed.

          if (content == SolidFunctionCallStatus.fail.toString() ||
              content == SolidFunctionCallStatus.notLoggedIn.toString()) {
            continue;
          }

          // Parse the JSON content from the file.

          final jsonData = json.decode(content.toString());

          // Process the record using the implementation-specific method.

          final record = processRecord(jsonData);

          // Add the processed record to the collection.

          allRecords.add(record);
        } catch (e) {
          // Log error and continue with next file if current file fails.

          debugPrint('Error processing file $fileName: $e');
          continue;
        }
      }

      // Verify we have at least one valid record.

      if (allRecords.isEmpty) {
        throw Exception('No valid $dataType records found');
      }

      // Sort all records by timestamp in ascending order.

      allRecords.sort((a, b) => a[timestampField].compareTo(b[timestampField]));

      // Create CSV rows starting with headers.

      List<List<dynamic>> rows = [csvHeaders];

      // Add data rows by mapping each record to the headers.

      for (var record in allRecords) {
        rows.add(csvHeaders.map((header) => record[header]).toList());
      }

      // Convert rows to CSV format.

      return const ListToCsvConverter().convert(rows);
    } catch (e) {
      // Log any errors during export process.

      debugPrint('Export error: $e');
      return null;
    }
  }
}
