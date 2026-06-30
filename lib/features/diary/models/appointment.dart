/// Appointment data model for the health data app.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang

library;

import 'dart:math';

/// A model class representing a medical appointment.
///
/// This class contains information about an appointment including its date,
/// title, description, and whether it's in the past or future.

class Appointment {
  /// A stable unique identifier for this appointment, used to match it for
  /// editing and deletion independently of its date/time.

  final String id;

  /// The date and time of the appointment.

  final DateTime date;

  /// The title or name of the appointment.

  final String title;

  /// A detailed description of the appointment.

  final String description;

  /// Whether the appointment is in the past.

  final bool isPast;

  /// The exact filename this appointment was loaded from on the Pod, if known.
  /// Used to delete/replace precisely without relying on field matching.

  final String? sourceFile;

  /// Creates a new [Appointment] instance.
  ///
  /// [date] is the date and time of the appointment.
  /// [title] is the title or name of the appointment.
  /// [description] is a detailed description of the appointment.
  /// [isPast] indicates whether the appointment is in the past.
  /// [id] uniquely identifies the appointment; when omitted a new one is
  /// generated.
  /// [sourceFile] is the Pod filename it was loaded from, if any.

  Appointment({
    required this.date,
    required this.title,
    required this.description,
    required this.isPast,
    String? id,
    this.sourceFile,
  }) : id = id ?? _generateId();

  /// Generate a reasonably unique id without external dependencies:
  /// a timestamp combined with a random suffix.

  static String _generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return '$ts-$rand';
  }
}
