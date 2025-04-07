/// Appointment data model for the health data app.
///
// Time-stamp: <Wednesday 2025-03-26 10:26:49 +1100 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
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

/// A model class representing a medical appointment.
///
/// This class contains information about an appointment including its date,
/// title, description, and whether it's in the past or future.
class Appointment {
  /// The date and time of the appointment.

  final DateTime date;

  /// The title or name of the appointment.

  final String title;

  /// A detailed description of the appointment.

  final String description;

  /// Whether the appointment is in the past.

  final bool isPast;

  /// Creates a new [Appointment] instance.
  ///
  /// [date] is the date and time of the appointment.
  /// [title] is the title or name of the appointment.
  /// [description] is a detailed description of the appointment.
  /// [isPast] indicates whether the appointment is in the past.

  Appointment({
    required this.date,
    required this.title,
    required this.description,
    required this.isPast,
  });
}
