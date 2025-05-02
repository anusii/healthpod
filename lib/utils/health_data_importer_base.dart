/// Base class for health data importers.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/format_timestamp_for_display.dart';
import 'package:healthpod/utils/is_valid_timestamp.dart';
import 'package:healthpod/utils/normalise_timestamp.dart';
import 'package:healthpod/utils/round_timestamp_to_second.dart';
import 'package:healthpod/utils/show_alert.dart';

/// Abstract base class for health data importers.
///
/// This class provides common functionality for importing health data from CSV files,
/// including file reading, CSV parsing, timestamp validation, and file saving.
/// Specific health data importers should extend this class and implement the abstract methods.

/// Abstract base class for health data importers.
///
/// This class provides common functionality for importing health data from CSV files,
/// including file reading, CSV parsing, timestamp validation, and file saving.
/// Specific health data importers should extend this class and implement the abstract methods.

abstract class HealthDataImporterBase {
  /// The data type identifier (e.g., 'blood_pressure', 'vaccination').

  String get dataType;

  /// The field name for timestamp in the data model.

  String get timestampField;

  /// Get the list of required column names that must be present in the CSV.

  List<String> get requiredColumns;

  /// Get the list of optional column names that may be present in the CSV.

  List<String> get optionalColumns;

  /// Create a response map with default values for a new record.
  ///
  /// This method should initialize a map with all the fields needed for the specific data type.

  Map<String, dynamic> createDefaultResponseMap();

  /// Process a specific field from the CSV row.
  ///
  /// This method handles the specific logic for each field type in the data model.
  /// Returns true if the field was processed successfully, false otherwise.
  ///
  /// Parameters:
  /// - [header]: The column header name
  /// - [value]: The value from the CSV
  /// - [responses]: The map to update with the processed value
  /// - [rowIndex]: The current row index for error reporting

  bool processField(
    String header,
    String value,
    Map<String, dynamic> responses,
    int rowIndex,
  );

  /// Shows a confirmation dialog for overriding duplicate files.
  ///
  /// This method displays a dialog with a list of duplicate files that would be overridden
  /// and asks the user to confirm the override.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  /// - [duplicateFiles]: List of file names that would be overridden
  ///
  /// Returns a boolean indicating whether the user confirmed the override.

