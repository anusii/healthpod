/// Utility function for constructing Pod paths.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
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
/// Authors: Kevin Wang.

library;

import 'package:healthpod/constants/paths.dart';

/// Constructs a path for a feature in the Pod.
///
/// This function standardizes the path construction for Pod features,
/// ensuring consistency across the application.
///
/// Parameters:
/// - [feature]: The feature name (e.g., 'blood_pressure', 'vaccination').
/// - [filename]: Optional filename to append to the path.
///
/// Returns a string representing the full path in the Pod.
///
/// Example:
/// ```dart
/// // Get directory path
/// final dirPath = getFeaturePath('blood_pressure');
/// // Returns: 'healthpod/data/blood_pressure'
///
/// // Get file path
/// final filePath = getFeaturePath('blood_pressure', 'bp_2023-05-15T14-30-22.json.enc.ttl');
/// // Returns: 'healthpod/data/blood_pressure/bp_2023-05-15T14-30-22.json.enc.ttl'
/// ```

String getFeaturePath(String feature, [String? filename]) {
  final basePath = '$kHealthDataBasePath/$feature';
  return filename != null ? '$basePath/$filename' : basePath;
}
