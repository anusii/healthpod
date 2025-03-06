/// File item model.
///
// Time-stamp: <Friday 2025-02-14 08:40:39 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

/// Represents a single file with its metadata such as name, path and date modified.
///
/// This model is used across the file module for consistent file representation.
/// It provides a common interface for file operations and UI components.

class FileItem {
  /// The name of the file.
  
  final String name;

  /// The full path to the file.
  
  final String path;

  /// The date and time the file was last modified.
  
  final DateTime dateModified;

  /// Creates a new [FileItem] instance.
  ///
  /// Parameters:
  /// - [name]: The name of the file.
  /// - [path]: The full path to the file.
  /// - [dateModified]: The date and time the file was last modified.

  FileItem({
    required this.name,
    required this.path,
    required this.dateModified,
  });
} 