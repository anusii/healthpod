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

  // Add a flag to track new observations.

  bool isNewObservation = false;

  // Keep track of current edits in a separate variable.

  BPObservation? currentEdit;

  // Maintain controllers as state variables.

  TextEditingController? systolicController;
  TextEditingController? diastolicController;
  TextEditingController? heartRateController;
  TextEditingController? notesController;

  /// Initialises text controllers with values from an observation
  ///
  /// This method sets up all text controllers with the current values
  /// from the provided observation. It first disposes of any existing
  /// controllers to prevent memory leaks.
  ///
  /// [observation] The BPObservation whose values should be used to
  /// initialise the controllers

  void initialiseControllers(BPObservation observation) {
    // Clean up existing controllers to prevent memory leaks.

    disposeControllers();

    // Initialise controllers with current values, converting 0 to empty string
    // for better user experience.

    systolicController = TextEditingController(
        text: observation.systolic == 0
            ? ''
            : parseBpNumericInput(observation.systolic));
    diastolicController = TextEditingController(
        text: observation.diastolic == 0
            ? ''
            : parseBpNumericInput(observation.diastolic));
    heartRateController = TextEditingController(
        text: observation.heartRate == 0
            ? ''
            : parseBpNumericInput(observation.heartRate));
    notesController = TextEditingController(text: observation.notes);
  }

  /// Disposes of all text controllers
  ///
  /// This method should be called when the controllers are no longer needed
  /// to prevent memory leaks.

  void disposeControllers() {
    systolicController?.dispose();
    diastolicController?.dispose();
    heartRateController?.dispose();
    notesController?.dispose();
  }

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
  /// This method:
  /// 1. Validates required fields (systolic, diastolic, heart rate)
  /// 2. Deletes old file if updating an existing observation
  /// 3. Creates new encrypted file with observation data
  /// 4. Reloads data to refresh the UI
  ///
  /// [observation] The BPObservation to save
  ///
  /// Shows error message if save fails or validation fails.

  Future<void> saveObservation(BPObservation observation) async {
    // Use currentEdit if available, otherwise use passed observation.

    final observationToSave = currentEdit ?? observation;

    // Validate required fields.

    if (observationToSave.systolic == 0 ||
        observationToSave.diastolic == 0 ||
        observationToSave.heartRate == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enter values for Systolic, Diastolic, and Heart Rate'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Only delete old file if this is an update to an existing record.

      if (!isNewObservation && editingIndex != null) {
        final oldObservation = observations[editingIndex!];
        final oldTimestamp =
            formatTimestampForFilename(oldObservation.timestamp);
        final oldFilename = 'blood_pressure_$oldTimestamp.json.enc.ttl';
        await deleteFile('healthpod/data/bp/$oldFilename');
      }

      // Generate a unique filename using formatted timestamp.

      final filename =
          'blood_pressure_${formatTimestampForFilename(observationToSave.timestamp)}.json.enc.ttl';

      // Write observation data to file.

      if (!mounted) return;
      await writePod(
        'bp/$filename',
        json.encode(observationToSave.toJson()),
        context,
        const Text('Saving'),
        encrypted: true,
      );

      // Reset editing state and reload data.

      if (!mounted) return;
      setState(() {
        editingIndex = null;
        isNewObservation = false;
        currentEdit = null; // Clear the current edit.
      });

      await loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  /// Cancels the current edit operation.
  ///
  /// Resets all editing state variables and disposes of controllers.

  void cancelEdit() {
    setState(() {
      editingIndex = null;
      isNewObservation = false;
      currentEdit = null;
      disposeControllers(); // Clean up controllers when canceling.
    });
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
    final newObservation = BPObservation(
      timestamp: DateTime.now(),
      systolic: 0,
      diastolic: 0,
      heartRate: 0,
      feeling: '',
      notes: '',
    );

    setState(() {
      observations.insert(0, newObservation);
      editingIndex = 0; // Start editing the new observation.
      isNewObservation = true;
      currentEdit = newObservation;
      initialiseControllers(newObservation);
    });
  }

  // UI BUILDING METHODS

  /// Builds a read-only display row for a blood pressure observation.
  ///
  /// Creates a DataRow with formatted display of all observation fields
  /// and edit/delete action buttons.
  ///
  /// [observation] The BPObservation to display
  /// [index] The index of this observation in the list

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
    // Use currentEdit if available, otherwise use the observation.

    // Initialise controllers if not already set.

    if (systolicController == null) {
      initialiseControllers(currentEdit ?? observation);
    }

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

        DataCell(
          TextField(
            controller: systolicController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                currentEdit = (currentEdit ?? observation).copyWith(
                  systolic: value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
                );
              });
            },
          ),
        ),

        DataCell(
          TextField(
            controller: diastolicController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                currentEdit = (currentEdit ?? observation).copyWith(
                  diastolic:
                      value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
                );
              });
            },
          ),
        ),

        DataCell(
          TextField(
            controller: heartRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                currentEdit = (currentEdit ?? observation).copyWith(
                  heartRate:
                      value.isEmpty ? 0 : (double.tryParse(value) ?? 0.0),
                );
              });
            },
          ),
        ),

        DataCell(DropdownButton<String>(
          value: (currentEdit ?? observation).feeling.isEmpty
              ? null
              : (currentEdit ?? observation).feeling,
          items: ['Excellent', 'Good', 'Fair', 'Poor']
              .map((feeling) => DropdownMenuItem(
                    value: feeling,
                    child: Text(feeling),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              currentEdit = (currentEdit ?? observation).copyWith(
                feeling: value ?? '',
              );
            });
          },
        )),

        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: TextField(
              controller: notesController, // Use the maintained controller.
              maxLines: null,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
              onChanged: (value) {
                setState(() {
                  currentEdit = (currentEdit ?? observation).copyWith(
                    notes: value,
                  );
                });
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
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isNarrowScreen = screenWidth < 600;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: isNarrowScreen
                          ? const EdgeInsets.all(
                              12) // Equal padding for square-like shape.
                          : const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isNarrowScreen
                            ? 12
                            : 8), // Increased radius for narrow screen.
                      ),
                      minimumSize: isNarrowScreen
                          ? const Size(46, 46)
                          : null, // Fixed size for narrow screen.
                    ),
                    onPressed: addNewObservation,
                    child: isNarrowScreen
                        ? const Icon(Icons
                            .add_circle) // Just centered icon for narrow screens.
                        : const Row(
                            // Manual row layout for wider screens.

                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle),
                              SizedBox(width: 8),
                              Text('Add New Reading'),
                            ],
                          ),
                  );
                },
              ),
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
