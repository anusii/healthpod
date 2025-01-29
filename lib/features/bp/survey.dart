/// BP survey page.
//
// Time-stamp: <Monday 2025-01-20 16:54:30 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/colours.dart';
import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/constants/survey.dart';
import 'package:healthpod/utils/fetch_key_saved_status.dart';
import 'package:healthpod/utils/upload_json_to_pod.dart';
import 'package:healthpod/features/survey/form.dart';
import 'package:healthpod/features/survey/question.dart';

/// A page for collecting blood pressure survey data.

class BPSurvey extends StatelessWidget {
  final List<HealthSurveyQuestion> questions = [
    HealthSurveyQuestion(
      question: "What's your systolic blood pressure?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 70,
      max: 200,
    ),
    HealthSurveyQuestion(
      question: "What's your diastolic measurement?",
      type: HealthDataType.number,
      unit: "mm Hg",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "What's your heart rate?",
      type: HealthDataType.number,
      unit: "bpm",
      min: 40,
      max: 220,
    ),
    HealthSurveyQuestion(
      question: "How are you feeling?",
      type: HealthDataType.categorical,
      options: ["Excellent", "Good", "Fair", "Poor"],
    ),
    HealthSurveyQuestion(
      question: "Any additional notes about your health?",
      type: HealthDataType.text,
      isRequired: false,
    ),
  ];

  BPSurvey({super.key});

  /// Saves the survey responses to a local file.

  Future<void> _saveResponsesLocally(
      BuildContext context, Map<String, dynamic> responses) async {
    try {
      // Add timestamp to responses.

      final responseData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': responses,
      };

      // Convert to JSON string with proper formatting and base64 encode.

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(responseData);
      final base64Content = base64Encode(utf8.encode(jsonString));

      // Generate default filename.

      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]+'), '-');
      final defaultFileName = 'blood_pressure_$timestamp.json';

      // Show file picker for save location.

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Survey Response',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        throw Exception('Save cancelled by user');
      }

      // Ensure .json extension.

      if (!outputFile.toLowerCase().endsWith('.json')) {
        outputFile = '$outputFile.json';
      }

      // Save the base64 encoded file.

      final file = File(outputFile);
      await file.writeAsString(base64Content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Saves the survey responses directly to POD.
  ///
  /// Uses uploadJsonToPod utility which:
  /// 1. Creates a properly formatted JSON file
  /// 2. Uses uploadFileToPod internally for consistent file handling
  /// 3. Ensures proper encryption and file naming
  /// 4. Manages temporary file cleanup
  ///
  /// This provides the same file format and handling as manual uploads
  /// through the file browser.

  Future<void> _saveResponsesToPod(
      BuildContext context, Map<String, dynamic> responses) async {
    try {
      // Prepare response data with timestamp.

      final responseData = {
        'timestamp': DateTime.now().toIso8601String(),
        'responses': responses,
      };

      // Use utility to handle the upload process.

      final result = await uploadJsonToPod(
        data: responseData, // Our structured survey data
        targetPath: '/bp', // Store in blood pressure directory
        fileNamePrefix: 'blood_pressure', // Consistent file naming
        context: context,
      );

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to save survey responses (Status: $result)');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving survey to POD: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles the submission of the survey.

  Future<void> _handleSubmit(
      BuildContext context, Map<String, dynamic> responses) async {
    if (!context.mounted) return;

    // Check login and security key status first.

    final isKeySaved = await fetchKeySavedStatus(context);

    if (!context.mounted) return;

    // Show save location options dialog.

    final saveChoice = await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Survey Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose how to save your results:'),
              if (!isKeySaved) ...[
                const SizedBox(height: 12),
                const Text(
                  'Note: POD saving requires setting up your security key first.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('local'),
              child: const Text('Save Locally'),
            ),
            TextButton(
              onPressed:
                  isKeySaved ? () => Navigator.of(context).pop('pod') : null,
              child: Text(
                'Save to POD',
                style: TextStyle(
                  color: isKeySaved ? null : Colors.grey,
                ),
              ),
            ),
            // Option to save to both places.
            // Instead of saving to only one place, so that user has a backup.

            TextButton(
              onPressed:
                  isKeySaved ? () => Navigator.of(context).pop('both') : null,
              child: Text(
                'Save Both Places',
                style: TextStyle(
                  color: isKeySaved ? null : Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (saveChoice == null) return; // User cancelled

    if (!context.mounted) return;

    try {
      // Show saving indicator.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving survey results...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Perform the selected save operations.

      if (saveChoice == 'local' || saveChoice == 'both') {
        await _saveResponsesLocally(context, responses);
      }

      if (!context.mounted) return;

      if (saveChoice == 'pod' || saveChoice == 'both') {
        await _saveResponsesToPod(context, responses);
      }

      if (!context.mounted) return;

      // Show final success message.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey submitted and saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Return to previous screen after brief delay.

      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving survey: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Builds the health survey page.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Survey'),
        backgroundColor: titleBackgroundColor,
      ),
      body: HealthSurveyForm(
        questions: HealthSurveyConstants.questions,
        onSubmit: (responses) => _handleSubmit(context, responses),
      ),
    );
  }
}
