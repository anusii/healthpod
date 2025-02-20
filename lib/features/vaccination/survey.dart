/// Vaccination survey form.
///
// Time-stamp: <Wednesday 2025-02-12 15:50:35 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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

import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

class VaccinationSurvey extends StatefulWidget {
  const VaccinationSurvey({super.key});

  @override
  State<VaccinationSurvey> createState() => _VaccinationSurveyState();
}

class _VaccinationSurveyState extends State<VaccinationSurvey> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _vaccineController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _professionalController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveResponsesLocally(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseLocally(
      context: context,
      responses: responses,
      filePrefix: 'vaccination',
      dialogTitle: 'Save Vaccination Record',
    );
  }

  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseToPod(
      context: context,
      responses: responses,
      podPath: '/vaccination',
      filePrefix: 'vaccination',
    );
  }

  /// Handles the submission of the survey.

  Future<void> _handleSubmit(
      BuildContext context, Map<String, dynamic> responses) async {
    await handleSurveySubmit(
      context: context,
      responses: responses,
      saveLocally: _saveResponsesLocally,
      saveToPod: _saveResponsesToPod,
      title: 'Save Vaccination Record',
    );

    // Clear all form fields after successful submission
    setState(() {
      _selectedDate = DateTime.now(); // Reset to current date
      _vaccineController.clear();
      _providerController.clear();
      _professionalController.clear();
      _costController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Diary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker.

              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Vaccine Name.

              TextFormField(
                controller: _vaccineController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vaccine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Provider.

              TextFormField(
                controller: _providerController,
                decoration: const InputDecoration(
                  labelText: 'Provider (e.g., Clinic Name)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Healthcare Professional.

              TextFormField(
                controller: _professionalController,
                decoration: const InputDecoration(
                  labelText: 'Healthcare Professional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Cost.

              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Notes.

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button.

              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Collect form data into properly typed Map.

                        final Map<String, dynamic> responses = {
                          'date':
                              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                          'vaccine_name': _vaccineController.text,
                          'provider': _providerController.text,
                          'professional': _professionalController.text,
                          'cost': _costController.text,
                          'notes': _noteController.text,
                        };

                        _handleSubmit(context, responses);
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vaccineController.dispose();
    _providerController.dispose();
    _professionalController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
