/// Save health plan data to pod.
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

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/utils/upload_json_to_pod.dart';
import 'package:healthpod/utils/validate_health_plan_data.dart';

/// Saves health plan data directly to POD.
///
/// Parameters:
/// - context: BuildContext for showing error messages
/// - title: Title of the health plan
/// - planItems: List of health plan items
/// - additionalData: Optional additional data to include

Future<bool> saveHealthPlanData({
  required BuildContext context,
  required String title,
  required List<String> planItems,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    // Prepare health plan data with timestamp and any additional data.

    final healthPlanData = {
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'title': title,
        'planItems': planItems,
      },
      if (additionalData != null) ...additionalData,
    };

    // Use utility to handle the upload process.

    final result = await uploadJsonToPod(
      data: healthPlanData,
      targetPath: 'health_plan',
      fileNamePrefix: 'health_plan',
      context: context,
    );

    if (result != SolidFunctionCallStatus.success) {
      throw Exception('Failed to save health plan data (Status: $result)');
    }

    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving health plan to POD: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}

/// Validates and saves uploaded health plan data.
///
/// Parameters:
/// - context: BuildContext for showing error messages
/// - data: Health plan data to validate and save

Future<bool> validateAndSaveHealthPlanData({
  required BuildContext context,
  required Map<String, dynamic> data,
}) async {
  // Validate the uploaded data.

  if (!validateHealthPlanData(data)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid health plan data format'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  // Save the validated data.

  return saveHealthPlanData(
    context: context,
    title: data['title'] as String,
    planItems: (data['planItems'] as List).cast<String>(),
  );
}
