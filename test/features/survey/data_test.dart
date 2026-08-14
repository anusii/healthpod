/// Tests for survey data ordering and de-duplication.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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

import 'package:healthpod/features/survey/data.dart';

Map<String, dynamic> observation(String timestamp) => {
      'timestamp': timestamp,
      'responses': {'systolic': 120, 'diastolic': 80},
    };

void main() {
  test('keeps every observation recorded on the same day', () {
    final entries = SurveyData.sortAndDeduplicate([
      observation('2025-09-28 08:12:44'),
      observation('2025-09-28 12:30:55'),
      observation('2025-09-28 08:23:48'),
      observation('2025-09-13 12:30:55'),
    ]);

    expect(
      entries.map((e) => e['timestamp']),
      [
        '2025-09-13 12:30:55',
        '2025-09-28 08:12:44',
        '2025-09-28 08:23:48',
        '2025-09-28 12:30:55',
      ],
    );
  });

  test('drops an observation repeated at the same timestamp', () {
    final entries = SurveyData.sortAndDeduplicate([
      observation('2025-09-28T08:12:44'),
      observation('2025-09-28 08:12:44'),
    ]);

    expect(entries.length, 1);
  });
}
