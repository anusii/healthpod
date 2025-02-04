/// Blood pressure editor widget.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Ashley Tang.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/features/bp/observation.dart';
import 'package:healthpod/utils/format_timestamp_for_filename.dart';
import 'package:healthpod/utils/parse_bp_numeric_input.dart';

/// Data Editor Page.
///
/// A widget that provides CRUD (Create, Read, Update, Delete) operations for blood pressure observations.
/// Observations are stored in encrypted format in the user's POD storage under the 'bp' directory.
/// Each observation contains timestamp, systolic/diastolic pressure, heart rate, feeling, and notes.

class BPEditor extends StatefulWidget {
  const BPEditor({super.key});

  @override
  State<BPEditor> createState() => _BPEditorState();
}

class _BPEditorState extends State<BPEditor> {
  // List of blood pressure observations loaded from POD.

  List<BPObservation> observations = [];

  // Index of observation currently being edited, null if no observation is being edited.

  int? editingIndex;

  // Loading state for async operations.

  bool isLoading = true;

  // Error message if data loading fails.

  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Loads blood pressure observations from POD storage.
  ///
  /// Fetches all .enc.ttl files from the bp directory, decrypts them,
  /// and parses them into BPObservation objects. Observations are sorted by timestamp
  /// in descending order (newest first).

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        error = null; // Clear any previous error message.
      });

      // Get URL of directory containing blood pressure data.

      final dirUrl = await getDirUrl('healthpod/data/bp');

      // Retrieve list of files in directory.

      final resources = await getResourcesInContainer(dirUrl);

      final List<BPObservation> loadedObservations = [];
      for (final file in resources.files) {
        // Skip files that don't match expected naming pattern.

        if (!file.endsWith('.enc.ttl')) continue;

        // Prevent processing if widget is no longer mounted.

        if (!mounted) break;

        // Read encrypted file content.

        final content = await readPod(
          'healthpod/data/bp/$file',
          context,
          const Text('Loading file'),
        );

        // Check if content was successfully retrieved.

        if (content != SolidFunctionCallStatus.fail &&
            content != SolidFunctionCallStatus.notLoggedIn &&
            content != null) {
          try {
            // Parse JSON content into a `BPObservation`.
            final data = json.decode(content.toString());
            loadedObservations.add(BPObservation.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing file $file: $e');
          }
        }
      }

      // Update UI with loaded and sorted observations.

      setState(() {
        observations = loadedObservations
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        isLoading = false;
      });
    } catch (e) {
      // Handle errors during data loading.

      setState(() {
        error = e.toString();
        isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  /// Saves a blood pressure observation to POD storage.
  ///
  /// Creates or updates an encrypted file in the bp directory with the observation data.
  /// File name is generated from the observation's timestamp.

  Future<void> saveObservation(BPObservation observation) async {
    try {
      // Delete old file if updating existing observation.

      if (editingIndex != null) {
        final oldObservation = observations[editingIndex!];
        final oldTimestamp = formatTimestampForFilename(
            oldObservation.timestamp); // Ensure no milliseconds in filename.
        final oldFilename = 'blood_pressure_$oldTimestamp.json.enc.ttl';
        await deleteFile('healthpod/data/bp/$oldFilename');
      }

      // Generate a unique filename using formatted timestamp.

      final filename =
          'blood_pressure_${formatTimestampForFilename(observation.timestamp)}.json.enc.ttl';

      // Write observation data to file.

      if (!mounted) return;
      await writePod(
        'bp/$filename',
        json.encode(observation.toJson()),
        context,
        const Text('Saving'),
        encrypted: true,
      );

      // Refresh the observation list after saving.

      if (!mounted) return; // Check if the widget is still mounted
      setState(() {
        editingIndex = null;
      });

      await loadData();
    } catch (e) {
      if (mounted) {
        // Handle errors during save operation.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  /// Deletes a blood pressure observation from POD storage.
  ///
  /// Removes the encrypted file corresponding to the observation from the bp directory.

  Future<void> deleteObservation(BPObservation observation) async {
    try {
      // Generate the filename from the observation's timestamp.

      final timestamp =
          observation.timestamp.toIso8601String().substring(0, 19);

      final filename =
          'blood_pressure_${timestamp.replaceAll(RegExp(r'[:.]+'), '-')}.json.enc.ttl';

      // Delete the file from the POD.

      await deleteFile('healthpod/data/bp/$filename');

      // Reload the data to reflect the deletion.

      if (!mounted) return;
      await loadData();
    } catch (e) {
      if (mounted) {
        // Handle errors during delete operation.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  /// Creates a new blank blood pressure observation.
  ///
  /// Inserts a new observation at the beginning of the list and enters edit mode.

  void addNewObservation() {
    setState(() {
      observations.insert(
          0,
          BPObservation(
            timestamp: DateTime.now(),
            systolic: 0,
            diastolic: 0,
            heartRate: 0,
            feeling: '',
            notes: '',
          ));
      editingIndex = 0; // Start editing the new observation.
    });
  }

  /// Builds a read-only display row for a blood pressure observation.
  ///
  /// Displays formatted timestamp, systolic/diastolic pressure, heart rate,
  /// feeling, and notes as static text. Includes edit and delete action buttons.

  DataRow _buildDisplayRow(BPObservation observation, int index) {
    return DataRow(
      cells: [
        // Timestamp, systolic, diastolic, heart rate, feeling, and notes.

        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss')
            .format(observation.timestamp))), // Format timestamp without 'T'.

        DataCell(Text(parseBpNumericInput(observation
            .systolic))), // Round to nearest int to display according to user expectation.
        DataCell(Text(parseBpNumericInput(observation.diastolic))),
        DataCell(Text(parseBpNumericInput(observation.heartRate))),

        DataCell(Text(observation.feeling)),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              observation.notes,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button.

            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => editingIndex = index),
            ),
            // Delete button.

            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteObservation(observation),
            ),
          ],
        )),
      ],
    );
  }

  /// Builds an editable row for a blood pressure observation.
  ///
  /// Creates text fields for timestamp, systolic/diastolic pressure, and heart rate,
  /// a dropdown for feeling selection, and a notes field. Each field has its own
  /// controller and updates the observation on change.

  DataRow _buildEditingRow(BPObservation observation, int index) {
    final systolicController =
        TextEditingController(text: parseBpNumericInput(observation.systolic));
    final diastolicController =
        TextEditingController(text: parseBpNumericInput(observation.diastolic));
    final heartRateController =
        TextEditingController(text: parseBpNumericInput(observation.heartRate));
    TextEditingController(text: observation.heartRate.toString());
    final notesController = TextEditingController(text: observation.notes);

    return DataRow(
      cells: [
        // Editable timestamp with date and time pickers.

        DataCell(
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: observation.timestamp,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(observation.timestamp),
                );

                if (time != null && mounted) {
                  // Show dialog for milliseconds with explicit confirmation.

                  final TextEditingController msController =
                      TextEditingController();
                  final milliseconds = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Set Milliseconds'),
                      content: TextField(
                        controller: msController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter milliseconds (0-999)',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(0),
                          child: const Text('Skip'),
                        ),
                        TextButton(
                          onPressed: () {
                            final ms = int.tryParse(msController.text) ?? 0;
                            Navigator.of(context).pop(ms.clamp(0, 999));
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );

                  final newTimestamp = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                    0, // seconds
                    milliseconds ?? 0,
                  );

                  if (observations.any((r) =>
                      r.timestamp == newTimestamp &&
                      observations.indexOf(r) != index)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'A observation with this timestamp already exists'),
                        ),
                      );
                    }
                    return;
                  }

                  setState(() {
                    observations[index] =
                        observation.copyWith(timestamp: newTimestamp);
                  });
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                DateFormat('yyyy-MM-dd HH:mm:ss.SSS')
                    .format(observation.timestamp),
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),

        // Editable systolic, diastolic, heart rate, feeling, and notes fields.

        DataCell(TextField(
          controller: systolicController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsedValue =
                double.tryParse(value) ?? 0.0; // Keep as double.
            observations[index] = observation.copyWith(
              systolic: parsedValue, // Store the double value.
            );
          },
        )),

        DataCell(TextField(
          controller: diastolicController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsedValue = double.tryParse(value) ?? 0.0;
            observations[index] = observation.copyWith(
              diastolic: parsedValue,
            );
          },
        )),

        DataCell(TextField(
          controller: heartRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsedValue = double.tryParse(value) ?? 0.0;
            observations[index] = observation.copyWith(
              heartRate: parsedValue,
            );
          },
        )),

        DataCell(DropdownButton<String>(
          value: observation.feeling.isEmpty ? null : observation.feeling,
          items: ['Excellent', 'Good', 'Fair', 'Poor']
              .map((feeling) => DropdownMenuItem(
                    value: feeling,
                    child: Text(feeling),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              observations[index] = observation.copyWith(feeling: value ?? '');
            });
          },
        )),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: TextField(
              controller: notesController,
              maxLines: null,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
              onChanged: (value) {
                observations[index] = observation.copyWith(notes: value);
              },
            ),
          ),
        ),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save button.

            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => saveObservation(observations[index]),
            ),
            // Cancel button.

            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => setState(() => editingIndex = null),
            ),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Observations'),
        backgroundColor: titleBackgroundColor,
        actions: [
          // Add new observation button.

          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: addNewObservation,
              tooltip: 'Add New Reading',
            ),
        ],
      ),
      body: (() {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (error != null) {
          return Center(child: Text('Error: $error'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Systolic')),
                DataColumn(label: Text('Diastolic')),
                DataColumn(label: Text('Heart Rate')),
                DataColumn(label: Text('Feeling')),
                DataColumn(label: Text('Notes')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List<DataRow>.generate(
                observations.length,
                (index) {
                  final observation = observations[index];
                  if (editingIndex == index) {
                    return _buildEditingRow(observation, index);
                  }
                  return _buildDisplayRow(observation, index);
                },
              ),
            ),
          ),
        );
      })(),
    );
  }
}
