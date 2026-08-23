/// Tests for reading the analysis the Analyser Pod shares back.
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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthpod/constants/analyser.dart';
import 'package:healthpod/features/bp/analyser/model.dart';
import 'package:healthpod/features/bp/analyser/result_service.dart';

/// A minimal PNG: the signature is all the decoder here checks.

final List<int> _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2];

Map<String, dynamic> resultJson({
  String generatedAt = '2026-08-21T09:15:00+00:00',
  Object? chart,
}) =>
    {
      'schema_version': 1,
      'kind': 'pod-average',
      'generated_at': generatedAt,
      'average': {'systolic': 125.0, 'diastolic': 82.5, 'heart_rate': 67.0},
      'pod': {'observation_count': 12},
      'cohort': {
        'pod_count': 3,
        'average_of_averages': {
          'systolic': 134.2,
          'diastolic': 86.9,
          'heart_rate': 71.4,
        },
      },
      if (chart != null) 'chart': chart,
    };

void main() {
  group('Where the result lives', () {
    test('reduces a WebID to the label the analyser uses', () {
      expect(
        BPAnalyserResultService.podId(
          'https://solid.dev.empwr.au/alice/profile/card#me',
        ),
        'solid.dev.empwr.au-alice',
      );
    });

    test('handles a Pod hosted at the server root', () {
      expect(
        BPAnalyserResultService.podId(
          'https://alice.example.org/profile/card#me',
        ),
        'alice.example.org',
      );
    });

    test('builds the URL the analyser publishes to', () {
      final url = BPAnalyserResultService.resultUrl(
        'https://solid.dev.empwr.au/alice/profile/card#me',
      );

      expect(url, startsWith('https://solid.dev.empwr.au/Analyser'));
      expect(url, contains(Analyser.resultsPathFragment));
      expect(url, contains('solid.dev.empwr.au-alice'));
      expect(url, endsWith(Analyser.podAverageFileName));
      // A single slash between every segment.
      expect(url.substring('https://'.length), isNot(contains('//')));
    });
  });

  group('Classifying a failed read', () {
    // A wrong key surfaces from PointyCastle as a padding fault, which is the
    // only signal available that the content arrived but could not be opened.

    test('recognises a padding fault as a decryption failure', () {
      expect(
        BPAnalyserResultService.isDecryptionFailure(
          ArgumentError('Invalid or corrupted pad block'),
        ),
        isTrue,
      );
    });

    test('recognises the message even without the type', () {
      expect(
        BPAnalyserResultService.isDecryptionFailure(
          Exception('Invalid argument(s): Invalid or corrupted pad block'),
        ),
        isTrue,
      );
    });

    test('does not mistake a missing resource for a bad key', () {
      expect(
        BPAnalyserResultService.isDecryptionFailure(
          Exception('https://example.org/x does not exist'),
        ),
        isFalse,
      );
    });
  });

  group('Reading a result document', () {
    test('takes both sets of averages', () {
      final result = AnalyserResult.fromJson(resultJson());

      expect(result.own.systolic, 125.0);
      expect(result.own.diastolic, 82.5);
      expect(result.own.heartRate, 67.0);
      expect(result.everyone.systolic, 134.2);
      expect(result.observationCount, 12);
      expect(result.podCount, 3);
    });

    test('decodes the chart', () {
      final result = AnalyserResult.fromJson(
        resultJson(
          chart: {
            'format': 'png',
            'encoding': 'base64',
            'data': base64Encode(_png),
          },
        ),
      );

      expect(result.chart, isNotNull);
      expect(result.chart!.sublist(0, 8), _png.sublist(0, 8));
    });

    test('survives a result with no chart', () {
      final result = AnalyserResult.fromJson(resultJson());

      expect(result.chart, isNull);
      expect(result.own.systolic, 125.0);
    });

    test('ignores a chart in a format it cannot show', () {
      final result = AnalyserResult.fromJson(
        resultJson(
          chart: {
            'format': 'svg',
            'encoding': 'base64',
            'data': base64Encode(_png),
          },
        ),
      );

      expect(result.chart, isNull);
    });

    test('ignores a corrupted chart rather than failing', () {
      final result = AnalyserResult.fromJson(
        resultJson(
          chart: {'format': 'png', 'encoding': 'base64', 'data': 'not base64!'},
        ),
      );

      expect(result.chart, isNull);
      expect(result.observationCount, 12);
    });

    test('refuses a document that is not an analyser result', () {
      expect(
        () => AnalyserResult.fromJson({'kind': 'something-else'}),
        throwsFormatException,
      );
    });

    test('refuses a result with no timestamp', () {
      final json = resultJson()..remove('generated_at');

      expect(() => AnalyserResult.fromJson(json), throwsFormatException);
    });
  });

  group('Telling a fresh result from a stale one', () {
    AnalyserResult at(String moment) =>
        AnalyserResult.fromJson(resultJson(generatedAt: moment));

    test('accepts anything when nothing was published before', () {
      expect(at('2026-08-21T09:15:00+00:00').isFresherThan(null), isTrue);
    });

    test('rejects the result that was already there', () {
      final result = at('2026-08-21T09:15:00+00:00');

      expect(
        result.isFresherThan(DateTime.utc(2026, 8, 21, 9, 15)),
        isFalse,
      );
    });

    test('accepts a result from a later run', () {
      final result = at('2026-08-21T09:20:00+00:00');

      expect(
        result.isFresherThan(DateTime.utc(2026, 8, 21, 9, 15)),
        isTrue,
      );
    });

    test('does not depend on this device agreeing with the server clock', () {
      // A result stamped well in the past is still the new one, as long as it
      // is not the result that was there before.
      final result = at('2020-01-01T00:00:00+00:00');

      expect(
        result.isFresherThan(DateTime.utc(2026, 8, 21, 9, 15)),
        isTrue,
      );
    });

    test('reads a timestamp in any time zone as the same moment', () {
      // 09:15 UTC, written as 19:15 in AEST.
      final result = at('2026-08-21T19:15:00+10:00');

      expect(result.generatedAt, DateTime.utc(2026, 8, 21, 9, 15));
      expect(
        result.isFresherThan(DateTime.utc(2026, 8, 21, 9, 15)),
        isFalse,
      );
    });
  });
}