  Future<bool> _showOverrideConfirmationDialog(
    BuildContext context,
    List<String> duplicateFiles,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Duplicate Data Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'These observations need to be overridden. Are you sure you want to override?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The following existing files have the same dates as records in your import file:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: duplicateFiles
                          .map((filename) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        filename,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Proceeding will replace these files with your imported data.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Override',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ) ??
        false;
  }

  /// Check for existing files that would be overridden by this import.
  ///
  /// This method checks if there are existing files with the same timestamps
  /// in the specified directory.
  ///
  /// Parameters:
  /// - [dirPath]: The directory path to check in
  /// - [timestamps]: List of timestamps to check for
  ///
  /// Returns a list of file names that would be overridden.

  Future<List<String>> _checkForExistingFiles(
    String dirPath,
    List<String> timestamps,
  ) async {
    try {
      // Handle path construction based on the directory structure.

      String path;
      if (dirPath.endsWith('/$dataType')) {
        path = dataType;
      } else if (dirPath.startsWith('healthpod/data')) {
        path = dirPath.replaceFirst('healthpod/data/', '');
        path = path.isEmpty ? '' : path;
      } else {
        path = dirPath;
      }

      // Get the base path for querying resources.

      final basePath = path.isEmpty ? '' : path;
      debugPrint('Checking for duplicates in path: $basePath');

      // Try to get files in the directory directly.

      try {
        final dirUrl = await getDirUrl(basePath);
        final resources = await getResourcesInContainer(dirUrl);

        // Extract date parts from existing files for comparison.

        final existingFiles = resources.files
            .where((file) =>
                file.startsWith('${dataType}_') &&
                file.endsWith('.json.enc.ttl'))
            .toList();

        debugPrint(
            'Found ${existingFiles.length} $dataType files in directory');

        // Create date-based lookup index for faster comparison.

        final Map<String, List<String>> existingFileDateIndex = {};

        for (final file in existingFiles) {
          // Extract date part from filename (everything between dataType_ and T).

          final dateMatch =
              RegExp('${dataType}_(\\d{4}-\\d{2}-\\d{2})T').firstMatch(file);
          if (dateMatch != null && dateMatch.groupCount >= 1) {
            final dateStr = dateMatch.group(1)!;
            if (!existingFileDateIndex.containsKey(dateStr)) {
              existingFileDateIndex[dateStr] = [];
            }
            existingFileDateIndex[dateStr]!.add(file);
          }
        }

        debugPrint(
            'Created date index with ${existingFileDateIndex.keys.length} unique dates');

        // Create a list to store the duplicate file names.

        final duplicateFiles = <String>[];

        // Extract just the date part from each timestamp (YYYY-MM-DD).

        for (final timestamp in timestamps) {
          // Extract the date part before any 'T' character.

          final datePart = timestamp.split('T')[0];

          // Check if we have any files with this date.

          if (existingFileDateIndex.containsKey(datePart)) {
            // Add all files with this date to duplicates.

            duplicateFiles.addAll(existingFileDateIndex[datePart]!);
            debugPrint(
                'Found ${existingFileDateIndex[datePart]!.length} duplicate files for date $datePart');
          }
        }

        // Return unique list of duplicate files.

        return duplicateFiles.toSet().toList();
      } catch (resourceError) {
        debugPrint('Error accessing resources: $resourceError');

        // Fall back to direct file checking.

        return _checkForExistingFilesDirectly(path, timestamps);
      }
    } catch (e) {
      debugPrint('Error checking for existing files: $e');
      return [];
    }
  }

  /// Fall back method to check for existing files directly.
  ///
  /// This method is used when we can't get the directory listing.

  Future<List<String>> _checkForExistingFilesDirectly(
    String path,
    List<String> timestamps,
  ) async {
    debugPrint('Falling back to direct file checking');
    final duplicateFiles = <String>[];

    // Extract just the date part from each timestamp (YYYY-MM-DD).

    final dateParts = timestamps.map((timestamp) {
      // Extract the date part before any 'T' character or just use the full string if no 'T'.

      final datePart = timestamp.split('T')[0];
      return datePart;
    }).toSet();

    // Instead of using hardcoded known files, try to check potential file paths
    // using pattern matching against the timestamps.

    for (final datePart in dateParts) {
      // Try various path formats that might exist.

      final possiblePaths = [
        path.isEmpty ? '' : path,
        dataType,
        'healthpod/data/$dataType',
      ];

      for (final basePath in possiblePaths) {
        try {
          // Generate the potential filename pattern.

          final filePattern = '${dataType}_${datePart}T';
          debugPrint(
              'Looking for files with pattern: $filePattern in $basePath');

          // Try to get directory listing if possible.

          try {
            final dirUrl = await getDirUrl(basePath);
            final resources = await getResourcesInContainer(dirUrl);

            // Check for any matching files.

            final matches = resources.files
                .where((file) =>
                    file.startsWith(filePattern) &&
                    file.endsWith('.json.enc.ttl'))
                .toList();

            if (matches.isNotEmpty) {
              duplicateFiles.addAll(matches);
              debugPrint('Found ${matches.length} matching files in $basePath');
            }
          } catch (e) {
            debugPrint('Could not check directory $basePath: $e');
          }
        } catch (e) {
          debugPrint('Error checking path $path for date $datePart: $e');
        }
      }
    }

    // If no files were found using directory checks, construct potential filenames
    // based on the pattern we've observed in the codebase.

    if (duplicateFiles.isEmpty) {
      debugPrint(
          'No files found through directory listing, using standard patterns');

      for (final datePart in dateParts) {
        // Create a standard filename for each date (using 00-00-00 for the time portion).

        final standardFilename =
            '${dataType}_${datePart}T00-00-00.json.enc.ttl';
        duplicateFiles.add(standardFilename);
        debugPrint('Added standard pattern file: $standardFilename');
      }
    }

    return duplicateFiles;
  }

  /// Helper method to check if a file exists in the POD.
  ///
  /// This is a check that attempts to determine if a file exists
  /// by checking the file listing from the directory or using a direct method.
  ///
  /// Returns true if the file exists, false otherwise.

  Future<bool> fileExistsInPod(String filePath) async {
    try {
      // Extract file name from path.

      final parts = filePath.split('/');
      final fileName = parts.last;

      // Try to access the directory containing the file.

      final dirPath =
          parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';

      try {
        // Try to get directory listing.

        final dirUrl = await getDirUrl(dirPath);
        final resources = await getResourcesInContainer(dirUrl);

        // Check if file exists in directory.

        final exists = resources.files.contains(fileName);

        if (exists) {
          debugPrint('Found existing file: $fileName');
          return true;
        } else {
          // Try alternative path formats.

          final alternativePaths = [
            dataType,
            '$dataType/$fileName',
            'healthpod/data/$dataType',
            'healthpod/data/$dataType/$fileName',
          ];

          for (final altPath in alternativePaths) {
            try {
              final altDirUrl = await getDirUrl(altPath);
              final altResources = await getResourcesInContainer(altDirUrl);

              if (altResources.files.contains(fileName)) {
                debugPrint(
                    'Found existing file in alternative path: $altPath/$fileName');
                return true;
              }
            } catch (e) {
              debugPrint('Error checking alternative path $altPath: $e');
            }
          }

          debugPrint('File "$fileName" does not exist in any checked paths');
          return false;
        }
      } catch (e) {
        debugPrint('Error accessing directory: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if file exists: $e');
      return false;
    }
  }

  /// Import health data from a CSV file.
  ///
  /// This method reads a CSV file, validates its structure, processes each row,
  /// and saves the data as individual encrypted JSON files in the specified directory.
  ///
  /// Parameters:
  /// - [filePath]: Path to the CSV file to import
  /// - [dirPath]: Directory path where the JSON files will be saved
  /// - [context]: Flutter build context for UI interactions
  ///
  /// Returns a boolean indicating whether the import was successful.

  Future<bool> importFromCsv(
    String filePath,
    String dirPath,
    BuildContext context,
  ) async {
    try {
      // Start processing the CSV file by reading its contents.

      final file = File(filePath);
      final String content = await file.readAsString();

      // Convert CSV content to a list of fields using specific parsing settings.

      final fields = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: ',',
        allowInvalid: true,
        textDelimiter: '"',
        textEndDelimiter: '"',
      ).convert(content);

      // Check if the CSV file contains any data.

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract and normalize the header row from the CSV.

      final headers = List<String>.from(
          fields[0].map((h) => h.toString().trim().toLowerCase()));

      // Check for any missing required columns and show an alert if any are missing.

      final lowerRequiredColumns =
          requiredColumns.map((col) => col.toLowerCase()).toList();
      final missingColumns =
          lowerRequiredColumns.where((col) => !headers.contains(col)).toList();

      if (missingColumns.isNotEmpty) {
        if (!context.mounted) return false;

        // Build the alert message with required and optional columns.

        final requiredColumnsStr =
            requiredColumns.map((col) => '- $col').join('\n');
        final optionalColumnsStr =
            optionalColumns.map((col) => '- $col').join('\n');

        showAlert(context, '''
        Required columns missing: ${missingColumns.join(", ")}

        The following columns are required:
        $requiredColumnsStr

        These columns are optional:
        $optionalColumnsStr
        ''');
        return false;
      }

      // Initialise tracking variables for duplicate detection and success monitoring.

      final Set<String> seenTimestamps = {};
      final List<String> duplicateTimestamps = [];
      final List<String> allTimestamps = [];
      bool allSuccess = true;
      int successfulSaves = 0;

      // First pass: collect all timestamps from the CSV file.

      for (var i = 1; i < fields.length; i++) {
        final row =
            List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
        if (row.isEmpty) continue;

        while (row.length < headers.length) {
          row.add('');
        }

        for (var j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = row[j].toString().trim();

          if (header == timestampField.toLowerCase() && value.isNotEmpty) {
            try {
              final timestamp =
                  normaliseTimestamp(roundTimestampToSecond(value));
              if (isValidTimestamp(timestamp)) {
                allTimestamps.add(timestamp);
              }
            } catch (e) {
              // Skip invalid timestamps.

              debugPrint('Invalid timestamp: $e');
            }
            break;
          }
        }
      }

      // Check for existing files that would be overridden.

      List<String> duplicateFiles = [];

      if (allTimestamps.isNotEmpty) {
        try {
          duplicateFiles = await _checkForExistingFiles(dirPath, allTimestamps);

          // If duplicate files exist, show confirmation dialog.

          if (duplicateFiles.isNotEmpty && context.mounted) {
            debugPrint(
                'Found ${duplicateFiles.length} duplicate files! Showing override dialog.');
            final shouldOverride = await _showOverrideConfirmationDialog(
              context,
              duplicateFiles,
            );

            // If user cancels the override, abort the import.

            if (!shouldOverride) {
              debugPrint('User cancelled override, aborting import.');
              return false;
            }
            debugPrint(
                'User confirmed override, deleting existing files before import.');

            if (!context.mounted) return false;

            // Delete the existing files before proceeding with import.

            await _deleteExistingFiles(context, dirPath, duplicateFiles);
          } else {
            debugPrint('No duplicate files found, proceeding with import.');
          }
        } catch (e) {
          debugPrint('Unable to check for duplicates: $e');

          // Show warning that we can't check for duplicates.

          if (context.mounted) {
            final shouldProceed =
                await _showDuplicateCheckFailedDialog(context);
            if (!shouldProceed) {
              return false;
            }
          }
        }
      }

      // Process each row in the CSV file starting from the second row.

      for (var i = 1; i < fields.length; i++) {
        try {
          // Convert row data to a list of strings, handling null values.

          final row =
              List<String>.from(fields[i].map((f) => f?.toString() ?? ''));
          if (row.isEmpty) continue;

          // Pad the row with empty strings if it has fewer columns than headers.

          while (row.length < headers.length) {
            row.add('');
          }

          // Initialize the responses map with default values.

          final Map<String, dynamic> responses = createDefaultResponseMap();

          // Initialize timestamp and validation flag.

          String timestamp = '';
          bool hasRequiredFields = true;

          // Process each column in the current row.

          for (var j = 0; j < headers.length; j++) {
            final header = headers[j];
            final value = row[j].toString().trim();

            // Handle timestamp field specially

            if (header == timestampField.toLowerCase()) {
              if (value.isEmpty) {
                hasRequiredFields = false;
                debugPrint('Row $i: Missing required timestamp');
                continue;
              }

              timestamp = normaliseTimestamp(roundTimestampToSecond(value));
              if (!isValidTimestamp(timestamp)) {
                throw FormatException(
                    'Row $i: Invalid timestamp format: $value');
              }

              if (!seenTimestamps.add(timestamp)) {
                duplicateTimestamps.add(formatTimestampForDisplay(timestamp));
              }
              continue;
            }

            // Process other fields using the implementation-specific method

            final fieldProcessed = processField(header, value, responses, i);
            if (!fieldProcessed && lowerRequiredColumns.contains(header)) {
              hasRequiredFields = false;
            }
          }

          // Skip rows with missing required fields.

          if (!hasRequiredFields) {
            debugPrint(
                'Skipping row $i due to missing or invalid required fields');
            continue;
          }

          // Create the JSON data structure for the current record.

          final jsonData = {
            timestampField: timestamp,
            'responses': responses,
          };

          // Generate a safe filename using the timestamp.

          final safeTimestamp = timestamp.replaceAll(RegExp(r'[:.]+'), '-');
          final outputFileName = '${dataType}_$safeTimestamp.json.enc.ttl';

          // Determine the correct save path based on the directory structure.

          String savePath;
          if (dirPath.endsWith('/$dataType')) {
            savePath = '$dataType/$outputFileName';
          } else {
            final cleanDirPath =
                dirPath.replaceFirst(RegExp(r'^healthpod/data/?'), '');
            savePath = cleanDirPath.isEmpty
                ? outputFileName
                : '$cleanDirPath/$outputFileName';
          }

          // Check if context is still valid before proceeding.

          if (!context.mounted) return false;

          // Write the encrypted data to the pod.

          final result = await writePod(
            savePath,
            json.encode(jsonData),
            context,
            Text('Converting row $i'),
            encrypted: true,
          );

          // Track the success status of each save operation.

          if (result == SolidFunctionCallStatus.success) {
            successfulSaves++;
          } else {
            allSuccess = false;
            debugPrint('Failed to save file for row $i');
          }
        } catch (rowError) {
          debugPrint('Error processing row $i: $rowError');
          allSuccess = false;
        }
      }

      // Log the completion status.

      debugPrint(
          'Processing complete. Successfully saved $successfulSaves files');

      // Show warning for any duplicate timestamps found within the CSV.

      if (duplicateTimestamps.isNotEmpty) {
        if (!context.mounted) return allSuccess;
        showAlert(
          context,
          'Warning: Multiple entries found for these timestamps:\n${duplicateTimestamps.join("\n")}\n\nOnly the last entry for each timestamp will be saved.',
        );
      }

      // Return overall success status.

      return allSuccess && successfulSaves > 0;
    } catch (e) {
      // Handle any errors during the import process.

      debugPrint('Import error: $e');
      if (context.mounted) {
        showAlert(context, 'Error importing CSV: ${e.toString()}');
      }
      return false;
    }
  }

  /// Shows a warning dialog when duplicate checking fails.
  ///
  /// This dialog informs the user that we can't check for duplicate files
  /// and asks if they want to proceed anyway.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  ///
  /// Returns a boolean indicating whether the user wants to proceed.

  Future<bool> _showDuplicateCheckFailedDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Warning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to check for duplicate files.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This import might overwrite existing files with the same dates. Do you want to proceed anyway?',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                SizedBox(height: 12),
                Text(
                  'Note: Proceeding without checking may lead to unintended data loss.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Proceed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ) ??
        false;
  }

  /// Deletes existing files before importing new ones.
  ///
  /// This method deletes files that would be overridden by the import operation.
  ///
  /// Parameters:
  /// - [context]: Flutter build context for UI interactions
  /// - [dirPath]: The directory path where files are stored
  /// - [filesToDelete]: List of file names to delete
  ///
  /// Returns a Future that completes when all files are deleted.

  Future<void> _deleteExistingFiles(
    BuildContext context,
    String dirPath,
    List<String> filesToDelete,
  ) async {
    debugPrint('Deleting ${filesToDelete.length} existing files before import');

    // Determine the full path format based on the directory structure.

    String basePath;
    if (dirPath.endsWith('/$dataType')) {
      basePath = dataType;
    } else {
      final cleanDirPath =
          dirPath.replaceFirst(RegExp(r'^healthpod/data/?'), '');
      basePath = cleanDirPath.isEmpty ? '' : cleanDirPath;
    }

    // Attempt to delete each file.

    for (final fileName in filesToDelete) {
      try {
        // Construct the full path.

        final fullPath = basePath.isEmpty ? fileName : '$basePath/$fileName';

        debugPrint('Deleting file: $fullPath');

        // Try to delete the file with the primary path.

        try {
          if (context.mounted) {
            await deleteFile(fullPath);
            debugPrint('Successfully deleted: $fullPath');
            continue;
          }
        } catch (deleteError) {
          // Check if it's a "not found" error (404).

          if (deleteError.toString().contains('404') ||
              deleteError.toString().contains('NotFoundHttpError')) {
            debugPrint('File not found at primary path: $fullPath');

            // Try alternative path formats.

            final alternativePaths = [
              // Try without basePath.

              fileName,
              // Try with only dataType prefix.

              '$dataType/$fileName',
              // Try with healthpod/data prefix.

              'healthpod/data/$dataType/$fileName',
            ];

            bool deleted = false;
            for (final altPath in alternativePaths) {
              try {
                if (context.mounted) {
                  debugPrint('Trying alternative path: $altPath');
                  await deleteFile(altPath);
                  debugPrint(
                      'Successfully deleted with alternative path: $altPath');
                  deleted = true;
                  break;
                }
              } catch (altError) {
                debugPrint(
                    'Failed with alternative path $altPath: ${altError.toString().substring(0, min(100, altError.toString().length))}');
              }
            }

            if (!deleted) {
              debugPrint('Could not delete file with any path: $fileName');
            }
          } else {
            // For other errors, just log and continue.

            debugPrint('Error deleting file: $deleteError');
          }
        }
      } catch (e) {
        debugPrint('Error processing file $fileName: $e');
      }
    }
  }

  // Helper function to get minimum of two integers.

  int min(int a, int b) => a < b ? a : b;
}
