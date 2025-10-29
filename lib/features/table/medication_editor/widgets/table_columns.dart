/// Table column configuration for medication editor.
///
// Time-stamp: <Tuesday 2025-04-29 15:45:00 +1000 Graham Williams>
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
/// Authors: Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

/// Utility class for configuring medication table columns based on screen width.

class MedicationTableColumns {
  const MedicationTableColumns._();

  /// Gets the list of columns for the DataTable based on screen width.
  ///
  /// Implements responsive column visibility:
  /// - Base columns (Name, Dosage) always visible
  /// - Frequency visible when width > 500
  /// - Start Date visible when width > 700
  /// - Notes visible when width > 900
  /// - Actions column always visible

  static List<DataColumn> getColumns(double width) {
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Dosage')),
    ];

    if (width > 500) {
      columns.add(const DataColumn(label: Text('Frequency')));
    }

    if (width > 700) {
      columns.add(const DataColumn(label: Text('Start Date')));
    }

    if (width > 900) {
      columns.add(const DataColumn(label: Text('Notes')));
    }

    columns.add(const DataColumn(label: Text('Actions')));

    return columns;
  }
}
