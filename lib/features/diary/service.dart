/// Diary service for managing appointments in the POD.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:healthpod/constants/paths.dart';
import 'package:healthpod/features/diary/models/appointment.dart';
import 'package:healthpod/utils/create_feature_folder.dart';
import 'package:healthpod/utils/get_feature_path.dart';
import 'package:healthpod/utils/save_response_pod.dart';

/// Service for managing diary appointments in the POD.
class DiaryService {
  static const String feature = 'diary';

  /// Load all appointments from the diary directory.
  static Future<List<Appointment>> loadAppointments(
      BuildContext context) async {
    final podDirPath = getFeaturePath(feature);
    final dirUrl = await getDirUrl(podDirPath);
    final resources = await getResourcesInContainer(dirUrl);

    final List<Appointment> appointments = [];

    for (final file in resources.files) {
      if (file.endsWith('.enc.ttl')) {
        final filePath = getFeaturePath(feature, file);
        final content = await readPod(
          filePath,
          context,
          const Text('Loading appointment'),
        );

        if (content != SolidFunctionCallStatus.fail.toString() &&
            content != SolidFunctionCallStatus.notLoggedIn.toString()) {
          try {
            final data = jsonDecode(content.toString());
            appointments.add(Appointment(
              date: DateTime.parse(data['date']),
              title: data['title'],
              description: data['description'],
              isPast: DateTime.parse(data['date']).isBefore(DateTime.now()),
            ));
          } catch (e) {
            debugPrint('Error parsing appointment file: $e');
          }
        }
      }
    }

    return appointments;
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
      final fileName =
          'appointment_${appointment.date.toIso8601String()}.json.enc.ttl';
      final filePath = getFeaturePath(feature, fileName);

      await deleteFile(filePath);
      return true;
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      return false;
    }
  }
}
