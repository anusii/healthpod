/// A single set of health profile measurements recorded on the pod.
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
/// Authors: Graham Williams

library;

import 'package:healthpod/constants/health_profile.dart';

/// A measurement together with the date it was recorded.

typedef DatedValue = ({double value, DateTime updated});

/// One health profile record: the measurements entered at a point in time.
///
/// Only the measurements actually entered are held, so updating a weight on
/// its own leaves the dates recorded against the other measurements alone.

class HealthProfileEntry {
  const HealthProfileEntry({
    required this.timestamp,
    required this.values,
    required this.filename,
  });

  /// When the measurements were recorded.

  final DateTime timestamp;

  /// The measurements recorded, keyed by field name.

  final Map<String, double> values;

  /// The pod file this record was read from, needed to delete it.

  final String filename;

  /// Builds a record from the JSON stored on the pod.
  ///
  /// Returns null for anything without a usable timestamp, since a record
  /// that cannot be placed in time cannot be shown or superseded.

  static HealthProfileEntry? fromJson(
    Map<String, dynamic> json,
    String filename,
  ) {
    final timestamp = DateTime.tryParse('${json['timestamp']}');
    if (timestamp == null) return null;

    final responses = json['responses'];
    final values = <String, double>{};
    if (responses is Map) {
      for (final field in HealthProfileConstants.units.keys) {
        final value = _toDouble(responses[field]);
        if (value != null) values[field] = value;
      }
    }

    return HealthProfileEntry(
      timestamp: timestamp,
      values: values,
      filename: filename,
    );
  }

  /// Reads a measurement however it was stored, as a number or as text.

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
