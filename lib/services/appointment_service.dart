import 'package:flutter/material.dart';
import 'package:healthpod/services/api_service.dart';

class AppointmentService {
  static Future<List<Map<String, dynamic>>> loadAppointments(
      BuildContext context) async {
    try {
      final response = await ApiService.get('/appointments', context);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((appointment) => {
                  'title': appointment['title'] ?? '',
                  'date': DateTime.parse(appointment['date']),
                  'location': appointment['location'] ?? '',
                  'doctor': appointment['doctor'] ?? '',
                })
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      return [];
    }
  }
}
