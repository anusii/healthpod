import 'package:flutter/material.dart';
import 'package:healthpod/utils/handle_submit.dart';
import 'package:healthpod/utils/save_response_locally.dart';
import 'package:healthpod/utils/save_response_pod.dart';

class VaccinationDiary extends StatefulWidget {
  const VaccinationDiary({super.key});

  @override
  State<VaccinationDiary> createState() => _VaccinationDiaryState();
}

class _VaccinationDiaryState extends State<VaccinationDiary> {
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
      filePrefix: 'vaccination_diary',
      dialogTitle: 'Save Vaccination Record',
    );
  }

  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    await saveResponseToPod(
      context: context,
      responses: responses,
      podPath: '/vaccination',
      filePrefix: 'vaccination_diary',
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
              // Date Picker
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Vaccine Name
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

              // Provider
              TextFormField(
                controller: _providerController,
                decoration: const InputDecoration(
                  labelText: 'Provider (e.g., Clinic Name)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Healthcare Professional
              TextFormField(
                controller: _professionalController,
                decoration: const InputDecoration(
                  labelText: 'Healthcare Professional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Cost
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

              // Notes
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Collect form data into properly typed Map
                        final Map<String, dynamic> responses = {
                          'date':
                              '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                          'vaccine_name': _vaccineController.text,
                          'provider': _providerController.text,
                          'professional': _professionalController.text,
                          'cost': _costController.text,
                          'notes': _noteController.text,
                          // Add other form fields as needed
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
