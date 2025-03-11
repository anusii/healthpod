/// Constants for blood pressure survey fields.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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

/// Constants for blood pressure survey field names.
///
/// These constants are used to access and store blood pressure data consistently
/// across the application, particularly in JSON serialization/deserialization.

/// Field name for systolic blood pressure.

class HealthSurveyConstants {
  /// Field name for systolic blood pressure.

  static const String fieldSystolic = 'systolic';

  /// Field name for diastolic blood pressure.

  static const String fieldDiastolic = 'diastolic';

  /// Field name for heart rate.

  static const String fieldHeartRate = 'heart_rate';

  /// Field name for subjective feeling.

  static const String fieldFeeling = 'feeling';

  /// Field name for additional notes.

  static const String fieldNotes = 'notes';
}
