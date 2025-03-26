/// Constants for CSV field definitions.
///
/// This file contains shared CSV field definitions used by importers and exporters.
///
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
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
/// Authors: Kevin Wang.

library;

/// Blood pressure CSV field definitions.
class BPCSVFields {
  /// All CSV headers for blood pressure data.
  static const List<String> allFields = [
    fieldTimestamp,
    fieldSystolic,
    fieldDiastolic,
    fieldHeartRate,
    fieldFeeling,
    fieldNotes,
  ];

  /// Required CSV fields for blood pressure data.
  static const List<String> requiredFields = [
    fieldTimestamp,
    fieldSystolic,
    fieldDiastolic,
    fieldHeartRate,
  ];

  /// Optional CSV fields for blood pressure data.
  static const List<String> optionalFields = [
    fieldFeeling,
    fieldNotes,
  ];

  // Individual field names
  static const String fieldTimestamp = 'timestamp';
  static const String fieldSystolic = 'systolic';
  static const String fieldDiastolic = 'diastolic';
  static const String fieldHeartRate = 'heart_rate';
  static const String fieldFeeling = 'feeling';
  static const String fieldNotes = 'notes';
}
