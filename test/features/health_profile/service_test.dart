/// Tests for reading the health profile records.
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

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/features/health_profile/model.dart';
import 'package:healthpod/features/health_profile/service.dart';

HealthProfileEntry? entry(String timestamp, Map<String, dynamic> responses) =>
    HealthProfileEntry.fromJson(
      {'timestamp': timestamp, 'responses': responses},
      'health_profile_$timestamp.json.enc.ttl',
    );

void main() {
  group('Reading a record', () {
    test('keeps only the measurements recorded', () {
      final record = entry('2026-08-01T09:00:00', {
        'weight': 80.5,
        'height': null,
        'waist': '92',
        'hip': 'not a number',
      })!;

      expect(record.values, {'weight': 80.5, 'waist': 92.0});
      expect(record.timestamp, DateTime(2026, 8, 1, 9));
    });

    test('is dropped without a usable timestamp', () {
      const measured = {
        'responses': {'weight': 80},
      };

      expect(HealthProfileEntry.fromJson(measured, 'f.ttl'), isNull);
    });
  });

  group('Latest values', () {
    test('take the most recent entry that recorded each measurement', () {
      final entries = [
        entry('2026-06-01T09:00:00', {'weight': 82, 'height': 180})!,
        entry('2026-07-01T09:00:00', {'weight': 81})!,
        entry('2026-08-01T09:00:00', {'waist': 92, 'hip': 100})!,
      ];

      final latest = HealthProfileService.latestValues(entries);

      // The height keeps the date it was recorded, not the date of the most
      // recent entry.

      expect(latest['weight']?.value, 81);
      expect(latest['weight']?.updated, DateTime(2026, 7, 1, 9));
      expect(latest['height']?.value, 180);
      expect(latest['height']?.updated, DateTime(2026, 6, 1, 9));
      expect(latest['waist']?.value, 92);
      expect(latest['hip']?.updated, DateTime(2026, 8, 1, 9));
    });

    test('are empty when nothing has been recorded', () {
      expect(HealthProfileService.latestValues([]), isEmpty);
    });
  });
}
