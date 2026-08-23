/// Tests for sharing blood pressure readings with the Analyser Pod.
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

import 'package:flutter_test/flutter_test.dart';

import 'package:solidpod/solidpod.dart' show AccessMode, getAccessMode;

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/share_service.dart';

void main() {
  group('Permissions granted to the Analyser', () {
    // grantPermission() casts each entry to a String internally, so passing
    // AccessMode values compiles but fails at run time. These tests pin the
    // form solidpod actually accepts.

    test('are plain strings, not enum values', () {
      expect(BPAnalyserShareService.permissions, everyElement(isA<String>()));
    });

    test('are understood by solidpod', () {
      expect(
        BPAnalyserShareService.permissions.map(getAccessMode).toList(),
        [AccessMode.read],
      );
    });

    test('grant read access and nothing more', () {
      expect(BPAnalyserShareService.permissions, hasLength(1));
      expect(
        BPAnalyserShareService.permissions.map(getAccessMode),
        isNot(contains(AccessMode.write)),
      );
      expect(
        BPAnalyserShareService.permissions.map(getAccessMode),
        isNot(contains(AccessMode.control)),
      );
    });
  });

  group('Choosing which resources to share', () {
    test('includes encrypted readings', () {
      expect(
        BPAnalyserShareService.isShareable(
          'blood_pressure_2026-08-21T00-43-42.json.enc.ttl',
        ),
        isTrue,
      );
    });

    test('includes plain JSON readings', () {
      expect(
        BPAnalyserShareService.isShareable('blood_pressure_2026-08-21.json'),
        isTrue,
      );
    });

    test('skips access control files', () {
      expect(
        BPAnalyserShareService.isShareable(
          'blood_pressure_2026-08-21T00-43-42.json.enc.ttl.acl',
        ),
        isFalse,
      );
    });

    test('skips anything else in the folder', () {
      expect(BPAnalyserShareService.isShareable('notes.txt'), isFalse);
      expect(BPAnalyserShareService.isShareable('readme.md'), isFalse);
    });
  });

  group('The Analyser address', () {
    test('is a WebID pointing at a profile document', () {
      expect(Analyser.webId, startsWith('https://'));
      expect(Analyser.webId, endsWith('/profile/card#me'));
    });

    test('publishes results under the folder the app looks in', () {
      expect(Analyser.resultsPathFragment, startsWith('/healthpod/data/'));
      expect(Analyser.podAverageFileName, endsWith('.enc.ttl'));
      expect(Analyser.cohortAverageFileName, endsWith('.enc.ttl'));
    });
  });
}
