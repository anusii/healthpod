/// Utility function for constructing Pod directory paths.
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

/// Constructs a path for a data directory in the Pod.
///
/// This function standardizes the path construction for Pod data directories,
/// ensuring consistency across the application.
///
/// Parameters:
/// - [dataType]: The type of data (e.g., 'blood_pressure', 'vaccination').
///
/// Returns a string representing the full path to the data directory in the Pod.
///
/// Example:
/// ```dart
/// final dirPath = constructPodDirPath('blood_pressure');
/// // Returns: 'healthpod/data/blood_pressure'
/// ```

String constructPodDirPath(String dataType) {
  return 'healthpod/data/$dataType';
}
