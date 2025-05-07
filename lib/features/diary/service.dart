/// Diary service for managing appointments in the POD.
///
/// This service provides functionality to:
/// - Load appointments from the POD
/// - Save new appointments to the POD
/// - Delete existing appointments from the POD
///
/// All appointments are stored as encrypted TTL files in the POD,
/// with each appointment containing date, title, and description.
///
// Time-stamp: <Wednesday 2025-03-26 10:26:49 +1100 Graham Williams>
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
/// Authors: Kevin Wang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/utils/get_feature_path.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// Service for managing diary appointments in the POD.
class DiaryService {
  /// The feature identifier for diary functionality.
  /// This is used to construct the path where appointment files are stored.

  static const String feature = 'diary';

  /// Load all appointments from the diary directory in the POD.
  ///
  /// This method:
  /// 1. Gets the diary directory path
  /// 2. Retrieves all encrypted TTL files
  /// 3. Parses each file to extract appointment data
  /// 4. Returns a list of Appointment objects
  ///
  /// Returns an empty list if there are any errors during loading.

  static Future<List<Appointment>> loadAppointments(
      BuildContext context) async {
    try {
      // Get the path to the diary directory in the POD.

      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      final List<Appointment> appointments = [];

      // Process each file in the directory.

      for (final file in resources.files) {
        if (file.endsWith('.enc.ttl')) {
          final filePath = getFeaturePath(feature, file);
          if (!context.mounted) return appointments;
          final content = await readPod(
            filePath,
            context,
            const Text('Loading appointment'),
          );

          // Check if the file was successfully read.

          if (content != SolidFunctionCallStatus.fail.toString() &&
              content != SolidFunctionCallStatus.notLoggedIn.toString()) {
            try {
              // Parse the appointment data from the file.

              final data = jsonDecode(content.toString());
              final appointmentData = data['responses'] ?? data;

              // Try to get date from both root level and responses.
              // This is because the date is sometimes stored in the root level and sometimes in the responses.

              final rootDateStr = data['date']?.toString();
              final responseDateStr = appointmentData['date']?.toString();
              final dateStr = rootDateStr ?? responseDateStr;

              if (dateStr == null) {
                debugPrint('Error: No date found in appointment data');
                continue;
              }

              appointments.add(Appointment(
                date: DateTime.parse(dateStr),
                title: appointmentData['title'],
                description: appointmentData['description'],
                isPast: DateTime.parse(dateStr).isBefore(DateTime.now()),
              ));
            } catch (e) {
              debugPrint('Error parsing appointment file $file: $e');
            }
          }
        }
      }

      return appointments;
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }

  /// Save an appointment to the POD.
  ///
  /// This method:
  /// 1. Creates a data map with the appointment details
  /// 2. Saves the data to the POD using saveResponseToPod
  /// 3. Returns true if successful, false otherwise

  static Future<bool> saveAppointment(
      BuildContext context, Appointment appointment) async {
    try {
      // Prepare the appointment data for saving.

      final data = {
        'date': appointment.date.toIso8601String(),
        'title': appointment.title,
        'description': appointment.description,
      };

      // Save the appointment to the POD.
      if (!context.mounted) return false;

      await saveResponseToPod(
        context: context,
        responses: data,
        podPath: '/$feature',
        filePrefix: 'appointment',
      );

      return true;
    } catch (e) {
      debugPrint('Error saving appointment: $e');
      return false;
    }
  }

  /// Delete an appointment from the POD.
  ///
  /// This method:
  /// 1. Finds the file containing the appointment
  /// 2. Verifies the appointment data matches
  /// 3. Deletes the file from the POD
  /// 4. Returns true if successful, false otherwise

  static Future<bool> deleteAppointment(
      BuildContext context, Appointment appointment) async {
    try {
      // Get the diary directory path.

      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      // Find and delete the matching appointment file.

      for (final file in resources.files) {
        if (file.endsWith('.enc.ttl')) {
          final filePath = getFeaturePath(feature, file);
          if (!context.mounted) return false;
          final content = await readPod(
            filePath,
            context,
            const Text('Loading appointment for deletion'),
          );

          if (content != SolidFunctionCallStatus.fail.toString() &&
              content != SolidFunctionCallStatus.notLoggedIn.toString()) {
            try {
              // Check if this file contains the appointment to delete.

              final data = jsonDecode(content.toString());
              final appointmentData = data['responses'] ?? data;

              // Try to get date from both root level and responses.

              final rootDateStr = data['date']?.toString();
              final responseDateStr = appointmentData['date']?.toString();
              final dateStr = rootDateStr ?? responseDateStr;

              if (dateStr == null) {
                debugPrint('Error: No date found in appointment data');
                continue;
              }

              final fileDate = DateTime.parse(dateStr);
              if (fileDate.isAtSameMomentAs(appointment.date)) {
                await deleteFile(filePath);
                return true;
              }
            } catch (e) {
              debugPrint('Error parsing appointment file $file: $e');
            }
          }
        }
      }

      debugPrint('No matching appointment file found for deletion');
      return false;
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      return false;
    }
  }
}
