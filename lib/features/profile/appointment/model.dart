import 'package:flutter/material.dart';

/// Model class to represent an appointment.

class Appointment {
  final String doctorName;
  final String specialty;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final String notes;

  Appointment({
    required this.doctorName,
    required this.specialty,
    required this.location,
    required this.date,
    required this.time,
    required this.notes,
  });
}
