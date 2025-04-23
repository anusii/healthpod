library;

import 'package:flutter/material.dart';
import 'package:healthpod/theme/card_style.dart';
import 'package:intl/intl.dart';

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
  // Medications data
  final List<Medication> _medications = [
    Medication(
      name: 'Lisinopril',
      dosage: '10mg',
      frequency: 'Once daily',
      time: TimeOfDay(hour: 8, minute: 0),
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      notes: 'Take with food',
    ),
    Medication(
      name: 'Metformin',
      dosage: '500mg',
      frequency: 'Twice daily',
      time: TimeOfDay(hour: 18, minute: 0),
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      notes: 'Take after meals',
    ),
  ];

  /// Opens dialog to add or edit a medication
  void _showMedicationDialog([Medication? medication, int? index]) {
    final bool isEditing = medication != null;
    
    final nameController = TextEditingController(text: medication?.name ?? '');
    final dosageController = TextEditingController(text: medication?.dosage ?? '');
    final frequencyController = TextEditingController(text: medication?.frequency ?? '');
    final notesController = TextEditingController(text: medication?.notes ?? '');
    
    TimeOfDay selectedTime = medication?.time ?? TimeOfDay.now();
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
                        hintText: 'e.g., Once daily',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Reminder Time: '),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Text(
                            '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
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
                    final medication = Medication(
                      name: nameController.text.trim(),
                      dosage: dosageController.text.trim(),
                      frequency: frequencyController.text.trim(),
                      time: selectedTime,
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

  /// Deletes a medication at the specified index
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
              child: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showMedicationDialog(),
                tooltip: 'Add Medication',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
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
                                  Text('${medication.dosage} - ${medication.frequency}'),
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
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _showMedicationDialog(medication, index),
                                  tooltip: 'Edit',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => _deleteMedication(index),
                                  tooltip: 'Delete',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${medication.time.hour}:${medication.time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
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

/// Model class to represent a medication
class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final DateTime startDate;
  final String notes;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.startDate,
    required this.notes,
  });
} 