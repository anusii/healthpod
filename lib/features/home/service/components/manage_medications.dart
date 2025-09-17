/// A widget to display and manage medications.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:healthpod/features/medication/obs/model.dart';
import 'package:healthpod/theme/card_style.dart';

/// A widget to display and manage medications.
///
/// This widget allows users to view their current medications,
/// add new medications, edit existing ones, and set reminders.

class ManageMedications extends StatefulWidget {
  const ManageMedications({super.key});

  @override
  State<ManageMedications> createState() => _ManageMedicationsState();
}

class _ManageMedicationsState extends State<ManageMedications> {
  // Medications data.

  final List<MedicationObservation> _medications = [
    MedicationObservation(
      name: 'e.g. Lisinopril',
      dosage: '10mg',
      frequency: 'Once daily at 8:00 AM',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      notes: 'Take with food',
    ),
    MedicationObservation(
      name: 'e.g. Metformin',
      dosage: '500mg',
      frequency: 'Twice daily at 8:00 AM and 6:00 PM',
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      notes: 'Take after meals',
    ),
  ];

  /// Opens dialog to add or edit a medication.

  void _showMedicationDialog([MedicationObservation? medication, int? index]) {
    final bool isEditing = medication != null;

    final nameController = TextEditingController(text: medication?.name ?? '');
    final dosageController =
        TextEditingController(text: medication?.dosage ?? '');
    final frequencyController =
        TextEditingController(text: medication?.frequency ?? '');
    final notesController =
        TextEditingController(text: medication?.notes ?? '');

    DateTime selectedDate = medication?.startDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${isEditing ? 'Edit' : 'Add'} Medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        hintText: 'e.g., Lisinopril',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: 'e.g., 10mg',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: frequencyController,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        hintText: 'e.g., Once daily at 8:00 AM',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Start Date: '),
                        TextButton(
                          onPressed: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2025),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'e.g., Take with food',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final medication = MedicationObservation(
                      name: nameController.text.trim(),
                      dosage: dosageController.text.trim(),
                      frequency: frequencyController.text.trim(),
                      startDate: selectedDate,
                      notes: notesController.text.trim(),
                    );

                    if (medication.name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication name is required'),
                        ),
                      );
                      return;
                    }

                    this.setState(() {
                      if (isEditing && index != null) {
                        _medications[index] = medication;
                      } else {
                        _medications.add(medication);
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Deletes a medication at the specified index.

  void _deleteMedication(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: Text(
            'Are you sure you want to delete ${_medications[index].name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _medications.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(16.0),
      decoration: getHomeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Medications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              MarkdownTooltip(
                message: '**Add** a new medication',
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showMedicationDialog(),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_medications.isEmpty)
            const Center(
              child: Text(
                'No medications added yet',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final medication = _medications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medication.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${medication.dosage} - ${medication.frequency}',
                                  ),
                                  if (medication.notes.isNotEmpty)
                                    Text(
                                      medication.notes,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                MarkdownTooltip(
                                  message: '**Edit** this medication',
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showMedicationDialog(
                                      medication,
                                      index,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                MarkdownTooltip(
                                  message: '**Delete** this medication',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => _deleteMedication(index),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Since ${DateFormat('MMM d, yyyy').format(medication.startDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
