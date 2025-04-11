/// Diary service for managing appointments in the POD.
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

  static const String feature = 'diary';

  /// Load all appointments from the diary directory.

  static Future<List<Appointment>> loadAppointments(
      BuildContext context) async {
    try {
      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      final List<Appointment> appointments = [];

      for (final file in resources.files) {
        if (file.endsWith('.enc.ttl')) {
          final filePath = getFeaturePath(feature, file);
          if (!context.mounted) return appointments;
          final content = await readPod(
            filePath,
            context,
            const Text('Loading appointment'),
          );

          if (content != SolidFunctionCallStatus.fail.toString() &&
              content != SolidFunctionCallStatus.notLoggedIn.toString()) {
            try {
              final data = jsonDecode(content.toString());
              // Check if the data is in the responses format.

              final appointmentData = data['responses'] ?? data;
              appointments.add(Appointment(
                date: DateTime.parse(appointmentData['date']),
                title: appointmentData['title'],
                description: appointmentData['description'],
                isPast: DateTime.parse(appointmentData['date'])
                    .isBefore(DateTime.now()),
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

  static Future<bool> saveAppointment(
      BuildContext context, Appointment appointment) async {
    try {
      final data = {
        'date': appointment.date.toIso8601String(),
        'title': appointment.title,
        'description': appointment.description,
      };

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

  static Future<bool> deleteAppointment(
      BuildContext context, Appointment appointment) async {
    try {
      final podDirPath = getFeaturePath(feature);
      final dirUrl = await getDirUrl(podDirPath);
      final resources = await getResourcesInContainer(dirUrl);

      // Find the file that matches the appointment.

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
              final data = jsonDecode(content.toString());
              final appointmentData = data['responses'] ?? data;
              final fileDate = DateTime.parse(appointmentData['date']);

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
