/// Health-specific file type configurations for SolidFile.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
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
/// Authors: Tony Chen

library;

import 'package:solidui/solidui.dart';

// Health-specific data format configurations.

/// Pre-defined format configurations for HealthPod data types.

class HealthDataFormats {
  static const bloodPressure = DataFormatConfig(
    title: 'Blood Pressure CSV Format',
    requiredFields: ['timestamp', 'systolic', 'diastolic', 'heart_rate'],
    optionalFields: ['notes'],
  );

  static const vaccination = DataFormatConfig(
    title: 'Vaccination CSV Format',
    requiredFields: ['timestamp', 'name', 'type'],
    optionalFields: ['location', 'notes', 'batch_number'],
  );

  static const medication = DataFormatConfig(
    title: 'Medication CSV Format',
    requiredFields: ['timestamp', 'name', 'dosage', 'frequency', 'start_date'],
    optionalFields: ['notes'],
  );

  static const diary = DataFormatConfig(
    title: 'Appointment CSV Format',
    requiredFields: ['timestamp', 'content'],
    optionalFields: ['mood', 'tags', 'notes'],
  );

  static const profile = DataFormatConfig(
    title: 'Profile JSON Format',
    requiredFields: [
      'name',
      'address',
      'bestContactPhone',
      'alternativeContactNumber',
      'email',
      'dateOfBirth',
      'gender',
    ],
    isJson: true,
  );
}

// Health-specific file type resolver.

/// Default upload tooltip text used across all health file types.

const String _healthUploadTooltip = '''

**Upload**: Tap here to upload a file to your Solid Health Pod.

''';

/// Resolves a normalised path to a health-specific [FileTypeConfig].
///
/// Returns `null` when the path does not match any known health directory,
/// allowing solidui to fall back to its generic behaviour.

FileTypeConfig? healthFileTypeResolver(
  String normalisedPath,
  String? basePath,
) {
  bool matches(String dirName) =>
      normalisedPath.contains('/$dirName') ||
      normalisedPath.contains('$dirName/') ||
      normalisedPath.endsWith(dirName);

  if (matches('blood_pressure')) {
    return const FileTypeConfig(
      typeId: 'blood_pressure',
      displayName: 'Blood Pressure Data',
      showCsvButtons: true,
      formatConfig: HealthDataFormats.bloodPressure,
      uploadTooltip: _healthUploadTooltip,
    );
  } else if (matches('vaccination')) {
    return const FileTypeConfig(
      typeId: 'vaccination',
      displayName: 'Vaccination Data',
      showCsvButtons: true,
      formatConfig: HealthDataFormats.vaccination,
      uploadTooltip: _healthUploadTooltip,
    );
  } else if (matches('medication')) {
    return const FileTypeConfig(
      typeId: 'medication',
      displayName: 'Medication Data',
      showCsvButtons: true,
      formatConfig: HealthDataFormats.medication,
      uploadTooltip: _healthUploadTooltip,
    );
  } else if (matches('diary')) {
    return const FileTypeConfig(
      typeId: 'diary',
      displayName: 'Appointments Data',
      showCsvButtons: true,
      formatConfig: HealthDataFormats.diary,
      uploadTooltip: _healthUploadTooltip,
    );
  } else if (matches('profile')) {
    return const FileTypeConfig(
      typeId: 'profile',
      displayName: 'Profile Data',
      showProfileButtons: true,
      formatConfig: HealthDataFormats.profile,
      uploadTooltip: _healthUploadTooltip,
    );
  }

  // No match — let solidui use its generic behaviour.

  return null;
}

// Health-specific folder name overrides.

/// Maps directory basenames to user-friendly display names for the file
/// browser path bar.

const Map<String, String> healthFolderNameOverrides = {
  'diary': 'Appointments Data',
  'health_profile': 'Health Profile Data',
  'blood_pressure': 'Blood Pressure Data',
  'medication': 'Medication Data',
  'vaccination': 'Vaccination Data',
  'profile': 'Profile Data',
  'health_plan': 'Health Plan Data',
  'pathology': 'Pathology Data',
};
