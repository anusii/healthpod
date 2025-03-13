/// Utility function for formatting timestamps for filenames.
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
/// Authors: Kevin Wang

library;

/// Formats a DateTime object into a string suitable for use in filenames.
///
/// The format is YYYY-MM-DDThh-mm-ss, which ensures proper sorting and
/// avoids characters that might be problematic in filenames.
/// The 'T' separator is used between date and time to match ISO 8601 format.
///
/// Example: 2023-05-15T14-30-22 for May 15, 2023, 2:30:22 PM

String formatTimestampForFilename(DateTime dt) {
  final year = dt.year.toString();
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');

  return '$year-$month-${day}T$hour-$minute-$second';
}

/// Formats a DateTime object into a string suitable for use in filenames with underscore separator.
/// This is provided for backward compatibility with older files.
///
/// The format is YYYY-MM-DD_HH-MM-SS.
///
/// Example: 2023-05-15_14-30-22 for May 15, 2023, 2:30:22 PM

String formatTimestampForFilenameWithUnderscore(DateTime dt) {
  final year = dt.year.toString();
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');

  return '$year-$month-${day}_$hour-$minute-$second';
}
